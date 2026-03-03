# Profiling Guide

## Purpose
`profiling/` stores lightweight, version-controlled profiling documentation:
- command patterns
- run manifests
- concise result summaries

It does not store raw profiler binaries or large traces.

## What Belongs Here
- `COMMANDS.md`: canonical command templates and validated command variants.
- `PREFLIGHT.md`: environment and tooling readiness checklist before profiling runs.
- `ASSETS_STATUS.md`: current availability state of required datasets/checkpoints.
- `CAMPAIGN_PLAN.md`: scenario/slice matrix with stage gates and per-slice status.
- `RUNS.md`: structured run records (one entry per run attempt).
- `RESULTS.md`: compact findings, comparisons, and conclusions.
- `scripts/profile_baseline.sh`: lightweight wrapper for smoke/`nsys`/`ncu` baseline commands.

## What Does Not Belong Here
- Raw `nsys` / `ncu` output files.
- Large logs and binary artifacts.
- Temporary scratch notes that are not reusable.

Raw profiling outputs belong under `artifacts/profiles/` and remain out of Git.

## Handoff vs Profiling Docs
- `handoff/` files track project state and the single immediate next task.
- `profiling/` files track profiling operations and findings over time.
- Keep these responsibilities separate: execution continuity in `handoff/`, profiling evidence in `profiling/`.

## High-Level Workflow
1. Run `make profiling-preflight`.
2. Select the next pending campaign row (`campaign_id + slice_id + profile_stage`) in `CAMPAIGN_PLAN.md`.
3. Run bounded smoke + profiler commands for that row and write raw outputs to `artifacts/profiles/...`.
4. Record run metadata in `RUNS.md` (including `campaign_id`, `scenario`, `slice_id`, `profile_stage`).
5. Update row status and run IDs in `CAMPAIGN_PLAN.md`.
6. Summarize findings in `RESULTS.md`:
   - baseline unannotated summaries first (`nsys`)
   - then coarse NVTX-annotated summaries (`nsys`)
   - then targeted hotspot deep dives (`ncu`)
7. Do not run `ncu` until baseline + annotation gates are met for the scenario.
8. Update `handoff/` files before ending the session.

## Config Conventions For Profiling
- Default training config remains `hconfig.yaml` (repo baseline).
- Profiling baseline slices should prefer `hconfig_profiling_single_gpu.yaml` to reduce multi-process noise and improve reproducibility for first-pass traces.
- Workflow order is strict: baseline `nsys` -> minimal NVTX annotation -> annotated `nsys` validation -> hotspot shortlist -> targeted `ncu`.
