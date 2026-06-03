# EXP04 — Local Griffin Prototype

**Status:** Not started

---

## Purpose

Implement a minimal schema-aware packing or batching change in a local copy of Griffin's model code at the call sites identified in EXP01. Verify that training/inference runs to completion, produces matching metrics, and reduces the hotspot_1 launch count in profiling.

---

## Prerequisite Docs / Artifacts

| Required | Where |
|---|---|
| `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` | Must be complete: identified call sites |
| `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md` | Must be complete: shape distribution |
| `docs/research_plan/experiments/EXP03_PACKING_MICROBENCHMARK.md` | Must be complete with positive gate |
| `docs/research_plan/DECISION_LOG.md` | Must contain explicit EXP04 authorization entry |
| `profiling/COMMANDS.md` | Profiling workflow for before/after comparison |
| Baseline analysis bundle: `artifacts/profiles/analysis/20260312-1537-trb1-realistic-20260312a-s03/` | Baseline for comparison |

---

## Allowed Changes

- Modify Griffin model source files **only at the call sites identified in EXP01 and validated by EXP02/EXP03**.
- Add a new script `scripts/exp04_smoke_test.py` if needed for isolated correctness testing.
- Run a bounded smoke slice and a bounded nsys slice on GPU3.
- Update `profiling/RUNS.md` and `profiling/RESULTS.md` with new run IDs and findings.
- Update this file, `SESSION_LOG.md`, `STATUS.md`, `DECISION_LOG.md`.

## Disallowed Changes

- Do not change loss functions, attention mechanisms, optimizer logic, or dataset pipeline.
- Do not modify training entry points beyond the specific packing implementation at identified call sites.
- Do not run production-scale training (use `slice_size_tier=8/4` bounds).
- Do not force-push or overwrite existing baseline artifacts.

---

## Exact Deliverables

1. Modified Griffin code at identified call sites (committed to git).
2. Smoke run confirmation: completes to end, metrics match baseline within expected variance.
3. Bounded nsys analysis bundle for the prototype run.
4. Before/after comparison table: launch count and GPU time share for hotspot_1.
5. Updated `EXP04_GRIFFIN_PROTOTYPE.md` with findings.
6. `profiling/RUNS.md` and `profiling/RESULTS.md` entries.
7. `DECISION_LOG.md` entry and `STATUS.md` update.

---

## Correctness Test

Before profiling, run the following check:
- Fixed random seed (e.g., `torch.manual_seed(42)`).
- One forward + backward pass on a minimal input.
- Assert: `max(abs(output_original - output_prototype)) < 1e-5`.

If this fails, do not proceed to profiling. Identify the semantic change and fix it.

---

## Success Criteria

- Modified Griffin runs to completion with matching metrics.
- Launch count for hotspot_1 decreases in the prototype nsys bundle vs the baseline bundle.
- GPU time share for hotspot_1 decreases or wall-time improves.
- Numerical correctness test passes.

---

## Decision Gate

- **Metrics match + profiling improves** → proceed to EXP05.
- **Metrics match + profiling unchanged** → investigate why packing is not reducing launch count; check whether the identified call site is actually the source of hotspot_1; reassess before EXP05.
- **Metrics diverge** → identify the semantic change; fix and retest; do not proceed to EXP05 until correctness is confirmed.

---

## Required Handoff Update

After completing:
1. Fill in Findings below.
2. Add entry to `SESSION_LOG.md`.
3. Add entry to `DECISION_LOG.md`.
4. Update `STATUS.md`.
5. Confirm git commit hash.

---

## Findings

*(Fill in after experiment is run)*

### Modified Call Sites

| File | Line Range | Change Description |
|---|---|---|
| | | |

### Correctness Test Result

### Before/After Comparison

| Metric | Baseline | Prototype | Change |
|---|---|---|---|
| hotspot_1 launch count / slice | | | |
| hotspot_1 GPU time share | | | |
| Wall-time per slice (sec) | | | |
| Validation metric | | | |

### Decision Gate Outcome
