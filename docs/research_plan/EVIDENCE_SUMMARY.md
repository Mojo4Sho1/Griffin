# Evidence Summary

This document separates measured profiling facts from interpretations. Read `ARTIFACT_INDEX.md` for file locations.

**Claim-by-claim provenance is tracked in `docs/research_plan/VERIFICATION_LEDGER.md`.**

The ledger distinguishes:
- `Verified from raw/derived artifacts` — confirmed from `.nsys-rep`, `.ncu-rep`, SQLite, or analysis bundle files.
- `Verified by notebook` — notebook executed and output inspected.
- `Verified by exported notebook output` — exported CSV or table confirmed.
- `Markdown-reported` — reported in `profiling/RESULTS.md` or similar; not yet re-confirmed from raw artifact in this session.
- `Prior-discussion reported` — appeared only in prior conversation; not found in any file in this checkout.
- `Not yet measured` — quantity has not been measured at all.

**Advisor-facing claims should eventually be backed by at least one of:**
- Notebook-computed results or exported notebook tables (see `artifacts/profiles/dashboard_exports/` — planned).
- Raw or derived profiler artifacts.
- Explicit versioned record in `profiling/RESULTS.md`.

Do not cite `Prior-discussion reported` claims in advisor materials without first resolving them to a file-backed source.

---

## Source Files to Inspect

| File | What it Contains |
|---|---|
| `profiling/RESULTS.md` | Versioned result records for all profiling campaigns; source for all quantitative claims below |
| `profiling/NCU_COVERAGE.md` | NCU section coverage tracker; source for TR-N1 import status and metric values |
| `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Interactive cross-scenario kernel time-share, launch-count, NVTX, and advisor views |
| `profiling/notebooks/ncu_sqlite_review.ipynb` | NCU deep-dive notebook for hotspot_1; reads from `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite` |
| `artifacts/profiles/analysis/20260304-1541-train-annotated-completion-01/` | Annotated train analysis bundle |
| `artifacts/profiles/analysis/20260319-1514-train-completion-01/` | TR-N1 NCU analysis bundle (hotspot_1) |

---

## Measured Facts

These values are directly reported in `profiling/RESULTS.md` under the result records listed.

### Cross-Scenario Hotspot Identity (result: `gfm-20260304-r02-realistic-cross-scenario-review-01`)

| Kernel | Name | GPU Time Share | Rank |
|---|---|---|---|
| hotspot_1 | `ampere_sgemm_32x32_sliced1x4_tn` | ~30–32% | 1 (all scenarios) |
| hotspot_2 | `fmha_cutlassF_f32_aligned_64x64_rf_sm80` | ~12.5–13% | 2 (all scenarios) |
| hotspot_3 | `ampere_sgemm_32x128_tn` | ~9.3–9.8% | 3 (all scenarios) |

- Top-3 overlap across train, finetune, and inference: **3/3**
- Intra-scenario timeshare drift across paired slices: **≤ 1.72%** (train)
- Inference has ~1/3 the GEMM launch count of train/finetune: **7,477 vs 22,731–22,754 per slice**

These measurements were made at `slice_size_tier=8/4` (max 8 train steps, 4 eval steps) on GPU3 of a shared 4-GPU server.

### NCU Analysis of hotspot_1 (result: `gfm-20260304-r02-train-ncu-hotspot-01`)

Source: `profiling/RESULTS.md`, `profiling/NCU_COVERAGE.md`, `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite`

| Metric | Value |
|---|---|
| `full_waves` (Waves/SM) | 0.617 |
| `eligible_warps_per_cycle` | 0.387 |
| `issue_every_cycles` | 3.314 |
| `active_warps_per_scheduler` | 1.838 |
| L2 active/elapsed ratio | ~1.003% |
| DRAM active/elapsed ratio | ~0.946% |

All 8 NCU core sections imported successfully into SQLite for this hotspot. Sections: `LaunchStats`, `Occupancy`, `SchedulerStats`, `WarpStateStats`, `ComputeWorkloadAnalysis`, `MemoryWorkloadAnalysis`, `SpeedOfLight`, `WorkloadDistribution`.

---

## Interpretations (Not Yet Verified by Controlled Experiment)

### Small-GEMM Fragmentation Interpretation

The high launch count for hotspot_1 (~22k per training slice) combined with `full_waves=0.617` suggests that individual launches are not filling the GPU. The kernel name `ampere_sgemm_32x32_sliced1x4_tn` uses a 32×32 tile, which is smaller than the 128×128 tiles used in high-throughput GEMM paths (e.g., `ampere_sgemm_128x64`). Together, these suggest fragmented computation.

**Caution:** "Waves/SM ≈ 0.617" does not mean exactly 38.3% of the GPU is idle. It means the kernel launch has less than one full wave of thread blocks per Streaming Multiprocessor, indicating spatial underutilization per launch. The actual impact on throughput depends on kernel duration, memory access patterns, and scheduler behavior.

### Relational Schema as the Cause

The hypothesis that relational schema heterogeneity causes the fragmentation is motivated by Griffin's architecture (graph attention over variable-schema relational tables) and the observation that inference has ~1/3 the launches of train/finetune, consistent with fewer evaluation tasks per slice. However, the specific code paths responsible for the launches have not yet been identified (pending EXP01).

### Tensor Core Utilization

Current NCU evidence (low wave occupancy, small-tile kernel name) is consistent with reduced Tensor Core utilization, but this has not been directly measured. A targeted NCU metric capture (`TC_FU_UTILIZATION` or equivalent) would be needed to confirm or deny TC usage.

---

## Provenance Notes on Key Values

| Claim | Status | Ledger Ref |
|---|---|---|
| hotspot_1 ~30–32% GPU time | Markdown-reported (`profiling/RESULTS.md`) | C-04 |
| hotspot_1 launch count ~22,731–22,754 per train/finetune | Markdown-reported | C-05 |
| hotspot_1 launch count ~7,477 per inference | Markdown-reported | C-06 |
| Cross-scenario average ~17.6k launches | **Prior-discussion reported** — not in any file | C-07 |
| Per-call duration ~6.1 µs | **Prior-discussion reported** — not in any file | C-08 |
| `full_waves` = 0.617 | Markdown-reported (`profiling/RESULTS.md`, `NCU_COVERAGE.md`, `ncu_analysis.sqlite`) | C-09 |
| `eligible_warps_per_cycle` = 0.387 | Markdown-reported | C-10 |
| Tensor Core utilization | **Not yet measured** | C-15 |

See `VERIFICATION_LEDGER.md` for full table including all 17 tracked claims.

---

## What Evidence Is Still Missing

| Missing | Needed For |
|---|---|
| NCU deep dives for hotspot_2 (fmha) and hotspot_3 (sgemm_32x128) | Complete picture of all three major hotspots |
| Source code locations producing hotspot_1 launches | EXP01 prerequisite for EXP02 |
| Actual matrix shapes at identified call sites | EXP02; required to design a packing strategy |
| Controlled microbenchmark at EXP02 shapes | EXP03; required to quantify packing benefit |
| Direct Tensor Core utilization measurement | Would strengthen or weaken TC-bypass framing |
| Per-call duration measurement for hotspot_1 | The ~6.1 µs per call figure is `Prior-discussion reported` (Ledger: C-08) — not verified from any file in this checkout; could be computed as total kernel time / launch count from analysis bundles |

---

## Notes on Measurement Quality

- All slice captures use `slice_size_tier=8/4`. These are short bounded slices, not production-scale full training runs. Kernel time-share percentages are relative indicators; production absolute values may differ.
- Runs were constrained to GPU3 on a shared 4-GPU server. Wall-time variation (e.g., ±10s across slices for train) reflects shared-host noise, not model instability.
- The TR-N1 NCU report (`20260319-1514-train-completion-01`) was captured with legacy `--set full` and no launch cap, producing a 7.8 GB file. Future NCU runs use `--sections-profile core --launch-count 5`.
