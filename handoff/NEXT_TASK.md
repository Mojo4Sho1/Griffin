# Next Task

## Single Bounded Task
Execute a full overnight rerun of campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` as a new autonomous 3-slice smoke chain in detached `tmux` with a fresh chain ID (do not reuse `trb1-realistic-20260305a`), then sync campaign/handoff docs and supersession metadata.

## Why This Is Immediate Priority
- A successful capped 3-slice chain already exists (`trb1-realistic-20260305a`), but canonical evidence is intentionally rerun because continuity was uncertain during the prior session.
- Detached `tmux` operation is now validated on this host and should be used for unattended overnight execution.
- Completing canonical `TR-B1` chain evidence unlocks paired realistic-scale `nsys` follow-up and campaign progression.

## Exact Outputs Expected
- Launch the chain in detached `tmux` (GPU3 only) with:
  - `--num-slices 3`
  - `--max_train_steps 8`
  - `--max_eval_steps 4`
  - `--mode smoke`
  - `--resume-mode model`
- Write per-slice records and one aggregate summary block to `profiling/chains/active/CHAIN_SUMMARY_<new_chain_id>.md`.
- Append 3 run records in `profiling/RUNS.md` for the new chain (`run_class: realistic_scale`, `slice_id: TR-B1`).
- Update `profiling/CAMPAIGN_PLAN.md` `TR-B1` row with the new chain run IDs and canonical status.
- Mark prior chain `trb1-realistic-20260305a` as superseded in `profiling/RUNS.md` notes + `handoff/SESSION_LOG.md`; archive it with:
  - `scripts/archive_chain_summary.sh --chain-id trb1-realistic-20260305a --reason "superseded by <new_chain_id> overnight rerun"`
- Update `handoff/CURRENT_STATUS.md` and append `handoff/SESSION_LOG.md` with chain timing and decision lines.
- Keep `handoff/NEXT_TASK.md` rotated to exactly one bounded follow-up action.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations; this remains baseline-validation evidence capture.

## Stopping Criteria
- New detached `tmux` chain completes 3 attempted slices and is fully documented.
- Aggregate summary exists for the new chain and timing/decision is mirrored in `handoff/SESSION_LOG.md`.
- Prior chain is explicitly marked superseded and archived.
- Campaign + handoff docs are synchronized to the rerun outcome.
- `handoff/NEXT_TASK.md` remains a single bounded next action.

## Definition Of Done (Template Style)
- [ ] Detached `tmux` chain run executed with a new `chain_id` for `TR-B1` (`3` capped slices attempted).
- [ ] `profiling/chains/active/CHAIN_SUMMARY_<new_chain_id>.md` contains per-slice entries and one aggregate summary block.
- [ ] Three new `TR-B1` run records are appended in `profiling/RUNS.md`.
- [ ] Prior chain `trb1-realistic-20260305a` is marked superseded and archived under `profiling/chains/archive/`.
- [ ] `profiling/CAMPAIGN_PLAN.md` `TR-B1` row is updated with canonical rerun status/run IDs.
- [ ] `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` are updated.
- [ ] `handoff/NEXT_TASK.md` contains one bounded follow-up action.
