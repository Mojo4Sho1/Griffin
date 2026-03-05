# Chain Summary: toychain-state-20260305

- campaign_id: gfm-20260304-r02
- slice_id: TR-AUTO-STATE-01
- run_class: realistic_scale
- scenario: train
- profile_stage: baseline_validation
- mode: smoke
- resume_mode: state
- num_slices: 2
- max_train_steps: 6
- max_eval_steps: 3

## Slice 01
- run_id: 20260305-2258-toychain-state-20260305-s01
- status: success
- checkpoint_in: na
- checkpoint_out: checkpoints/slice-chain-toy-state/state-slice-01
- log_name: train-chain-toy-state-s01

## Slice 02
- run_id: 20260305-2300-toychain-state-20260305-s02
- status: success
- checkpoint_in: checkpoints/slice-chain-toy-state/state-slice-01
- checkpoint_out: checkpoints/slice-chain-toy-state/state-slice-02
- log_name: train-chain-toy-state-s02

