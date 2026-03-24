# Nsight Compute Coverage Tracker

Last updated: `2026-03-24` UTC

## Current Default Workflow
- Capture-time default: `scripts/run_ncu_hotspot.sh <scenario> <hotspot>` now resolves to `--sections-profile core --launch-count 5` unless the run record explicitly chooses another path.
- Current `core` section list: `LaunchStats`, `Occupancy`, `SchedulerStats`, `WarpStateStats`, `ComputeWorkloadAnalysis`, `MemoryWorkloadAnalysis`, `SpeedOfLight`, `WorkloadDistribution`.
- Tooling-smoke default: use the same helper with `--launch-count 1`.
- Explicit escalation: `--set full` remains available, but it is no longer the preferred default for new hotspot work.
- Post-capture analysis default: run `python scripts/analyze_ncu_run.py --run-id <run_id>` in `tmux` for large reports and do not add timeout flags unless the operator explicitly wants them.
- Import behavior: section imports are atomic, resumable, and no-timeout by default; interrupted `*.tmp` files are debug-only and are never ingested as final structured data.
- Legacy note: `TR-N1` (`20260319-1514-train-completion-01`) remains valid source evidence, but it was captured with historical `--set full` and no launch cap, producing a legacy oversized `7.8G` report that is not the preferred default report shape for future captures.

## Notebook Upgrade Checklist
- [x] Capture health with per-section import status, elapsed time, row count, and sidecar reuse state.
- [x] Kernel identity and match scope with total launch count, sampled launch count, and sampled span.
- [x] Structured Launch Statistics and Occupancy tables/charts.
- [x] Structured Compute Workload, Memory Workload, and Speed-of-Light tables/charts.
- [x] Structured WorkloadDistribution run-level and sampled views.
- [x] Structured Scheduler Statistics and Warp State tables/charts.
- [x] Sampled per-launch distributions across the repeated kernel launches.
- [x] Structured Nsight-style rule/advice cards using `rule_name`, `rule_type`, and estimated speedup fields.
- [x] Guided interpretation and explicit notebook-side coverage-gap reporting.
- [ ] Add source/instruction-level views only when a concrete follow-on investigation requires them.

## Validation Snapshot
- The no-timeout `tmux` re-analysis of `TR-N1` completed successfully on `2026-03-24`.
- Resume behavior is now proven: after interrupting the re-analysis mid-run, the restart reused completed `session`, `LaunchStats`, and `Occupancy` sidecars and continued with the remaining sections.
- A follow-on `TR-N1` rerun promoted `WorkloadDistribution` into the default `core` profile, imported it cleanly in `154.785s`, and rebuilt the SQLite bundle after teaching the analyzer to parse comma-separated cycle values into the numeric-summary layer.
- The upgraded `TR-N1` bundle now contains `ncu_analysis.sqlite`, `ncu_summary.md`, `ncu_metrics.json`, `ncu_progress.log`, and stable `sections/<section_id>.csv` sidecars for all eight core sections.
- `profiling/notebooks/ncu_sqlite_review.ipynb` now executes successfully in `griffin-profiling` and surfaces Launch, Occupancy, Compute Workload, Memory Workload, Speed-of-Light, WorkloadDistribution, Scheduler, Warp State, per-launch distribution, and guidance-card views from the SQLite-first bundle.

## Core Section Coverage

| Section ID | Human Name | Capture Default | `TR-N1` Import Status | SQLite Support | Notebook Support | Parity Gap / Next Step |
| --- | --- | --- | --- | --- | --- | --- |
| `LaunchStats` | Launch Statistics | default (`core`) | success | normalized rows, sampled-launch markers, numeric summaries | guided structured tables plus sampled wave plots | add richer cross-run launch-comparison helpers later |
| `Occupancy` | Occupancy | default (`core`) | success | normalized rows, occupancy-limit data, numeric summaries | guided structured tables plus occupancy/limiter charts | expose even clearer occupancy-constraint narration if we add more kernels/runs |
| `SchedulerStats` | Scheduler Statistics | default (`core`) | success | normalized rows, scheduler metrics, numeric summaries | guided structured tables plus scheduler eligibility charts | add more cross-run comparison helpers once multiple hotspot bundles exist |
| `WarpStateStats` | Warp State Statistics | default (`core`) | success | normalized rows, warp-state metrics, numeric summaries | guided structured tables plus warp-cycle charts | improve label fidelity if we later import richer warp-state sections |
| `ComputeWorkloadAnalysis` | Compute Workload Analysis | default (`core`) | success | normalized rows, compute metrics, numeric summaries | guided structured tables plus compute busy / IPC summaries | strengthen multi-run comparison and trend helpers later |
| `MemoryWorkloadAnalysis` | Memory Workload Analysis | default (`core`) | success | normalized rows, memory metrics, numeric summaries | guided structured tables plus throughput / hit-rate summaries | consider adding more hierarchy detail only if future investigations need it |
| `SpeedOfLight` | GPU Speed Of Light Throughput | default (`core`) | success | normalized rows, throughput metrics, numeric summaries | guided structured tables plus throughput cards/charts | roofline-style parity remains deferred |
| `WorkloadDistribution` | GPU and Memory Workload Distribution | default (`core`) | success | normalized rows, numeric cycle summaries, sampled-launch rows, derived resource-level ratios | guided raw cycle tables plus derived active/elapsed ratio charts and sampled workload-distribution plots | keep source/instruction pages deferred unless a concrete kernel-tuning investigation needs them |

## Deferred Or Fallback Coverage
- `SourceCounters` / instruction-level views: not in the default capture profile and not yet supported in SQLite or the notebook. Defer until a concrete source-level investigation requires them.
- Monolithic `details` / `raw` exports: retained as occasional debugging aids only. They are no longer the primary analysis path once structured section sidecars are available.

## Current Readiness Summary
- Extractor status: usable for the eight-section core Nsight Compute review surface with validated no-timeout, atomic, resumable imports.
- SQLite status: suitable as the canonical working bundle for notebook review and future dashboard work.
- Notebook status: now a guided structured review surface for the imported core sections, while still intentionally below full vendor-UI parity.
- Future-facing note: the stable interface for downstream tools is `artifacts/profiles/analysis/<run_id>/ncu_analysis.sqlite` plus `artifacts/profiles/analysis/<run_id>/sections/<section_id>.csv`.
