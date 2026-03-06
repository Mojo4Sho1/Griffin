
# Next Task

## Single Bounded Task
Execute realistic cross-scenario review row `gfm-20260304-r02 / RV-R2 / review_gate` using completed `TR-B1`, `FT-B1`, and `IF-B1` realistic-v2 evidence, and record the review decision state across profiling and handoff docs.

## Why This Is Immediate Priority
- `TR-B1` (`scenario_completion_state=complete_legacy`), `FT-B1` (`complete`), and `IF-B1` (`complete`) are now all satisfied.
- `RV-R2` is the required gate before any realistic-scale `ncu` planning.
- Policy now requires cross-scenario review after full scenario-owned multi-slice `nsys` completion.

## Exact Outputs Expected
- Synthesize cross-scenario evidence from realistic-v2 rows:
  - `TR-B1`: `20260306-1502-trb1-realistic-nsys-01`
  - `FT-B1`: `20260306-1538-ftb1-realistic-20260306a-s01`, `20260306-1543-ftb1-realistic-20260306a-s02`, `20260306-1553-ftb1-realistic-20260306a-s03`
  - `IF-B1`: `20260306-1647-ifb1-realistic-20260306b-s01`, `20260306-1650-ifb1-realistic-20260306b-s02`, `20260306-1652-ifb1-realistic-20260306b-s03`
- Update `profiling/CAMPAIGN_PLAN.md` row `RV-R2` status and blocker/decision text.
- Append review-gate entry in `profiling/RUNS.md` (review record style with decision metadata).
- Update `handoff/CURRENT_STATUS.md` workflow-gate fields and realistic review state.
- Append `handoff/SESSION_LOG.md` with review actions/outcome.
- Rotate `handoff/NEXT_TASK.md` to exactly one bounded follow-up based on review outcome.

## next_action Contract
- `ready_for_cross_scenario_review`: use only while preparing/performing `RV-R2`.
- `scenario_done`: use once `RV-R2` is complete and next task is downstream gated work.
- `continue_scenario`: not applicable unless review uncovers missing scenario evidence.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations unless policy gates explicitly permit after review state update.

## Stopping Criteria
- `RV-R2` decision is recorded and synchronized in campaign/run/handoff docs.
- `handoff/NEXT_TASK.md` remains one bounded action with explicit next_action.
