# Chain Summary: ifb1-realistic-20260306b

- campaign_id: gfm-20260304-r02
- slice_id: IF-B1
- run_class: realistic_scale
- scenario: inference
- profile_stage: baseline_validation
- mode: nsys
- resume_mode: fixed
- num_slices: 3
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260306-1647-ifb1-realistic-20260306b-s01
- status: success
- checkpoint_in: checkpoints/single-sft/best_checkpoint
- checkpoint_out: checkpoints/single-sft/best_checkpoint
- log_name: inference-ifb1-realistic-nsys-s01

## Slice 02
- run_id: 20260306-1650-ifb1-realistic-20260306b-s02
- status: success
- checkpoint_in: checkpoints/single-sft/best_checkpoint
- checkpoint_out: checkpoints/single-sft/best_checkpoint
- log_name: inference-ifb1-realistic-nsys-s02

## Slice 03
- run_id: 20260306-1652-ifb1-realistic-20260306b-s03
- status: success
- checkpoint_in: checkpoints/single-sft/best_checkpoint
- checkpoint_out: checkpoints/single-sft/best_checkpoint
- log_name: inference-ifb1-realistic-nsys-s03

## Aggregate Summary
- slices_attempted: 3/3
- slices_completed: 3/3
- representativeness_decision: pass
- hotspot_stability_trend: stable primary inference hotspot mix across three bounded slices
- total_elapsed_wall_time: 00:07:32 (approx)
- next_action: stop chain execution; rotate to `RV-R2` cross-scenario realistic review
