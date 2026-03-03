# Profiling Campaign Plan

This file is the scenario-and-slice control plane for multi-run profiling campaigns.
It complements `profiling/RUNS.md` (append-only run records) by tracking required slices and gate progress.

## Campaign Rules

- Campaign IDs use: `gfm-<YYYYMMDD>-rNN`.
- Scenarios in scope for this campaign: `train`, `finetune`, `inference`.
- Transfer/downsample profiling is out of scope for this campaign and deferred.
- Slice execution is sequential: at most one row may be `in progress` at a time.
- Shared host guardrail applies to every row: check GPU3 occupancy first and run with `CUDA_VISIBLE_DEVICES=3`.

Status values in this file: `not started` | `in progress` | `blocked` | `done`

`profile_stage` enum:
- `baseline_unannotated`
- `baseline_annotated`
- `ncu_hotspot`

## Scenario Gates

- Baseline gate (Phase 4):
  - `train`: at least 2 successful `baseline_unannotated` `nsys` slices
  - `finetune`: at least 2 successful `baseline_unannotated` `nsys` slices
  - `inference`: at least 2 successful `baseline_unannotated` `nsys` slices
- Annotation gate (Phase 5):
  - at least 1 successful `baseline_annotated` `nsys` slice per scenario
- Deep-dive gate (Phase 7):
  - at least 1 successful `ncu_hotspot` slice per scenario after hotspot shortlist is confirmed

## Active Campaign

- campaign_id: `gfm-20260303-r01`
- canonical inference path: `hmaintask_combine.py --mode test --loadpath checkpoints/single-sft/best_checkpoint`

## Slice Matrix

| campaign_id | scenario | slice_id | profile_stage | objective | entry_script | mode | dataset | loadpath | savepath | smoke_run_id | nsys_run_id | ncu_run_id | status | blocker |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gfm-20260303-r01 | train | TR-S1 | baseline_unannotated | Baseline bounded completion train slice (validated). | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `20260302-1636-train-completion-01` | `20260302-1637-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | train | TR-S2 | baseline_unannotated | Second baseline train slice for reproducibility. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `20260303-1726-train-completion-02` | `20260303-1727-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-S1 | baseline_unannotated | First baseline finetune slice. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `20260303-1744-finetune-combine-01` | `20260303-1745-finetune-combine-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-S2 | baseline_unannotated | Second baseline finetune slice for reproducibility. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | none |
| gfm-20260303-r01 | inference | IF-S1 | baseline_unannotated | First baseline inference slice (combine test mode). | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | none |
| gfm-20260303-r01 | inference | IF-S2 | baseline_unannotated | Second baseline inference slice for reproducibility. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | none |
| gfm-20260303-r01 | train | TR-A1 | baseline_annotated | Annotated train validation slice after NVTX insertion. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `-` | `-` | not started | waits for Phase 5b |
| gfm-20260303-r01 | finetune | FT-A1 | baseline_annotated | Annotated finetune validation slice after NVTX insertion. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | waits for Phase 5b |
| gfm-20260303-r01 | inference | IF-A1 | baseline_annotated | Annotated inference validation slice after NVTX insertion. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | waits for Phase 5b |
| gfm-20260303-r01 | train | TR-N1 | ncu_hotspot | One targeted train hotspot deep-dive run. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `-` | `-` | not started | waits for hotspot shortlist |
| gfm-20260303-r01 | finetune | FT-N1 | ncu_hotspot | One targeted finetune hotspot deep-dive run. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | waits for hotspot shortlist |
| gfm-20260303-r01 | inference | IF-N1 | ncu_hotspot | One targeted inference hotspot deep-dive run. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | waits for hotspot shortlist |

## Update Rule

- Every completed run entry in `profiling/RUNS.md` must map to exactly one matrix row above.
- Update row `status`, run IDs, and blocker text immediately after each run attempt.
- If a required precondition is missing (asset, GPU availability, etc.), mark row `blocked` and mirror blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
