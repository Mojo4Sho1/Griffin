# Current Status

## Snapshot
- Date: 2026-03-04 (UTC)
- Branch: `main-public`
- Commit: `235b7970ca75a77ab0f1043e6b5df5c1d330d9b9`
- Profiling effort phase: Baseline validation gates (Phases 4a/4b/4c), Phase 5 (`steady_unannotated` representativeness), Phase 6 (`coarse` NVTX insertion), and Phase 7 (`steady_annotated` capture execution) are complete across the current campaign scope; Phase 8 (`review_gate`) is in progress with capture evidence recorded and pending explicit human outcome.
- Tooling snapshot:
  - `nsys`: `/usr/local/bin/nsys` (version `2023.4.4.54-234433681190v0`)
  - `ncu`: `/usr/local/bin/ncu` (version `2024.3.2.0`)
  - `sqlite3`: available (version `3.45.3`)
  - `conda`: `/home/jxc02713/miniconda3/bin/conda` (version `25.3.1`; `griffin-profiling` activation now works)
  - `accelerate`: available in `griffin-profiling`
  - `torch_geometric`: available in `griffin-profiling` (import verified)

## Campaign Counters (`gfm-20260303-r01`)
- baseline_nsys_success:
  - train: 2
  - finetune: 2
  - inference: 2
- steady_unannotated_representative_pairs:
  - train: 1
  - finetune: 1
  - inference: 1
- annotated_nsys_success:
  - train: 1
  - finetune: 1
  - inference: 1
- ncu_success:
  - train: 0
  - finetune: 0
  - inference: 0

## Workflow Gate State
- capture_complete: true
- capture_evidence_result_id: gfm-20260303-r01-capture-gate-01
- review_complete: false
- review_outcome_pending: true
- ncu_allowed: false
- optimization_discussion_allowed: false

## What Is Established
- Stable project operating rules now live in `AGENTS.md`.
- Handoff system is initialized in `handoff/` with strict file roles.
- Session history log now exists at `handoff/SESSION_LOG.md`.
- Profiling documentation scaffold is initialized in `profiling/`.
- Profiling overview doc is `profiling/_PROFILING_GUIDE.md` (no additional README files).
- Campaign matrix now exists at `profiling/CAMPAIGN_PLAN.md` with explicit rows for `train`/`finetune`/`inference` across `baseline_validation`, `steady_unannotated`, `steady_annotated`, `review_gate`, and `ncu_post_review` stages.
- Environment scaffold now exists at `environment.yml` with GPU-coupled package guidance in `profiling/PREFLIGHT.md`.
- Environment contract: `environment.yml` now uses conda-native PyTorch/PyG stack entries (`pytorch`, `pytorch_geometric`, `pytorch_scatter`) and is treated as the canonical setup baseline.
- Single-process profiling accelerate config exists at `hconfig_profiling_single_gpu.yaml` for baseline slice reproducibility.
- One-command readiness check exists: `make profiling-preflight`.
- `make profiling-preflight` now passes in `griffin-profiling` for the current environment.
- Profiling asset-availability tracker now exists at `profiling/ASSETS_STATUS.md`.
- Dataset path `datasets/single-pretrain-v3` is now staged with minimal required metadata/embeddings/HF dataset tree so `Graph(args.dataset)` and `Task(args.dataset)` initialize successfully for command-path verification.
- Completion-script fix applied at `hmaintask_completion.py:246` to use `accelerator.device` in the metric gather tensor allocation (non-semantic runtime compatibility fix).
- Finetune combine-script compatibility fix applied at `hmaintask_combine.py:238` to use `accelerator.device` for validation metric gather tensor allocation (non-semantic runtime compatibility fix).
- Baseline validation slices are now explicitly treated as pipeline-validation evidence only; optimization evidence requires steady-state gates.
- Workflow sequencing is now explicit in docs: baseline validation -> steady-state unannotated -> minimal NVTX annotation -> steady-state annotated final capture -> human review -> post-review targeted `ncu` -> post-review optimization discussion.
- Phase 6a output is now documented in `profiling/_PROFILING_GUIDE.md` as a minimal coarse NVTX taxonomy and script-level insertion map for `hmaintask_completion.py` and `hmaintask_combine.py`.
- NVTX documentation now includes a two-tier escalation policy: immutable coarse roots plus optional `targeted_fine` child labels gated by `RV-G1` review completion and approved hotspot shortlist.
- NVTX policy contract is now hardened with explicit range-nesting interpretation, default `all_ranks` emission policy, and schema-change/versioning rules (`nvtx-v<major>.<minor>`).
- Phase 6b code insertion is complete in `hmaintask_completion.py` and `hmaintask_combine.py` with minimal coarse ranges (`gfm.setup`, `gfm.mode_test_only`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`) via a reversible helper context wrapper.
- Raw profiling artifact directories exist at:
  - `artifacts/profiles/nsys/`
  - `artifacts/profiles/ncu/`
- Raw profiling artifact paths above are excluded from Git; lightweight summaries remain tracked in docs.
- Wrapper compatibility fix applied: `scripts/profile_baseline.sh` now uses `nsys profile ... accelerate launch ...` (without extra `--` before application).
- Hybrid analysis workflow now exists:
  - Human playbook: `profiling/MANUAL_ANALYSIS.md`
  - SQL deep-dive query library: `profiling/sql/manual_queries.sql`
  - Automated post-`nsys` analyzer: `scripts/analyze_nsys_run.sh`
- Analysis bundle schema is now standardized at `artifacts/profiles/analysis/<run_id>/` (`summary.md`, `metrics.json`, `nvtx_sum.txt`, `cuda_gpu_kern_sum.txt`, `cuda_api_sum.txt`, `meta.txt`).
- Gate-critical analysis artifact backfill is complete for:
  - `20260303-1727-train-completion-01`
  - `20260303-1945-finetune-combine-01`
  - `20260303-2031-inference-combine-01`
  - `20260303-2049-train-completion-01`
  - `20260303-2050-train-completion-01`
  - `20260303-2058-finetune-combine-01`
  - `20260303-2059-finetune-combine-01`
  - `20260303-2134-inference-combine-01`
  - `20260303-2138-inference-combine-01`
  - `20260304-1541-train-annotated-completion-01`
  - `20260304-1622-finetune-annotated-combine-01`
  - `20260304-1652-inference-annotated-combine-01`

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
  - `artifacts/profiles/nsys/20260304-1652-inference-annotated-combine-01.nsys-rep`
- Transfer script stdout/stderr logs: `output/transfer/.../*.log`.

## Blockers, Uncertainties, Assumptions
- Baseline slice asset status now:
  - `datasets/single-pretrain-v3`: present (minimal synthetic staging for command-path verification)
  - `checkpoints/single-completion/best_checkpoint`: present (generated in successful reruns)
  - `checkpoints/single-sft/best_checkpoint`: present (generated in FT-S1 rerun)
  - `datasets/joint-v65`: missing
  - `checkpoints/transfer`: missing
- Current campaign blocker surface:
  - no active runtime blocker in `train`/`finetune` baseline-validation paths.
  - Phase 4b finetune baseline-validation gate is complete (`FT-B1` + `FT-B2`).
  - Phase 4c inference baseline-validation gate is complete (`IF-B1` + `IF-B2`).
  - Phase 5 steady-state representativeness train row `TR-SU1` is complete (`representative_pass=true`, `top3_overlap=3/3`, `timeshare_drift_pct=1.72`).
  - Phase 5 steady-state representativeness finetune row `FT-SU1` is complete (`representative_pass=true`, `top3_overlap=3/3`, `timeshare_drift_pct=1.16`).
  - Phase 5 steady-state representativeness inference row `IF-SU1` is complete (`representative_pass=true`, `top3_overlap=3/3`, `timeshare_drift_pct=0.86`).
  - Phase 6b coarse NVTX insertion is complete and syntax sanity check passed (`python -m py_compile hmaintask_completion.py hmaintask_combine.py`).
  - Phase 7 `steady_annotated` row `TR-SA1` is complete with coarse labels observed in `nvtxsum` (`gfm.setup`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`).
  - Phase 7 `steady_annotated` row `FT-SA1` is complete with verified coarse NVTX labels after forced-export `nvtx_sum` recheck (`20260304-1622-finetune-annotated-combine-01`); the earlier empty `nvtxsum` output is treated as an export/reporting-path false negative.
  - Phase 7 `steady_annotated` row `IF-SA1` is complete with forced-export `nvtx_sum` coverage present for inference-path coarse labels (`20260304-1652-inference-annotated-combine-01`).
  - Capture gate status is now `capture_complete=true`; next active workflow boundary is Phase 8 human review gate (`RV-G1`).
- Optimization/recommendation policy surface:
  - Optimization recommendations are prohibited until capture_complete and review_complete are both true.
  - `targeted_fine` label expansion is optional and allowed only post-review (`RV-G1` done with approved hotspot focus), while keeping `profile_stage=steady_annotated`.
  - `ncu` runs are prohibited until `ncu_allowed: true` (post-review gate).
  - Analysis bundle policy: every new successful `nsys` run must include `artifacts/profiles/analysis/<run_id>/` and corresponding `profiling/RUNS.md` metadata fields.
- Canonical smoke and `nsys` commands are executable end-to-end for bounded `train`, `finetune`, and `inference` baseline-validation slices, and `nsys` emits `.nsys-rep`.
- Remaining uncertainty: current dataset/checkpoint setup is synthetic/minimal for command-path verification, so kernel/runtime distribution may not match production-scale workloads.
