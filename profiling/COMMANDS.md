# Profiling Command Patterns

This file stores canonical command patterns for baseline and follow-on profiling.  
Use placeholders where environment-specific details are not yet confirmed.

## Repo-Confirmed Training Launch Patterns

Completion pretraining (`hmaintask_completion.py`):
```bash
accelerate launch --config_file hconfig.yaml hmaintask_completion.py \
  <dataset_path> <log_dir> <log_name> \
  --savepath <checkpoint_dir> \
  --hop <int> --fanout <int> --fewshotfanout <int> \
  --maxepoch <int> --batchsize <int> --lr <float> --wd <float> \
  --num_mp <int> --use_rev <bool> --use_gate <bool> \
  --eval_per_epoch <int> --hiddim <int>
```

SFT pretraining / fine-tuning (`hmaintask_combine.py`):
```bash
accelerate launch --config_file hconfig.yaml hmaintask_combine.py \
  <dataset_path> <log_dir> <log_name> \
  --loadpath <checkpoint_dir_or_file> \
  --savepath <checkpoint_dir> \
  --tasks <task_or_group> \
  --hop <int> --fanout <int> --fewshotfanout <int> \
  --maxepoch <int> --patience <int> --eval_per_epoch <int> \
  --batchsize <int> --lr <float> --wd <float> \
  --num_mp <int> --use_rev <bool> --use_gate <bool> --hiddim <int>
```

Transfer/downsample launcher:
```bash
bash transfer.sh <gpu_ids> <split_1> <split_2> <task> <model_idx> [eval_sample_ratio] [seed_start] [seed_end]
```

## Recommended Baseline Slice Launch Config

Use this config for minimal baseline profiling slices:
- `hconfig_profiling_single_gpu.yaml` (`num_processes: 1`, `distributed_type: "NO"`)

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

## Baseline Profiling Wrapper Patterns (To Validate)

`nsys` wrapper pattern:
```bash
CUDA_VISIBLE_DEVICES=3 nsys profile <nsys_flags> \
  --output artifacts/profiles/nsys/<run_id> \
  --force-overwrite true \
  accelerate launch --config_file hconfig_profiling_single_gpu.yaml <task_script.py> ...
```

`ncu` wrapper pattern:
```bash
CUDA_VISIBLE_DEVICES=3 ncu <ncu_flags> \
  --export artifacts/profiles/ncu/<run_id> \
  --target-processes all \
  -- accelerate launch --config_file hconfig_profiling_single_gpu.yaml <task_script.py> ...
```

## Baseline Wrapper Script (Preferred)

Use the lightweight wrapper to reduce command-construction errors:

```bash
scripts/profile_baseline.sh <smoke|nsys|ncu> <run_id> <task_script.py> <dataset> <log_dir> <log_name> -- <extra_task_args...>
```

Example smoke run:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke 20260228-1640-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --maxepoch 1 --batchsize 64
```

Example nsys run:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys 20260228-1641-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof nsys -- --maxepoch 1 --batchsize 64
```

## Concrete Starter Command (Template)

Use this as the default first command shape for a bounded smoke run.  
Replace only the placeholder values before running.

```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py <dataset_path> <log_dir> <log_name> -- --savepath <checkpoint_dir> --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

After smoke success, switch `smoke` to `nsys` or `ncu` and keep the rest of the command structure unchanged unless the task requires it.

## Preflight Command Snippets

Preferred one-command preflight:
```bash
make profiling-preflight
```

Tool availability checks:
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

## Known-Good Commands (Fill As Soon As First Run Succeeds)

Status: `verified` (last attempted 2026-03-02 UTC)

Minimal no-profiler smoke command (verified end-to-end):  
`CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke 20260302-1636-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`

Minimal baseline profiler command (verified end-to-end with artifact):  
`CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys 20260302-1637-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof nsys -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`

Raw output destination used:  
`artifacts/profiles/nsys/20260302-1637-train-completion-01.nsys-rep` (generated)

Blockers:
- None for this bounded completion slice command path after the gather-device fix.

Notes:
- `hmaintask_completion.py` gather path now uses `accelerator.device` instead of `model.device`.
- `make profiling-preflight` passes in `griffin-profiling`.
- Shared-host policy: run GPU3 occupancy checks first; do not run commands if GPU3 has active compute processes.
- Current staged dataset remains a minimal synthetic fixture for command-path verification; not production-scale profiling data.

## Annotation and Deep-Dive Command Classes

Annotated run class (coarse human-readable annotations; exact implementation pending):
```bash
<profiler_cmd> <flags> -- accelerate launch --config_file hconfig_profiling_single_gpu.yaml <task_script.py> <args>
```

Deep hotspot investigation class (after hotspot selection):
```bash
<targeted_profiler_cmd> <kernel_or_range_scope_flags> -- accelerate launch --config_file hconfig_profiling_single_gpu.yaml <task_script.py> <args>
```

## Pending Confirmation Items
- Which single script/args define the minimal representative baseline slice in this environment.
- Available profiler binaries and required flags on this machine.
- Process-count adjustments for minimal reproducible runs.
- Required asset path availability (tracked in `profiling/ASSETS_STATUS.md`).
