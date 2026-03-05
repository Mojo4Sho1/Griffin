# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` as an autonomous scenario chain under the adaptive policy: run required preflight + GPU3 occupancy checks, run initial 3 step-capped slices (`--max_train_steps 8 --max_eval_steps 4`) with per-slice chain summary updates, then write an end-of-scenario aggregate summary and mirror elapsed timing/decision in `handoff/SESSION_LOG.md`.

## Why This Is Immediate Priority
- Asset provenance is satisfied and bounded slice orchestration is now validated via autonomous chain runs.
- `TR-B1` still lacks successful realistic-scale autonomous chain evidence under the updated bounded controls and adaptive depth policy.
- Completing this row unlocks realistic campaign sequencing to `FT-B1`/`IF-B1`.

## Exact Outputs Expected
- Run 3 capped slices for `TR-B1` and append per-slice records in `profiling/RUNS.md` (`run_class: realistic_scale`).
- Update `profiling/CHAIN_SUMMARY_<chain_id>.md` after each slice with status and checkpoint/state handoff path.
- Add one end-of-scenario aggregate summary block to `profiling/CHAIN_SUMMARY_<chain_id>.md` (attempted/completed, representativeness decision, hotspot stability trend, total wall time, explicit next action).
- Mirror chain total time, per-slice elapsed deltas, and any extension rationale in `handoff/SESSION_LOG.md`.
- Update `profiling/CAMPAIGN_PLAN.md` row `TR-B1` with run IDs/status and whether policy requires extension to 5.
- Update `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` to reflect completion or concrete blocker boundary.
- Keep `handoff/NEXT_TASK.md` rotated to exactly one bounded follow-up action.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations; this remains baseline-validation evidence capture.

## Stopping Criteria
- Three initial capped slices are attempted and documented with per-slice chain summary entries.
- One aggregate end-of-scenario summary is written and mirrored to `handoff/SESSION_LOG.md` with elapsed timing.
- If representativeness fails at 3, extension recommendation to 5 is documented (without ambiguity on continuation input/path).
- If any slice fails, blocker is documented with concrete runtime evidence and one bounded follow-up is set.
- Campaign + handoff docs are synchronized to the execution outcome.
- `handoff/NEXT_TASK.md` remains a single bounded next action for the subsequent agent.

## Definition Of Done (Template Style)
- [ ] Three capped `TR-B1` slice run records are appended in `profiling/RUNS.md`.
- [ ] `profiling/CHAIN_SUMMARY_<chain_id>.md` contains per-slice entries and one aggregate end-of-scenario summary block.
- [ ] `handoff/SESSION_LOG.md` includes chain elapsed timing (total + per-slice deltas) and decision/extension rationale.
- [ ] `profiling/CAMPAIGN_PLAN.md` `TR-B1` row is updated with run IDs/status and next-target decision.
- [ ] Relevant handoff docs are updated (`CURRENT_STATUS` and `SESSION_LOG`).
- [ ] `handoff/NEXT_TASK.md` contains one bounded follow-up action.
