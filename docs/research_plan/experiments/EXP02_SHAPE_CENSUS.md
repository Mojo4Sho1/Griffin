# EXP02 — Shape Census

**Status:** Not started

---

## Purpose

Measure the actual matrix dimensions (M, N, K) produced at the call sites identified in EXP01 during a representative Griffin forward pass. Determine whether the shapes are consistent with the small-tile GEMM kernels seen in profiling.

---

## Prerequisite Docs / Artifacts

| Required | Where |
|---|---|
| `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` | Must be complete with identified call sites |
| `docs/research_plan/HYPOTHESIS.md` | Review shape-fragmentation framing |
| `profiling/SCALE_PROFILES.md` | Guidance on run scale for the forward pass |
| Griffin source: `hmodel.py`, identified call sites from EXP01 | |

---

## Allowed Changes

- Write `scripts/exp02_shape_census.py` (new file).
- Run the script with a short forward pass.
- Write output CSV to `artifacts/exp02_shape_census.csv`.
- Update this file and `SESSION_LOG.md`.
- Updating `STATUS.md` and `DECISION_LOG.md`.

## Disallowed Changes

- Do not modify core model logic or training entry points.
- Do not run full training campaigns or nsys/ncu profiling runs.
- Do not add permanent instrumentation to `hmodel.py`.

---

## Exact Deliverables

1. `scripts/exp02_shape_census.py` — shape-logging script using `argparse` for dataset/checkpoint paths.
2. `artifacts/exp02_shape_census.csv` — recorded (M, N, K, site, count) per launch.
3. Analysis of shape distribution: are shapes small? Variable? Consistent with 32×32 tile?
4. Updated `EXP02_SHAPE_CENSUS.md` with findings.
5. `DECISION_LOG.md` entry and `STATUS.md` update.

---

## Success Criteria

- Script runs to completion and produces a readable CSV.
- Observed shapes are consistent with small-tile GEMM (M, N, or K < 128 for at least the majority of launches).
- Shape distribution shows diversity (many distinct shapes), not uniformity.

---

## Decision Gate

- **Shapes are small and diverse** → hypothesis supported; proceed to EXP03.
- **Shapes are large and uniform** → fragmentation hypothesis weakened; reassess before EXP03.
- **Shapes are large but few** → packing may already be happening; document and reassess.

---

## Required Handoff Update

After completing:
1. Fill in Findings below.
2. Add entry to `SESSION_LOG.md`.
3. Add entry to `DECISION_LOG.md`.
4. Update `STATUS.md`.

---

## Findings

*(Fill in after experiment is run)*

### Shape Distribution Summary

| Call Site (file:line) | Min (M,N,K) | Max (M,N,K) | Distinct Shapes | Total Launches |
|---|---|---|---|---|
| | | | | |

### Assessment

*(Are shapes consistent with small-tile GEMM? Is there evidence of fragmentation?)*

### Decision Gate Outcome
