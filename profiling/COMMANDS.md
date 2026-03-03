# Profiling Command Patterns

This file stores canonical command patterns for baseline and follow-on profiling.
Use placeholders where environment-specific details are not yet confirmed.

## Shared GPU Guardrail (Required On This Host)

- This is a shared 4-GPU server. Profiling runs must target GPU3 only.
- Before any smoke/profiler command, run:

```bash
nvidia-smi
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
```

- If GPU3 has any compute process attached, do not run profiling commands.
- Notify the human operator and document blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
- Command prefix requirement:

```bash
CUDA_VISIBLE_DEVICES=3 <command>
```

## Campaign Conventions

- Run IDs follow `profiling/RUNS.md` canonical format:
  - `<YYYYMMDD>-<HHMM>-<mode>-<entry>-<seq>`
- Campaign/slice/stage tracking is authoritative in `profiling/CAMPAIGN_PLAN.md`.
- Required `profile_stage` values:
  - `baseline_unannotated`
  - `baseline_annotated`
  - `ncu_hotspot`

## Preferred Baseline Wrapper

```bash
scripts/profile_baseline.sh <smoke|nsys|ncu> <run_id> <task_script.py> <dataset> <log_dir> <log_name> -- <extra_task_args...>
```

## Scenario Command Classes

### 1) Baseline Unannotated (`profile_stage: baseline_unannotated`)

#### Train scenario (`hmaintask_completion.py`, mode `train`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof train-baseline-smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof train-baseline-nsys -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

#### Finetune scenario (`hmaintask_combine.py`, mode `train`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-finetune-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof finetune-baseline-smoke -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-finetune-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof finetune-baseline-nsys -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

#### Inference scenario (`hmaintask_combine.py`, mode `test`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-inference-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof inference-baseline-smoke -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-inference-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof inference-baseline-nsys -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### 2) Baseline Annotated (`profile_stage: baseline_annotated`)

These commands are the same scenario command classes as baseline-unannotated and must be executed only after Phase 5b inserts minimal NVTX ranges in:
- `hmaintask_completion.py`
- `hmaintask_combine.py`

Annotated `nsys` templates:

Train:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-train-completion-annot-01> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof train-annot-nsys -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Finetune:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-finetune-combine-annot-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof finetune-annot-nsys -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Inference:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-inference-combine-annot-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof inference-annot-nsys -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### 3) Targeted Deep Dive (`profile_stage: ncu_hotspot`)

Run only after hotspot shortlist is confirmed from annotated `nsys` traces.

Train:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh ncu <YYYYMMDD-HHMM-train-completion-hotspot-01> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof train-hotspot-ncu -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Finetune:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh ncu <YYYYMMDD-HHMM-finetune-combine-hotspot-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof finetune-hotspot-ncu -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Inference:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh ncu <YYYYMMDD-HHMM-inference-combine-hotspot-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof inference-hotspot-ncu -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

## Preflight Command Snippets

Preferred one-command preflight:
```bash
make profiling-preflight
```

Tool availability and occupancy checks:
```bash
command -v nsys
command -v ncu
command -v accelerate
nvidia-smi
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
```

Conda environment bootstrap:
```bash
conda env create -f environment.yml
conda activate griffin-profiling
```

Single-GPU profiling config check:
```bash
cat hconfig_profiling_single_gpu.yaml
```

## Known-Good Commands (Current Repo-Validated)

Status: `partially verified` (train baseline path verified end-to-end; finetune/inference pending in campaign)

Train smoke command (verified):
`CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke 20260302-1636-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`

Train baseline `nsys` command (verified):
`CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys 20260302-1637-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof nsys -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`

Generated artifact:
`artifacts/profiles/nsys/20260302-1637-train-completion-01.nsys-rep`

## Pending Confirmation Items

- Finetune baseline smoke + `nsys` command validation.
- Inference baseline smoke + `nsys` command validation (`--mode test` with `checkpoints/single-sft/best_checkpoint`).
- Minimal NVTX annotation insertion and annotated `nsys` validation per scenario.
- Hotspot shortlist and one targeted `ncu` deep-dive per scenario.
