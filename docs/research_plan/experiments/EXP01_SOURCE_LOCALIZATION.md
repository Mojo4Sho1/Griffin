# EXP01 — Source Localization

**Status:** EXP01A Complete (2026-06-03). EXP01B Complete (2026-06-03, user-authorized). Decision gate: Proceed to EXP02.

**EXP01B summary:** Fine-grained NVTX instrumentation added to `hmodel.py` (env-gated by `GFM_EXP01B_NVTX=1`). One bounded nsys capture run (ID: `exp01b-nvtx-confirm-20260603-2100`). Results: hotspot_2 (fmha) 100% confirmed inside crossattention ranges; hotspot_1 (sgemm_32x32) 55.1% of GPU time inside aggregator ranges (remaining 44.9% in uninstrumented MLP/backward regions). `SelfAttentionAggregator.linq` contributes 5.8% of hotspot_1 time. RMPNN.rellin cannot be assessed at hop=0. Full report: `docs/research_plan/reports/EXP01B_TARGETED_NVTX_CONFIRMATION_REPORT.md`.

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

**Full report:** `docs/research_plan/reports/EXP01A_SOURCE_LOCALIZATION_REPORT.md`

### hotspot_1 Candidate Call Sites (sgemm_32x32)

| File | Line Range | NVTX Context | Relational Structure | Reasoning |
|---|---|---|---|---|
| `hmodel.py` | 24–25, 30–36 | `gfm.eval_task` | Per-table-type loop, layer 0 (SelfAverageAggregator) | QKV projection inside `nn.MultiheadAttention`; NCU grid (16,18,1) → M=576=64×9 (batchsize×n_columns) |
| `hmodel.py` | 66–67, 78–84 | `gfm.eval_task` | Per-table-type loop, layers 1-3 (SelfAttentionAggregator) | Same QKV projection for cross-attention; 1-token query projection per node type |
| `hmodel.py` | 37, 85 | `gfm.eval_task` | Per-table-type loop | `linq = nn.Linear(512,512)` applied after crossattention, per node type per layer |
| `hmodel.py` | 168 | `gfm.eval_task` | RMPNN edge-type projection | `rellin = nn.Linear(512,512)` applied to `edge_attr[#edge_types, 512]`; small M if few edge types |

### hotspot_2 Candidate Call Sites (fmha)

| File | Line Range | NVTX Context | Relational Structure | Reasoning |
|---|---|---|---|---|
| `hmodel.py` | 24–25, 30–36 | `gfm.eval_task` | Per-table-type loop, layer 0 | `SelfAverageAggregator.crossattention`; CUTLASS fmha_f32 with head_dim=64=512/8 |
| `hmodel.py` | 66–67, 78–84 | `gfm.eval_task` | Per-table-type loop, layers 1-3 | `SelfAttentionAggregator.crossattention`; 1-token cross-attention per table type per layer |

### Fragmentation Assessment

Fragmentation is driven by an **explicit Python for-loop over node types (table types) in `GriffinMod.forward()` at hmodel.py:343–369**. Each iteration of this loop corresponds to one distinct table type in the heterogeneous relational subgraph. Each iteration calls `crossattention` (producing fmha) and inner-projection GEMMs (producing sgemm_32x32) separately. These calls are NOT batched across table types.

Key quantitative evidence:
- Both hotspot kernels scale exactly 3:1 with eval_task instance counts (train 153 vs inference 51 instances).
- ~148 sgemm_32x32 and ~16 fmha per eval_task; ~4 fmha per forward pass (consistent with 4 MP layers × ~1 table type with fmha).
- NCU launch data: sgemm_32x32 with grid (16,18,1) → GEMM M=576=64_nodes×9_columns, N=512, K=512.

EXP02 primary target: capture `feat.shape = [#nodes_j, #feat_j, 512]` in the per-node-type loop (hmodel.py:343–369) and `edge_attr.shape` before RMPNN.rellin (hmodel.py:168).

### Decision Gate Outcome

**Gate triggered: Clear source locations found → Proceed to EXP02 shape census.**

EXP01B (targeted instrumentation) is NOT needed. Source localization from existing artifacts is conclusive.

EXP02 instrumentation targets:
1. `hmodel.py:343–369` — per-node-type loop: capture `len(node)`, `feat.shape`, `colfeat.shape` per iteration per layer
2. `hmodel.py:168` — RMPNN.rellin: capture `edge_attr.shape` before projection
3. `hmodel.py:30–36, 78–84` — crossattention calls: capture tensor shapes (optional cross-check)
