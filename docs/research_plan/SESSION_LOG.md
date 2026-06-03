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

## Summary of `docs/agent_trace.md` (Legacy)

The legacy `docs/agent_trace.md` contained one entry (2026-06-03), summarized here:

**2026-06-03 — nsys cross-scenario dashboard notebook**
- Created `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` (32 cells).
- Notebook loads 9/9 realistic NSYS analysis bundles from `artifacts/profiles/analysis/*/metrics.json`.
- Regenerates kernel time-share, launch-count, NVTX, host-API, advisor summary, optimization matrix, and validation-against-RESULTS.md tables and charts.
- Validation: 16/16 claims PASS; no existing files modified.
- Revised root `README.md` to describe this as a profiling fork of Griffin. Added quick-orientation table, profiling status, key findings table, notebook/workflow sections. Original Griffin usage content preserved. All 16 local links verified present; no overclaiming language introduced.

Full archived text: `docs/research_plan/archive/agent_trace_legacy.md`
