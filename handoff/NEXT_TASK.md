# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / RV-G1 / review_gate`: perform human review sign-off using the standardized analysis bundles, then record explicit review outcome and update review-gate permissions (`review_complete`, `ncu_allowed`, `optimization_discussion_allowed`) in campaign/results/handoff docs (no new profiler runs).

## Why This Is Immediate Priority
- Capture completion evidence is now documented (`gfm-20260303-r01-capture-gate-01`) and `RV-G1` is waiting on a review decision only.
- Gate-critical run analysis bundles are now available in `artifacts/profiles/analysis/<run_id>/` for review-package inspection.
- Workflow policy requires human review gate completion before any `ncu_post_review` run or optimization discussion.

## Exact Outputs Expected
- Append a `Human Review Summary` result in `profiling/RESULTS.md` for `RV-G1` with explicit review decision fields:
  - `review_complete: <true|false>`
  - `ncu_allowed: <true|false>`
  - `targeted_fine_allowed: <true|false>`
  - `optimization_discussion_allowed: <true|false>`
- Update `profiling/CAMPAIGN_PLAN.md` row `RV-G1` status/blocker to match the human decision outcome.
- Update `handoff/CURRENT_STATUS.md` workflow gate state fields to reflect the recorded review outcome.
- Append `handoff/SESSION_LOG.md` with a concise review-decision entry.
- Include references to the reviewed analysis bundle paths (at least one per scenario) in review notes.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation changes.
- No `nsys` or `ncu` execution in this task.
- No optimization recommendations unless human review explicitly allows them.

## Stopping Criteria
- Human review outcome is explicitly recorded in `profiling/RESULTS.md`.
- `RV-G1` row state/context is synchronized in campaign + handoff docs.
- `handoff/NEXT_TASK.md` remains a single bounded next action for the subsequent agent.

## Definition Of Done (Template Style)
- [ ] Human review result recorded in `profiling/RESULTS.md`.
- [ ] `profiling/CAMPAIGN_PLAN.md` `RV-G1` status/blocker updated to the decision outcome.
- [ ] `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` updated.
