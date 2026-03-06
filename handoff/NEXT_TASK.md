# Next Task

## Single Bounded Task
Complete realistic-scale scenario row `gfm-20260304-r02 / IF-B1 / baseline_validation` end-to-end under `execution_policy_version=realistic-v2` using a multi-slice `nsys` chain on GPU3, with per-slice analysis bundles and scenario aggregate summary.

## Why This Is Immediate Priority
- `TR-B1` is retained as legacy evidence (`scenario_completion_state=complete_legacy`) and `FT-B1` is now complete (`scenario_completion_state=complete`).
- `IF-B1` is the final scenario-owned realistic-v2 baseline row required before cross-scenario review (`RV-R2`).
- `RV-R2` remains gated until `IF-B1` reaches scenario completion.

## Exact Outputs Expected
- Run preconditions in order:
  - activate `griffin-profiling`
  - `make profiling-preflight`
  - `nvidia-smi`
  - `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`
- If GPU3 is occupied, do not run; document blocker in `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md` with `next_action=continue_scenario`.
- If GPU3 is clear, run `IF-B1` as chained `nsys` slices via `scripts/run_slice_chain.sh`:
  - `--mode nsys`, `--run-class realistic_scale`, `--profile-stage baseline_validation`, `--scenario inference`
  - default tier: `--max_train_steps 8 --max_eval_steps 4`
  - default depth target: `--num-slices 3`
  - scenario args include `--mode test --loadpath checkpoints/single-sft/best_checkpoint --savepath checkpoints/slice-chain-ifb1-realistic`
- Use this exact command template (replace `<chain_id>` only):
```bash
CUDA_VISIBLE_DEVICES=3 scripts/run_slice_chain.sh \
  --chain-id <chain_id> \
  --campaign-id gfm-20260304-r02 \
  --slice-id IF-B1 \
  --run-class realistic_scale \
  --task-script hmaintask_combine.py \
  --dataset datasets/single-pretrain-v3-hf \
  --log-dir logs/prof \
  --log-name-prefix inference-ifb1-realistic-nsys \
  --savepath checkpoints/slice-chain-ifb1-realistic \
  --num-slices 3 \
  --max-train-steps 8 \
  --max-eval-steps 4 \
  --mode nsys \
  --resume-mode model \
  --profile-stage baseline_validation \
  --scenario inference \
  -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```
- After each successful slice:
  - execute `scripts/analyze_nsys_run.sh --run-id <slice_run_id>`
  - verify bundle under `artifacts/profiles/analysis/<slice_run_id>/`
  - append run entry in `profiling/RUNS.md`
- If representativeness is insufficient:
  - extend depth first (`3 -> 5 -> 7 -> +2`)
  - only if still insufficient, increase tier (`8/4 -> 16/8 -> 32/16`) with new `chain_id`
  - do not exceed `32/16` without explicit human instruction
- Update docs on completion/stop:
  - `profiling/CAMPAIGN_PLAN.md` row `IF-B1` (`smoke_run_id` optional, `nsys_run_id`, status, blocker, metadata fields)
  - `profiling/RUNS.md` entries include: `execution_policy_version`, `legacy_policy_evidence`, `slice_size_tier`, `scenario_completion_state`
  - chain summary includes end-of-scenario aggregate block
  - `handoff/CURRENT_STATUS.md` and append `handoff/SESSION_LOG.md`
  - rotate `handoff/NEXT_TASK.md` to exactly one bounded follow-up

## Required Metadata Values (`IF-B1`)
- `execution_policy_version=realistic-v2`
- `legacy_policy_evidence=false`
- `slice_size_tier=8/4` initially (or upgraded tier if applied)
- `scenario_completion_state`:
  - `in_progress` while chain is ongoing
  - `complete` once `IF-B1` criteria are met

## next_action Contract
- `continue_scenario`: scenario not complete; resume same scenario chain policy.
- `scenario_done`: `IF-B1` complete; next task should move to `RV-R2` cross-scenario realistic review.
- `ready_for_cross_scenario_review`: use only when `TR-B1`, `FT-B1`, and `IF-B1` completion states are all satisfied and the next bounded action is `RV-R2`.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations.

## Stopping Criteria
- One full `IF-B1` scenario attempt is recorded under `realistic-v2`.
- Each successful slice has `nsys` artifact + analysis bundle.
- Campaign + handoff state is synchronized with explicit `next_action`.
- `handoff/NEXT_TASK.md` remains one bounded action.
