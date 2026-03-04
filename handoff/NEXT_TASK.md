# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / RV-G1 / review_gate`: record capture-complete gate evidence and prepare the human review decision package (no new profiler runs).

## Why This Is Immediate Priority
- Baseline validation, steady-state unannotated, and steady-state annotated rows are now complete for all in-scope scenarios (`train`, `finetune`, `inference`).
- Workflow policy requires human review gate completion before any `ncu_post_review` run or optimization discussion.

## Exact Outputs Expected
- Confirm and document capture completeness in `profiling/RESULTS.md` using the `Capture Completion Gate Template` with:
  - `baseline_validation_complete: true`
  - `steady_unannotated_complete: true`
  - `steady_annotated_complete: true`
  - `non_actionable_blockers_documented: true`
  - `capture_complete: true`
- Update `profiling/CAMPAIGN_PLAN.md` row `RV-G1` blocker text to explicitly state that capture is complete and row is awaiting human review outcome.
- Update `handoff/CURRENT_STATUS.md` gate/review snapshot fields if needed for clarity.
- Append `handoff/SESSION_LOG.md` with a concise review-gate preparation entry.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation changes.
- No `nsys` or `ncu` execution in this task.
- No optimization recommendations before human review gate completion.

## Stopping Criteria
- Capture-gate result is explicitly recorded in `profiling/RESULTS.md`.
- `RV-G1` row state/context is synchronized in campaign + handoff docs.
- `handoff/NEXT_TASK.md` remains a single bounded next action for the subsequent agent.

## Definition Of Done (Template Style)
- [ ] Capture-complete result recorded in `profiling/RESULTS.md`.
- [ ] `profiling/CAMPAIGN_PLAN.md` `RV-G1` context updated for human review handoff.
- [ ] `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` updated.
