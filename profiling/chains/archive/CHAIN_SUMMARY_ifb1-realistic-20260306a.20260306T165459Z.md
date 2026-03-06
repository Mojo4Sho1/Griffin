# Chain Summary: ifb1-realistic-20260306a

- campaign_id: gfm-20260304-r02
- slice_id: IF-B1
- run_class: realistic_scale
- scenario: inference
- profile_stage: baseline_validation
- mode: nsys
- resume_mode: model
- num_slices: 3
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260306-1619-ifb1-realistic-20260306a-s01
- status: failed
- reason: no checkpoint-* directory found after successful slice.
- checkpoint_in: na
- checkpoint_out: na
- analysis_bundle: artifacts/profiles/analysis/20260306-1619-ifb1-realistic-20260306a-s01/

## Aggregate Summary
- slices_attempted: 1/3
- slices_completed: 0/3 (chain-level)
- representativeness_decision: fail
- hotspot_stability_trend: insufficient evidence (single processed slice before chain stop)
- total_elapsed_wall_time: 00:02:16 (approx)
- next_action: handoff resume with inference-compatible chain policy (checkpointless continuation for `--mode test`)
