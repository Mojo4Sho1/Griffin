# Decision Log

Append-only. Add new entries at the bottom. Do not edit existing entries.

Format: `## YYYY-MM-DD — Decision Title`

---

## 2026-06-03 — Proceed to EXP01 Source Localization

**Decision:** Advance from profiling and dashboard evidence to EXP01 source localization.

**Reason:** The profiling campaign (NSYS realistic-scale + NCU hotspot_1) is sufficiently complete to justify shifting from measurement to analysis. The dominant GPU hotspot (`ampere_sgemm_32x32_sliced1x4_tn`, ~31% GPU time, ~22k launches per slice, `full_waves=0.617`) is well-characterized. Before designing any optimization, the source code locations producing these launches must be identified. Executing NCU deep dives for hotspot_2 and hotspot_3 is approved but can be deferred until source localization is underway or complete, since those results are unlikely to change the EXP01 approach.

**Evidence:**
- `profiling/RESULTS.md` — `gfm-20260304-r02-realistic-cross-scenario-review-01` (cross-scenario hotspot identity)
- `profiling/RESULTS.md` — `gfm-20260304-r02-train-ncu-hotspot-01` (NCU analysis: `full_waves=0.617`, `eligible_warps_per_cycle=0.387`)
- `profiling/NCU_COVERAGE.md` — all 8 core sections imported for hotspot_1
- Cross-scenario review gate `gfm-20260304-r02-realistic-review-gate-01` PASS

**Next action:** Execute EXP01 source localization per `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` and `EXPERIMENT_PROTOCOLS.md`.

---

## 2026-06-03 — EXP01 Starts as Read-Only EXP01A; EXP01B Requires Explicit Approval

**Decision:** EXP01 is split into two sub-phases. EXP01A (read-only source localization from existing artifacts) is the default authorized next step. EXP01B (targeted instrumentation follow-up) is only permitted if EXP01A is inconclusive and requires explicit user approval before any source changes are made.

**Reason:** EXP01A can potentially resolve the source localization question entirely using existing profiling artifacts, analysis bundles, NVTX output, and code inspection. Adding instrumentation (EXP01B) carries risk of scope creep, semantic changes, or unnecessary profiling runs. Requiring explicit approval for EXP01B ensures the decision is deliberate.

**Evidence:** EXP01A protocol added to `EXPERIMENT_PROTOCOLS.md`; EXP01B requirements documented.

**Next action:** Execute EXP01A.

---

## 2026-06-03 — VERIFICATION_LEDGER Created for Claim-Level Provenance

**Decision:** Create `docs/research_plan/VERIFICATION_LEDGER.md` to track the provenance of all key quantitative claims in the research campaign.

**Reason:** Several important values (cross-scenario average launch count ~17.6k, per-call duration ~6.1 µs) were present only in prior chat discussion and could not be traced to any file in the checkout. This created a risk of advisor-facing materials citing unverified figures. The ledger makes the verification status of each claim explicit and provides a checklist for upgrading provenance over time.

**Evidence:** Ledger created with 17 tracked claims. C-07 and C-08 flagged `Prior-discussion reported`. C-15, C-16, C-17 flagged `Not yet measured`.

**Next action:** As notebook exports and new analyses are generated, update ledger statuses from `Markdown-reported` to `Verified by exported notebook output` or stronger.

---

## 2026-06-03 — Delete Obsolete Root `docs/agent_trace.md`

**Decision:** Delete `docs/agent_trace.md` from the repository root.

**Reason:** The file was already summarized in `docs/research_plan/SESSION_LOG.md` and archived verbatim in `docs/research_plan/archive/agent_trace_legacy.md` during the EXP00 documentation setup session. The root file was a legacy artifact with no unique content; retaining it risked confusion about which file is canonical. The archive is preserved.

**Evidence:** `docs/research_plan/archive/agent_trace_legacy.md` confirmed present. `docs/research_plan/SESSION_LOG.md` contains summary.

**Next action:** No further action needed.

---

## 2026-06-03 — EXP01A Complete: Proceed to EXP02 Shape Census

**Decision:** EXP01A source localization is complete and conclusive. Both hotspots are localized to `gfm.eval_task` → `GriffinMod.forward()` → per-node-type aggregation loop (`hmodel.py:343–369`). Proceed to EXP02 shape census. EXP01B targeted instrumentation is not needed.

**Evidence:**
- sgemm_32x32 launches: 22,731 (train, 153 eval_tasks) vs 7,477 (inference, 51 eval_tasks). Ratio 3.039 matches eval_task ratio 3.000 exactly. Source: `artifacts/profiles/analysis/*/cuda_gpu_kern_sum.txt` (direct read).
- fmha launches: 2,420 (train) vs 796 (inference). Ratio 3.040 matches eval_task ratio 3.000 exactly. Same source.
- NCU launch_settings (ncu_analysis.sqlite): NCU run used `--hop 0 --fewshotfanout 0 --batchsize 64`. All 5 sampled sgemm_32x32 launches had grid (16,18,1) → GEMM M=576=64×9 (batchsize×n_columns_per_table), N=512, K=512.
- GriffinMod.forward() (hmodel.py:327–394): explicit Python for-loop over node types (tables) at lines 343–369; each iteration calls `crossattention` (fmha source) and inner-projection GEMMs (sgemm_32x32 source) independently per table type.
- eval_task() call path confirmed: hmaintask_completion.py:264,294,330 → eval_task() → compute_output():105 → model(*data) = GriffinMod.forward().

**Uncertainty documented:**
- Exact GEMM shapes at realistic scale (hop=2, batchsize=512) unknown — NCU used simplified hop=0.
- T (number of node types per forward pass) estimated ~1 from fmha ratio but uncertain.
- RMPNN.rellin edge_attr shape (#edge_types) not measured.

**Next action:** Execute EXP02 shape census per `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md` and `EXPERIMENT_PROTOCOLS.md`. Primary instrumentation sites: `hmodel.py:343–369` (per-node-type loop) and `hmodel.py:168` (RMPNN.rellin). Write `scripts/exp02_shape_census.py`.

---

## 2026-06-03 — EXP01B User Authorization and Approval Record

**Decision:** User explicitly authorized EXP01B fine-grained NVTX confirmation despite EXP01A session concluding it was not needed.

**Reason:** User wanted direct NVTX evidence to confirm the EXP01A source localization before proceeding to EXP02. This is the "explicit user approval" required by CAMPAIGN_PLAN.md Section EXP01B. The EXP01A session recommended skipping EXP01B but noted that EXP01B could be run if user requested it.

**Evidence:** User-provided prompt in current session explicitly requests EXP01B with detailed instrumentation and profiling requirements.

**Constraints accepted:** EXP01B remains scoped to instrumentation-only changes and one bounded nsys capture. No semantic model changes. No EXP02 shape census during EXP01B.

---

## 2026-06-03 — EXP01B Complete: Hotspots Confirmed at Sub-Module Level; Proceed to EXP02

**Decision:** EXP01B targeted NVTX confirmation is complete. Direct NVTX evidence confirms EXP01A localization at the sub-module level. Proceed to EXP02 shape census.

**Evidence:**
- Run ID `exp01b-nvtx-confirm-20260603-2100` (nsys, hop=0, batchsize=64, max_train_steps=8, max_eval_steps=4, CUDA_VISIBLE_DEVICES=3).
- hotspot_2 (fmha): 2,420/2,420 launches = 100% inside `gfm.exp01b.SelfAverageAggregator.crossattention` or `gfm.exp01b.SelfAttentionAggregator.crossattention`. Split 605/1815 = 25.4%/74.6% matches 1:3 = layer-0:layers-1,2,3 ratio exactly.
- hotspot_1 (sgemm_32x32): 8,460/22,731 launches; 75.52/137.1 ms = 55.1% inside aggregator NVTX ranges. Remaining 44.9% in uninstrumented GriffinMod MLP/backward regions (expected). Crossattention sub-ranges alone account for 49.3% of hotspot_1 GPU time.
- SelfAttentionAggregator.linq: 1,806 launches, 7.97 ms = 5.8% of total hotspot_1 GPU time. Material contributor.
- RMPNN.rellin NVTX range: 0 instances fired (hop=0, no edges). Cannot assess from this capture.
- SQLite time-range join query: `CUPTI_ACTIVITY_KIND_KERNEL.start >= NVTX_EVENTS.start AND end <= NVTX_EVENTS.end`.

**Uncertainty documented:**
- RMPNN.rellin: cannot assess at hop=0. EXP02 must use hop≥1.
- GriffinMod MLP/lintask/gatelin contribution to hotspot_1: 44.9% in uninstrumented regions; consistent with expected but not directly confirmed.
- Capture scale (hop=0) differs from realistic scale (hop=2); kernel identities match but shapes are different.

**Source changes:** Instrumentation only. `hmodel.py` modified to add env-gated NVTX ranges. Disable with `GFM_EXP01B_NVTX=0` (default is disabled). Remove by reverting the hmodel.py diff.

**Full report:** `docs/research_plan/reports/EXP01B_TARGETED_NVTX_CONFIRMATION_REPORT.md`

**Next action:** Execute EXP02 shape census. Primary sites: `hmodel.py:343–369` (per-node-type loop) and `hmodel.py:168` (RMPNN.rellin; requires hop=2). Write `scripts/exp02_shape_census.py`.

---

## 2026-06-03 — EXP00 Documentation Structure Established

**Decision:** Create `docs/research_plan/` as the canonical documentation location for the new research campaign. Retire `docs/agent_trace.md` as the primary record.

**Reason:** Prior session accounting was stored in `docs/agent_trace.md`, which is not structured for agent handoff and does not contain experiment protocols, decision gates, or hypothesis framing. The new structure provides entry point (`README.md`), current state (`STATUS.md`), campaign plan with gates (`CAMPAIGN_PLAN.md`), hypothesis framing (`HYPOTHESIS.md`), and per-experiment briefs — sufficient for a fresh Claude instance to continue without losing context.

**Evidence:** Contents of `docs/agent_trace.md` summarized in `SESSION_LOG.md`. Old `handoff/` campaign left untouched.

**Next action:** Begin EXP01.
