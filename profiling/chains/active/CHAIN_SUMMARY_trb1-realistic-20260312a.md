# Chain Summary: trb1-realistic-20260312a

- campaign_id: gfm-20260304-r02
- slice_id: TR-B1
- run_class: realistic_scale
- scenario: train
- profile_stage: baseline_validation
- mode: nsys
- resume_mode: model
- num_slices: 3
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260312-1526-trb1-realistic-20260312a-s01
- status: success
- checkpoint_in: na
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260312a/checkpoint-0-8
- log_name: train-trb1-realistic-nsys-s01

## Slice 02
- run_id: 20260312-1532-trb1-realistic-20260312a-s02
- status: success
- checkpoint_in: checkpoints/slice-chain-trb1-realistic-20260312a/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260312a/checkpoint-0-8
- log_name: train-trb1-realistic-nsys-s02

## Slice 03
- run_id: 20260312-1537-trb1-realistic-20260312a-s03
- status: success
- checkpoint_in: checkpoints/slice-chain-trb1-realistic-20260312a/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260312a/checkpoint-0-8
- log_name: train-trb1-realistic-nsys-s03

## Aggregate Summary
- slices_attempted: 3/3
- slices_completed: 3/3
- representativeness_decision: pass
- hotspot_stability_trend: not evaluated in baseline_validation nsys chain
- total_elapsed_wall_time: 00:17:08 (approx)
- next_action: stop chain execution; mark `TR-B1` realistic-v2 parity as complete and rotate to `RV-R2` cross-scenario realistic review
- parity_completion_note: `TR-B1` now matches `FT-B1` and `IF-B1` with a scenario-owned multi-slice `nsys` chain and per-slice analysis bundles.
