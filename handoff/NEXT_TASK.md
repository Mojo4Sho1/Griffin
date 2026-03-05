# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` (`run_class=realistic_scale`): run required preflight + GPU3 occupancy checks, then execute bounded smoke and `nsys` train slices using production-equivalent assets.

## Why This Is Immediate Priority
- Asset provenance gate is now satisfied for realistic-scale input data/checkpoints (`profiling/ASSET_PROVENANCE.md`).
- Campaign matrix row `TR-B1` is no longer blocked and is the next sequential executable row for `gfm-20260304-r02`.
- Starting `TR-B1` advances realistic-scale evidence collection and allows `FT-B1`/`IF-B1` sequencing.

## Exact Outputs Expected
- Append smoke and `nsys` run records for `TR-B1` in `profiling/RUNS.md` with `run_class: realistic_scale` and dataset/checkpoint provenance references.
- Generate analysis bundle for successful `nsys` run (`scripts/analyze_nsys_run.sh --run-id <run_id>`) and record path/status in `profiling/RUNS.md`.
- Update `profiling/CAMPAIGN_PLAN.md` row `TR-B1` status/run IDs to match execution outcome.
- Update `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` to reflect execution/blocker boundary.
- Keep `handoff/NEXT_TASK.md` rotated to exactly one bounded follow-up action.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations; this remains baseline-validation evidence capture.

## Stopping Criteria
- `TR-B1` is executed (smoke + `nsys`) or explicitly blocked with concrete runtime evidence.
- Campaign + handoff docs are synchronized to the execution outcome.
- `handoff/NEXT_TASK.md` remains a single bounded next action for the subsequent agent.

## Definition Of Done (Template Style)
- [ ] `TR-B1` smoke + `nsys` records are appended in `profiling/RUNS.md`.
- [ ] Analysis bundle is generated for successful `nsys` run and recorded.
- [ ] `profiling/CAMPAIGN_PLAN.md` `TR-B1` row is updated with run IDs/status.
- [ ] Relevant handoff docs are updated (`CURRENT_STATUS` and `SESSION_LOG`).
- [ ] `handoff/NEXT_TASK.md` contains one bounded follow-up action.
