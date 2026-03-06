# Chain Summary: ifb1-fixed-smoke-20260306c

- campaign_id: gfm-20260304-r02
- slice_id: IF-B1
- run_class: realistic_scale
- scenario: inference
- profile_stage: baseline_validation
- mode: smoke
- resume_mode: fixed
- num_slices: 2
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260306-1646-ifb1-fixed-smoke-20260306c-s01
- status: success
- checkpoint_in: checkpoints/single-sft/best_checkpoint
- checkpoint_out: checkpoints/single-sft/best_checkpoint
- log_name: inference-ifb1-fixed-smoke-s01

## Slice 02
- run_id: 20260306-1646-ifb1-fixed-smoke-20260306c-s02
- status: success
- checkpoint_in: checkpoints/single-sft/best_checkpoint
- checkpoint_out: checkpoints/single-sft/best_checkpoint
- log_name: inference-ifb1-fixed-smoke-s02

