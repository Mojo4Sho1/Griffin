#!/usr/bin/env python3
"""Generate a resumable SQLite-first analysis bundle for an Nsight Compute report."""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import sqlite3
import subprocess
import sys
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

CORE_SECTIONS: list[tuple[str, str]] = [
    ("LaunchStats", "Launch Statistics"),
    ("Occupancy", "Occupancy"),
    ("SchedulerStats", "Scheduler Statistics"),
    ("WarpStateStats", "Warp State Statistics"),
    ("ComputeWorkloadAnalysis", "Compute Workload Analysis"),
    ("MemoryWorkloadAnalysis", "Memory Workload Analysis"),
    ("SpeedOfLight", "GPU Speed Of Light Throughput"),
    ("WorkloadDistribution", "GPU and Memory Workload Distribution"),
]
SECTION_DISPLAY_NAMES = dict(CORE_SECTIONS)
SECTION_PROFILES: dict[str, list[str]] = {
    "core": [section_id for section_id, _ in CORE_SECTIONS],
}
EMBEDDED_SECTION_NAMES = [
    "Compute Workload Analysis",
    "GPU and Memory Workload Distribution",
    "Memory Workload Analysis",
    "Scheduler Statistics",
    "Warp State Statistics",
    "GPU Speed Of Light Roofline Chart",
    "GPU Speed Of Light Throughput",
    "Launch Statistics",
    "Occupancy",
    "Theoretical Occupancy",
]
SUCCESS_STATUSES = {"success", "cached_success"}
LAUNCH_UNDERFILL_RE = re.compile(r"only ([0-9]+(?:\.[0-9]+)?) full waves")
SCHEDULER_RE = re.compile(
    r"every ([0-9]+(?:\.[0-9]+)?) cycles.*maximum of ([0-9]+(?:\.[0-9]+)?) "
    r"warps per scheduler, this kernel allocates an average of "
    r"([0-9]+(?:\.[0-9]+)?) active warps per scheduler, but only an average of "
    r"([0-9]+(?:\.[0-9]+)?) warps were eligible per cycle"
)
FINISHED_IMPORT_RE = re.compile(
    r"^\[(?P<timestamp>[^\]]+)\] Finished import for (?P<target>[^:]+): "
    r"status=(?P<status>\S+) elapsed_sec=(?P<elapsed>[0-9]+(?:\.[0-9]+)?) "
    r"line_count=(?P<line_count>[0-9]+)"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a resumable derived SQLite analysis bundle for an Nsight Compute report."
    )
    parser.add_argument("--run-id", required=True, help="Canonical run id.")
    parser.add_argument(
        "--rep-path",
        help="Path to .ncu-rep file (default: artifacts/profiles/ncu/<run_id>.ncu-rep).",
    )
    parser.add_argument(
        "--out-dir",
        help="Output bundle directory (default: artifacts/profiles/analysis/<run_id>).",
    )
    parser.add_argument(
        "--runs-path",
        default="profiling/RUNS.md",
        help="Path to RUNS.md used to infer the recorded kernel filter.",
    )
    parser.add_argument(
        "--kernel-filter",
        help="Override the kernel filter recorded in RUNS.md (example: regex:ampere_sgemm...).",
    )
    parser.add_argument(
        "--sections-profile",
        default="core",
        help="Section profile to import (default: core). Accepts a known profile name or a comma-separated list of section identifiers.",
    )
    parser.add_argument(
        "--session-timeout-sec",
        type=int,
        help="Optional timeout for the session-page import. Omit for no timeout.",
    )
    parser.add_argument(
        "--section-timeout-sec",
        type=int,
        help="Optional timeout for per-section imports. Omit for no timeout.",
    )
    parser.add_argument(
        "--import-timeout-sec",
        type=int,
        help="Deprecated alias that applies the same timeout to both session and section imports when the newer flags are omitted.",
    )
    parser.add_argument(
        "--sample-launches",
        type=int,
        default=250,
        help="Maximum number of evenly distributed launch IDs to mark as sampled in SQLite (default: 250).",
    )
    parser.add_argument(
        "--strings-min-len",
        type=int,
        default=20,
        help="Minimum string length passed to the strings utility.",
    )
    return parser.parse_args()


def iso_now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def log_message(log_path: Path, message: str) -> None:
    line = f"[{iso_now_utc()}] {message}"
    print(line, flush=True)
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")


def infer_kernel_filter(run_id: str, runs_path: Path) -> str | None:
    if not runs_path.exists():
        return None

    text = runs_path.read_text(errors="replace")
    marker = f"### Run: {run_id}"
    if marker not in text:
        return None

    _, tail = text.split(marker, 1)
    block = tail.split("\n### Run:", 1)[0]

    patterns = [
        re.compile(r"-k\s+(regex:[^\s`]+)"),
        re.compile(r"--kernel-name\s+(regex:[^\s`]+)"),
        re.compile(r'--kernel-name\s+"(regex:[^"]+)"'),
    ]
    for pattern in patterns:
        match = pattern.search(block)
        if match:
            return match.group(1)
    return None


def kernel_name_from_filter(kernel_filter: str | None) -> str | None:
    if not kernel_filter:
        return None
    if kernel_filter.startswith("regex:"):
        return kernel_filter.split("regex:", 1)[1]
    return kernel_filter


def resolve_timeouts(args: argparse.Namespace) -> tuple[int | None, int | None]:
    session_timeout = args.session_timeout_sec
    section_timeout = args.section_timeout_sec
    if args.import_timeout_sec is not None:
        if session_timeout is None:
            session_timeout = args.import_timeout_sec
        if section_timeout is None:
            section_timeout = args.import_timeout_sec
    return session_timeout, section_timeout


def resolve_sections(profile: str) -> list[str]:
    if profile in SECTION_PROFILES:
        return list(SECTION_PROFILES[profile])
    sections = [value.strip() for value in profile.split(",") if value.strip()]
    if not sections:
        raise SystemExit(f"Invalid sections profile: {profile!r}")
    return sections


def display_name_for_section(section_id: str) -> str:
    return SECTION_DISPLAY_NAMES.get(section_id, section_id)


def load_historical_import_timings(
    metrics_json_path: Path,
    progress_log_path: Path,
) -> dict[str, dict[str, float]]:
    history: dict[str, dict[str, float]] = {}

    if metrics_json_path.exists():
        try:
            payload = json.loads(metrics_json_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            payload = None
        if isinstance(payload, dict):
            attempts: list[dict[str, object]] = []
            session_attempt = payload.get("session_import_attempt")
            if isinstance(session_attempt, dict):
                attempts.append(session_attempt)
            section_attempts = payload.get("section_import_attempts", [])
            if isinstance(section_attempts, list):
                attempts.extend(item for item in section_attempts if isinstance(item, dict))
            for attempt in attempts:
                target_name = attempt.get("section_id") or attempt.get("page")
                if not isinstance(target_name, str) or not target_name:
                    continue
                import_elapsed = attempt.get("import_elapsed_sec")
                if import_elapsed is None and attempt.get("status") == "success":
                    import_elapsed = attempt.get("elapsed_sec")
                try:
                    elapsed_value = float(import_elapsed) if import_elapsed is not None else None
                except (TypeError, ValueError):
                    elapsed_value = None
                if elapsed_value is not None and elapsed_value > 0:
                    history[target_name] = {"import_elapsed_sec": round(elapsed_value, 3)}

    if progress_log_path.exists():
        for line in progress_log_path.read_text(encoding="utf-8", errors="replace").splitlines():
            match = FINISHED_IMPORT_RE.match(line)
            if not match or match.group("status") != "success":
                continue
            history[match.group("target")] = {
                "import_elapsed_sec": round(float(match.group("elapsed")), 3)
            }

    return history


def line_count(path: Path) -> int:
    if not path.exists() or path.stat().st_size == 0:
        return 0
    with path.open("r", errors="replace") as handle:
        return sum(1 for _ in handle)


def flat_csv_row_count(path: Path) -> int:
    lines = line_count(path)
    return max(lines - 1, 0)


def format_timeout_value(timeout_sec: int | None) -> str:
    return "none" if timeout_sec is None else str(timeout_sec)


def temp_path(path: Path) -> Path:
    return path.with_name(path.name + ".tmp")


def cleanup_temp_files(*paths: Path) -> None:
    for path in paths:
        if path.exists():
            path.unlink()


def output_path_for_attempt(final_path: Path, tmp_path: Path) -> Path:
    if final_path.exists():
        return final_path
    if tmp_path.exists():
        return tmp_path
    return final_path


def run_import_csv(
    rep_path: Path,
    page: str,
    kernel_filter: str | None,
    timeout_sec: int | None,
    stdout_path: Path,
    stderr_path: Path,
    log_path: Path,
    historical_imports: dict[str, dict[str, float]] | None = None,
    section_id: str | None = None,
) -> dict[str, object]:
    target_name = section_id or page
    historical_import = (historical_imports or {}).get(target_name, {})
    import_elapsed_sec = historical_import.get("import_elapsed_sec")
    if stdout_path.exists() and stdout_path.stat().st_size > 0:
        log_message(log_path, f"Reusing existing complete import for {target_name}: {stdout_path}")
        return {
            "page": page,
            "section_id": section_id,
            "display_name": display_name_for_section(target_name),
            "status": "cached_success",
            "timeout_sec": timeout_sec,
            "elapsed_sec": 0.0,
            "import_elapsed_sec": import_elapsed_sec,
            "stdout_path": str(stdout_path),
            "stderr_path": str(stderr_path),
            "line_count": line_count(stdout_path),
            "row_count": flat_csv_row_count(stdout_path),
            "return_code": 0,
            "reused_existing": 1,
        }

    tmp_stdout = temp_path(stdout_path)
    tmp_stderr = temp_path(stderr_path)
    cleanup_temp_files(tmp_stdout, tmp_stderr)

    cmd = ["ncu", "--import", str(rep_path)]
    if kernel_filter:
        cmd.extend(["--kernel-name", kernel_filter])
    cmd.extend(["--page", page])
    if section_id:
        cmd.extend(["--section", section_id])
    cmd.append("--csv")

    log_message(
        log_path,
        "Starting import: "
        + " ".join(cmd)
        + f" (timeout_sec={format_timeout_value(timeout_sec)})",
    )

    start = time.time()
    status = "error_empty"
    return_code: int | None = None
    try:
        with tmp_stdout.open("w", encoding="utf-8") as out_handle, tmp_stderr.open(
            "w", encoding="utf-8"
        ) as err_handle:
            completed = subprocess.run(
                cmd,
                stdout=out_handle,
                stderr=err_handle,
                text=True,
                check=False,
                timeout=timeout_sec,
            )
        return_code = completed.returncode
        if return_code == 0 and tmp_stdout.exists() and tmp_stdout.stat().st_size > 0:
            tmp_stdout.replace(stdout_path)
            tmp_stderr.replace(stderr_path)
            status = "success"
        elif return_code == 0:
            status = "empty"
        else:
            status = "error_partial" if tmp_stdout.exists() and tmp_stdout.stat().st_size > 0 else "error_empty"
    except subprocess.TimeoutExpired:
        status = "timeout_partial" if tmp_stdout.exists() and tmp_stdout.stat().st_size > 0 else "timeout_empty"
    except FileNotFoundError:
        status = "missing_ncu"

    elapsed = round(time.time() - start, 3)
    result_stdout = output_path_for_attempt(stdout_path, tmp_stdout)
    result_stderr = output_path_for_attempt(stderr_path, tmp_stderr)
    attempt = {
        "page": page,
        "section_id": section_id,
        "display_name": display_name_for_section(target_name),
        "status": status,
        "timeout_sec": timeout_sec,
        "elapsed_sec": elapsed,
        "import_elapsed_sec": elapsed if status == "success" else import_elapsed_sec,
        "stdout_path": str(result_stdout),
        "stderr_path": str(result_stderr),
        "line_count": line_count(result_stdout),
        "row_count": flat_csv_row_count(result_stdout),
        "return_code": return_code,
        "reused_existing": 0,
    }
    log_message(
        log_path,
        f"Finished import for {target_name}: status={status} elapsed_sec={elapsed} line_count={attempt['line_count']}",
    )
    return attempt


def parse_sectioned_csv(path: Path) -> dict[str, dict[str, object]]:
    if not path.exists() or path.stat().st_size == 0:
        return {}

    lines = path.read_text(errors="replace").splitlines()
    sections: dict[str, dict[str, object]] = {}
    index = 0
    while index < len(lines):
        title = lines[index].strip()
        if title and index + 1 < len(lines) and lines[index + 1].startswith('"'):
            header = next(csv.reader([lines[index + 1]]))
            rows = []
            cursor = index + 2
            while cursor < len(lines) and lines[cursor].strip():
                rows.append(next(csv.reader([lines[cursor]])))
                cursor += 1
            sections[title] = {"header": header, "rows": rows}
            index = cursor
        else:
            index += 1
    return sections


def extract_strings(rep_path: Path, min_len: int, target_kernel: str | None) -> dict[str, object]:
    cmd = ["strings", "-n", str(min_len), str(rep_path)]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, errors="replace")

    section_counts: Counter[str] = Counter()
    target_kernel_hits = 0
    rule_rows: list[dict[str, object]] = []
    excerpt_lines: list[str] = []

    for raw_line in proc.stdout or []:
        line = raw_line.strip()
        if not line:
            continue

        if line in EMBEDDED_SECTION_NAMES:
            section_counts[line] += 1
            excerpt_lines.append(line)

        if target_kernel and target_kernel in line:
            target_kernel_hits += 1

        if line.startswith("This kernel grid is too small"):
            waves = None
            match = LAUNCH_UNDERFILL_RE.search(line)
            if match:
                waves = float(match.group(1))
            rule_rows.append(
                {
                    "rule_kind": "launch_underfill",
                    "rule_text": line,
                    "full_waves": waves,
                    "issue_every_cycles": None,
                    "active_warps_per_scheduler": None,
                    "eligible_warps_per_cycle": None,
                    "max_warps_per_scheduler": None,
                }
            )
            excerpt_lines.append(line)
            continue

        if line.startswith("Every scheduler is capable of issuing one instruction per cycle"):
            issue_every_cycles = None
            max_warps = None
            active_warps = None
            eligible_warps = None
            match = SCHEDULER_RE.search(line)
            if match:
                issue_every_cycles = float(match.group(1))
                max_warps = float(match.group(2))
                active_warps = float(match.group(3))
                eligible_warps = float(match.group(4))
            rule_rows.append(
                {
                    "rule_kind": "scheduler_underutilization",
                    "rule_text": line,
                    "full_waves": None,
                    "issue_every_cycles": issue_every_cycles,
                    "active_warps_per_scheduler": active_warps,
                    "eligible_warps_per_cycle": eligible_warps,
                    "max_warps_per_scheduler": max_warps,
                }
            )
            excerpt_lines.append(line)

    stderr_text = proc.stderr.read() if proc.stderr is not None else ""
    return_code = proc.wait()
    return {
        "section_counts": dict(section_counts),
        "target_kernel_hits": target_kernel_hits,
        "rule_rows": rule_rows,
        "stderr_text": stderr_text,
        "return_code": return_code,
        "excerpt_lines": excerpt_lines,
    }


def aggregate_rule_metrics(rule_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    metric_values: dict[str, list[float]] = {
        "full_waves": [],
        "issue_every_cycles": [],
        "active_warps_per_scheduler": [],
        "eligible_warps_per_cycle": [],
        "max_warps_per_scheduler": [],
    }
    for row in rule_rows:
        for key in metric_values:
            value = row.get(key)
            if isinstance(value, (int, float)):
                metric_values[key].append(float(value))

    units = {
        "full_waves": "waves",
        "issue_every_cycles": "cycles",
        "active_warps_per_scheduler": "warps",
        "eligible_warps_per_cycle": "warps",
        "max_warps_per_scheduler": "warps",
    }

    derived = []
    for metric_name, values in metric_values.items():
        if not values:
            continue
        derived.append(
            {
                "metric_name": metric_name,
                "unit": units[metric_name],
                "source": "strings_rule_parse",
                "occurrences": len(values),
                "min_value": min(values),
                "max_value": max(values),
                "avg_value": sum(values) / len(values),
            }
        )
    return derived


def safe_float(value: str | None) -> float | None:
    if value is None:
        return None
    text = value.strip()
    if not text:
        return None
    if text.endswith("%"):
        text = text[:-1]
    text = text.replace(",", "")
    try:
        return float(text)
    except ValueError:
        return None


def safe_int(value: str | None) -> int | None:
    if value is None:
        return None
    text = value.strip()
    if not text:
        return None
    try:
        return int(text)
    except ValueError:
        return None


def choose_even_sample(values: list[int], sample_size: int) -> list[int]:
    if sample_size <= 0 or not values:
        return []
    if len(values) <= sample_size:
        return values
    if sample_size == 1:
        return [values[0]]
    selected_indexes = {
        round(index * (len(values) - 1) / (sample_size - 1)) for index in range(sample_size)
    }
    return [values[index] for index in sorted(selected_indexes)]


def create_schema(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.executescript(
        """
        CREATE TABLE bundle_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
        CREATE TABLE import_attempts (
          page TEXT PRIMARY KEY,
          status TEXT NOT NULL,
          timeout_sec INTEGER,
          elapsed_sec REAL NOT NULL,
          import_elapsed_sec REAL,
          stdout_path TEXT NOT NULL,
          stderr_path TEXT NOT NULL,
          line_count INTEGER NOT NULL,
          row_count INTEGER NOT NULL,
          return_code INTEGER,
          reused_existing INTEGER NOT NULL
        );
        CREATE TABLE section_import_attempts (
          section_id TEXT PRIMARY KEY,
          display_name TEXT NOT NULL,
          page TEXT NOT NULL,
          status TEXT NOT NULL,
          timeout_sec INTEGER,
          elapsed_sec REAL NOT NULL,
          import_elapsed_sec REAL,
          stdout_path TEXT NOT NULL,
          stderr_path TEXT NOT NULL,
          line_count INTEGER NOT NULL,
          row_count INTEGER NOT NULL,
          return_code INTEGER,
          reused_existing INTEGER NOT NULL
        );
        CREATE TABLE launch_settings (
          attribute TEXT NOT NULL,
          value TEXT NOT NULL
        );
        CREATE TABLE session_attributes (
          attribute TEXT NOT NULL,
          value TEXT NOT NULL
        );
        CREATE TABLE processes (
          process_id TEXT NOT NULL,
          process_name TEXT NOT NULL
        );
        CREATE TABLE device_attributes (
          device TEXT NOT NULL,
          attribute TEXT NOT NULL,
          value TEXT NOT NULL
        );
        CREATE TABLE report_sections (
          section_name TEXT PRIMARY KEY,
          occurrences INTEGER NOT NULL
        );
        CREATE TABLE kernel_targets (
          kernel_filter TEXT,
          kernel_name TEXT,
          matched_in_strings INTEGER NOT NULL,
          string_occurrences INTEGER NOT NULL
        );
        CREATE TABLE rule_occurrences (
          rule_kind TEXT NOT NULL,
          occurrence_index INTEGER NOT NULL,
          rule_text TEXT NOT NULL,
          full_waves REAL,
          issue_every_cycles REAL,
          active_warps_per_scheduler REAL,
          eligible_warps_per_cycle REAL,
          max_warps_per_scheduler REAL
        );
        CREATE TABLE derived_metrics (
          metric_name TEXT PRIMARY KEY,
          unit TEXT NOT NULL,
          source TEXT NOT NULL,
          occurrences INTEGER NOT NULL,
          min_value REAL,
          max_value REAL,
          avg_value REAL
        );
        CREATE TABLE extraction_warnings (
          message TEXT NOT NULL
        );
        CREATE TABLE section_metric_values (
          section_id TEXT NOT NULL,
          launch_id INTEGER,
          process_id TEXT,
          process_name TEXT,
          host_name TEXT,
          kernel_name TEXT,
          context TEXT,
          stream TEXT,
          block_size TEXT,
          grid_size TEXT,
          device TEXT,
          cc TEXT,
          section_name TEXT,
          metric_name TEXT,
          metric_unit TEXT,
          metric_value_text TEXT,
          metric_value_num REAL,
          rule_name TEXT,
          rule_type TEXT,
          rule_description TEXT,
          estimated_speedup_type TEXT,
          estimated_speedup REAL
        );
        CREATE TABLE numeric_metric_summaries (
          section_id TEXT NOT NULL,
          metric_name TEXT NOT NULL,
          metric_unit TEXT,
          value_count INTEGER NOT NULL,
          min_value REAL,
          max_value REAL,
          avg_value REAL,
          PRIMARY KEY (section_id, metric_name, metric_unit)
        );
        CREATE TABLE sampled_launches (
          launch_id INTEGER PRIMARY KEY,
          sample_rank INTEGER NOT NULL
        );
        CREATE VIEW sampled_section_metric_values AS
        SELECT values_table.*, launches.sample_rank
        FROM section_metric_values AS values_table
        JOIN sampled_launches AS launches
          ON launches.launch_id = values_table.launch_id;
        """
    )
    conn.commit()


def insert_session_sections(conn: sqlite3.Connection, session_sections: dict[str, dict[str, object]]) -> None:
    cur = conn.cursor()
    if "Launch Settings" in session_sections:
        cur.executemany(
            "INSERT INTO launch_settings(attribute, value) VALUES(?, ?)",
            session_sections["Launch Settings"]["rows"],
        )
    if "Session Info" in session_sections:
        cur.executemany(
            "INSERT INTO session_attributes(attribute, value) VALUES(?, ?)",
            session_sections["Session Info"]["rows"],
        )
    if "Processes" in session_sections:
        cur.executemany(
            "INSERT INTO processes(process_id, process_name) VALUES(?, ?)",
            session_sections["Processes"]["rows"],
        )
    if "Device Attributes" in session_sections:
        device_header = session_sections["Device Attributes"]["header"]
        rows = session_sections["Device Attributes"]["rows"]
        for row in rows:
            attribute = row[0]
            for index, value in enumerate(row[1:], start=1):
                device_name = device_header[index] if index < len(device_header) else f"Device {index - 1}"
                cur.execute(
                    "INSERT INTO device_attributes(device, attribute, value) VALUES(?, ?, ?)",
                    (device_name, attribute, value),
                )
    conn.commit()


def ingest_section_metric_values(
    conn: sqlite3.Connection,
    section_attempts: list[dict[str, object]],
    sample_launches: int,
) -> int:
    cur = conn.cursor()
    insert_sql = """
        INSERT INTO section_metric_values(
          section_id,
          launch_id,
          process_id,
          process_name,
          host_name,
          kernel_name,
          context,
          stream,
          block_size,
          grid_size,
          device,
          cc,
          section_name,
          metric_name,
          metric_unit,
          metric_value_text,
          metric_value_num,
          rule_name,
          rule_type,
          rule_description,
          estimated_speedup_type,
          estimated_speedup
        ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    for attempt in section_attempts:
        if attempt["status"] not in SUCCESS_STATUSES:
            continue
        section_path = Path(str(attempt["stdout_path"]))
        if not section_path.exists() or section_path.stat().st_size == 0:
            continue
        with section_path.open("r", encoding="utf-8", errors="replace", newline="") as handle:
            reader = csv.DictReader(handle)
            batch: list[tuple[object, ...]] = []
            for row in reader:
                batch.append(
                    (
                        attempt["section_id"],
                        safe_int(row.get("ID")),
                        row.get("Process ID"),
                        row.get("Process Name"),
                        row.get("Host Name"),
                        row.get("Kernel Name"),
                        row.get("Context"),
                        row.get("Stream"),
                        row.get("Block Size"),
                        row.get("Grid Size"),
                        row.get("Device"),
                        row.get("CC"),
                        row.get("Section Name"),
                        row.get("Metric Name"),
                        row.get("Metric Unit"),
                        row.get("Metric Value"),
                        safe_float(row.get("Metric Value")),
                        row.get("Rule Name"),
                        row.get("Rule Type"),
                        row.get("Rule Description"),
                        row.get("Estimated Speedup Type"),
                        safe_float(row.get("Estimated Speedup")),
                    )
                )
                if len(batch) >= 1000:
                    cur.executemany(insert_sql, batch)
                    batch.clear()
            if batch:
                cur.executemany(insert_sql, batch)
    conn.commit()

    cur.execute(
        """
        INSERT INTO numeric_metric_summaries(
          section_id,
          metric_name,
          metric_unit,
          value_count,
          min_value,
          max_value,
          avg_value
        )
        SELECT
          section_id,
          metric_name,
          metric_unit,
          COUNT(metric_value_num),
          MIN(metric_value_num),
          MAX(metric_value_num),
          AVG(metric_value_num)
        FROM section_metric_values
        WHERE metric_value_num IS NOT NULL
        GROUP BY section_id, metric_name, metric_unit
        """
    )
    launch_ids = [
        row[0]
        for row in cur.execute(
            "SELECT DISTINCT launch_id FROM section_metric_values WHERE launch_id IS NOT NULL ORDER BY launch_id"
        )
    ]
    sampled_ids = choose_even_sample(launch_ids, sample_launches)
    cur.executemany(
        "INSERT INTO sampled_launches(launch_id, sample_rank) VALUES(?, ?)",
        [(launch_id, index) for index, launch_id in enumerate(sampled_ids, start=1)],
    )
    conn.commit()
    return len(sampled_ids)


def write_sqlite_bundle(
    db_path: Path,
    metadata: dict[str, str],
    session_attempt: dict[str, object],
    section_attempts: list[dict[str, object]],
    session_sections: dict[str, dict[str, object]],
    strings_data: dict[str, object],
    kernel_filter: str | None,
    target_kernel: str | None,
    warnings: list[str],
    sample_launches: int,
) -> int:
    if db_path.exists():
        db_path.unlink()

    conn = sqlite3.connect(db_path)
    create_schema(conn)
    cur = conn.cursor()

    cur.executemany(
        "INSERT INTO bundle_metadata(key, value) VALUES(?, ?)",
        sorted(metadata.items()),
    )
    cur.execute(
        """
        INSERT INTO import_attempts(
          page,
          status,
          timeout_sec,
          elapsed_sec,
          import_elapsed_sec,
          stdout_path,
          stderr_path,
          line_count,
          row_count,
          return_code,
          reused_existing
        ) VALUES(:page, :status, :timeout_sec, :elapsed_sec, :import_elapsed_sec, :stdout_path, :stderr_path, :line_count, :row_count, :return_code, :reused_existing)
        """,
        session_attempt,
    )
    cur.executemany(
        """
        INSERT INTO section_import_attempts(
          section_id,
          display_name,
          page,
          status,
          timeout_sec,
          elapsed_sec,
          import_elapsed_sec,
          stdout_path,
          stderr_path,
          line_count,
          row_count,
          return_code,
          reused_existing
        ) VALUES(:section_id, :display_name, :page, :status, :timeout_sec, :elapsed_sec, :import_elapsed_sec, :stdout_path, :stderr_path, :line_count, :row_count, :return_code, :reused_existing)
        """,
        section_attempts,
    )
    conn.commit()

    insert_session_sections(conn, session_sections)

    for section_name, occurrences in sorted(strings_data["section_counts"].items()):
        cur.execute(
            "INSERT INTO report_sections(section_name, occurrences) VALUES(?, ?)",
            (section_name, occurrences),
        )
    cur.execute(
        """
        INSERT INTO kernel_targets(kernel_filter, kernel_name, matched_in_strings, string_occurrences)
        VALUES(?, ?, ?, ?)
        """,
        (
            kernel_filter,
            target_kernel,
            1 if strings_data["target_kernel_hits"] > 0 else 0,
            int(strings_data["target_kernel_hits"]),
        ),
    )
    for index, row in enumerate(strings_data["rule_rows"], start=1):
        cur.execute(
            """
            INSERT INTO rule_occurrences(
              rule_kind,
              occurrence_index,
              rule_text,
              full_waves,
              issue_every_cycles,
              active_warps_per_scheduler,
              eligible_warps_per_cycle,
              max_warps_per_scheduler
            ) VALUES(?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                row["rule_kind"],
                index,
                row["rule_text"],
                row["full_waves"],
                row["issue_every_cycles"],
                row["active_warps_per_scheduler"],
                row["eligible_warps_per_cycle"],
                row["max_warps_per_scheduler"],
            ),
        )
    for metric in aggregate_rule_metrics(strings_data["rule_rows"]):
        cur.execute(
            """
            INSERT INTO derived_metrics(
              metric_name,
              unit,
              source,
              occurrences,
              min_value,
              max_value,
              avg_value
            ) VALUES(?, ?, ?, ?, ?, ?, ?)
            """,
            (
                metric["metric_name"],
                metric["unit"],
                metric["source"],
                metric["occurrences"],
                metric["min_value"],
                metric["max_value"],
                metric["avg_value"],
            ),
        )
    for message in warnings:
        cur.execute("INSERT INTO extraction_warnings(message) VALUES(?)", (message,))
    conn.commit()

    sampled_launch_count = ingest_section_metric_values(conn, section_attempts, sample_launches)
    conn.close()
    return sampled_launch_count


def main() -> int:
    args = parse_args()
    rep_path = Path(args.rep_path or f"artifacts/profiles/ncu/{args.run_id}.ncu-rep")
    out_dir = Path(args.out_dir or f"artifacts/profiles/analysis/{args.run_id}")
    runs_path = Path(args.runs_path)
    session_timeout_sec, section_timeout_sec = resolve_timeouts(args)
    sections = resolve_sections(args.sections_profile)

    if not rep_path.exists():
        print(f"Input report not found: {rep_path}", file=sys.stderr)
        return 1
    if shutil.which("ncu") is None:
        print("ncu is not available in PATH", file=sys.stderr)
        return 1
    if shutil.which("strings") is None:
        print("strings is not available in PATH", file=sys.stderr)
        return 1

    out_dir.mkdir(parents=True, exist_ok=True)
    sections_dir = out_dir / "sections"
    sections_dir.mkdir(parents=True, exist_ok=True)
    progress_log = out_dir / "ncu_progress.log"

    kernel_filter = args.kernel_filter or infer_kernel_filter(args.run_id, runs_path)
    target_kernel = kernel_name_from_filter(kernel_filter)
    generated_at_utc = iso_now_utc()
    ncu_version = subprocess.check_output(["ncu", "--version"], text=True).splitlines()[0].strip()

    session_csv = out_dir / "ncu_session.csv"
    session_err = out_dir / "ncu_session.stderr.txt"
    excerpt_txt = out_dir / "ncu_strings_excerpt.txt"
    meta_txt = out_dir / "ncu_meta.txt"
    summary_md = out_dir / "ncu_summary.md"
    metrics_json = out_dir / "ncu_metrics.json"
    sqlite_path = out_dir / "ncu_analysis.sqlite"

    historical_imports = load_historical_import_timings(metrics_json, progress_log)

    log_message(progress_log, f"Starting analyze_ncu_run for run_id={args.run_id}")
    log_message(progress_log, f"Using sections_profile={args.sections_profile} sections={','.join(sections)}")

    session_attempt = run_import_csv(
        rep_path,
        "session",
        kernel_filter,
        session_timeout_sec,
        session_csv,
        session_err,
        progress_log,
        historical_imports=historical_imports,
    )

    section_attempts: list[dict[str, object]] = []
    for section_id in sections:
        section_csv = sections_dir / f"{section_id}.csv"
        section_err = sections_dir / f"{section_id}.stderr.txt"
        attempt = run_import_csv(
            rep_path,
            "details",
            kernel_filter,
            section_timeout_sec,
            section_csv,
            section_err,
            progress_log,
            historical_imports=historical_imports,
            section_id=section_id,
        )
        section_attempts.append(attempt)

    session_sections = parse_sectioned_csv(session_csv) if session_attempt["status"] in SUCCESS_STATUSES else {}
    strings_data = extract_strings(rep_path, args.strings_min_len, target_kernel)

    warnings: list[str] = []
    if session_attempt["status"] not in SUCCESS_STATUSES:
        warnings.append(
            "session page import did not complete cleanly; launch/session metadata may be incomplete."
        )
    incomplete_sections = [
        attempt
        for attempt in section_attempts
        if attempt["status"] not in SUCCESS_STATUSES
    ]
    for attempt in incomplete_sections:
        warnings.append(
            f"section {attempt['section_id']} did not complete cleanly (status={attempt['status']}); any .tmp sidecar is debug-only and was not ingested."
        )
    if len(incomplete_sections) == len(section_attempts):
        warnings.append(
            "no structured section imports completed; SQLite bundle relies on session CSV plus embedded-string fallback evidence."
        )
    if not target_kernel:
        warnings.append(
            "Kernel filter could not be inferred from profiling/RUNS.md; bundle stores only strings-based kernel targeting evidence."
        )
    if strings_data["return_code"] != 0:
        warnings.append("strings returned a non-zero exit code; embedded-text extraction may be incomplete.")

    excerpt_txt.write_text(
        "\n".join(strings_data["excerpt_lines"]) + ("\n" if strings_data["excerpt_lines"] else ""),
        encoding="utf-8",
    )

    metadata = {
        "run_id": args.run_id,
        "source_rep": str(rep_path),
        "generated_at_utc": generated_at_utc,
        "ncu_version": ncu_version,
        "kernel_filter": kernel_filter or "unknown",
        "target_kernel": target_kernel or "unknown",
        "sections_profile": args.sections_profile,
        "section_ids": ",".join(sections),
        "session_timeout_sec": format_timeout_value(session_timeout_sec),
        "section_timeout_sec": format_timeout_value(section_timeout_sec),
        "sample_launches": str(args.sample_launches),
        "analysis_db": str(sqlite_path),
        "progress_log": str(progress_log),
    }

    sampled_launch_count = write_sqlite_bundle(
        sqlite_path,
        metadata,
        session_attempt,
        section_attempts,
        session_sections,
        strings_data,
        kernel_filter,
        target_kernel,
        warnings,
        args.sample_launches,
    )

    derived_metrics = aggregate_rule_metrics(strings_data["rule_rows"])
    metrics_payload = {
        "run_id": args.run_id,
        "source_rep": str(rep_path),
        "generated_at_utc": generated_at_utc,
        "ncu_version": ncu_version,
        "kernel_filter": kernel_filter,
        "target_kernel": target_kernel,
        "sections_profile": args.sections_profile,
        "section_ids": sections,
        "session_import_attempt": session_attempt,
        "section_import_attempts": section_attempts,
        "section_success_count": sum(1 for attempt in section_attempts if attempt["status"] in SUCCESS_STATUSES),
        "section_attempt_count": len(section_attempts),
        "section_counts": strings_data["section_counts"],
        "target_kernel_string_hits": strings_data["target_kernel_hits"],
        "derived_metrics": derived_metrics,
        "sampled_launch_count": sampled_launch_count,
        "warnings": warnings,
        "analysis_db": str(sqlite_path),
        "progress_log": str(progress_log),
    }
    metrics_json.write_text(json.dumps(metrics_payload, indent=2) + "\n", encoding="utf-8")

    lines = [
        f"# Nsight Compute Analysis Summary: {args.run_id}",
        "",
        f"- source_rep: `{rep_path}`",
        f"- generated_at_utc: `{generated_at_utc}`",
        f"- ncu_version: `{ncu_version}`",
        f"- kernel_filter: `{kernel_filter or 'unknown'}`",
        f"- target_kernel: `{target_kernel or 'unknown'}`",
        f"- sections_profile: `{args.sections_profile}`",
        f"- session_timeout_sec: `{format_timeout_value(session_timeout_sec)}`",
        f"- section_timeout_sec: `{format_timeout_value(section_timeout_sec)}`",
        f"- sampled_launch_count: `{sampled_launch_count}`",
        f"- analysis_db: `{sqlite_path}`",
        f"- progress_log: `{progress_log}`",
        "",
        "## Import Attempts",
        f"- session: status=`{session_attempt['status']}` attempt_elapsed_sec=`{session_attempt['elapsed_sec']}` import_elapsed_sec=`{session_attempt.get('import_elapsed_sec', 'n/a')}` line_count=`{session_attempt['line_count']}`",
        "",
        "## Section Import Attempts",
    ]
    for attempt in section_attempts:
        lines.append(
            f"- {attempt['section_id']}: status=`{attempt['status']}` attempt_elapsed_sec=`{attempt['elapsed_sec']}` import_elapsed_sec=`{attempt.get('import_elapsed_sec', 'n/a')}` line_count=`{attempt['line_count']}` row_count=`{attempt['row_count']}`"
        )

    lines.extend(["", "## Embedded Section Hits"])
    if strings_data["section_counts"]:
        for section_name, count in sorted(strings_data["section_counts"].items()):
            lines.append(f"- `{section_name}`: {count}")
    else:
        lines.append("- none")

    lines.extend(["", "## Rule Findings"])
    if derived_metrics:
        for metric in derived_metrics:
            lines.append(
                f"- `{metric['metric_name']}`: occurrences={metric['occurrences']} min={metric['min_value']:.3f} max={metric['max_value']:.3f} avg={metric['avg_value']:.3f} {metric['unit']}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## Warnings"])
    if warnings:
        for warning in warnings:
            lines.append(f"- {warning}")
    else:
        lines.append("- none")
    summary_md.write_text("\n".join(lines) + "\n", encoding="utf-8")

    meta_lines = [
        f"run_id: {args.run_id}",
        f"source_rep: {rep_path}",
        f"generated_at_utc: {generated_at_utc}",
        f"ncu_version: {ncu_version}",
        f"kernel_filter: {kernel_filter or 'unknown'}",
        f"target_kernel: {target_kernel or 'unknown'}",
        f"sections_profile: {args.sections_profile}",
        f"session_timeout_sec: {format_timeout_value(session_timeout_sec)}",
        f"section_timeout_sec: {format_timeout_value(section_timeout_sec)}",
        f"sample_launches: {args.sample_launches}",
        f"analysis_db: {sqlite_path}",
        f"progress_log: {progress_log}",
        "commands:",
        f"  - ncu --import {rep_path} "
        + (f"--kernel-name {kernel_filter} " if kernel_filter else "")
        + "--page session --csv",
    ]
    for section_id in sections:
        meta_lines.append(
            f"  - ncu --import {rep_path} "
            + (f"--kernel-name {kernel_filter} " if kernel_filter else "")
            + f"--page details --section {section_id} --csv"
        )
    meta_lines.append(f"  - strings -n {args.strings_min_len} {rep_path}")
    meta_txt.write_text("\n".join(meta_lines) + "\n", encoding="utf-8")

    log_message(progress_log, f"Finished analyze_ncu_run for run_id={args.run_id}")
    print(f"[analyze_ncu_run] wrote bundle to {out_dir}")
    print(f"[analyze_ncu_run] sqlite: {sqlite_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
