# Profiling Guide

## Purpose
`profiling/` stores lightweight, version-controlled profiling documentation:
- command patterns
- run manifests
- concise result summaries

It does not store raw profiler binaries or large traces.

## What Belongs Here
- `COMMANDS.md`: canonical command templates and validated command variants.
- `PREFLIGHT.md`: environment and tooling readiness checklist before profiling runs.
- `ASSETS_STATUS.md`: current availability state of required datasets/checkpoints.
- `CAMPAIGN_PLAN.md`: scenario/slice matrix with stage gates and per-slice status.
- `RUNS.md`: structured run records (one entry per run attempt).
- `RESULTS.md`: compact findings, comparisons, and conclusions.
- `MANUAL_ANALYSIS.md`: human-focused deep-dive workflow and interpretation checklist.
- `sql/manual_queries.sql`: reusable query library for SQLite deep dives.
- `scripts/profile_baseline.sh`: lightweight wrapper for smoke/`nsys`/`ncu` baseline commands.
- `scripts/analyze_nsys_run.sh`: post-run summary generator for `nsys` traces.
- `scripts/run_slice_chain.sh`: autonomous multi-slice runner with checkpoint/state handoff and per-chain markdown summaries.

## What Does Not Belong Here
- Raw `nsys` / `ncu` output files.
- Large logs and binary artifacts.
- Temporary scratch notes that are not reusable.

Raw profiling outputs belong under `artifacts/profiles/` and remain out of Git.

## Handoff vs Profiling Docs
- `handoff/` files track project state and the single immediate next task.
- `profiling/` files track profiling operations and findings over time.
- Keep these responsibilities separate: execution continuity in `handoff/`, profiling evidence in `profiling/`.

## High-Level Workflow
1. Run `make profiling-preflight`.
2. Select the next pending campaign row (`campaign_id + slice_id + profile_stage`) in `CAMPAIGN_PLAN.md`.
3. Run bounded smoke + profiler commands for that row and write raw outputs to `artifacts/profiles/...`.
4. Record run metadata in `RUNS.md` (including `campaign_id`, `scenario`, `slice_id`, `profile_stage`).
5. Update row status and run IDs in `CAMPAIGN_PLAN.md`.
6. Generate analysis bundle for each successful `nsys` run (`scripts/analyze_nsys_run.sh --run-id <run_id>`).
7. Summarize findings in `RESULTS.md`:
   - baseline unannotated summaries first (`nsys`)
   - then coarse NVTX-annotated summaries (`nsys`)
   - then targeted hotspot deep dives (`ncu`)
8. Do not run `ncu` until baseline + annotation gates are met for the scenario.
9. Update `handoff/` files before ending the session.

For autonomous chained slices:
- Use `scripts/run_slice_chain.sh` with explicit `--max-train-steps`/`--max-eval-steps`.
- `resume-mode=model` validates model-checkpoint handoff workflow.
- `resume-mode=state` validates full trainer-state handoff workflow via `state-slice-<k>` directories.

## Config Conventions For Profiling
- Default training config remains `hconfig.yaml` (repo baseline).
- Profiling baseline slices should prefer `hconfig_profiling_single_gpu.yaml` to reduce multi-process noise and improve reproducibility for first-pass traces.
- Workflow order is strict: baseline `nsys` -> minimal NVTX annotation -> annotated `nsys` validation -> hotspot shortlist -> targeted `ncu`.

## Trace and Analysis Artifact Roles

- `*.nsys-rep` is the canonical source trace artifact for profiling analysis.
- `artifacts/profiles/analysis/<run_id>/` is the standard per-run analysis bundle for routine review.
- `summary.md` and `metrics.json` are the default first-pass review inputs.
- For deeper manual inspection, use:
  - `profiling/MANUAL_ANALYSIS.md`
  - `profiling/sql/manual_queries.sql`

Historical migration policy:
- Backfill analysis bundles for gate-critical historical runs only.
- For new successful `nsys` runs, analysis bundle generation is mandatory.

## Phase 6a Coarse NVTX Taxonomy (Spec Only)
This Phase 6a output defines the minimal NVTX label set for Phase 6b insertion. It is intentionally coarse, reversible, and limited to high-level workload boundaries.

### Label Names And Boundary Definitions
| Label | Start Boundary | End Boundary | Intent |
|---|---|---|---|
| `gfm.setup` | Enter `main(args)` after tracker setup | Immediately before mode branch (`if args.mode == "test"`) | One range for model/data/optimizer construction and accelerator preparation. |
| `gfm.mode_test_only` | Enter mode-test branch | Right before `accelerator.end_training()` return in test mode | Coarse coverage for inference-only path when `--mode test`. |
| `gfm.train_epoch` | Start of each epoch loop iteration | End of epoch body after eval/checkpoint handling | Epoch-level timeline anchor for train mode. |
| `gfm.train_step` | Start of each train loader iteration | After optimizer step and optional train-loss logging | Coarse per-batch train loop envelope. This range covers the in-loop batch compute body after batch yield; it does not attempt to measure upstream loader wait time unless a later approved refinement adds a separate input-pipeline range. |
| `gfm.eval_task` | Immediately before each `eval_task(...)` call site | Immediately after the call returns | Per-task evaluation envelope reused for valid/test calls. |
| `gfm.checkpoint_io` | Immediately before save/load checkpoint operations | Immediately after each save/load operation | Isolate checkpoint serialization overhead from compute ranges. |
| `gfm.final_test_pass` | Immediately before final post-train test loop | After final test summary print and before `accelerator.end_training()` | Distinguish terminal test sweep from in-epoch evaluation. |

### Range Nesting And Overlap Policy
- Nested NVTX ranges are expected and intentional.
- Parent ranges provide coarse ownership; child ranges isolate major sub-phases.
- Overlap between parent and child ranges must not be treated as double-counting in analysis.
- Examples of intentional nesting include:
  - `gfm.train_epoch` containing `gfm.train_step`
  - `gfm.train_epoch` containing `gfm.eval_task`
  - `gfm.train_epoch` containing `gfm.checkpoint_io`
  - `gfm.final_test_pass` containing `gfm.eval_task`
  - `gfm.mode_test_only` containing `gfm.eval_task`

### Script-Level Insertion Map
Line references below are reconnaissance aids only and may drift as the fork evolves. The semantic block/function boundaries are the real insertion contract.

#### `hmaintask_completion.py`
- `gfm.setup`: `main(args)` setup block around model/dataset construction and `accelerator.prepare(...)` (`hmaintask_completion.py:104-170`).
- `gfm.mode_test_only`: test-mode branch (`hmaintask_completion.py:171-188`).
- `gfm.train_epoch`: epoch loop body (`for epoch in range(args.maxepoch)`) (`hmaintask_completion.py:192-273`).
- `gfm.train_step`: inner train loader loop body (`for data in loader`) (`hmaintask_completion.py:207-220`).
- `gfm.eval_task`: evaluation call sites at validation/test checkpoints and final test sweep (`hmaintask_completion.py:230`, `hmaintask_completion.py:259`, `hmaintask_completion.py:289`).
- `gfm.checkpoint_io`: checkpoint save/load boundaries (`hmaintask_completion.py:223`, `hmaintask_completion.py:280`, `hmaintask_completion.py:285`).
- `gfm.final_test_pass`: post-training final test loop (`hmaintask_completion.py:286-306`).

#### `hmaintask_combine.py`
- `gfm.setup`: `main(args)` setup block around model/dataset construction and `accelerator.prepare(...)` (`hmaintask_combine.py:105-166`).
- `gfm.mode_test_only`: test-mode branch (`hmaintask_combine.py:168-185`).
- `gfm.train_epoch`: epoch loop body (`for epoch in range(args.maxepoch)`) (`hmaintask_combine.py:189-264`).
- `gfm.train_step`: inner train loader loop body (`for data in loader`) (`hmaintask_combine.py:204-212`).
- `gfm.eval_task`: evaluation call sites at validation/test checkpoints and final test sweep (`hmaintask_combine.py:223`, `hmaintask_combine.py:247`, `hmaintask_combine.py:280`).
- `gfm.checkpoint_io`: checkpoint save/load boundaries (`hmaintask_combine.py:216`, `hmaintask_combine.py:271`, `hmaintask_combine.py:276`).
- `gfm.final_test_pass`: post-training final test loop (`hmaintask_combine.py:277-297`).

### Distributed / Rank Emission Policy
- Emit the same coarse NVTX labels on all active training processes unless a later profiling campaign explicitly scopes capture to a single rank.
- Do not create rank-specific label names; rank identity belongs in run metadata, not label taxonomy.
- Any rank filtering or single-rank capture decisions must be documented in run metadata, not encoded in the label names themselves.

### Non-Goals (Explicit)
- No per-kernel, per-op, or per-layer NVTX tagging.
- No detailed data-loader internals tagging beyond coarse loop envelopes.
- No modifications to model semantics, optimizer behavior, or task logic.
- No optimization recommendations before Phase 8 review gate completion.

### Reversibility And Policy Alignment
- Phase 6b should implement these ranges via minimal wrappers around existing blocks and call sites only.
- The label set is intentionally small and shared across both scripts to keep removal straightforward.
- This spec is documentation-only for Phase 6a; no NVTX code insertion is performed in this phase.

## NVTX Granularity Escalation Policy (Two-Tier)
This policy preserves coarse-label comparability while allowing targeted refinement later in the workflow.

### Tier Definitions
- Tier 1 (`coarse`): default and required baseline for annotated captures; uses only immutable coarse root labels from Phase 6a.
- Tier 2 (`targeted_fine`): optional, hotspot-scoped child labels under a coarse root for deeper post-review inspection.

### Hard Gate For `targeted_fine`
- `targeted_fine` is prohibited until campaign review gate row `RV-G1` is `done`.
- Human review must include an approved hotspot shortlist/focus list before any `targeted_fine` relabel pass.
- No new `profile_stage` is introduced for this; use existing `steady_annotated` stage with tier metadata.

### Immutable Coarse Root Contract
The following root labels are stable and must not be renamed:
- `gfm.setup`
- `gfm.mode_test_only`
- `gfm.train_epoch`
- `gfm.train_step`
- `gfm.eval_task`
- `gfm.checkpoint_io`
- `gfm.final_test_pass`

### Child Label Naming Contract
- `targeted_fine` labels must be children of one coarse root and use dotted suffixes.
- Format: `<coarse_root>.<child_scope>`.
- Valid examples:
  - `gfm.train_step.forward`
  - `gfm.train_step.backward`
  - `gfm.train_step.optimizer`
  - `gfm.eval_task.metric_gather`
- Invalid pattern: introducing unrelated roots that do not map to a Phase 6a coarse root.

### Scope Rules
- Refine only review-approved hotspot parent ranges; do not relabel the full script broadly.
- Keep targeted-fine insertions minimal and reversible, same as coarse policy.
- Do not introduce per-kernel or per-op label explosion unless separately approved as a post-review exception.

### Metadata Contract For Annotated Runs/Results
When `profile_stage=steady_annotated`, record:
- `label_tier: coarse|targeted_fine`
- `label_schema_version` (for example `nvtx-v1.0`)
- `hotspot_focus_id` (`na` for coarse; required ID for targeted-fine)
- `parent_label_anchor` (`na` for coarse; required coarse root for targeted-fine)

### Comparability Rule
- Do not treat `coarse` and `targeted_fine` traces as directly comparable for time-share conclusions unless explicitly normalized and caveated in analysis notes.

### Schema Change Rule
- Any change to coarse root labels, boundary semantics, or child-label naming rules requires a deliberate schema-version update and corresponding documentation update before use.
- Use `nvtx-v<major>.<minor>` format for `label_schema_version`.
- Major bump requirements:
  - coarse root label changes
  - boundary semantic changes
  - child-label naming contract changes
- Minor bump requirements:
  - additive targeted-fine child labels under existing roots with unchanged parent semantics
- No silent taxonomy drift is permitted.

### Example Progression
- `steady_annotated` coarse pass
- `RV-G1` review with approved hotspot shortlist
- optional `steady_annotated` targeted-fine relabel under approved anchor(s), such as `gfm.train_step.*`
- follow-on targeted analysis and/or `ncu_post_review`
