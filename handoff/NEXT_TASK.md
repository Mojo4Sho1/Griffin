# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` using the new step-capped controls: run required preflight + GPU3 occupancy checks, execute capped smoke (`--max_train_steps 8 --max_eval_steps 4`) and then paired capped `nsys`, then generate analysis bundle.

## Why This Is Immediate Priority
- Asset provenance is satisfied and bounded slice orchestration is now validated via autonomous chain runs.
- `TR-B1` still lacks successful realistic-scale profiler evidence (`smoke` + `nsys` + analysis bundle) under the updated bounded controls.
- Completing this row unlocks realistic campaign sequencing to `FT-B1`/`IF-B1`.

## Exact Outputs Expected
- Append `TR-B1` capped smoke and capped `nsys` records in `profiling/RUNS.md` (`run_class: realistic_scale`).
- Run `scripts/analyze_nsys_run.sh --run-id <nsys_run_id>` and record analysis path/status in `profiling/RUNS.md`.
- Update `profiling/CAMPAIGN_PLAN.md` row `TR-B1` with new run IDs and final status.
- Update `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` to reflect row completion or concrete blocker boundary.
- Keep `handoff/NEXT_TASK.md` rotated to exactly one bounded follow-up action.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations; this remains baseline-validation evidence capture.

## Stopping Criteria
- Capped `TR-B1` smoke and paired capped `nsys` are attempted and documented.
- If `nsys` succeeds, analysis bundle is generated and linked.
- If either run fails, blocker is documented with concrete runtime evidence and one bounded follow-up is set.
- Campaign + handoff docs are synchronized to the execution outcome.
- `handoff/NEXT_TASK.md` remains a single bounded next action for the subsequent agent.

## Definition Of Done (Template Style)
- [ ] Capped `TR-B1` smoke run record is appended in `profiling/RUNS.md`.
- [ ] Capped `TR-B1` `nsys` record is appended and analysis bundle is generated/recorded.
- [ ] `profiling/CAMPAIGN_PLAN.md` `TR-B1` row is updated with run IDs/status.
- [ ] Relevant handoff docs are updated (`CURRENT_STATUS` and `SESSION_LOG`).
- [ ] `handoff/NEXT_TASK.md` contains one bounded follow-up action.
