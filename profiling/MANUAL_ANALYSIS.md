# Manual Profiling Analysis Playbook

This guide is for humans who want to inspect profiling results beyond high-level summaries.

## Purpose

Use this playbook to move from quick triage to detailed validation when interpreting `nsys` captures.

## When To Use Manual Analysis

Use manual deep-dive when any of the following is true:
- A run has unexpected metric drift or behavior changes.
- Top kernels or NVTX labels differ from expectation.
- You need to validate an agent-produced interpretation before a gate decision.
- You need extra confidence before writing review conclusions in `profiling/RESULTS.md`.

## Analysis Inputs

Primary inputs:
- `artifacts/profiles/nsys/<run_id>.nsys-rep`
- `artifacts/profiles/analysis/<run_id>/summary.md`
- `artifacts/profiles/analysis/<run_id>/metrics.json`

Optional deep-dive input:
- `artifacts/profiles/nsys/<run_id>.sqlite`

## Three-Layer Workflow

### Layer 1: Quick Triage

1. Open `artifacts/profiles/analysis/<run_id>/summary.md`.
2. Confirm top contributors for:
   - NVTX ranges
   - GPU kernels
   - CUDA runtime APIs
3. Check `nvtx_coverage_status` in `metrics.json`.

Use this layer for fast directional understanding and to choose what needs deeper inspection.

### Layer 2: Timeline Inspection (`nsys-ui`)

1. Open the trace:

```bash
nsys-ui artifacts/profiles/nsys/<run_id>.nsys-rep
```

2. Inspect:
- Overall timeline spans and idle gaps
- CUDA stream utilization patterns
- Alignment between NVTX ranges and kernel activity
- Large CPU runtime/API regions that may indicate launch/sync overhead

Use this layer to build hypotheses about bottlenecks and phase boundaries.

### Layer 3: SQL Deep-Dive

Use the query library:
- `profiling/sql/manual_queries.sql`

Example execution:

```bash
sqlite3 -header -column artifacts/profiles/nsys/<run_id>.sqlite \
  < profiling/sql/manual_queries.sql
```

Or run targeted query blocks one-by-one in `sqlite3`.

Use this layer to validate hypotheses with exact counts/times.

## Interpretation Checklist

Before finalizing conclusions, verify:
- Kernel dominance: which kernels consume the largest total GPU time?
- NVTX alignment: do expensive kernels align with expected labeled phases?
- Runtime overhead: are CUDA runtime APIs unusually expensive (launch/sync/mem ops)?
- Stability context: is this behavior consistent with paired or prior runs?

## Confidence and Caveats Rubric

- `high`: repeated behavior across comparable runs, no contradictory evidence.
- `medium`: coherent evidence from one run with minor unknowns.
- `low`: conflicting signals, incomplete data, or unresolved parsing/coverage issues.

Always record caveats (dataset scale, synthetic assets, partial visibility, etc.) in `profiling/RESULTS.md`.

## Manual + Agent Collaboration Rule

- Agents generate standard analysis bundles after successful `nsys` runs.
- Humans review bundles and perform deeper checks when needed.
- Interpretive conclusions should be human-reviewed before gate decisions are finalized.

## Backfill Policy

Current policy for the new analysis bundle system:
- Backfill gate-critical historical runs only.
- For all new successful `nsys` runs, analysis bundle generation is mandatory.

Backfill set for this campaign:
- Baseline validation (latest per scenario):
  - `20260303-1727-train-completion-01`
  - `20260303-1945-finetune-combine-01`
  - `20260303-2031-inference-combine-01`
- Steady unannotated:
  - `20260303-2049-train-completion-01`
  - `20260303-2050-train-completion-01`
  - `20260303-2058-finetune-combine-01`
  - `20260303-2059-finetune-combine-01`
  - `20260303-2134-inference-combine-01`
  - `20260303-2138-inference-combine-01`
- Steady annotated:
  - `20260304-1541-train-annotated-completion-01`
  - `20260304-1622-finetune-annotated-combine-01`
  - `20260304-1652-inference-annotated-combine-01`
