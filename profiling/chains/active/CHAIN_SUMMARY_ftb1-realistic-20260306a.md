# Chain Summary: ftb1-realistic-20260306a

- campaign_id: gfm-20260304-r02
- slice_id: FT-B1
- run_class: realistic_scale
- scenario: finetune
- profile_stage: baseline_validation
- mode: nsys
- resume_mode: model
- num_slices: 3
- max_train_steps: 8
- max_eval_steps: 4

## Slice 01
- run_id: 20260306-1538-ftb1-realistic-20260306a-s01
- status: success
- checkpoint_in: na
- checkpoint_out: checkpoints/slice-chain-ftb1-realistic/checkpoint-0-8
- log_name: finetune-ftb1-realistic-nsys-s01

## Slice 02
- run_id: 20260306-1543-ftb1-realistic-20260306a-s02
- status: success
- checkpoint_in: checkpoints/slice-chain-ftb1-realistic/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-ftb1-realistic/checkpoint-0-8
- log_name: finetune-ftb1-realistic-nsys-s02

## Slice 03
- run_id: 20260306-1553-ftb1-realistic-20260306a-s03
- status: success
- checkpoint_in: checkpoints/slice-chain-ftb1-realistic/checkpoint-0-8
- checkpoint_out: checkpoints/slice-chain-ftb1-realistic/checkpoint-0-8
- log_name: finetune-ftb1-realistic-nsys-s03

## Aggregate Summary
- slices_attempted: 3
- slices_completed: 3
- representativeness_decision: pass (baseline-validation bounded execution health)
- hotspot_stability_trend: not evaluated in baseline_validation nsys chain
- chain_timing_total: 00:21:03 (approx, derived from run-id timestamps and nsys artifact completion times)
- chain_timing_per_slice: s01~00:05:51; s02~00:10:13; s03~00:06:03
- next_action: stop; mark `FT-B1` scenario completion as `complete` and proceed to `IF-B1` realistic-v2 scenario chain
