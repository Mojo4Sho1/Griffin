# Research Campaign — Current Status

Last updated: 2026-06-03 (EXP01B targeted NVTX confirmation complete)

---

## Current Phase

**EXP01A + EXP01B complete. Decision gate passed. Proceed to EXP02 shape census.**

EXP01A read-only source localization completed on 2026-06-03. EXP01B fine-grained NVTX confirmation also completed on 2026-06-03 (user-authorized). Both hotspots confirmed inside `gfm.eval_task` → `GriffinMod.forward()` → per-node-type aggregation loop via direct NVTX evidence. EXP02 shape census is the authorized next step.

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
| 2026-06-03 | EXP00 documentation campaign and housekeeping pass completed. |
| 2026-06-03 | **EXP01A complete.** Both hotspots localized to `gfm.eval_task` → `GriffinMod.forward()` → per-node-type loop (`hmodel.py:343–369`). Decision gate PASS. EXP02 authorized. |
| 2026-06-03 | **EXP01B complete** (user-authorized). Fine-grained NVTX instrumentation added to `hmodel.py`. Run ID: `exp01b-nvtx-confirm-20260603-2100`. hotspot_2 (fmha) 100% inside crossattention ranges. hotspot_1 55.1% inside aggregator ranges. RMPNN.rellin: cannot assess at hop=0. Decision gate PASS. Proceed to EXP02. |

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
- **Source locations identified (EXP01A complete):** `hmodel.py:343–369` per-node-type loop in `GriffinMod.forward()`.
- Actual GEMM shapes at realistic scale (hop=2, batchsize=512) not yet measured (EXP02 next).
- Number of node types T per forward pass at realistic scale: estimated ~1 from fmha ratio, but uncertain.
- #edge_types in RMPNN.rellin not measured (EXP02 secondary target).
- No controlled microbenchmark yet compares fragmented vs packed GEMM at these shapes (EXP03).
- Tensor Core utilization status: current NCU evidence shows low wave occupancy but does not directly confirm or deny TC utilization. NCU was run with hop=0, not realistic config.

---

## Next Recommended Action

**EXP02 — Shape Census** at the identified EXP01A source sites.

Key finding: both hotspots come from `GriffinMod.forward()` → per-node-type loop at `hmodel.py:343–369`.

EXP02 should measure:
1. `len(node)` — number of node types (T) per forward pass at realistic scale
2. `feat.shape = [#nodes_j, #feat_j, 512]` per node type per iteration — determines GEMM M-dimension
3. `edge_attr.shape` before `RMPNN.rellin` at `hmodel.py:168` — determines whether edge projection contributes sgemm_32x32

Brief: `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md`
Protocol: `docs/research_plan/EXPERIMENT_PROTOCOLS.md` — EXP02 section

**Do not run EXP01B.** It is not needed.

EXP02 requires writing a shape-logging script (scripts/exp02_shape_census.py) and running a single forward pass. Check GPU availability before running.

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

- Do not modify Griffin model source code beyond the EXP01B NVTX instrumentation already in `hmodel.py`.
- Do not run expensive profiling jobs (NCU TR-N2 or TR-N3, new nsys chains) until EXP02 is complete.
- Do not implement packing, batching, or optimization code.
- Do not run EXP03, EXP04, or EXP05 before EXP02 is complete and its decision gate passed.
- Do not remove EXP01B NVTX instrumentation from `hmodel.py` until EXP02 is complete (disable by not setting `GFM_EXP01B_NVTX=1`; the env var gate makes it a no-op).

---

## Claim Ledger Updates (EXP01A)

- C-16 (source locations for hotspot_1): **Updated to `Markdown-reported / EXP01A-localized`** — localized to `hmodel.py:343–369` (per-node-type loop) with high confidence from profiling artifact inspection.
- C-17 (matrix shapes): Still `Not yet measured`; EXP02 is the next step.
- C-07, C-08 (avg launches, per-call duration): Still `Prior-discussion reported`; not resolved in EXP01A.

## Recently Created or Modified Files

| File | Change | Date |
|---|---|---|
| `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Created (32 cells, loads 9 analysis bundles) | 2026-06-03 |
| `README.md` | Revised to describe profiling fork; links and tables added | 2026-06-03 |
| `docs/research_plan/` (all files) | Created in EXP00 | 2026-06-03 |
| `docs/research_plan/reports/EXP01A_SOURCE_LOCALIZATION_REPORT.md` | Created (EXP01A) | 2026-06-03 |
| `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` | Updated with findings (EXP01A) | 2026-06-03 |
| `docs/research_plan/STATUS.md` | Updated to EXP01A complete (this file) | 2026-06-03 |
| `docs/research_plan/SESSION_LOG.md` | EXP01A session entry appended | 2026-06-03 |
| `docs/research_plan/DECISION_LOG.md` | EXP01A decision entry appended | 2026-06-03 |
| `hmodel.py` | EXP01B: NVTX instrumentation added (env-gated `GFM_EXP01B_NVTX=1`) | 2026-06-03 |
| `artifacts/profiles/nsys/exp01b-nvtx-confirm-20260603-2100.nsys-rep` | EXP01B confirmation capture | 2026-06-03 |
| `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/` | EXP01B analysis bundle | 2026-06-03 |
| `docs/research_plan/reports/EXP01B_TARGETED_NVTX_CONFIRMATION_REPORT.md` | Created (EXP01B) | 2026-06-03 |
| `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` | Updated with EXP01B summary | 2026-06-03 |
| `docs/research_plan/STATUS.md` | Updated to EXP01B complete (this file) | 2026-06-03 |
