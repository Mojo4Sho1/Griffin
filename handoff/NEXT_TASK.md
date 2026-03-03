# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / FT-S1 / baseline_unannotated`: run the first bounded `finetune` baseline `nsys` slice (with smoke prerequisite), then update campaign/run/result/handoff state.

## Why This Is Immediate Priority
- Phase 4a (`train`) gate is now complete (`TR-S1` + `TR-S2` successful).
- Phase 4b (`finetune`) is the next active baseline gate and requires `>=2` successful unannotated `nsys` slices.
- Campaign execution policy is one-slice-at-a-time; `FT-S1` is the next required row.

## Exact Outputs Expected
- Confirm shared-host preconditions:
  - `conda activate griffin-profiling`
  - `make profiling-preflight`
  - GPU3 occupancy checks (`nvidia-smi` commands per policy)
- Execute row commands for `FT-S1`:
  - smoke (bounded finetune combine-train slice)
  - `nsys` (same slice and args, distinct run_id)
- Update documentation/state:
  - `profiling/CAMPAIGN_PLAN.md` row `FT-S1` (`status`, `smoke_run_id`, `nsys_run_id`, `blocker`)
  - `profiling/RUNS.md` records with required campaign fields (`campaign_id`, `scenario`, `slice_id`, `profile_stage`)
  - `profiling/RESULTS.md` baseline scenario summary update for `finetune` (or blocker note)
  - `handoff/CURRENT_STATUS.md` counters and snapshot
  - `handoff/CHECKLIST.md` Phase 4b progress note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No detailed NVTX instrumentation yet (Phase 5 gates are not active).

## Stopping Criteria
- `FT-S1` has a documented successful smoke+`nsys` completion in campaign + run logs, or an actionable blocker is documented.
- Handoff and profiling docs are updated so a fresh agent can resume without additional discovery.

## Definition Of Done (Template Style)
- [ ] `FT-S1` smoke run executed or blocked with actionable reason.
- [ ] `FT-S1` baseline `nsys` run executed successfully (or blocked with actionable reason) and artifact path recorded.
- [ ] `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md` are synchronized for `FT-S1`.
- [ ] `finetune` baseline summary in `profiling/RESULTS.md` is updated or blocker is documented.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
