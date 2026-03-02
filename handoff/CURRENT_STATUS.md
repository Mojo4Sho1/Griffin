# Current Status

## Snapshot
- Date: 2026-03-02 (UTC)
- Branch: `main-public`
- Commit: `eebeccb1d752a14cd22488459870f876957a2748`
- Profiling effort phase: Phase 3 actively executed; smoke and nsys attempts now pass dependency/preflight gates and are blocked at dataset staging boundary.
- Tooling snapshot:
  - `nsys`: `/usr/local/bin/nsys` (version `2023.4.4.54-234433681190v0`)
  - `ncu`: `/usr/local/bin/ncu` (version `2024.3.2.0`)
  - `conda`: `/home/jxc02713/miniconda3/bin/conda` (version `25.3.1`; `griffin-profiling` activation now works)
  - `accelerate`: available in `griffin-profiling`
  - `torch_geometric`: available in `griffin-profiling` (import verified)

## What Is Established
- Stable project operating rules now live in `AGENTS.md`.
- Handoff system is initialized in `handoff/` with strict file roles.
- Session history log now exists at `handoff/SESSION_LOG.md`.
- Profiling documentation scaffold is initialized in `profiling/`.
- Profiling overview doc is `profiling/_PROFILING_GUIDE.md` (no additional README files).
- Environment scaffold now exists at `environment.yml` with GPU-coupled package guidance in `profiling/PREFLIGHT.md`.
- Environment contract: `environment.yml` now uses conda-native PyTorch/PyG stack entries (`pytorch`, `pytorch_geometric`, `pytorch_scatter`) and is treated as the canonical setup baseline.
- Single-process profiling accelerate config exists at `hconfig_profiling_single_gpu.yaml` for baseline slice reproducibility.
- One-command readiness check exists: `make profiling-preflight`.
- `make profiling-preflight` now passes in `griffin-profiling` for the current environment.
- Profiling asset-availability tracker now exists at `profiling/ASSETS_STATUS.md`.
- Raw profiling artifact directories exist at:
  - `artifacts/profiles/nsys/`
  - `artifacts/profiles/ncu/`
- Raw profiling artifact paths above are excluded from Git; lightweight summaries remain tracked in docs.
- Wrapper compatibility fix applied: `scripts/profile_baseline.sh` now uses `nsys profile ... accelerate launch ...` (without extra `--` before application).

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

## Confirmed Safe Future Coarse Annotation Sites
- `hmaintask_completion.py`
  - `main(...)` epoch/step boundary: around `for epoch in range(args.maxepoch)` at line 192 and inner loader loop following it.
  - eval boundary: `eval_task(...)` at line 17 and call sites at lines 176/230/254/284.
  - compute boundary: `compute_loss(...)` line 92 and `compute_output(...)` line 82.
- `hmaintask_combine.py`
  - `main(...)` epoch/step boundary: line 189 plus inner train loop (loss call at line 207).
  - eval boundary: `eval_task(...)` line 18 and call sites at lines 173/223/247/280.
  - compute boundary: `compute_loss(...)` line 93 and `compute_output(...)` line 83.
- `hmaintask_downsample_absolute_eval_sample.py`
  - `main(...)` epoch/step boundary: line 193 plus inner train loop (loss call at line 211).
  - eval boundary: `eval_task(...)` line 20 and call sites at lines 177/227/252/287.
  - compute boundary: `compute_loss(...)` line 98 and `compute_output(...)` line 88.
- These are preferred for minimal, reversible, coarse timing markers only (no semantic changes).

## Confirmed Output and Artifact Paths
- TensorBoard/accelerate logging: `ProjectConfiguration(project_dir=args.logdir, logging_dir=args.logdir)` in:
  - `hmaintask_completion.py:105`
  - `hmaintask_combine.py:106`
  - `hmaintask_downsample_absolute_eval_sample.py:111`
- Checkpoint output destination: `args.savepath` and `best_checkpoint` save path in:
  - `hmaintask_completion.py:221` and `hmaintask_completion.py:280`
  - `hmaintask_combine.py:213` and `hmaintask_combine.py:276`
  - `hmaintask_downsample_absolute_eval_sample.py:217` and `hmaintask_downsample_absolute_eval_sample.py:282`
- Baseline profiler output destination conventions (wrapper-confirmed):
  - Nsight Systems: `artifacts/profiles/nsys/<run_id>` (`scripts/profile_baseline.sh:70`)
  - Nsight Compute: `artifacts/profiles/ncu/<run_id>` (`scripts/profile_baseline.sh:79`)
- Generated artifact from latest attempt:
  - `artifacts/profiles/nsys/20260302-1542-train-completion-01.nsys-rep`
- Transfer script stdout/stderr logs: `output/transfer/.../*.log`.

## Blockers, Uncertainties, Assumptions
- Smoke and nsys workload launches now fail at dataset initialization boundary:
  - `FileNotFoundError: datasets/single-pretrain-v3/metanode.yaml`
- Baseline slice assets validated as missing:
  - `datasets/single-pretrain-v3`
  - `datasets/joint-v65`
  - `checkpoints/single-completion/best_checkpoint`
  - `checkpoints/single-sft`
  - `checkpoints/transfer`
- Canonical smoke and nsys commands are executable and profiler artifacts are generated; successful workload progression now requires dataset staging only.
