# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / FT-B2 / baseline_validation`: run the second bounded `finetune` baseline validation `nsys` slice (with smoke prerequisite), then update campaign/run/result/handoff state.

## Why This Is Immediate Priority
- Phase 4a (`train`) gate is now complete (`TR-S1` + `TR-S2` successful).
- FT-B1 is now complete after the `hmaintask_combine.py` gather-device compatibility fix.
- Phase 4b (`finetune`) requires one more successful baseline-validation `nsys` slice (`FT-B2`) to reach the `2/2` gate.
- Workflow order is now enforced: baseline validation -> steady-state unannotated -> annotation -> steady-state annotated -> human review -> post-review `ncu` -> post-review optimization discussion.

## Exact Outputs Expected
- Confirm shared-host preconditions:
  - `conda activate griffin-profiling`
  - `make profiling-preflight`
  - GPU3 occupancy checks (`nvidia-smi` commands per policy)
- Execute row commands for `FT-B2`:
  - smoke (bounded finetune combine-train slice)
  - `nsys` (same slice and args, distinct run_id)
- Update documentation/state:
  - `profiling/CAMPAIGN_PLAN.md` row `FT-B2` (`status`, `smoke_run_id`, `nsys_run_id`, `blocker`)
  - `profiling/RUNS.md` records with required campaign fields (`campaign_id`, `scenario`, `slice_id`, `profile_stage`)
  - `profiling/RESULTS.md` baseline scenario summary update for `finetune` reproducibility (`FT-B1` vs `FT-B2`)
  - `handoff/CURRENT_STATUS.md` counters and snapshot
  - `handoff/CHECKLIST.md` Phase 4b progress note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No detailed NVTX instrumentation yet (Phase 5 gates are not active).
- No optimization recommendations in any updated docs before review gate completion (`review_complete: true`).

## Stopping Criteria
- `FT-B2` has a documented successful smoke+`nsys` completion in campaign + run logs, or an actionable blocker is documented.
- Handoff and profiling docs are updated so a fresh agent can resume without additional discovery.
- Any updates must preserve capture-first/review-first policy and must not introduce post-review stages (`ncu`, optimization discussion) early.

## Definition Of Done (Template Style)
- [ ] `FT-B2` smoke run executed or blocked with actionable reason.
- [ ] `FT-B2` baseline `nsys` run executed successfully (or blocked with actionable reason) and artifact path recorded.
- [ ] `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md` are synchronized for `FT-B2`.
- [ ] `finetune` baseline validation summary in `profiling/RESULTS.md` is updated with `FT-B1` vs `FT-B2` status.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
