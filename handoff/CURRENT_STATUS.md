# Current Status

## Snapshot
- Date: 2026-02-28 (UTC)
- Branch: `main-public`
- Commit: `b9d0e1fa8d89dfb1cd8bd5976b71de8a3b515427`
- Profiling effort phase: Setup and reconnaissance complete; baseline profiling command verification pending.
- Tooling snapshot:
  - `nsys`: `/usr/local/bin/nsys` (version `2023.4.4.54-234433681190v0`)
  - `ncu`: `/usr/local/bin/ncu` (version `2024.3.2.0`)
  - `conda`: `/home/jxc02713/miniconda3/bin/conda` (version `25.3.1`)

## What Is Established
- Stable project operating rules now live in `AGENTS.md`.
- Handoff system is initialized in `handoff/` with strict file roles.
- Session history log now exists at `handoff/SESSION_LOG.md`.
- Profiling documentation scaffold is initialized in `profiling/`.
- Profiling overview doc is `profiling/_PROFILING_GUIDE.md` (no additional README files).
- Environment scaffold now exists at `environment.yml` with GPU-coupled package guidance in `profiling/PREFLIGHT.md`.
- Single-process profiling accelerate config exists at `hconfig_profiling_single_gpu.yaml` for baseline slice reproducibility.
- One-command readiness check exists: `make profiling-preflight`.
- Profiling asset-availability tracker now exists at `profiling/ASSETS_STATUS.md`.
- Raw profiling artifact directories exist at:
  - `artifacts/profiles/nsys/`
  - `artifacts/profiles/ncu/`
- Raw profiling artifact paths above are excluded from Git; lightweight summaries remain tracked in docs.

## Repo Entry-Point Reconnaissance
- Main completion pretraining entry point:
  - `hmaintask_completion.py` (CLI entry at `if __name__ == "__main__"`; main training loop in `main`)
- Main SFT pretraining and fine-tuning entry point:
  - `hmaintask_combine.py` (same CLI style; supports `--tasks` and `--mode train/test`)
- Transfer/downsample training + sampled evaluation entry point:
  - `hmaintask_downsample_absolute_eval_sample.py`
- Transfer experiment launcher:
  - `transfer.sh` wraps `accelerate launch ... hmaintask_downsample_absolute_eval_sample.py`
- No dedicated standalone inference script found; evaluation/inference is currently done via `--mode test` in the main task scripts.

## Launch and Config Surface
- Training is launched through `accelerate launch`.
- Primary accelerate config: `hconfig.yaml` (multi-GPU, `num_processes: 8` currently configured).
- Task split mapping config: `task_names.yaml`.
- Canonical command examples are in `README.md` and `transfer.sh`.

## Likely Safe Future Coarse Annotation Sites
- Per-epoch and per-step training loops in:
  - `hmaintask_completion.py`
  - `hmaintask_combine.py`
  - `hmaintask_downsample_absolute_eval_sample.py`
- Task-level eval loops via `eval_task(...)` in the same files.
- Shared compute boundaries:
  - `compute_loss(...)`
  - `compute_output(...)`

## Observed Output and Artifact Paths
- TensorBoard/accelerate logging: `args.logdir` (examples under `logs/...`).
- Checkpoints/best checkpoint: `args.savepath` (examples under `checkpoints/...`).
- Transfer script stdout/stderr logs: `output/transfer/.../*.log`.

## Blockers, Uncertainties, Assumptions
- `nsys` and `ncu` binary availability/version are verified; exact baseline invocation flags for this repo workload are still unverified.
- No run has yet validated a minimal profiling slice command end-to-end on this environment.
- Dataset and checkpoint availability are assumed to follow README layout; not yet validated locally.
