# Research Campaign — Current Status

Last updated: 2026-06-03 (EXP00 housekeeping pass)

---

## Current Phase

**EXP00 complete. Housekeeping complete. EXP01A — Source Localization pending.**

EXP00 documentation setup is done. A housekeeping pass was completed on 2026-06-03 to clean up `docs/agent_trace.md`, create `VERIFICATION_LEDGER.md`, and clarify the EXP01A/EXP01B distinction before the next session begins EXP01A.

---

## What Has Already Happened

| Date | Event |
|---|---|
| 2026-03-03 to 2026-03-04 | Baseline validation and steady-state (unannotated + annotated) captures completed for train, finetune, and inference at staged scale. All NVTX labels confirmed present. |
| 2026-03-04 | Capture gate `gfm-20260303-r01-capture-gate-01` closed (all 3 scenarios complete). |
| 2026-03-05 | Review gate `gfm-20260303-r01-review-gate-01`: ncu NOT allowed at staged scale; realistic-scale campaign started. |
| 2026-03-06, 2026-03-12 | Realistic-scale chains (TR-B1, FT-B1, IF-B1) completed: 9/9 slices, NVTX present, cross-scenario hotspot identity confirmed. |
| 2026-03-18 | Cross-scenario review gate `gfm-20260304-r02-realistic-review-gate-01` PASS. NCU deep dives approved. Three-kernel hotspot shortlist approved: sgemm_32x32 (hotspot_1), fmha (hotspot_2), sgemm_32x128 (hotspot_3). |
| 2026-03-19 to 2026-03-24 | TR-N1 NCU capture and analysis completed for hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`). All 8 core sections imported into SQLite. Key metrics: `full_waves=0.617`, `eligible_warps_per_cycle=0.387`. |
| 2026-06-03 | Root `README.md` revised to describe profiling fork; 16/16 validation claims confirmed. `nsys_cross_scenario_dashboard.ipynb` created (32 cells, loads 9 analysis bundles). |
| 2026-06-03 | This EXP00 documentation campaign started. |

NCU deep dives for hotspot_2 (fmha) and hotspot_3 (sgemm_32x128) have been approved but not yet executed.

---

## Current Best Hypothesis

Griffin's relational database structure appears to fragment dense computation into many small GPU launches. These launches individually underfill the GPU (Waves/SM ≈ 0.617 for hotspot_1). Schema-aware packing, batching, or tensorization may combine equivalent relational dense operations into fewer, larger, more hardware-efficient launches while preserving Griffin's semantics.

See `HYPOTHESIS.md` for precise framing and falsification criteria.

---

## Key Evidence

| Metric | Value | Source |
|---|---|---|
| hotspot_1 GPU time share | ~30–32% | `profiling/RESULTS.md` — realistic cross-scenario review |
| hotspot_1 launch count (train/finetune) | ~22,731–22,754 per slice | `profiling/RESULTS.md` |
| hotspot_1 launch count (inference) | ~7,477 per slice | `profiling/RESULTS.md` |
| hotspot_1 Waves/SM (`full_waves`) | 0.617 | `profiling/RESULTS.md` — TR-N1 NCU |
| hotspot_1 eligible_warps_per_cycle | 0.387 | `profiling/RESULTS.md` — TR-N1 NCU |
| hotspot_2 (fmha) GPU time share | ~12.5–13% | `profiling/RESULTS.md` — realistic cross-scenario review |
| hotspot_3 (sgemm_32x128) GPU time share | ~9.3–9.8% | `profiling/RESULTS.md` — realistic cross-scenario review |
| Cross-scenario hotspot rank stability | top-3 overlap = 3/3, drift ≤ 1.72% | `profiling/RESULTS.md` |

For ~6.1 µs per call (Ledger: C-08) and ~17.6k average launch count per slice (Ledger: C-07): both are `Prior-discussion reported` — consistent with the above values but not yet confirmed from any file in this checkout. See `VERIFICATION_LEDGER.md` for required follow-up.

---

## Current Blockers / Unknowns

- NCU deep dives for hotspot_2 (fmha) and hotspot_3 (sgemm_32x128) not yet run.
- Source locations producing the small-GEMM launches not yet identified (EXP01).
- Actual matrix shapes of the fragmented launches not yet measured (EXP02).
- No controlled microbenchmark yet compares fragmented vs packed GEMM at these shapes (EXP03).
- Tensor Core utilization status: current NCU evidence shows low wave occupancy but does not directly confirm or deny TC utilization.

---

## Next Recommended Action

Start **EXP01A — Source Localization from Existing Artifacts and Read-Only Code Inspection.**

Brief: `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`
Protocol: `docs/research_plan/EXPERIMENT_PROTOCOLS.md` — EXP01A section

EXP01A is read-only. It may inspect existing artifacts, notebooks, Markdown summaries, and Griffin source code. It may write documentation reports only. It may not modify source files, add NVTX instrumentation, or run profiling jobs.

**EXP01B** (targeted instrumentation follow-up) is only allowed if EXP01A is inconclusive, and requires explicit user approval before any source changes are made.

---

## Claim-Level Provenance

Quantitative claims are tracked in `docs/research_plan/VERIFICATION_LEDGER.md`.

Key caveats flagged in the ledger:
- Average per-call duration (~6.1 µs) — `Prior-discussion reported`; not yet confirmed from a file in this checkout (Ledger: C-08).
- Cross-scenario average launch count (~17.6k) — `Prior-discussion reported`; not yet confirmed from a file in this checkout (Ledger: C-07).
- Tensor Core utilization status — `Not yet measured` (Ledger: C-15).
- Source code locations for hotspot_1 — `Not yet measured` (Ledger: C-16).
- Matrix shapes for hotspot_1 — `Not yet measured` (Ledger: C-17).

---

## Do Not Do Yet

- Do not add NVTX instrumentation (EXP01A is read-only; EXP01B requires explicit approval).
- Do not modify Griffin model code (`hmodel.py`, `hmaintask_*.py`, `hloaderwrapper.py`, etc.).
- Do not run expensive profiling jobs (NCU TR-N2 or TR-N3, new nsys chains).
- Do not implement packing, batching, or optimization code.
- Do not run EXP02, EXP03, EXP04, or EXP05 before EXP01A is complete and its decision gate passed.

---

## Recently Created or Modified Files

| File | Change | Date |
|---|---|---|
| `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Created (32 cells, loads 9 analysis bundles) | 2026-06-03 |
| `README.md` | Revised to describe profiling fork; links and tables added | 2026-06-03 |
| `docs/research_plan/` (all files) | Created in EXP00 | 2026-06-03 |
