# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / IF-B2 / baseline_validation`: run the second bounded `inference` baseline validation `nsys` slice (with smoke prerequisite), then update campaign/run/result/handoff state.

## Why This Is Immediate Priority
- Phase 4a (`train`) gate is complete (`TR-B1` + `TR-B2` successful).
- Phase 4b (`finetune`) gate is complete (`FT-B1` + `FT-B2` successful).
- Phase 4c (`inference`) now has `IF-B1` complete and needs the second successful baseline-validation `nsys` slice (`IF-B2`) to close the `2/2` gate.
- Workflow order remains enforced: baseline validation -> steady-state unannotated -> annotation -> steady-state annotated -> human review -> post-review `ncu` -> post-review optimization discussion.

## Exact Outputs Expected
- Confirm shared-host preconditions:
  - `conda activate griffin-profiling`
  - `make profiling-preflight`
  - GPU3 occupancy checks (`nvidia-smi` commands per policy)
- Execute row commands for `IF-B2`:
  - smoke (bounded combine-test inference slice)
  - `nsys` (same slice and args, distinct run_id)
- Update documentation/state:
  - `profiling/CAMPAIGN_PLAN.md` row `IF-B2` (`status`, `smoke_run_id`, `nsys_run_id`, `blocker`)
  - `profiling/RUNS.md` records with required campaign fields (`campaign_id`, `scenario`, `slice_id`, `profile_stage`)
  - `profiling/RESULTS.md` baseline scenario summary update for initial `inference` baseline validation status
  - `handoff/CURRENT_STATUS.md` counters and snapshot
  - `handoff/CHECKLIST.md` Phase 4c progress note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No detailed NVTX instrumentation yet (Phase 5 gates are not active).
- No optimization recommendations in any updated docs before review gate completion (`review_complete: true`).

## Stopping Criteria
- `IF-B2` has a documented smoke+`nsys` completion in campaign + run logs, or an actionable blocker is documented.
- Handoff and profiling docs are updated so a fresh agent can resume without additional discovery.
- Any updates must preserve capture-first/review-first policy and must not introduce post-review stages (`ncu`, optimization discussion) early.

## Definition Of Done (Template Style)
- [ ] `IF-B2` smoke run executed or blocked with actionable reason.
- [ ] `IF-B2` baseline `nsys` run executed successfully (or blocked with actionable reason) and artifact path recorded.
- [ ] `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md` are synchronized for `IF-B2`.
- [ ] `inference` baseline validation summary in `profiling/RESULTS.md` is updated.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
