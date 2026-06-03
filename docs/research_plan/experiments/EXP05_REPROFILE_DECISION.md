# EXP05 — Re-Profile and Research Decision

**Status:** Not started

---

## Purpose

Run the full realistic-scale profiling pipeline on the EXP04 prototype and produce a structured before/after comparison. Make a final research decision: extend, publish, or abandon the optimization direction.

---

## Prerequisite Docs / Artifacts

| Required | Where |
|---|---|
| `docs/research_plan/experiments/EXP04_GRIFFIN_PROTOTYPE.md` | Must be complete with positive gate |
| `profiling/COMMANDS.md` | Realistic-scale chain workflow |
| `profiling/SCALE_PROFILES.md` | Run-scale definitions |
| Baseline analysis bundles from `gfm-20260304-r02` | `artifacts/profiles/analysis/` |

---

## Allowed Changes

- Run realistic-scale nsys chains on GPU3 for the prototype branch.
- Generate analysis bundles with `scripts/analyze_nsys_run.sh`.
- Add run entries to `profiling/RUNS.md`.
- Add result entries to `profiling/RESULTS.md`.
- Update this file, `SESSION_LOG.md`, `STATUS.md`, `DECISION_LOG.md`.

## Disallowed Changes

- Do not overwrite or delete existing baseline artifacts.
- Do not run NCU on the prototype until nsys comparison shows a clear signal worth investigating.

---

## Exact Deliverables

1. New profiling run IDs in `profiling/RUNS.md` (prototype train chain at minimum).
2. New result entries in `profiling/RESULTS.md` with before/after comparison.
3. Quantitative before/after table: launch count, GPU time share, wall-time, metric values.
4. Final research decision in `DECISION_LOG.md`.
5. Updated `EXP05_REPROFILE_DECISION.md` with findings.

---

## Success Criteria

The experiment is successful if a clear, quantified, reproducible before/after comparison is produced. Both positive and negative results are valid outcomes.

- **Positive result:** hotspot_1 launch count reduced by ≥50%, GPU time share reduced, wall-time improved or unchanged, metrics match.
- **Null result:** launch count unchanged despite EXP04 showing correctness — document and redirect.
- **Negative result:** metrics diverge in realistic-scale run — identify cause.

---

## Decision Gate

- **Improvement clear and reproducible** → write up findings for publication or further development.
- **Improvement marginal** → document tradeoffs; decide whether to continue.
- **Negative / null result** → document falsified hypothesis; redirect research.

---

## Required Handoff Update

After completing:
1. Fill in Findings below.
2. Add entry to `SESSION_LOG.md`.
3. Add **final** entry to `DECISION_LOG.md` with research decision.
4. Update `STATUS.md` to reflect campaign outcome.

---

## Findings

*(Fill in after experiment is run)*

### Before/After Comparison (Realistic Scale)

| Metric | Baseline (gfm-20260304-r02) | Prototype | Change |
|---|---|---|---|
| hotspot_1 launch count / slice | ~22,731 (train) | | |
| hotspot_1 GPU time share | ~30–32% | | |
| hotspot_2 GPU time share | ~12.5–13% | | |
| Wall-time per slice (sec) | | | |
| Validation metric | | | |

### Reproducibility

*(Is the improvement consistent across multiple slices?)*

### Research Decision

*(Publish? Extend? Redirect?)*
