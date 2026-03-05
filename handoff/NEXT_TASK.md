# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` for `run_class=realistic_scale`: verify production-equivalent asset provenance for the train scenario and either run the bounded baseline-validation smoke+`nsys` slice on GPU3 or record a concrete asset blocker if provenance requirements are not met.

## Why This Is Immediate Priority
- `RV-G1` is now complete and documented (`gfm-20260303-r01-review-gate-01`), but review outcome keeps escalation permissions disabled for `minimal_staged` evidence.
- The next forward path is to start realistic-scale evidence collection (`gfm-20260304-r02`) per `profiling/SCALE_PROFILES.md`.
- Campaign counters for `gfm-20260304-r02` are currently all zero, so `TR-B1` is the first executable row.

## Exact Outputs Expected
- If assets are available, append `TR-B1` run records in `profiling/RUNS.md` (smoke + `nsys`) with `run_class: realistic_scale`, asset provenance fields, and analysis bundle path for successful `nsys`.
- If assets are unavailable, record a blocker entry in `profiling/RUNS.md` and mark `TR-B1` as `blocked` in `profiling/CAMPAIGN_PLAN.md` with precise missing asset paths.
- Update `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md` (if phase state changes), and `handoff/SESSION_LOG.md` to reflect either execution or blocker outcome.
- Keep `handoff/NEXT_TASK.md` rotated to exactly one bounded follow-up action.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations; this task is only realistic-scale baseline evidence capture/blocker documentation.

## Stopping Criteria
- `TR-B1` is either executed with run artifacts/records or explicitly marked blocked with non-actionable provenance details.
- Campaign + handoff docs are synchronized to the chosen outcome.
- `handoff/NEXT_TASK.md` remains a single bounded next action for the subsequent agent.

## Definition Of Done (Template Style)
- [ ] `TR-B1` realistic-scale outcome (run success or blocked) is recorded in `profiling/RUNS.md` and `profiling/CAMPAIGN_PLAN.md`.
- [ ] Relevant handoff docs are updated (`CURRENT_STATUS`, `SESSION_LOG`, and `CHECKLIST` if needed).
- [ ] `handoff/NEXT_TASK.md` contains one bounded follow-up action.
