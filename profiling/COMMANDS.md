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
9. Post-run analysis bundle generation for each successful `nsys` run
10. Cross-scenario realistic-scale review (`RV-R2`) after `TR-B1` + `FT-B1` + `IF-B1`

Policy: no optimization recommendations before capture + review gates complete.
Policy: `targeted_fine` relabeling is optional and only allowed after `RV-G1` is `done` with approved hotspot focus; see `profiling/_PROFILING_GUIDE.md` section `NVTX Granularity Escalation Policy (Two-Tier)`.
Policy: default rank emission is `all_ranks`; any single-rank/subset filtering must be documented in run metadata.
Policy: for annotated-stage NVTX verification, use `nvtx_sum` with forced export (`nsys stats --force-export=true --report nvtx_sum <run>.nsys-rep`); do not use deprecated `nvtxsum` as canonical evidence.
Policy: false-negative guardrail for annotated runs: if an initial NVTX report is empty, rerun once with `--force-export=true` before documenting any NVTX anomaly/blocker.
Policy: one staged `ncu` smoke run is allowed to validate tooling before realistic-scale `ncu`; record those runs with `ncu_intent: tooling_smoke`.
Policy: staged `ncu` smoke is non-gating and not optimization evidence.
Policy: realistic-scale execution now uses `execution_policy_version=realistic-v2` with one full scenario per agent.
Policy: realistic-scale scenario unit is a multi-slice `nsys` chain with per-slice analysis bundles; do not substitute smoke-chain + single `nsys`.
Policy: realistic adaptation order is fixed: depth first (`3 -> 5 -> 7 -> +2`), then size tiers (`8/4 -> 16/8 -> 32/16`) only if still unstable.
Policy: hard size cap is `32/16`; exceeding it requires explicit human instruction.
Cross-reference: follow `profiling/_PROFILING_GUIDE.md` sections `Range Nesting And Overlap Policy`, `Distributed / Rank Emission Policy`, and `Schema Change Rule`.
Run-scale reference: see `profiling/SCALE_PROFILES.md` for strict staged-vs-realistic criteria.

Post-`nsys` analysis policy:
- After each successful `nsys` run, generate:
  - `scripts/analyze_nsys_run.sh --run-id <run_id>`
- The generated bundle at `artifacts/profiles/analysis/<run_id>/` is the default human-review input.
- For historical data migration, backfill analysis bundles for gate-critical runs only; all new successful `nsys` runs are mandatory.

Post-`ncu` analysis policy:
- After each successful `ncu` run, generate:
  - `python scripts/analyze_ncu_run.py --run-id <run_id>`
- The generated derived bundle at `artifacts/profiles/analysis/<run_id>/` is the default notebook/SQL review input.
- `ncu` derived bundles are expected to contain `ncu_analysis.sqlite`, summary sidecars, `ncu_progress.log`, and stable `sections/<section_id>.csv` sidecars for each completed import; interrupted `*.tmp` files are debug-only and are never ingested as final structured data.

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
- Required metadata for new realistic-scale entries:
  - `execution_policy_version` (`realistic-v2`)
  - `legacy_policy_evidence` (`true|false`)
  - `slice_size_tier` (`8/4|16/8|32/16`)
  - `scenario_completion_state` (`in_progress|complete|complete_legacy`)

## Preferred Baseline Wrapper

```bash
scripts/profile_baseline.sh <smoke|nsys|ncu> <run_id> <task_script.py> <dataset> <log_dir> <log_name> -- <extra_task_args...>
```

## Autonomous Slice-Chain Wrapper

Use this wrapper to execute sequential bounded slices with automatic checkpoint/state handoff and summary output.

```bash
scripts/run_slice_chain.sh \
  --chain-id <id> \
  --campaign-id <campaign_id> \
  --slice-id <slice_id> \
  --run-class <minimal_staged|realistic_scale> \
  --task-script <task_script.py> \
  --dataset <dataset_path> \
  --log-dir <log_dir> \
  --log-name-prefix <prefix> \
  --savepath <checkpoint_dir> \
  --num-slices <n> \
  --max-train-steps <n> \
  --max-eval-steps <n> \
  --mode <smoke|nsys> \
  --resume-mode <model|state|fixed> \
  --initial-loadpath <path> \
  --profile-stage <baseline_validation|steady_unannotated|steady_annotated|ncu_post_review> \
  --scenario <train|finetune|inference> \
  -- <extra_task_args...>
```

Notes:
- Runs `make profiling-preflight` once at chain start.
- Checks GPU3 occupancy before each slice.
- Appends human-readable summary to `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md` by default.
- `resume-mode=model` uses latest `checkpoint-*` output path for next slice `--loadpath` (checkpoint-producing scenarios only).
- `resume-mode=state` uses `--save_state_path/--load_state_path` handoff via `state-slice-<k>` directories.
- `resume-mode=fixed` uses a constant `--initial-loadpath` for every slice and does not require `checkpoint-*` or `state-slice-*` outputs.
- In `resume-mode=fixed`, do not pass `--loadpath` in extra args; the wrapper injects it from `--initial-loadpath`.

### Realistic-Scale Scenario Standard (`realistic-v2`)

For realistic-scale rows (`gfm-20260304-r02`), use `run_slice_chain.sh` in `nsys` mode as the canonical scenario execution path.

Default starting parameters:
- `--num-slices 3`
- `--max-train-steps 8`
- `--max-eval-steps 4`
- `--mode nsys`
- `--resume-mode model` for checkpoint-producing scenarios (`train`/`finetune`)
- `--resume-mode fixed` for checkpointless inference scenarios (`--mode test`)

If stability is insufficient:
1. Extend depth first: `3 -> 5 -> 7 -> +2`
2. If still unstable, increase size tier and restart scenario chain with a new `chain_id`:
   - `8/4 -> 16/8 -> 32/16`

Required outputs per slice:
- `artifacts/profiles/nsys/<run_id>.nsys-rep`
- `artifacts/profiles/analysis/<run_id>/` via `scripts/analyze_nsys_run.sh --run-id <run_id>`
- append-only chain summary entry in `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md`

### Detached Execution (Required for Long Runs)

Use `tmux` for unattended or overnight chains. Do not rely on a foreground shell session.

```bash
tmux new -d -s <session_name> "bash -lc 'eval \"\$(conda shell.bash hook)\" && conda activate griffin-profiling && CUDA_VISIBLE_DEVICES=3 scripts/run_slice_chain.sh ...'"
tmux ls
tmux capture-pane -pt <session_name> | tail -n 80
```

If a disconnect/session interruption occurs:
- do not delete prior chain artifacts or docs;
- rerun the full scenario with a new `chain_id`;
- mark the prior chain as superseded in `profiling/RUNS.md` and `handoff/SESSION_LOG.md`;
- archive non-canonical summaries with `scripts/archive_chain_summary.sh --chain-id <old_chain_id> --reason "<reason>"`.

## Post-Run Analysis Bundle Command

```bash
scripts/analyze_nsys_run.sh --run-id <run_id>
```

Expected outputs:
- `artifacts/profiles/analysis/<run_id>/summary.md`
- `artifacts/profiles/analysis/<run_id>/metrics.json`
- `artifacts/profiles/analysis/<run_id>/nvtx_sum.txt`
- `artifacts/profiles/analysis/<run_id>/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/<run_id>/cuda_api_sum.txt`
- `artifacts/profiles/analysis/<run_id>/meta.txt`

## 1) Baseline Validation Commands (Short Slices)

These are intentionally bounded to verify command/runtime/profiler path health.
For realistic-scale scenario execution under `realistic-v2`, prefer the chain commands below over standalone smoke + single-`nsys` pairs.

Active dataset default in this workspace:
- `datasets/single-pretrain-v3-hf`
- `datasets/single-pretrain-v3` remains a historical staged path referenced by older records.

### Train (`hmaintask_completion.py`, mode `train`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py datasets/single-pretrain-v3-hf logs/prof train-baseline-smoke -- --savepath checkpoints/single-completion --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-train-completion-01> hmaintask_completion.py datasets/single-pretrain-v3-hf logs/prof train-baseline-nsys -- --savepath checkpoints/single-completion --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### Finetune (`hmaintask_combine.py`, mode `train`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-finetune-combine-01> hmaintask_combine.py datasets/single-pretrain-v3-hf logs/prof finetune-baseline-smoke -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-finetune-combine-01> hmaintask_combine.py datasets/single-pretrain-v3-hf logs/prof finetune-baseline-nsys -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### Inference (`hmaintask_combine.py`, mode `test`)

Smoke:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh smoke <YYYYMMDD-HHMM-inference-combine-01> hmaintask_combine.py datasets/single-pretrain-v3-hf logs/prof inference-baseline-smoke -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --max_eval_steps 4 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

`nsys`:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-inference-combine-01> hmaintask_combine.py datasets/single-pretrain-v3-hf logs/prof inference-baseline-nsys -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --max_eval_steps 4 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### Realistic-Scale Chain Examples (`realistic-v2`, preferred)

Finetune scenario (`FT-B1`, default tier `8/4`, 3 slices):
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

Inference scenario (`IF-B1`, default tier `8/4`, 3 slices):
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
  --resume-mode fixed \
  --initial-loadpath checkpoints/single-sft/best_checkpoint \
  --profile-stage baseline_validation \
  --scenario inference \
  -- --mode test --tasks ALLTASK --maxepoch 1 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
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
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-train-completion-annot-01> hmaintask_completion.py datasets/single-pretrain-v3-hf logs/prof train-annot-nsys -- --savepath checkpoints/single-completion --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Finetune:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-finetune-combine-annot-01> hmaintask_combine.py datasets/single-pretrain-v3-hf logs/prof finetune-annot-nsys -- --mode train --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --tasks ALLTASK --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --patience 5 --eval_per_epoch 1 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Inference:
```bash
CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh nsys <YYYYMMDD-HHMM-inference-combine-annot-01> hmaintask_combine.py datasets/single-pretrain-v3-hf logs/prof inference-annot-nsys -- --mode test --loadpath checkpoints/single-sft/best_checkpoint --tasks ALLTASK --max_eval_steps 4 --batchsize 64 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

## 4) Targeted Deep Dive (`ncu_post_review`)

Run only after:
- capture-complete gate passes
- human review gate is marked done
- realistic-scale review outputs provide the hotspot shortlist by default

Two-tier policy:
- `ncu_intent: hotspot_deep_dive` is the evidence-grade path. The preferred default is `core + cap`: collect the core Nsight Compute sections we actually review and cap matched launches at `5` unless the run record justifies a different value.
- `ncu_intent: tooling_smoke` is the operator-friendly validation path. Use it to validate `sudo`, `tmux`, command shape, and artifact creation before committing to a longer evidence-grade capture. Recommended launch cap is `1`.
- `tooling_smoke` runs are non-gating and must not be treated as optimization-prioritization evidence unless a later review explicitly promotes them.
- `--set full` is now an explicit escalation path only. Do not use it as the default capture mode for new hotspot work.
- Historical note: `TR-N1` (`20260319-1514-train-completion-01`) used legacy `--set full` with no launch cap, produced an oversized `7.8G` report, and remains valid source evidence, but it is not the preferred default report shape for future runs.

Preferred wrapper:
```bash
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh <train|finetune|inference> <hotspot_1|hotspot_2|hotspot_3> [--run-id <run_id>] [--launch-count <n>] [--sections-profile <profile>] [--print-only]
```

Wrapper behavior:
- Generates a fresh UTC run ID automatically when `--run-id` is omitted.
- Runs the required GPU3 occupancy checks and blocks if GPU3 is busy.
- Runs `make profiling-preflight` by default before launch.
- Prints the fully resolved `sudo env CUDA_VISIBLE_DEVICES=3 ncu ...` command before execution for auditability.
- Uses `sudo` by default because this host requires elevated access for valid Nsight Compute counter collection; use `--no-sudo` only if GPU counter permissions are already available without sudo.
- Defaults to `--sections-profile core` and `--launch-count 5`.
- Accepts either approved hotspot aliases (`hotspot_1`, `hotspot_2`, `hotspot_3`) or a raw kernel name/regex fragment.
- Supports `--launch-skip` when a later run record needs a specific match offset.

Default unattended pattern for privileged `ncu` capture:
- The human operator creates the `tmux` session and owns `sudo` credential entry.
- The human runs the helper inside the attached `tmux` session, confirms the command, enters the `sudo` password if prompted, then detaches with `Ctrl-b d`.
- The agent or human can monitor progress with `tmux capture-pane` or reattach with `tmux attach`.

Canonical user-started `tmux` flow for capture:
```bash
tmux new -s tr-ncu-h1-<YYYYMMDD-HHMM>
cd /home/jxc02713/projects/GFM/Griffin
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh train hotspot_1 |& tee artifacts/profiles/ncu/tr-ncu-h1-<YYYYMMDD-HHMM>.log
```

Canonical monitor commands:
```bash
tmux capture-pane -pt tr-ncu-h1-<YYYYMMDD-HHMM> | tail -n 80
tmux attach -t tr-ncu-h1-<YYYYMMDD-HHMM>
```

Evidence-grade realistic train deep dive default (`core + cap`):
```bash
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh train hotspot_1
```

Operator-friendly tooling smoke default (`core + launch-count 1`):
```bash
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh train hotspot_1 --launch-count 1
```

Explicit escalation back to the full set (document rationale in `profiling/RUNS.md` first):
```bash
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh train hotspot_1 --set full --launch-count 5
```

Print the exact command without launching:
```bash
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh train hotspot_1 --print-only
```

Current `core` section list: `LaunchStats`, `Occupancy`, `SchedulerStats`, `WarpStateStats`, `ComputeWorkloadAnalysis`, `MemoryWorkloadAnalysis`, `SpeedOfLight`, `WorkloadDistribution`.

Use the wrapper for manual command generation whenever possible. If fully manual control is needed, the preferred train command shape now mirrors the wrapper defaults:
```bash
sudo env PATH="$PATH" CUDA_VISIBLE_DEVICES=3 ncu -k regex:<kernel_name> --kernel-name-base function -c 5 --section LaunchStats --section Occupancy --section SchedulerStats --section WarpStateStats --section ComputeWorkloadAnalysis --section MemoryWorkloadAnalysis --section SpeedOfLight --section WorkloadDistribution --export artifacts/profiles/ncu/<YYYYMMDD-HHMM-train-completion-01> --target-processes all accelerate launch --config_file hconfig_profiling_single_gpu.yaml hmaintask_completion.py datasets/single-pretrain-v3-hf logs/prof train-hotspot-ncu --savepath checkpoints/single-completion --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

## Post-`ncu` Derived Bundle Command

Preferred long-running analysis pattern for large reports:
```bash
tmux new -s tr-ncu-analyze-<YYYYMMDD-HHMM>
cd /home/jxc02713/projects/GFM/Griffin
conda activate griffin-profiling
python scripts/analyze_ncu_run.py --run-id <run_id> |& tee artifacts/profiles/analysis/<run_id>/ncu_reanalysis_<YYYYMMDD-HHMM>.log
```

Analyzer behavior:
- No default import timeout. Large reports should run in `tmux` and be allowed to finish naturally.
- Optional explicit overrides remain available via `--session-timeout-sec` and `--section-timeout-sec`.
- Section imports are atomic: completed imports are promoted from `*.tmp` to stable sidecars only after a clean exit.
- Interrupted or timed-out `*.tmp` files are debug-only evidence and are never ingested as complete structured data.
- Rerunning the analyzer reuses completed sidecars and resumes the remaining sections instead of starting over.

Expected outputs:
- `artifacts/profiles/analysis/<run_id>/ncu_analysis.sqlite`
- `artifacts/profiles/analysis/<run_id>/ncu_summary.md`
- `artifacts/profiles/analysis/<run_id>/ncu_metrics.json`
- `artifacts/profiles/analysis/<run_id>/ncu_meta.txt`
- `artifacts/profiles/analysis/<run_id>/ncu_session.csv` (when session import completes)
- `artifacts/profiles/analysis/<run_id>/sections/<section_id>.csv` for each completed section import
- `artifacts/profiles/analysis/<run_id>/ncu_progress.log`
- `artifacts/profiles/analysis/<run_id>/ncu_strings_excerpt.txt`

Default review surfaces:
- SQL: `sqlite3 -header -column artifacts/profiles/analysis/<run_id>/ncu_analysis.sqlite < profiling/sql/manual_queries_ncu.sql`
- Notebook: `profiling/notebooks/ncu_sqlite_review.ipynb`
- Coverage tracker: `profiling/NCU_COVERAGE.md`

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
