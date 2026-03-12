
# Next Task

## Single Bounded Task
Execute `gfm-20260304-r02 / RV-R2 / review_gate` cross-scenario realistic review using completed parity-consistent `TR-B1`, `FT-B1`, and `IF-B1` realistic-v2 scenario-owned multi-slice `nsys` evidence; record the review decision and downstream gate permissions.
- next_action: `ready_for_cross_scenario_review`

## Why This Is Immediate Priority
- `TR-B1` parity rerun is now complete with scenario-owned multi-slice `nsys` evidence and per-slice analysis bundles.
- `FT-B1` and `IF-B1` are already complete under the same realistic-v2 evidence policy.
- `RV-R2` is now the required gate before any realistic-scale `ncu` planning/execution discussion.

## Exact Outputs Expected
- Review `TR-B1`, `FT-B1`, and `IF-B1` run bundles and chain summaries for cross-scenario consistency and readiness.
- Update `profiling/CAMPAIGN_PLAN.md` row `gfm-20260304-r02 / RV-R2` with status and gate decision notes.
- Update `profiling/RUNS.md` with one `RV-R2` review entry (decision record only; no profiler run).
- Update `handoff/CURRENT_STATUS.md` workflow gate fields and realistic-scale permission fields as dictated by review outcome.
- Append the review decision in `handoff/SESSION_LOG.md` and rotate `handoff/NEXT_TASK.md` to the next bounded action.

## next_action Contract
- `ready_for_cross_scenario_review`: current state; use while preparing/executing `RV-R2`.
- `scenario_done`: use after `RV-R2` decision and documentation synchronization are complete.
- `continue_scenario`: use only if review execution is split and requires continuation in a follow-up session.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No realistic-scale `ncu` execution before `RV-R2` decision is recorded.

## Stopping Criteria
- `RV-R2` review decision is documented in `profiling/CAMPAIGN_PLAN.md`, `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md`.
- `handoff/NEXT_TASK.md` is rotated to exactly one bounded post-review task with explicit `next_action`.
