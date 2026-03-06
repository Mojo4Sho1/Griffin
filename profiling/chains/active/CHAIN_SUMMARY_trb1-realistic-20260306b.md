# Chain Summary: trb1-realistic-20260306b

- campaign_id: gfm-20260304-r02
- slice_id: TR-B1
- run_class: realistic_scale
- scenario: train
- profile_stage: baseline_validation
- mode: smoke
- resume_mode: model
- num_slices: 3
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260306-0049-trb1-realistic-20260306b-s01
- status: success
- checkpoint_in: na
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260306b/checkpoint-0-8
- log_name: train-trb1-realistic-smoke-s01

## Slice 02
- run_id: 20260306-0051-trb1-realistic-20260306b-s02
- status: success
- checkpoint_in: checkpoints/slice-chain-trb1-realistic-20260306b/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260306b/checkpoint-0-8
- log_name: train-trb1-realistic-smoke-s02

## Slice 03
- run_id: 20260306-0052-trb1-realistic-20260306b-s03
- status: success
- checkpoint_in: checkpoints/slice-chain-trb1-realistic-20260306b/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260306b/checkpoint-0-8
- log_name: train-trb1-realistic-smoke-s03

## Aggregate Summary
- slices_attempted: 3
- slices_completed: 3
- representativeness_decision: pass (baseline-validation bounded execution health)
- hotspot_stability_trend: not evaluated in baseline_validation smoke chain
- chain_timing_total: 00:05:04 (approx, derived from slice run-id timestamps)
- chain_timing_per_slice: s01~00:01:40; s02~00:01:38; s03~00:01:46
- next_action: stop; mark `trb1-realistic-20260305a` superseded/archived and proceed to paired realistic-scale `TR-B1` `nsys` run with analysis bundle
