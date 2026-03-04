#!/usr/bin/env bash
set -euo pipefail

RUN_ID=""
REP_PATH=""
OUT_DIR=""
TOP_N=15

usage() {
  cat <<USAGE
Usage: scripts/analyze_nsys_run.sh --run-id <run_id> [--rep-path <path>] [--out-dir <path>] [--top-n <int>]

Defaults:
  --rep-path artifacts/profiles/nsys/<run_id>.nsys-rep
  --out-dir  artifacts/profiles/analysis/<run_id>
  --top-n    15
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="${2:-}"
      shift 2
      ;;
    --rep-path)
      REP_PATH="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --top-n)
      TOP_N="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$RUN_ID" ]]; then
  echo "Missing required --run-id" >&2
  usage >&2
  exit 2
fi

if ! [[ "$TOP_N" =~ ^[0-9]+$ ]] || [[ "$TOP_N" -lt 1 ]]; then
  echo "--top-n must be a positive integer" >&2
  exit 2
fi

if [[ -z "$REP_PATH" ]]; then
  REP_PATH="artifacts/profiles/nsys/${RUN_ID}.nsys-rep"
fi
if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="artifacts/profiles/analysis/${RUN_ID}"
fi

if ! command -v nsys >/dev/null 2>&1; then
  echo "nsys is not available in PATH" >&2
  exit 1
fi

if [[ ! -f "$REP_PATH" ]]; then
  echo "Input trace not found: $REP_PATH" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

NVTX_TXT="$OUT_DIR/nvtx_sum.txt"
KERN_TXT="$OUT_DIR/cuda_gpu_kern_sum.txt"
API_TXT="$OUT_DIR/cuda_api_sum.txt"
META_TXT="$OUT_DIR/meta.txt"
SUMMARY_MD="$OUT_DIR/summary.md"
METRICS_JSON="$OUT_DIR/metrics.json"

nsys stats --force-export=true --report nvtx_sum "$REP_PATH" > "$NVTX_TXT"
nsys stats --force-export=true --report cuda_gpu_kern_sum "$REP_PATH" > "$KERN_TXT"
nsys stats --force-export=true --report cuda_api_sum "$REP_PATH" > "$API_TXT"

UTC_NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NSYS_VERSION="$(nsys --version | head -n 1)"

cat > "$META_TXT" <<META
run_id: $RUN_ID
source_rep: $REP_PATH
generated_at_utc: $UTC_NOW
nsys_version: $NSYS_VERSION
top_n: $TOP_N
commands:
  - nsys stats --force-export=true --report nvtx_sum $REP_PATH
  - nsys stats --force-export=true --report cuda_gpu_kern_sum $REP_PATH
  - nsys stats --force-export=true --report cuda_api_sum $REP_PATH
META

python - "$RUN_ID" "$REP_PATH" "$UTC_NOW" "$NSYS_VERSION" "$TOP_N" "$NVTX_TXT" "$KERN_TXT" "$API_TXT" "$SUMMARY_MD" "$METRICS_JSON" <<'PY'
import json
import re
import sys
from pathlib import Path

(
    run_id,
    source_rep,
    generated_at_utc,
    nsys_version,
    top_n,
    nvtx_path,
    kern_path,
    api_path,
    summary_path,
    metrics_path,
) = sys.argv[1:]

top_n = int(top_n)

warnings = []


def parse_ascii_table(path: Path):
    lines = path.read_text(errors="replace").splitlines()
    start = None
    sep_idx = None
    for i, line in enumerate(lines):
        if re.match(r"^\s*Time \(%\)", line):
            start = i
            break
    if start is None:
        return [], lines
    for j in range(start + 1, len(lines)):
        if re.match(r"^\s*-{3,}", lines[j]):
            sep_idx = j
            break
    if sep_idx is None:
        return [], lines

    rows = []
    for line in lines[sep_idx + 1 :]:
        if not line.strip():
            continue
        m = re.match(r"^\s*([0-9]+(?:\.[0-9]+)?)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+(?:\.[0-9]+)?)\s+(.*)$", line)
        if not m:
            continue
        rows.append(
            {
                "time_pct": float(m.group(1)),
                "total_time_ns": int(m.group(2)),
                "instances": int(m.group(3)),
                "avg_ns": float(m.group(4)),
                "med_ns": float(m.group(5)),
                "min_ns": int(m.group(6)),
                "max_ns": int(m.group(7)),
                "stddev_ns": float(m.group(8)),
                "name": m.group(9).strip(),
            }
        )
    return rows, lines


def to_ms(ns):
    return round(ns / 1_000_000.0, 6)


def to_us(ns):
    return round(ns / 1_000.0, 6)


nvtx_rows, nvtx_lines = parse_ascii_table(Path(nvtx_path))
kern_rows, kern_lines = parse_ascii_table(Path(kern_path))
api_rows, api_lines = parse_ascii_table(Path(api_path))

if any("does not contain NV Tools Extension (NVTX) data" in line for line in nvtx_lines):
    nvtx_coverage_status = "absent"
elif nvtx_rows:
    nvtx_coverage_status = "present"
else:
    nvtx_coverage_status = "inconclusive"
    warnings.append("Unable to confidently parse NVTX rows from nvtx_sum output.")

if not kern_rows:
    warnings.append("Unable to parse CUDA kernel rows from cuda_gpu_kern_sum output.")
if not api_rows:
    warnings.append("Unable to parse CUDA API rows from cuda_api_sum output.")

nvtx_top = [
    {
        "label": r["name"],
        "instances": r["instances"],
        "total_ms": to_ms(r["total_time_ns"]),
        "avg_us": to_us(r["avg_ns"]),
        "time_pct": r["time_pct"],
    }
    for r in nvtx_rows[:top_n]
]

kern_top = [
    {
        "kernel_name": r["name"],
        "launches": r["instances"],
        "total_ms": to_ms(r["total_time_ns"]),
        "avg_us": to_us(r["avg_ns"]),
        "time_pct": r["time_pct"],
    }
    for r in kern_rows[:top_n]
]

api_top = [
    {
        "api_name": r["name"],
        "calls": r["instances"],
        "total_ms": to_ms(r["total_time_ns"]),
        "avg_us": to_us(r["avg_ns"]),
        "time_pct": r["time_pct"],
    }
    for r in api_rows[:top_n]
]

metrics = {
    "run_id": run_id,
    "source_rep": source_rep,
    "generated_at_utc": generated_at_utc,
    "nsys_version": nsys_version,
    "nvtx_coverage_status": nvtx_coverage_status,
    "top_nvtx_ranges": nvtx_top,
    "top_gpu_kernels": kern_top,
    "top_cuda_runtime_calls": api_top,
    "warnings": warnings,
}

Path(metrics_path).write_text(json.dumps(metrics, indent=2) + "\n")

summary_lines = []
summary_lines.append(f"# Nsight Analysis Summary: {run_id}")
summary_lines.append("")
summary_lines.append(f"- source_rep: `{source_rep}`")
summary_lines.append(f"- generated_at_utc: `{generated_at_utc}`")
summary_lines.append(f"- nsys_version: `{nsys_version}`")
summary_lines.append(f"- nvtx_coverage_status: `{nvtx_coverage_status}`")
summary_lines.append("")

if warnings:
    summary_lines.append("## Warnings")
    for w in warnings:
        summary_lines.append(f"- {w}")
    summary_lines.append("")

summary_lines.append("## Top NVTX Ranges")
if nvtx_top:
    for i, r in enumerate(nvtx_top, start=1):
        summary_lines.append(
            f"{i}. `{r['label']}` | instances={r['instances']} | total_ms={r['total_ms']} | avg_us={r['avg_us']} | time_pct={r['time_pct']}"
        )
else:
    summary_lines.append("- none")
summary_lines.append("")

summary_lines.append("## Top GPU Kernels")
if kern_top:
    for i, r in enumerate(kern_top, start=1):
        summary_lines.append(
            f"{i}. `{r['kernel_name']}` | launches={r['launches']} | total_ms={r['total_ms']} | avg_us={r['avg_us']} | time_pct={r['time_pct']}"
        )
else:
    summary_lines.append("- none")
summary_lines.append("")

summary_lines.append("## Top CUDA Runtime APIs")
if api_top:
    for i, r in enumerate(api_top, start=1):
        summary_lines.append(
            f"{i}. `{r['api_name']}` | calls={r['calls']} | total_ms={r['total_ms']} | avg_us={r['avg_us']} | time_pct={r['time_pct']}"
        )
else:
    summary_lines.append("- none")
summary_lines.append("")

Path(summary_path).write_text("\n".join(summary_lines))
PY

echo "Analysis bundle generated: $OUT_DIR"
