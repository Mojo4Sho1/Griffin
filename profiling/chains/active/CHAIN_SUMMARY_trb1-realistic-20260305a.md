# Chain Summary: trb1-realistic-20260305a

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
- run_id: 20260305-2359-trb1-realistic-20260305a-s01
- status: success
- checkpoint_in: na
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260305a/checkpoint-0-8
- log_name: train-trb1-realistic-smoke-s01

## Slice 02
- run_id: 20260306-0000-trb1-realistic-20260305a-s02
- status: success
- checkpoint_in: checkpoints/slice-chain-trb1-realistic-20260305a/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260305a/checkpoint-0-8
- log_name: train-trb1-realistic-smoke-s02

## Slice 03
- run_id: 20260306-0002-trb1-realistic-20260305a-s03
- status: success
- checkpoint_in: checkpoints/slice-chain-trb1-realistic-20260305a/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-trb1-realistic-20260305a/checkpoint-0-8
- log_name: train-trb1-realistic-smoke-s03

## Aggregate Summary
- slices_attempted: 3
- slices_completed: 3
- representativeness_decision: pass (baseline-validation bounded execution health)
- hotspot_stability_trend: not evaluated in baseline_validation smoke chain
- chain_timing_total: 00:04:52 (approx, derived from event/log timestamps)
- chain_timing_per_slice: s01~00:01:41; s02~00:01:39; s03~00:01:32
- next_action: rerun full TR-B1 scenario with a new chain_id in detached tmux for canonical overnight evidence, then mark this chain as superseded if rerun succeeds
