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
- Staged `ncu` row execution is optional and non-gating; use it only as tooling smoke validation when needed.
- Realistic-scale `ncu` rows are the default source for optimization-oriented deep-dive evidence.
- Until a dedicated table column is introduced, campaign rows should declare run class (`minimal_staged` or `realistic_scale`) in objective/blocker notes where ambiguity could affect interpretation.
- Canonical run-scale definitions and criteria are documented in `profiling/SCALE_PROFILES.md`.
- Historical `minimal_staged` rows may reference legacy dataset path `datasets/single-pretrain-v3`; active/default path for current realistic execution is `datasets/single-pretrain-v3-hf`.

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

## Autonomous Scenario Execution Policy

- Single-agent ownership: one agent handles one scenario row at a time for chained slice execution.
- Slice execution unit is step-bounded (`--max_train_steps`, optional `--max_eval_steps`), not wall-clock bounded.
- Long-running or overnight chains should be launched in detached `tmux` sessions; do not depend on an attached terminal session.
- Resume source for the next slice must be the latest successful output artifact from the prior slice:
  - model-resume mode: latest `checkpoint-*`
  - full-state mode: latest `state-slice-<k>`
- Per-slice summaries are mandatory and append-only at `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md`.

## Chain Rerun and Supersession Policy

- Chain history is append-only; never delete prior chain summaries/run records due to interruption uncertainty.
- If continuity is uncertain (disconnect/session loss), rerun the full scenario from slice 1 with a new `chain_id`.
- Mark the earlier chain as `superseded` in:
  - `profiling/RUNS.md` (notes field or explicit supersession metadata)
  - `handoff/SESSION_LOG.md`
- Archive superseded summaries from `profiling/chains/active/` into `profiling/chains/archive/` using `scripts/archive_chain_summary.sh`.
- Canonical decision input for a scenario row should reference only the latest non-superseded full-chain result.

## Adaptive Slice Depth Policy

- Default target for each scenario chain is `3` slices.
- If representativeness is not met at 3, extend target to `5`.
- If representativeness is not met at 5, extend target to `7`.
- If representativeness is still not met at 7, continue in `+2` blocks (`9`, `11`, `13`, ...) until criteria pass.
- Every extension beyond the current target must include an explicit rationale in chain and handoff logs (stability/drift evidence and new target).

## Continuation Contract (8+)

- Continuation index is deterministic:
  - `next_slice_index = last_completed_slice + 1`
- Continuation resume source is deterministic:
  - `resume_input = prior slice output artifact path`
- Source of truth for continuation:
  - latest entry in `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md` for `last_completed_slice`, status, and output path.
- New agents resuming a partial chain must not restart from slice 1 when a valid continuation artifact exists.

## End-of-Scenario Aggregate Summary Requirement

- After a scenario chain completes or stops, add one aggregate summary block to the same `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md`.
- Aggregate summary must include:
  - slices attempted/completed
  - representativeness decision (`pass`, `fail`, or `extend`)
  - hotspot stability trend across the processed slices
  - total elapsed wall time for the chain
  - explicit next action (`stop`, `extend to <target>`, or `handoff resume at slice <N+1>`)
- Mirror timing + decision outcome in `handoff/SESSION_LOG.md`.

## Active Campaign

- campaign_id: `gfm-20260303-r01`
- canonical inference path: `hmaintask_combine.py --mode test --loadpath checkpoints/single-sft/best_checkpoint`

## Next Campaign (Realistic Scale)

- campaign_id: `gfm-20260304-r02`
- run_class: `realistic_scale`
- current gate note: asset acquisition/provenance gate is satisfied; bounded slice controls and autonomous chain workflow are validated, and `TR-B1` can be rerun with step-capped arguments before paired `nsys`.

## Slice Matrix

| campaign_id | scenario | slice_id | profile_stage | objective | entry_script | mode | dataset | loadpath | savepath | smoke_run_id | nsys_run_id | ncu_run_id | status | blocker |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| gfm-20260303-r01 | train | TR-B1 | baseline_validation | Baseline bounded completion train slice (validated). | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `20260302-1636-train-completion-01` | `20260302-1637-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | train | TR-B2 | baseline_validation | Second baseline train validation slice for reproducibility. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `20260303-1726-train-completion-02` | `20260303-1727-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-B1 | baseline_validation | First baseline finetune validation slice. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `20260303-1744-finetune-combine-01` | `20260303-1745-finetune-combine-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-B2 | baseline_validation | Second baseline finetune validation slice for reproducibility. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `20260303-1944-finetune-combine-02` | `20260303-1945-finetune-combine-01` | `-` | done | none |
| gfm-20260303-r01 | inference | IF-B1 | baseline_validation | First baseline inference validation slice (combine test mode). | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `20260303-1953-inference-combine-01` | `20260303-1954-inference-combine-01` | `-` | done | none |
| gfm-20260303-r01 | inference | IF-B2 | baseline_validation | Second baseline inference validation slice for reproducibility. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `20260303-2030-inference-combine-01` | `20260303-2031-inference-combine-01` | `-` | done | none |
| gfm-20260303-r01 | train | TR-SU1 | steady_unannotated | Steady-state unannotated train window pair with stability gate. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `20260303-2049-train-completion-01;20260303-2050-train-completion-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-SU1 | steady_unannotated | Steady-state unannotated finetune window pair with stability gate. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `20260303-2058-finetune-combine-01;20260303-2059-finetune-combine-01` | `-` | done | none |
| gfm-20260303-r01 | inference | IF-SU1 | steady_unannotated | Steady-state unannotated inference window pair with stability gate. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `20260303-2134-inference-combine-01;20260303-2138-inference-combine-01` | `-` | done | none |
| gfm-20260303-r01 | train | TR-SA1 | steady_annotated | Steady-state annotated train capture after minimal NVTX insertion. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `20260304-1541-train-annotated-completion-01` | `-` | done | none |
| gfm-20260303-r01 | finetune | FT-SA1 | steady_annotated | Steady-state annotated finetune capture after minimal NVTX insertion. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `20260304-1622-finetune-annotated-combine-01` | `-` | done | `nsys` capture completed; forced-export `nvtx_sum` verification confirms expected coarse NVTX labels (initial `nvtxsum` empty output treated as false negative) |
| gfm-20260303-r01 | inference | IF-SA1 | steady_annotated | Steady-state annotated inference capture after minimal NVTX insertion. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `20260304-1652-inference-annotated-combine-01` | `-` | done | none |
| gfm-20260303-r01 | campaign | RV-G1 | review_gate | Capture-complete + human-review approval gate. | `-` | `-` | `-` | `-` | `-` | `-` | `-` | `-` | done | review outcome recorded in `gfm-20260303-r01-review-gate-01`; evidence class is `minimal_staged` (`profiling/SCALE_PROFILES.md`), so post-review permissions remain `ncu_allowed=false`, `targeted_fine_allowed=false`, `optimization_discussion_allowed=false` |
| gfm-20260303-r01 | train | TR-N1 | ncu_post_review | One staged train `ncu` tooling-smoke run (optional, non-gating). | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3` | `-` | `checkpoints/single-completion` | `-` | `-` | `-` | not started | optional; if used, record `ncu_intent: tooling_smoke` |
| gfm-20260303-r01 | finetune | FT-N1 | ncu_post_review | One staged finetune `ncu` tooling-smoke run (optional, non-gating). | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3` | `checkpoints/single-completion/best_checkpoint` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | optional; if used, record `ncu_intent: tooling_smoke` |
| gfm-20260303-r01 | inference | IF-N1 | ncu_post_review | One staged inference `ncu` tooling-smoke run (optional, non-gating). | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3` | `checkpoints/single-sft/best_checkpoint` | `-` | `-` | `-` | `-` | not started | optional; if used, record `ncu_intent: tooling_smoke` |
| gfm-20260303-r01 | train | TR-AUTO-SMOKE-01 | baseline_validation | Autonomous toy smoke chain validation (3 slices, model-checkpoint handoff). | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3-hf` | `latest checkpoint-*` | `checkpoints/slice-chain-toy-model` | `20260305-2252-toychain-model-20260305b-s01;20260305-2253-toychain-model-20260305b-s02;20260305-2255-toychain-model-20260305b-s03` | `-` | `-` | done | validated autonomous multi-slice orchestration and checkpoint handoff (`profiling/chains/active/CHAIN_SUMMARY_toychain-model-20260305b.md`). |
| gfm-20260304-r02 | train | TR-B1 | baseline_validation | Realistic-scale baseline train validation slice gated on production-equivalent assets/provenance. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3-hf` | `-` | `checkpoints/single-completion` | `20260305-2131-train-completion-01;20260305-2359-trb1-realistic-20260305a-s01;20260306-0000-trb1-realistic-20260305a-s02;20260306-0002-trb1-realistic-20260305a-s03` | `-` | `-` | in progress | initial 3-slice capped chain completed (`profiling/chains/active/CHAIN_SUMMARY_trb1-realistic-20260305a.md`); run is treated as provisional due disconnect uncertainty and should be rerun end-to-end in detached `tmux` with a new chain_id before marking canonical completion. |
| gfm-20260304-r02 | train | TR-AUTO-STATE-01 | baseline_validation | Full-state autonomous chain validation before realistic unattended campaign. | `hmaintask_completion.py` | `train` | `datasets/single-pretrain-v3-hf` | `state-slice-<k-1>` | `checkpoints/slice-chain-toy-state` | `20260305-2258-toychain-state-20260305-s01;20260305-2300-toychain-state-20260305-s02` | `-` | `-` | done | validated full trainer-state handoff with `state-slice-01 -> state-slice-02` (`profiling/chains/active/CHAIN_SUMMARY_toychain-state-20260305.md`). |
| gfm-20260304-r02 | finetune | FT-B1 | baseline_validation | Realistic-scale baseline finetune validation slice after TR-B1 and production-equivalent checkpoint confirmation. | `hmaintask_combine.py` | `train` | `datasets/single-pretrain-v3-hf` | `checkpoints/single-completion` | `checkpoints/single-sft` | `-` | `-` | `-` | not started | awaiting campaign execution order (`TR-B1` first). |
| gfm-20260304-r02 | inference | IF-B1 | baseline_validation | Realistic-scale baseline inference validation slice after TR-B1/FT-B1 readiness. | `hmaintask_combine.py` | `test` | `datasets/single-pretrain-v3-hf` | `checkpoints/single-sft` | `-` | `-` | `-` | `-` | not started | awaiting campaign execution order (`TR-B1` then `FT-B1`). |

## Update Rule

- Every completed run entry in `profiling/RUNS.md` must map to exactly one matrix row above.
- Update row `status`, run IDs, and blocker text immediately after each run attempt.
- If representativeness fails, use `blocked_non_representative` and record stability metrics.
- If a run exceeds planning budget due to healthy progress, allow completion and log overrun details; do not mark this as failure.
- For autonomous scenario chains, update chain target according to adaptive slice depth policy (`3 -> 5 -> 7 -> +2`) and log extension rationale.
- For resumed chains at slice `8+`, record continuation source path and `next_slice_index` derivation in the chain summary.
- Every completed/stopped chain must include an end-of-scenario aggregate summary block in `profiling/chains/active/CHAIN_SUMMARY_<chain_id>.md`.
- `ncu_post_review` rows are invalid unless `RV-G1` is `done`.
- `ncu_post_review` rows marked `ncu_intent: tooling_smoke` are allowed before `RV-G1` completion when the sole intent is path validation.
- If a required precondition is missing (asset, GPU availability, etc.), mark row `blocked` and mirror blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
