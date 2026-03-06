# Griffin Profiling Agent Guide

## Fork Purpose
This fork exists to profile and analyze Griffin GPU execution behavior to identify performance bottlenecks and optimization opportunities.

## Mission
- Prioritize profiling infrastructure, experiment organization, and continuity across fresh-context sessions.
- Preserve model semantics unless explicitly instructed otherwise.

## Explicit Non-Goals (Unless Asked)
- Kernel optimization work.
- Detailed NVTX instrumentation.
- Changes to model semantics or task behavior.
- Refactors of core training, fine-tuning, or inference logic.

## Profiling Philosophy
1. Baseline profiling first.
2. Coarse human-readable annotations second.
3. Hotspot analysis third.
4. Deep kernel analysis only after hotspots are confirmed.

## Instrumentation Rules
- Prefer minimal, reversible instrumentation changes.
- Keep instrumentation isolated and easy to remove.
- Avoid broad or invasive changes during profiling setup.

## Artifact Rules
- Keep raw profiling artifacts out of Git.
- Store raw profiler outputs under `artifacts/profiles/`.
- Track only lightweight summaries, manifests, and findings docs in version control.
- For every successful `nsys` run, generate an analysis bundle with `scripts/analyze_nsys_run.sh --run-id <run_id>`.
- Analysis bundles are written under `artifacts/profiles/analysis/<run_id>/` and should be referenced in `profiling/RUNS.md`.
- Human manual analysis workflow is documented in `profiling/MANUAL_ANALYSIS.md`.
- Reusable deep-dive SQL queries are documented in `profiling/sql/manual_queries.sql`.

## Execution Environment
- Before any run or profiling task, activate the project environment, then execute `make profiling-preflight`.
- Environment definition is `environment.yml`.
- For baseline profiling slices, prefer `hconfig_profiling_single_gpu.yaml` unless the task explicitly requires multi-process behavior.
- This profiling host is a shared 4-GPU system; default and required profiling target is GPU3.
- Before any smoke/profiler run, execute `nvidia-smi` and `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv` to check occupancy.
- Launch profiling commands with `CUDA_VISIBLE_DEVICES=3 ...`.
- If GPU3 has any active compute process attached, do not run profiling; notify the human operator and document the blocker in `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md`.
- If preflight or environment setup fails, document the blocker in `profiling/RUNS.md` and `handoff/CURRENT_STATUS.md`.
- Do not modify `hconfig.yaml` for profiling tasks; use `hconfig_profiling_single_gpu.yaml` or add a new profiling-specific config file.
- Long-running profiling/autonomous chains should be launched in a detached `tmux` session so execution is resilient to client disconnects.
- If a chain run has uncertain continuity (disconnect/session loss), do not delete prior artifacts/logs; rerun the full scenario with a new `chain_id` and mark the prior chain as superseded in profiling/handoff docs.

## Handoff Protocol
- `handoff/CURRENT_STATUS.md` is the current state snapshot.
- `handoff/NEXT_TASK.md` contains exactly one bounded next task.
- `handoff/CHECKLIST.md` is the durable cumulative phase tracker.
- `handoff/SESSION_LOG.md` is an append-only cross-session activity log.
- Every completed task must update all relevant handoff files before stopping.

## Fresh-Agent Operating Loop
1. Read `AGENTS.md`.
2. Read `handoff/CURRENT_STATUS.md`.
3. Read `handoff/CHECKLIST.md`.
4. Read `handoff/SESSION_LOG.md`.
5. Read `handoff/NEXT_TASK.md`.
6. Perform only the task in `handoff/NEXT_TASK.md`.
7. Update all relevant handoff files before stopping.
8. Update profiling docs if runs or findings occurred.
9. Stop cleanly.
