# Session Log

Append-only. Add new entries at the bottom.

---

## Session: 2026-06-03 — EXP00 Repo State Assessment and Documentation Setup

**Claude instance:** Fresh instance; no prior context from this conversation.

**Task:** Create `docs/research_plan/` documentation structure for the Griffin fragmentation-and-packing research campaign.

**Files read:**
- `docs/agent_trace.md`
- `README.md`
- `profiling/RESULTS.md`
- `profiling/NCU_COVERAGE.md`
- `handoff/` directory listing
- `profiling/notebooks/` directory listing
- `artifacts/profiles/analysis/` directory listing

**Files created:**
- `docs/research_plan/README.md`
- `docs/research_plan/STATUS.md`
- `docs/research_plan/CAMPAIGN_PLAN.md`
- `docs/research_plan/HYPOTHESIS.md`
- `docs/research_plan/EVIDENCE_SUMMARY.md`
- `docs/research_plan/ARTIFACT_INDEX.md`
- `docs/research_plan/DECISION_LOG.md`
- `docs/research_plan/SESSION_LOG.md` (this file)
- `docs/research_plan/HANDOFF_TEMPLATE.md`
- `docs/research_plan/EXPERIMENT_PROTOCOLS.md`
- `docs/research_plan/GLOSSARY.md`
- `docs/research_plan/archive/agent_trace_legacy.md`
- `docs/research_plan/experiments/EXP00_REPO_STATE_AND_DOCS.md`
- `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`
- `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md`
- `docs/research_plan/experiments/EXP03_PACKING_MICROBENCHMARK.md`
- `docs/research_plan/experiments/EXP04_GRIFFIN_PROTOTYPE.md`
- `docs/research_plan/experiments/EXP05_REPROFILE_DECISION.md`

**Files modified:** None (no existing files edited).

**Commands run:** Directory listings and file reads only. No profiling, no model code modifications.

**Findings:** Repository is in a well-documented state. Profiling through NCU hotspot_1 is complete. NCU TR-N2 and TR-N3 are approved but not yet run. Source localization (EXP01) is the clear next step.

**Open issues:**
- NCU deep dives for hotspot_2 (fmha) and hotspot_3 (sgemm_32x128) not yet run.
- Per-call duration (~6.1 µs) and ~17.6k launch cross-scenario average cited in prior discussion but not directly verified from a single file in this checkout.

**Next recommended task:** EXP01 — Source Localization.

---

---

## Session: 2026-06-03 — EXP00 Housekeeping Pass

**Claude instance:** Fresh instance; no prior context from this conversation.

**Purpose:** Clean up documentation state before EXP01A begins. Establish claim-level provenance tracking. Clarify EXP01A/EXP01B distinction.

**Files deleted:**
- `docs/agent_trace.md` — obsolete root file; already summarized in `SESSION_LOG.md` (this file) and archived in `docs/research_plan/archive/agent_trace_legacy.md`.

**Files created:**
- `docs/research_plan/VERIFICATION_LEDGER.md` — new claim-by-claim provenance tracker (17 claims).

**Files modified:**
- `docs/research_plan/STATUS.md` — updated current phase to "EXP00 complete; EXP01A pending"; added provenance caveats section; updated next action.
- `docs/research_plan/CAMPAIGN_PLAN.md` — split EXP01 into EXP01A (read-only, authorized) and EXP01B (instrumentation, requires explicit approval); clarified decision gate.
- `docs/research_plan/EXPERIMENT_PROTOCOLS.md` — renamed EXP01 to EXP01A; added EXP01B section with steps, allowed/disallowed, and gate.
- `docs/research_plan/EVIDENCE_SUMMARY.md` — added link to VERIFICATION_LEDGER; added provenance notes table; added source-of-truth policy.
- `docs/research_plan/ARTIFACT_INDEX.md` — added VERIFICATION_LEDGER entry; added planned `dashboard_exports/` directory; updated legacy documentation note.
- `docs/research_plan/SESSION_LOG.md` (this file) — added this entry.
- `docs/research_plan/DECISION_LOG.md` — added housekeeping decisions.

**Source/model/profiling changes:** None.
**Notebooks run:** None.
**Profiling jobs run:** None.

**Key outcomes:**
- `docs/agent_trace.md` removed; archive preserved at `docs/research_plan/archive/agent_trace_legacy.md`.
- `VERIFICATION_LEDGER.md` created; 17 claims tracked with explicit provenance status. Claims C-07 (~17.6k avg launches) and C-08 (~6.1 µs per call) explicitly flagged as `Prior-discussion reported`. Claims C-15, C-16, C-17 flagged as `Not yet measured`.
- EXP01A is the authorized next step (read-only). EXP01B requires explicit approval.

**Next recommended task:** EXP01A — Source Localization from existing artifacts and read-only code inspection.

---

## Session: 2026-06-03 — EXP01A Source Localization

**Claude instance:** Fresh instance; no prior context from this conversation.

**Task:** EXP01A — Source Localization from Existing Artifacts. Read-only. Map hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`) and hotspot_2 (`fmha_cutlassF_f32_aligned_64x64_rf_sm80`) to Griffin source code call sites.

**Files read:**
- `docs/research_plan/README.md`, `STATUS.md`, `CAMPAIGN_PLAN.md`, `EXPERIMENT_PROTOCOLS.md`, `VERIFICATION_LEDGER.md`, `EVIDENCE_SUMMARY.md`, `ARTIFACT_INDEX.md`
- `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`
- `profiling/RESULTS.md`
- `artifacts/profiles/analysis/20260312-1537-trb1-realistic-20260312a-s03/cuda_gpu_kern_sum.txt`, `nvtx_sum.txt`, `metrics.json`
- `artifacts/profiles/analysis/20260306-1652-ifb1-realistic-20260306b-s03/cuda_gpu_kern_sum.txt`, `nvtx_sum.txt`
- `artifacts/profiles/analysis/20260306-1553-ftb1-realistic-20260306a-s03/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/20260304-1541-train-annotated-completion-01/cuda_gpu_kern_sum.txt`, `nvtx_sum.txt`
- `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite` (structure, bundle_metadata, launch_settings, section_metric_values)
- `artifacts/profiles/analysis/20260319-1514-train-completion-01/sections/LaunchStats.csv`
- `hmaintask_completion.py` (full, 406 lines)
- `hmodel.py` (full, 534 lines)
- `hloaderwrapper.py` (full, 421 lines)
- `hdataset.py` (lines 1–200)

**Files created:**
- `docs/research_plan/reports/EXP01A_SOURCE_LOCALIZATION_REPORT.md`

**Files modified:**
- `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` — filled in Findings section, set status to Complete
- `docs/research_plan/STATUS.md` — updated current phase, next action, blockers, recently-modified files
- `docs/research_plan/SESSION_LOG.md` (this file) — appended this entry
- `docs/research_plan/DECISION_LOG.md` — appended EXP01A decision

**Commands run (read-only):**
- `ls artifacts/profiles/analysis/`
- `cat` on nvtx_sum.txt, cuda_gpu_kern_sum.txt, LaunchStats.csv
- `python3` (read-only): queried ncu_analysis.sqlite for table structure, bundle_metadata, launch_settings, LaunchStats rows
- `grep -n` on hmaintask_completion.py, hmodel.py for line numbers
- `wc -l` for file size info

**Artifacts inspected:**
- 4 realistic analysis bundles (train, finetune, inference x s03, plus annotated train)
- NCU SQLite for TR-N1 (hotspot_1 NCU analysis)

**Main findings:**
1. Both hotspot_1 and hotspot_2 scale proportionally 3:1 with eval_task instance counts (train 153 vs inference 51). Evidence from direct reading of cuda_gpu_kern_sum.txt files.
2. sgemm_32x32: 22,731 train / 7,477 inference (ratio 3.039 ≈ 3.000). fmha: 2,420 / 796 (ratio 3.040 ≈ 3.000).
3. Call path: `gfm.eval_task` → `eval_task()` (hmaintask_completion.py:30) → `compute_output()` (line 101) → `model(*data)` (line 105) → `GriffinMod.forward()` (hmodel.py:327).
4. hotspot_2 source: `SelfAverageAggregator.crossattention` (hmodel.py:30–36, layer 0) and `SelfAttentionAggregator.crossattention` (hmodel.py:78–84, layers 1–3), called per-node-type per-mp-layer inside a Python for-loop (hmodel.py:343–369).
5. hotspot_1 source: QKV projections inside `nn.MultiheadAttention` (hmodel.py:24–25, 66–67). NCU LaunchStats shows grid (16,18,1) → GEMM M=576=64×9 (batchsize×n_columns), N=512, K=512 for the NCU run (hop=0, batchsize=64).
6. Key NCU caveat: NCU run used `--hop 0 --fewshotfanout 0 --batchsize 64` (from launch_settings in SQLite). Realistic NSYS run uses hop=2, batchsize=512. NCU metrics apply to simplified config only.
7. Fragmentation driver: per-node-type Python for-loop in GriffinMod.forward() — NOT batched across table types.
8. T≈1 estimated from fmha/eval_task ratio, but uncertain (may reflect SDPA backend fallback).

**Decision gate result:** Clear source locations found → Proceed to EXP02. EXP01B not needed.

**Next recommended action:** EXP02 shape census. Instrument `hmodel.py:343–369` (per-node-type loop, capture feat.shape, colfeat.shape, len(node)) and `hmodel.py:168` (RMPNN.rellin, capture edge_attr.shape). Write `scripts/exp02_shape_census.py`. Run with realistic parameters (hop=2, batchsize=512, fewshotfanout=3).

---

## Session: 2026-06-03 — EXP01B Targeted NVTX Confirmation

**Claude instance:** Fresh instance; EXP01A report and all research docs read at session start.

**Authorization:** User explicitly authorized EXP01B as an additional confirmation step before EXP02, overriding the EXP01A session's recommendation that EXP01B was not needed.

**Task:** Add fine-grained environment-gated NVTX instrumentation to `hmodel.py`, run one bounded Nsight Systems confirmation capture with `GFM_EXP01B_NVTX=1`, analyze kernel-by-NVTX associations via SQLite time-range join, and update documentation.

**Files read:**
- All 13 required files from `read_first` section (docs/research_plan/* and profiling/*)
- `hmodel.py` (full, 534 lines)
- `scripts/profile_baseline.sh`
- `profiling/sql/manual_queries.sql`
- `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/nvtx_sum.txt`
- `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/summary.md`
- `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/metrics.json`

**Source changes (instrumentation-only):**
- `hmodel.py` lines 13–29: added `_EXP01B_NVTX` flag + `_nvtx` context manager class
- `hmodel.py` `SelfAverageAggregator.forward()`: added 3 nested `_nvtx` ranges (forward, crossattention, linq)
- `hmodel.py` `SelfAttentionAggregator.forward()`: added 3 nested `_nvtx` ranges (forward, crossattention, linq); changed `return ret * self.linq(tar)` to two statements to allow linq sub-range
- `hmodel.py` `RMPNN.forward()`: added `_nvtx` range around `self.rellin(edge_attr)` on non-degenerate path

**Commands run:**
- `nvidia-smi` — confirmed GPU3 clear
- Smoke test: `CUDA_VISIBLE_DEVICES=3 GFM_EXP01B_NVTX=1 scripts/profile_baseline.sh smoke ... --max_train_steps 4 --max_eval_steps 2` — PASSED
- nsys capture: `CUDA_VISIBLE_DEVICES=3 GFM_EXP01B_NVTX=1 scripts/profile_baseline.sh nsys exp01b-nvtx-confirm-20260603-2100 ... --max_train_steps 8 --max_eval_steps 4` — COMPLETED
- `scripts/analyze_nsys_run.sh --run-id exp01b-nvtx-confirm-20260603-2100` — bundle generated
- SQLite time-range join queries: `CUPTI_ACTIVITY_KIND_KERNEL.start >= NVTX_EVENTS.start AND end <= NVTX_EVENTS.end` for `gfm.exp01b.*` labels

**Key findings:**
1. hotspot_2 (fmha): 2,420/2,420 launches = 100% inside crossattention ranges (74.6% SelfAttentionAggregator, 25.4% SelfAverageAggregator). Strong confirmation.
2. hotspot_1 (sgemm_32x32): 8,460/22,731 launches = 37.2% inside aggregator ranges; 55.1% of GPU time. Remaining 44.9% in uninstrumented MLP/backward regions (expected).
3. hotspot_1 inside crossattention alone: 6,652 launches = 49.3% of total GPU time.
4. SelfAttentionAggregator.linq: 1,806 launches, 7.97 ms = 5.8% of total hotspot_1 GPU time. Material contributor.
5. RMPNN.rellin NVTX range: 0 instances fired. hop=0 means no edges; all RMPNN calls took the early-return path. Cannot assess RMPNN.rellin contribution from this capture.
6. T=1 confirmed: SelfAverageAggregator.forward = 605 instances; SelfAttentionAggregator.forward = 1,815 = 3×605; ratio = 3 = (num_mp − 1). One node type per forward pass at hop=0.

**Decision gate result:** Source localization confirmed at sub-module level. Proceed to EXP02 shape census. RMPNN.rellin must be assessed at hop≥1 in EXP02.

**Artifacts created:**
- `artifacts/profiles/nsys/exp01b-nvtx-confirm-20260603-2100.nsys-rep`
- `artifacts/profiles/nsys/exp01b-nvtx-confirm-20260603-2100.sqlite`
- `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/`

**Files created:**
- `docs/research_plan/reports/EXP01B_TARGETED_NVTX_CONFIRMATION_REPORT.md`

**Files modified:**
- `hmodel.py` — NVTX instrumentation (instrumentation-only, no semantic changes)
- `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` — updated status to include EXP01B
- `docs/research_plan/STATUS.md` — updated current phase and file listing
- `docs/research_plan/SESSION_LOG.md` (this file) — appended this entry
- `docs/research_plan/DECISION_LOG.md` — appended EXP01B decision

---

## Summary of `docs/agent_trace.md` (Legacy)

The legacy `docs/agent_trace.md` contained one entry (2026-06-03), summarized here:

**2026-06-03 — nsys cross-scenario dashboard notebook**
- Created `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` (32 cells).
- Notebook loads 9/9 realistic NSYS analysis bundles from `artifacts/profiles/analysis/*/metrics.json`.
- Regenerates kernel time-share, launch-count, NVTX, host-API, advisor summary, optimization matrix, and validation-against-RESULTS.md tables and charts.
- Validation: 16/16 claims PASS; no existing files modified.
- Revised root `README.md` to describe this as a profiling fork of Griffin. Added quick-orientation table, profiling status, key findings table, notebook/workflow sections. Original Griffin usage content preserved. All 16 local links verified present; no overclaiming language introduced.

Full archived text: `docs/research_plan/archive/agent_trace_legacy.md`
