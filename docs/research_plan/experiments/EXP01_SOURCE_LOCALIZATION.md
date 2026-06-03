# EXP01 — Source Localization

**Status:** Not started

---

## Purpose

Identify which specific Griffin source code locations produce the dominant small-GEMM launches (`ampere_sgemm_32x32_sliced1x4_tn`) and the flash-attention launches (`fmha_cutlassF_f32_aligned_64x64_rf_sm80`) observed in profiling. This is a prerequisite for EXP02.

---

## Prerequisite Docs / Artifacts

| Required | Where |
|---|---|
| `docs/research_plan/HYPOTHESIS.md` | Read before starting |
| `docs/research_plan/EVIDENCE_SUMMARY.md` | Review evidence before reading code |
| `profiling/RESULTS.md` — `gfm-20260304-r02-realistic-cross-scenario-review-01` | Cross-scenario hotspot identities and launch counts |
| `profiling/RESULTS.md` — `gfm-20260304-r02-train-ncu-hotspot-01` | NCU analysis of hotspot_1 |
| `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | NVTX structure showing which model phases contain the hotspots |

---

## Allowed Changes

- Read-only inspection of Griffin source files.
- `grep`, `find`, `cat` for code search.
- Writing findings to this file and `SESSION_LOG.md`.
- Writing a `DECISION_LOG.md` entry.
- Updating `STATUS.md`.

## Disallowed Changes

- Do not modify any Griffin source files (`hmodel.py`, `hmaintask_*.py`, `hloaderwrapper.py`, etc.).
- Do not add print statements, logging, or NVTX instrumentation.
- Do not run profiling jobs or training runs.
- Do not implement any optimization code.

---

## Exact Deliverables

1. List of candidate call sites for hotspot_1 (small-GEMM), with:
   - File path and approximate line number
   - Which NVTX label context it falls under
   - Which relational structure (table iteration, feature aggregation, attention) it represents
   - Why you believe it is responsible for the high launch count

2. List of candidate call sites for hotspot_2 (fmha), with same fields.

3. An assessment: is the fragmentation likely driven by explicit loops over schema elements, or by something else?

4. Updated `EXP01_SOURCE_LOCALIZATION.md` (this file) with findings filled in below.

5. `DECISION_LOG.md` entry and `STATUS.md` update.

---

## Success Criteria

- At least one plausible source location identified for each of hotspot_1 and hotspot_2.
- The identified locations are consistent with the NVTX label boundaries seen in profiling.
- The assessment is grounded in code reading, not speculation.

---

## Decision Gate

- **Clear source locations found for hotspot_1** → proceed to EXP02.
- **Source location ambiguous** → add targeted fine NVTX instrumentation per `EXPERIMENT_PROTOCOLS.md` and re-profile before EXP02.
- **Griffin operations are already batched / non-fragmentable** → document finding; update hypothesis; discuss with user before EXP02.

---

## Required Handoff Update

After completing this experiment:
1. Fill in the Findings section below.
2. Add entry to `SESSION_LOG.md` using `HANDOFF_TEMPLATE.md`.
3. Add entry to `DECISION_LOG.md`.
4. Update `STATUS.md` (phase, next action, blockers).

---

## Findings

*(Fill in after experiment is run)*

### hotspot_1 Candidate Call Sites

| File | Line Range | NVTX Context | Relational Structure | Reasoning |
|---|---|---|---|---|
| | | | | |

### hotspot_2 Candidate Call Sites

| File | Line Range | NVTX Context | Relational Structure | Reasoning |
|---|---|---|---|---|
| | | | | |

### Fragmentation Assessment

*(Is the fragmentation driven by explicit loops over schema elements? Or something else?)*

### Decision Gate Outcome

*(Which gate was triggered? What is the next step?)*
