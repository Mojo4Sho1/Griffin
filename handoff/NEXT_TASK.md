# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / TR-SU1 / steady_unannotated`: run the first paired steady-state unannotated `train` windows (A/B) under `nsys` on GPU3, compute representativeness metrics (`top3_overlap`, `timeshare_drift_pct`), and update campaign/run/result/handoff state.

## Why This Is Immediate Priority
- Baseline validation gates are complete:
  - Phase 4a (`train`): `TR-B1` + `TR-B2`
  - Phase 4b (`finetune`): `FT-B1` + `FT-B2`
  - Phase 4c (`inference`): `IF-B1` + `IF-B2`
- Workflow order now requires entering Phase 5 (`steady_unannotated`) before any annotation or post-review stages.
- `TR-SU1` is the first steady-state row in the campaign matrix and should establish the initial representativeness gate evidence.

## Exact Outputs Expected
- Confirm shared-host preconditions:
  - `conda activate griffin-profiling`
  - `make profiling-preflight`
  - GPU3 occupancy checks (`nvidia-smi` commands per policy)
- Execute `TR-SU1` paired steady-state runs:
  - run A (`nsys`) with stable bounded train settings
  - run B (`nsys`) with the same settings for comparison
- Record representativeness metadata in `profiling/RUNS.md` for both runs:
  - `window_warmup_iterations`
  - `window_profile_iterations`
  - `stability_pair_run_id`
  - `top3_overlap`
  - `timeshare_drift_pct`
  - `representative_pass`
  - `planned_soft_cap_minutes`
  - `actual_runtime_minutes`
- Update documentation/state:
  - `profiling/CAMPAIGN_PLAN.md` row `TR-SU1` (`status`, `nsys_run_id`, `blocker`)
  - `profiling/RESULTS.md` steady-state representativeness summary for `train`
  - `handoff/CURRENT_STATUS.md` counters/snapshot
  - `handoff/CHECKLIST.md` Phase 5 progress note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No detailed NVTX instrumentation (Phase 6 is not active yet).
- No optimization recommendations in any updated docs before review gate completion (`review_complete: true`).

## Stopping Criteria
- `TR-SU1` paired runs are documented with representativeness outcome (`representative_pass=true/false`), or an actionable blocker is documented.
- Campaign/run/results/handoff docs are synchronized so a fresh agent can resume without additional discovery.
- Capture-first/review-first policy remains intact; no early `ncu` or optimization discussion.

## Definition Of Done (Template Style)
- [ ] `TR-SU1` run A and run B executed (or blocked) with actionable details.
- [ ] Representativeness metrics are recorded in `profiling/RUNS.md` (`top3_overlap`, `timeshare_drift_pct`, `representative_pass`).
- [ ] `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md` are synchronized for `TR-SU1`.
- [ ] `profiling/RESULTS.md` steady-state representativeness summary is updated for `train`.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
