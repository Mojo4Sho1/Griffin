# Chain Summary: toychain-model-20260305b

- campaign_id: gfm-20260303-r01
- slice_id: TR-AUTO-SMOKE-01
- run_class: minimal_staged
- scenario: train
- profile_stage: baseline_validation
- mode: smoke
- resume_mode: model
- num_slices: 3
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260305-2252-toychain-model-20260305b-s01
- status: success
- checkpoint_in: na
- checkpoint_out: checkpoints/slice-chain-toy-model/checkpoint-0-8
- log_name: train-chain-toy-model-s01

## Slice 02
- run_id: 20260305-2253-toychain-model-20260305b-s02
- status: success
- checkpoint_in: checkpoints/slice-chain-toy-model/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-toy-model/checkpoint-0-8
- log_name: train-chain-toy-model-s02

## Slice 03
- run_id: 20260305-2255-toychain-model-20260305b-s03
- status: success
- checkpoint_in: checkpoints/slice-chain-toy-model/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-toy-model/checkpoint-0-8
- log_name: train-chain-toy-model-s03

