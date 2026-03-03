# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / TR-S2 / baseline_unannotated`: run one additional successful bounded `train` baseline `nsys` slice (with smoke prerequisite), then update campaign/run/result/handoff state.

## Why This Is Immediate Priority
- Phase 4a gate requires `>=2` successful unannotated baseline `nsys` slices for `train`.
- Current campaign status has only one successful `train` baseline `nsys` slice (`TR-S1` is done; `TR-S2` is pending).
- Campaign execution policy is one-slice-at-a-time; this row is the next required unit of work.

## Exact Outputs Expected
- Confirm shared-host preconditions:
  - `conda activate griffin-profiling`
  - `make profiling-preflight`
  - GPU3 occupancy checks (`nvidia-smi` commands per policy)
- Execute row commands for `TR-S2`:
  - smoke (bounded train completion slice)
  - `nsys` (same slice and args, distinct run_id)
- Update documentation/state:
  - `profiling/CAMPAIGN_PLAN.md` row `TR-S2` (`status`, `smoke_run_id`, `nsys_run_id`, `blocker`)
  - `profiling/RUNS.md` records with required campaign fields (`campaign_id`, `scenario`, `slice_id`, `profile_stage`)
  - `profiling/RESULTS.md` baseline scenario summary update for `train`
  - `handoff/CURRENT_STATUS.md` counters and snapshot
  - `handoff/CHECKLIST.md` Phase 4a progress note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No detailed NVTX instrumentation yet (Phase 5 gates are not active).

## Stopping Criteria
- `TR-S2` has a documented successful smoke+`nsys` completion in campaign + run logs, or an actionable blocker is documented.
- Handoff and profiling docs are updated so a fresh agent can resume without additional discovery.

## Definition Of Done (Template Style)
- [ ] `TR-S2` smoke run executed or blocked with actionable reason.
- [ ] `TR-S2` baseline `nsys` run executed successfully (or blocked with actionable reason) and artifact path recorded.
- [ ] `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md` are synchronized for `TR-S2`.
- [ ] `train` baseline summary in `profiling/RESULTS.md` reflects both successful baseline slices (`TR-S1`, `TR-S2`) or documented blocker.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
