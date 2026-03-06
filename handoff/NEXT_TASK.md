# Next Task

## Single Bounded Task
Complete realistic-scale scenario row `gfm-20260304-r02 / FT-B1 / baseline_validation` end-to-end under `execution_policy_version=realistic-v2` using a multi-slice `nsys` chain on GPU3, with per-slice analysis bundles and scenario aggregate summary.

## Why This Is Immediate Priority
- Realistic-scale policy is now `realistic-v2`: one agent owns one full scenario.
- `TR-B1` is retained as legacy evidence (`scenario_completion_state=complete_legacy`), so `FT-B1` is the first non-legacy scenario under the new policy.
- `IF-B1` and cross-scenario review (`RV-R2`) are gated on `FT-B1` scenario completion.

## Exact Outputs Expected
- Run preconditions in order:
  - activate `griffin-profiling`
  - `make profiling-preflight`
  - `nvidia-smi`
  - `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`
- If GPU3 is occupied, do not run; document blocker in `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md` with `next_action=continue_scenario`.
- If GPU3 is clear, run `FT-B1` as chained `nsys` slices via `scripts/run_slice_chain.sh`:
  - `--mode nsys`, `--run-class realistic_scale`, `--profile-stage baseline_validation`, `--scenario finetune`
  - default tier: `--max_train_steps 8 --max_eval_steps 4`
  - default depth target: `--num-slices 3`
  - scenario args include `--mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft`
- Use this exact command template (replace `<chain_id>` only):
```bash
CUDA_VISIBLE_DEVICES=3 scripts/run_slice_chain.sh \
  --chain-id <chain_id> \
  --campaign-id gfm-20260304-r02 \
  --slice-id FT-B1 \
  --run-class realistic_scale \
  --task-script hmaintask_combine.py \
  --dataset datasets/single-pretrain-v3-hf \
  --log-dir logs/prof \
  --log-name-prefix finetune-ftb1-realistic-nsys \
  --savepath checkpoints/slice-chain-ftb1-realistic \
  --num-slices 3 \
  --max-train-steps 8 \
  --max-eval-steps 4 \
  --mode nsys \
  --resume-mode model \
  --profile-stage baseline_validation \
  --scenario finetune \
  -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
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
  - `profiling/CAMPAIGN_PLAN.md` row `FT-B1` (`smoke_run_id` optional, `nsys_run_id`, status, blocker, metadata fields)
  - `profiling/RUNS.md` entries include: `execution_policy_version`, `legacy_policy_evidence`, `slice_size_tier`, `scenario_completion_state`
  - chain summary includes end-of-scenario aggregate block
  - `handoff/CURRENT_STATUS.md` and append `handoff/SESSION_LOG.md`
  - rotate `handoff/NEXT_TASK.md` to exactly one bounded follow-up

## Completion Checklist Artifact Map
- Per successful slice run ID:
  - `artifacts/profiles/nsys/<slice_run_id>.nsys-rep`
  - `artifacts/profiles/analysis/<slice_run_id>/summary.md`
  - `artifacts/profiles/analysis/<slice_run_id>/metrics.json`
  - `artifacts/profiles/analysis/<slice_run_id>/nvtx_sum.txt`
  - `artifacts/profiles/analysis/<slice_run_id>/cuda_gpu_kern_sum.txt`
  - `artifacts/profiles/analysis/<slice_run_id>/cuda_api_sum.txt`
  - `artifacts/profiles/analysis/<slice_run_id>/meta.txt`
- Scenario chain summary:
  - `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md` with required end-of-scenario aggregate block
- Documentation state:
  - `profiling/CAMPAIGN_PLAN.md` row `FT-B1` updated (run IDs, status, blocker, metadata fields)
  - `profiling/RUNS.md` appended for each run/slice with required realistic-v2 metadata fields
  - `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` updated
  - `handoff/NEXT_TASK.md` rotated with explicit `next_action`

## Interruption / Continuity Branch
- If session continuity is uncertain (disconnect, tmux/session loss, incomplete artifact provenance):
  - do not delete prior artifacts or logs
  - rerun full `FT-B1` scenario from slice 1 with a new `chain_id`
  - mark the prior chain as superseded in `profiling/RUNS.md` and `handoff/SESSION_LOG.md`
  - archive prior chain summary via `scripts/archive_chain_summary.sh --chain-id <old_chain_id> --reason \"superseded due continuity uncertainty\"`
  - continue under the new chain as the canonical decision input

## Required Metadata Values (`FT-B1`)
- `execution_policy_version=realistic-v2`
- `legacy_policy_evidence=false`
- `slice_size_tier=8/4` initially (or upgraded tier if applied)
- `scenario_completion_state`:
  - `in_progress` while chain is ongoing
  - `complete` once `FT-B1` criteria are met

## next_action Contract
- `continue_scenario`: scenario not complete; resume same scenario chain policy.
- `scenario_done`: `FT-B1` complete; next task should move to `IF-B1` scenario.
- `ready_for_cross_scenario_review`: use only after `TR-B1`, `FT-B1`, and `IF-B1` completion states are satisfied.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations.

## Stopping Criteria
- One full `FT-B1` scenario attempt is recorded under `realistic-v2`.
- Each successful slice has `nsys` artifact + analysis bundle.
- Campaign + handoff state is synchronized with explicit `next_action`.
- `handoff/NEXT_TASK.md` remains one bounded action.

## Definition Of Done (Template Style)
- [ ] Preconditions executed (`preflight` + GPU3 occupancy checks).
- [ ] `FT-B1` scenario chain executed in `nsys` mode (or blocker documented).
- [ ] Analysis bundle generated for every successful slice run.
- [ ] `profiling/RUNS.md` and `profiling/CAMPAIGN_PLAN.md` updated with required metadata fields.
- [ ] Chain summary includes end-of-scenario aggregate block.
- [ ] `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` updated.
- [ ] `handoff/NEXT_TASK.md` rotated with explicit `next_action`.
