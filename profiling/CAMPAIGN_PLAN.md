# Profiling Campaign Plan

This file is the scenario-and-slice control plane for multi-run profiling campaigns.
It complements `profiling/RUNS.md` (append-only run records) by tracking required slices, review gates, and execution order.

## Campaign Rules

- Campaign IDs use: `gfm-<YYYYMMDD>-rNN`.
- Scenarios in scope for this campaign: `train`, `finetune`, `inference`.
- Transfer/downsample profiling is out of scope for this campaign and deferred.
- Slice execution is sequential: at most one row may be `in progress` at a time.
- Shared host guardrail applies to every row: check GPU3 occupancy first and run with `CUDA_VISIBLE_DEVICES=3`.
- Baseline validation slices are pipeline-validation evidence only and are not sufficient for optimization recommendations.
- Optimization recommendations are prohibited until capture + review gates are complete.

Status values in this file:
- `not started`
- `in progress`
- `blocked`
- `blocked_non_representative`
- `blocked_budget_exhausted`
- `waiting_human_review`
- `done`

`profile_stage` enum:
- `baseline_validation`
- `steady_unannotated`
- `steady_annotated`
- `review_gate`
- `ncu_post_review`

## Scenario Gates

- Baseline validation gate (short slices):
  - `train`: at least 2 successful `baseline_validation` `nsys` slices
  - `finetune`: at least 2 successful `baseline_validation` `nsys` slices
  - `inference`: at least 2 successful `baseline_validation` `nsys` slices
- Steady-state representativeness gate (optimization-evidence class):
  - Unit is iterations, not epochs/minutes.
  - Compare two windows in same scenario/config.
  - Pass criteria: top-3 hotspot overlap `>= 2/3` and per-hotspot time-share drift `<= 20%`.
  - Adaptive window policy: `5/25 -> 10/50 -> 20/100 -> 40/200` (`warmup/profile` iterations).
  - Runtime policy: soft cap `45` minutes; do not kill healthy runs at cap, allow completion and log overrun.
- Capture-complete gate:
  - All baseline + steady-state rows are complete, or blocked with documented non-actionable reasons.
- Human review gate:
  - Must be `done` before any `ncu_post_review` row can execute.

## Active Campaign

- campaign_id: `gfm-20260303-r01`
- canonical inference path: `hmaintask_combine.py --mode test --loadpath checkpoints/single-sft/best_checkpoint`

## Slice Matrix

| campaign_id | scenario | slice_id | profile_stage | objective | entry_script | mode | dataset | loadpath | savepath | smoke_run_id | nsys_run_id | ncu_run_id | status | blocker |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gfm-20260303-r01 | train | TR-B1 | baseline_validation | Baseline bounded completion train slice (validated). | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `20260302-1636-train-completion-01` | `20260302-1637-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | train | TR-B2 | baseline_validation | Second baseline train validation slice for reproducibility. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `20260303-1726-train-completion-02` | `20260303-1727-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-B1 | baseline_validation | First baseline finetune validation slice. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `20260303-1744-finetune-combine-01` | `20260303-1745-finetune-combine-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-B2 | baseline_validation | Second baseline finetune validation slice for reproducibility. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `20260303-1944-finetune-combine-02` | `20260303-1945-finetune-combine-01` | `-` | done | none |
| gfm-20260303-r01 | inference | IF-B1 | baseline_validation | First baseline inference validation slice (combine test mode). | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `20260303-1953-inference-combine-01` | `20260303-1954-inference-combine-01` | `-` | done | none |
| gfm-20260303-r01 | inference | IF-B2 | baseline_validation | Second baseline inference validation slice for reproducibility. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `20260303-2030-inference-combine-01` | `20260303-2031-inference-combine-01` | `-` | done | none |
| gfm-20260303-r01 | train | TR-SU1 | steady_unannotated | Steady-state unannotated train window pair with stability gate. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `-` | `-` | not started | none |
| gfm-20260303-r01 | finetune | FT-SU1 | steady_unannotated | Steady-state unannotated finetune window pair with stability gate. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | queued after `TR-SU1` |
| gfm-20260303-r01 | inference | IF-SU1 | steady_unannotated | Steady-state unannotated inference window pair with stability gate. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | queued after `FT-SU1` |
| gfm-20260303-r01 | train | TR-SA1 | steady_annotated | Steady-state annotated train capture after minimal NVTX insertion. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `-` | `-` | not started | waits for annotation insertion + steady_unannotated |
| gfm-20260303-r01 | finetune | FT-SA1 | steady_annotated | Steady-state annotated finetune capture after minimal NVTX insertion. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | waits for annotation insertion + steady_unannotated |
| gfm-20260303-r01 | inference | IF-SA1 | steady_annotated | Steady-state annotated inference capture after minimal NVTX insertion. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | waits for annotation insertion + steady_unannotated |
| gfm-20260303-r01 | campaign | RV-G1 | review_gate | Capture-complete + human-review approval gate. | `-` | `-` | `-` | `-` | `-` | `-` | `-` | `-` | waiting_human_review | set to `done` only after all capture rows complete and human review concludes |
| gfm-20260303-r01 | train | TR-N1 | ncu_post_review | One targeted train hotspot deep-dive run. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `-` | `-` | not started | blocked until `RV-G1` is done |
| gfm-20260303-r01 | finetune | FT-N1 | ncu_post_review | One targeted finetune hotspot deep-dive run. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | blocked until `RV-G1` is done |
| gfm-20260303-r01 | inference | IF-N1 | ncu_post_review | One targeted inference hotspot deep-dive run. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | blocked until `RV-G1` is done |

## Update Rule

- Every completed run entry in `profiling/RUNS.md` must map to exactly one matrix row above.
- Update row `status`, run IDs, and blocker text immediately after each run attempt.
- If representativeness fails, use `blocked_non_representative` and record stability metrics.
- If a run exceeds planning budget due to healthy progress, allow completion and log overrun details; do not mark this as failure.
- `ncu_post_review` rows are invalid unless `RV-G1` is `done`.
- If a required precondition is missing (asset, GPU availability, etc.), mark row `blocked` and mirror blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
