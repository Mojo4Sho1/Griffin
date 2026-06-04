# Verification Ledger

This ledger tracks claim-by-claim provenance for key quantitative and qualitative findings in the Griffin fragmentation-and-packing research campaign.

Its purpose is to distinguish **measured or computed facts** (backed by raw profiler artifacts or notebook execution) from **copied summaries**, **interpretations**, and **claims that have not yet been independently verified from a primary artifact in this checkout**.

Do not treat prior chat discussion as sufficient provenance for advisor-facing claims.

---

## Source of Truth Policy

| Layer | What it is | Role |
|---|---|---|
| `artifacts/profiles/nsys/` | Raw `.nsys-rep` trace files | Primary data |
| `artifacts/profiles/ncu/` | Raw `.ncu-rep` files + `ncu_analysis.sqlite` | Primary data |
| `artifacts/profiles/analysis/` | Per-run analysis bundles | Derived data |
| `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Cross-scenario analysis notebook | Reproducible analysis |
| `profiling/notebooks/ncu_sqlite_review.ipynb` | NCU deep-dive notebook | Reproducible analysis |
| `profiling/RESULTS.md` | Versioned result records | Authoritative markdown summary |
| `docs/research_plan/EVIDENCE_SUMMARY.md` | Profiling facts vs interpretations | Campaign-level summary |

Advisor-facing claims should eventually be backed by at least one of:
- Notebook-computed results (notebook run, output inspected)
- Exported notebook tables (see `artifacts/profiles/dashboard_exports/` — planned)
- Raw or derived profiler artifacts
- Explicit versioned record in `profiling/RESULTS.md`

---

## Verification Categories

| Category | Meaning |
|---|---|
| `Verified from raw/derived artifacts` | Directly confirmed from `.nsys-rep`, `.ncu-rep`, `ncu_analysis.sqlite`, or analysis bundle files in this checkout |
| `Verified by notebook` | Notebook was executed and this claim appears in computed output |
| `Verified by exported notebook output` | Notebook output was exported (CSV or table) and the value was confirmed from that export |
| `Markdown-reported` | Reported in `profiling/RESULTS.md` or similar authoritative markdown; not yet independently re-confirmed from the raw artifact in this session |
| `Prior-discussion reported` | Mentioned only in prior conversation or session chat; not yet found in any file in this checkout |
| `Unverified` | Value appears in documentation but its primary source cannot be identified |
| `Not yet measured` | The quantity has not been measured at all; gap is known and documented |

---

## Claim Ledger

| Claim ID | Claim | Verification Status | Primary Evidence Source | Secondary Evidence Source | Notes / Caveats | Needed Action |
|---|---|---|---|---|---|---|
| C-01 | 9/9 realistic train/finetune/inference slices completed (TR-B1, FT-B1, IF-B1; 3 slices each) | Markdown-reported | `profiling/RESULTS.md` — `gfm-20260304-r02-realistic-cross-scenario-review-01` | `docs/research_plan/SESSION_LOG.md` | Cross-scenario review gate PASS recorded in STATUS.md; slice directories present in `artifacts/profiles/analysis/` | Verify slice count directly from `artifacts/profiles/analysis/` listing |
| C-02 | Top-3 kernel identities (hotspot_1, hotspot_2, hotspot_3) are stable across train/finetune/inference | Markdown-reported | `profiling/RESULTS.md` — cross-scenario review | `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` (16/16 validation pass reported) | Intra-scenario timeshare drift ≤ 1.72% for train; full cross-scenario drift not separately tabulated | Confirm from notebook export: `cross_scenario_top3_validation.csv` (planned) |
| C-03 | hotspot_1 kernel name is `ampere_sgemm_32x32_sliced1x4_tn` | Markdown-reported | `profiling/RESULTS.md` | `artifacts/profiles/analysis/*/cuda_gpu_kern_sum.txt` | Kernel name appears consistently across slices per cross-scenario review | Grep `cuda_gpu_kern_sum.txt` files for exact string to confirm |
| C-04 | hotspot_1 accounts for approximately 30–32% of GPU time across scenarios | Markdown-reported | `profiling/RESULTS.md` — realistic cross-scenario review | `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Range reflects per-scenario variation; slice_size_tier=8/4 so percentages are relative to short bounded captures | Confirm from notebook export: `cross_scenario_kernel_summary.csv` (planned) |
| C-05 | hotspot_1 launch count is approximately 22,731–22,754 per train/finetune slice | Markdown-reported | `profiling/RESULTS.md` | `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Per-slice values; range reflects train vs finetune variation; consistent with `gfm.eval_task` NVTX structure | Confirm from notebook export: `cross_scenario_launch_counts.csv` (planned) |
| C-06 | hotspot_1 launch count is approximately 7,477 per inference slice | Markdown-reported | `profiling/RESULTS.md` | `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Inference has ~1/3 the GEMM launch count of train/finetune, consistent with fewer eval tasks | Confirm from notebook export: `cross_scenario_launch_counts.csv` (planned) |
| C-07 | Cross-scenario average hotspot_1 launch count is approximately 17.6k per slice | Prior-discussion reported | Not found in any current file in this checkout | `docs/research_plan/STATUS.md` (caveated) | STATUS.md explicitly flags this as "reported from prior research discussion, consistent with above counts but not directly verified." Computed rough average of 22k+22k+7.5k / 3 ≈ 17.2k, close but not identical to claimed 17.6k. | Run notebook or compute from confirmed per-scenario launch counts |
| C-08 | Average hotspot_1 per-call duration is approximately 6.1 microseconds | Prior-discussion reported | Not found in any current file in this checkout | `docs/research_plan/EVIDENCE_SUMMARY.md` (flagged as unverified) | EVIDENCE_SUMMARY notes this was "reported in prior discussion but has not been directly verified from a specific file." Could be computed as total_kernel_time / launch_count. | Query `ncu_analysis.sqlite` or `nsys` analysis bundle for per-invocation timing |
| C-09 | hotspot_1 `full_waves` (Waves/SM) is approximately 0.617 | Markdown-reported | `profiling/RESULTS.md` — `gfm-20260304-r02-train-ncu-hotspot-01`; `profiling/NCU_COVERAGE.md` | `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite` (WorkloadDistribution section) | Caution: Waves/SM ≈ 0.617 means the kernel launch has less than one full wave of thread blocks per SM, indicating spatial underutilization per launch. This does not mean exactly 38.3% of the GPU is idle. | Query `ncu_analysis.sqlite` WorkloadDistribution section to re-confirm |
| C-10 | hotspot_1 `eligible_warps_per_cycle` is approximately 0.387 | Markdown-reported | `profiling/RESULTS.md` — TR-N1 NCU; `profiling/NCU_COVERAGE.md` | `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite` (SchedulerStats section) | All 8 core NCU sections confirmed imported into SQLite | Query `ncu_analysis.sqlite` SchedulerStats section to re-confirm |
| C-11 | hotspot_2 kernel name is `fmha_cutlassF_f32_aligned_64x64_rf_sm80` | Markdown-reported | `profiling/RESULTS.md` — realistic cross-scenario review | `artifacts/profiles/analysis/*/cuda_gpu_kern_sum.txt` | Flash-attention CUTLASS kernel; consistent with graph attention in Griffin | Grep analysis bundle `cuda_gpu_kern_sum.txt` for exact string |
| C-12 | hotspot_2 accounts for approximately 12.5–13% of GPU time | Markdown-reported | `profiling/RESULTS.md` — realistic cross-scenario review | `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Range reflects cross-scenario variation | Confirm from notebook export: `cross_scenario_kernel_summary.csv` (planned) |
| C-13 | hotspot_3 kernel name is `ampere_sgemm_32x128_tn` | Markdown-reported | `profiling/RESULTS.md` — realistic cross-scenario review | `artifacts/profiles/analysis/*/cuda_gpu_kern_sum.txt` | Larger-tile SGEMM; second GEMM kernel in hotspot shortlist | Grep analysis bundle `cuda_gpu_kern_sum.txt` for exact string |
| C-14 | hotspot_3 accounts for approximately 9.3–9.8% of GPU time | Markdown-reported | `profiling/RESULTS.md` — realistic cross-scenario review | `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Range reflects cross-scenario variation | Confirm from notebook export: `cross_scenario_kernel_summary.csv` (planned) |
| C-15 | Tensor Core utilization status for hotspot_1 is not fully established | Not yet measured | `docs/research_plan/EVIDENCE_SUMMARY.md` — explicitly documented as missing | NCU metric `TC_FU_UTILIZATION` or equivalent not yet captured | Current NCU evidence (low Waves/SM, small-tile kernel name) is consistent with reduced TC utilization but does not confirm or deny it. | Run targeted NCU capture with TC utilization metrics; requires a new NCU slice (EXP01B or later) |
| C-16 | Source code locations responsible for hotspot_1 launches are localized to `hmodel.py:343–369` (aggregator crossattention) and linq layers | EXP01A-localized + EXP01B-NVTX-confirmed | EXP01A: direct code reading + profiling artifact analysis; EXP01B: NVTX time-range join on `exp01b-nvtx-confirm-20260603-2100.sqlite` | `docs/research_plan/reports/EXP01B_TARGETED_NVTX_CONFIRMATION_REPORT.md` | 55.1% of hotspot_1 time directly confirmed inside aggregator NVTX ranges; remaining 44.9% in uninstrumented MLP/backward regions (expected). hotspot_2 100% inside crossattention ranges. | EXP02 shape census to measure GEMM dimensions at realistic scale |
| C-17 | Matrix shapes responsible for hotspot_1 launches are not yet measured | Not yet measured | `docs/research_plan/STATUS.md` — documented as open blocker | `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md` | Pending EXP01 completion. EXP01 is now complete (EXP01A + EXP01B). | Execute EXP02 shape census |
| C-18 | RMPNN.rellin contribution to hotspot_1 cannot be assessed at hop=0 | Not yet measured | EXP01B: RMPNN.rellin NVTX range fired 0 times at hop=0 (no edges) | `docs/research_plan/reports/EXP01B_TARGETED_NVTX_CONFIRMATION_REPORT.md` | EXP02 must use hop=2 to exercise RMPNN with actual edges. | EXP02 at realistic hop=2: capture edge_attr.shape before RMPNN.rellin (hmodel.py:168) |

---

## Ledger Maintenance Notes

- This ledger was created during the EXP00 housekeeping pass on 2026-06-03.
- Claims C-07 and C-08 are explicitly `Prior-discussion reported` and must be resolved before being cited in advisor-facing materials.
- Claims C-01 through C-06 and C-09 through C-14 are `Markdown-reported`. They are consistent with the documentation and cross-referenced across multiple files, but have not been re-confirmed by fresh notebook execution or direct artifact query in this session.
- Claims C-15, C-16, C-17 are known gaps; their `Not yet measured` status is accurate and expected.
- When dashboard exports are generated (see `artifacts/profiles/dashboard_exports/` — planned), update the status of C-02 through C-06 and C-11 through C-14 to `Verified by exported notebook output`.
