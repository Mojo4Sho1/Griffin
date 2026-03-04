# Profiling Command Patterns

This file stores canonical command patterns for validation slices, steady-state captures, and post-review deep dives.
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

## Workflow Order (Enforced)

1. Baseline validation (short slices, pipeline sanity only)
2. Steady-state unannotated profiling (representativeness gate)
3. Minimal coarse NVTX/labels insertion
4. Steady-state annotated profiling (final capture set)
5. Human analysis/review (`RV-G1`) and hotspot shortlist approval
6. Optional targeted-fine relabel + annotated `nsys` rerun (post-review only, hotspot-scoped)
7. Targeted `ncu` (only after review gate)
8. Optimization strategy discussion (post-review only)

Policy: no optimization recommendations before capture + review gates complete.
Policy: `targeted_fine` relabeling is optional and only allowed after `RV-G1` is `done` with approved hotspot focus; see `profiling/_PROFILING_GUIDE.md` section `NVTX Granularity Escalation Policy (Two-Tier)`.
Policy: default rank emission is `all_ranks`; any single-rank/subset filtering must be documented in run metadata.
Policy: for annotated-stage NVTX verification, use `nvtx_sum` with forced export (`nsys stats --force-export=true --report nvtx_sum <run>.nsys-rep`); do not use deprecated `nvtxsum` as canonical evidence.
Policy: false-negative guardrail for annotated runs: if an initial NVTX report is empty, rerun once with `--force-export=true` before documenting any NVTX anomaly/blocker.
Cross-reference: follow `profiling/_PROFILING_GUIDE.md` sections `Range Nesting And Overlap Policy`, `Distributed / Rank Emission Policy`, and `Schema Change Rule`.

## Campaign Conventions

- Run IDs follow `profiling/RUNS.md` canonical format:
  - `<YYYYMMDD>-<HHMM>-<mode>-<entry>-<seq>`
- Campaign/slice/stage tracking is authoritative in `profiling/CAMPAIGN_PLAN.md`.
- Required `profile_stage` values:
  - `baseline_validation`
  - `steady_unannotated`
  - `steady_annotated`
  - `review_gate`
  - `ncu_post_review`

## Preferred Baseline Wrapper

```bash
scripts/profile_baseline.sh <smoke|nsys|ncu> <run_id> <task_script.py> <dataset> <log_dir> <log_name> -- <extra_task_args...>
```

## 1) Baseline Validation Commands (Short Slices)

These are intentionally bounded to verify command/runtime/profiler path health.

### Train (`hmaintask_completion.py`, mode `train`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof train-baseline-smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof train-baseline-nsys -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### Finetune (`hmaintask_combine.py`, mode `train`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-finetune-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof finetune-baseline-smoke -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-finetune-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof finetune-baseline-nsys -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### Inference (`hmaintask_combine.py`, mode `test`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-inference-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof inference-baseline-smoke -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-inference-combine-01> hmaintask_combine.py datasets/single-pretrain-v3 logs/prof inference-baseline-nsys -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

## 2) Steady-State Unannotated Profiling (Representativeness Gate)

Purpose: optimization-evidence capture before annotation.

Policy:
- Unit is iterations (training steps), not epochs/minutes.
- Start with window `warmup=5`, `profile=25`.
- If unstable, expand window in sequence: `10/50 -> 20/100 -> 40/200`.
- Stability pass criteria:
  - top-3 hotspot overlap `>= 2/3`
  - per-hotspot time-share drift `<= 20%`
- Runtime policy:
  - planned soft cap `45` minutes
  - do not terminate healthy progressing runs at 45 minutes
  - allow completion and log overrun details
  - terminate only for no-progress/hang/shared-host policy violations

Execution note:
- Reuse scenario command templates above with `profile_stage=steady_unannotated` in run/campaign metadata.
- Maintain comparable args/config across paired runs for valid stability comparison.

## 3) Steady-State Annotated Profiling (Final Capture Set)

Execute only after minimal coarse NVTX ranges are inserted.

Policy:
- Same iteration-window and stability policy as steady-state unannotated.
- Reuse scenario command templates with annotated log names and `profile_stage=steady_annotated`.
- Tiering rule:
  - Coarse annotated captures are the default.
  - Post-review targeted-fine reruns keep `profile_stage=steady_annotated` and must record `label_tier`, `label_schema_version`, `hotspot_focus_id`, and `parent_label_anchor` metadata in `RUNS.md`/`RESULTS.md`.
- NVTX verification reliability rule:
  - Primary report command: `nsys stats --force-export=true --report nvtx_sum <run>.nsys-rep`
  - Optional secondary cross-check: `nsys stats --force-export=true --report cuda_gpu_kern_sum <run>.nsys-rep`
  - If the first NVTX report appears empty, retry with forced export before writing anomaly/blocker conclusions.

Annotated `nsys` examples:

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

## 4) Targeted Deep Dive (`ncu_post_review`)

Run only after:
- capture-complete gate passes
- human review gate is marked done

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
