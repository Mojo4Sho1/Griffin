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
2. Select a bounded run slice and canonical `run_id` (see `RUNS.md`).
3. Run profiler and write raw outputs to `artifacts/profiles/...`.
4. Record run metadata in `RUNS.md`.
5. Summarize key findings in `RESULTS.md`.
6. Update `handoff/` files before ending the session.

## Config Conventions For Profiling
- Default training config remains `hconfig.yaml` (repo baseline).
- Profiling baseline slices should prefer `hconfig_profiling_single_gpu.yaml` to reduce multi-process noise and improve reproducibility for first-pass traces.
