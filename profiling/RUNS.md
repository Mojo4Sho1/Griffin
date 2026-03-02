# Profiling Run Records

Use one record per profiling run attempt (including failed attempts).  
Keep records concise and reproducible.

## Canonical Run ID (Required)

Run IDs must follow:

`<YYYYMMDD>-<HHMM>-<mode>-<entry>-<seq>`

Where:
- `<mode>` is one of: `train` | `finetune` | `inference`
- `<entry>` is one of: `completion` | `combine` | `downsample` | `transfer`
- `<seq>` is a two-digit sequence for collisions within the same minute (for example `01`, `02`)

Example:
- `20260228-1640-train-completion-01`

## Required Record Fields
- Date/time (UTC)
- Mode (`train` / `fine-tune` / `inference`)
- Dataset
- Exact command
- Git commit hash
- Config used
- Slice definition
- Profiler used
- Output file paths
- Short notes on findings

## Run Template

```markdown
### Run: <run_id>
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- mode: <train|fine-tune|inference>
- dataset: <dataset_id_or_path>
- command: `<exact_command>`
- git_commit: `<commit_hash>`
- config: `<config_file_or_inline_key_flags>`
- slice_definition: <what subset/epochs/steps/tasks were profiled>
- profiler: <none|nsys|ncu|other>
- outputs:
  - <artifacts/profiles/...>
  - <logs/...> (if relevant)
- findings_notes: <1-5 concise bullets or sentences>
- status: <success|failed|partial>
- blocker_if_any: <none or short blocker statement>
```

## Conventions
- Use the canonical run ID format above for every run record.
- For reruns of the same slice, keep separate records and reference prior `run_id`.
- Do not paste raw profiler dumps; link paths only.

### Run: 20260301-1848-train-completion-01
- readiness_checklist:
  - `conda activate griffin-profiling`: failed (`EnvironmentNameNotFound`)
  - `conda env create -f environment.yml`: failed (`NoWritableEnvsDirError`; DNS resolution failed for `repo.anaconda.com`)
  - `make profiling-preflight`: failed at required binary check (`accelerate` not found in current environment)
  - asset path probe (`datasets`, `checkpoints`, `logs`): missing in workspace
- date_time_utc: 2026-03-01T18:46:57Z
- mode: train
- dataset: `datasets/single-pretrain-v3`
- command: `scripts/profile_baseline.sh smoke 20260301-1848-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`
- git_commit: `eebeccb1d752a14cd22488459870f876957a2748`
- config: `hconfig_profiling_single_gpu.yaml`
- slice_definition: One-epoch, small-batch completion training smoke slice intended as prerequisite for `nsys` baseline.
- profiler: none (smoke prerequisite for profiler wrapper)
- outputs:
  - `artifacts/profiles/nsys/` (available destination; no run artifact due failure before launch)
  - `artifacts/profiles/ncu/` (available destination; no run artifact due failure before launch)
  - `logs/prof` (not created; launch did not start)
- findings_notes:
  - Wrapper prerequisite failed at `command -v accelerate` (`scripts/profile_baseline.sh:58`).
  - `nsys` and `ncu` binaries are present at `/usr/local/bin/nsys` and `/usr/local/bin/ncu`.
  - Required dataset/checkpoint assets for representative slice are missing locally.
  - Baseline profiler command cannot be validated until environment + assets are provisioned.
- status: failed
- blocker_if_any: Conda environment cannot currently be created/activated in this runtime, and required dataset/checkpoint paths are absent.

### Run: 20260301-2005-train-completion-01
- readiness_checklist:
  - `conda activate griffin-profiling`: passed
  - `make profiling-preflight`: failed (Python import error via matplotlib: `/lib/x86_64-linux-gnu/libstdc++.so.6` missing `CXXABI_1.3.15`)
  - asset path probe (`datasets`, `checkpoints`, `logs`): missing in workspace
- date_time_utc: 2026-03-01T20:05:32Z
- mode: train
- dataset: `datasets/single-pretrain-v3`
- command: `scripts/profile_baseline.sh smoke 20260301-2005-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`
- git_commit: `eebeccb1d752a14cd22488459870f876957a2748`
- config: `hconfig_profiling_single_gpu.yaml`
- slice_definition: One-epoch, small-batch completion training smoke slice.
- profiler: none
- outputs:
  - `logs/prof` (not created; script exited before runtime setup)
  - `artifacts/profiles/nsys/` (destination available)
  - `artifacts/profiles/ncu/` (destination available)
- findings_notes:
  - Command resolved and `accelerate launch` started.
  - Runtime failed immediately with `ModuleNotFoundError: No module named 'torch_geometric'` from `hmodel.py`.
  - Dataset/checkpoint absence remains unresolved, but did not become first failure in this attempt.
- status: failed
- blocker_if_any: `torch_geometric` is not installed in `griffin-profiling`.

### Run: 20260301-2007-train-completion-01
- readiness_checklist:
  - `conda activate griffin-profiling`: passed
  - `make profiling-preflight`: failed (same `CXXABI_1.3.15` matplotlib import issue)
  - wrapper check: old `scripts/profile_baseline.sh nsys ... -- accelerate ...` form is invalid for local `nsys` (ambiguous option); direct `nsys` form used for this run
- date_time_utc: 2026-03-02T00:19:53Z
- mode: train
- dataset: `datasets/single-pretrain-v3`
- command: `nsys profile --output artifacts/profiles/nsys/20260301-2007-train-completion-01 --force-overwrite true accelerate launch --config_file hconfig_profiling_single_gpu.yaml hmaintask_completion.py datasets/single-pretrain-v3 logs/prof nsys --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`
- git_commit: `eebeccb1d752a14cd22488459870f876957a2748`
- config: `hconfig_profiling_single_gpu.yaml`
- slice_definition: Baseline `nsys` wrapper of the same bounded completion slice.
- profiler: nsys
- outputs:
  - `artifacts/profiles/nsys/20260301-2007-train-completion-01.nsys-rep`
  - `logs/prof` (not created; application exited before runtime setup)
- findings_notes:
  - `nsys` launch works when run without the extra `--` separator before `accelerate`.
  - Profiler artifact file was generated despite target app failure.
  - Target app failed before data loading with `ModuleNotFoundError: No module named 'torch_geometric'`.
- status: failed
- blocker_if_any: Python runtime dependency gap (`torch_geometric`) prevents executing the profiled workload.

### Run: 20260302-1541-train-completion-01
- readiness_checklist:
  - `conda activate griffin-profiling`: passed
  - `make profiling-preflight`: passed (`python deps ok`)
  - asset path probe: `datasets/single-pretrain-v3` missing
- date_time_utc: 2026-03-02T15:41:45Z
- mode: train
- dataset: `datasets/single-pretrain-v3`
- command: `scripts/profile_baseline.sh smoke 20260302-1541-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`
- git_commit: `eebeccb1d752a14cd22488459870f876957a2748`
- config: `hconfig_profiling_single_gpu.yaml`
- slice_definition: One-epoch, small-batch completion training smoke slice.
- profiler: none
- outputs:
  - `logs/prof` (launch starts, then exits at dataset initialization)
  - `artifacts/profiles/nsys/` (available destination)
  - `artifacts/profiles/ncu/` (available destination)
- findings_notes:
  - Previous dependency blockers are resolved in this environment: `torch_geometric` imports and `make profiling-preflight` passes.
  - Failure boundary moved to dataset staging: missing `datasets/single-pretrain-v3/metanode.yaml` during `Graph(args.dataset)` initialization.
  - This confirms command/runtime path is valid and next gate is dataset content availability.
- status: failed
- blocker_if_any: Dataset not staged; required file `datasets/single-pretrain-v3/metanode.yaml` is missing.

### Run: 20260302-1542-train-completion-01
- readiness_checklist:
  - `conda activate griffin-profiling`: passed
  - `make profiling-preflight`: passed (`python deps ok`)
  - asset path probe: `datasets/single-pretrain-v3` missing required metadata content
- date_time_utc: 2026-03-02T15:42:51Z
- mode: train
- dataset: `datasets/single-pretrain-v3`
- command: `scripts/profile_baseline.sh nsys 20260302-1542-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof nsys -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`
- git_commit: `eebeccb1d752a14cd22488459870f876957a2748`
- config: `hconfig_profiling_single_gpu.yaml`
- slice_definition: Baseline `nsys` wrapper of the same bounded completion slice.
- profiler: nsys
- outputs:
  - `artifacts/profiles/nsys/20260302-1542-train-completion-01.nsys-rep`
  - `logs/prof` (launch starts, then exits at dataset initialization)
- findings_notes:
  - `nsys` wrapper command executes and emits a `.nsys-rep` artifact.
  - Target app fails at the same dataset boundary (`metanode.yaml` missing), not at dependency import.
  - Previous dependency/runtime blocker class is resolved; dataset staging is now the only gating blocker for this slice.
- status: failed
- blocker_if_any: Dataset not staged; required file `datasets/single-pretrain-v3/metanode.yaml` is missing.
