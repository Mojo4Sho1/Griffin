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

## 2026-06-03 — EXP00 Documentation Structure Established

**Decision:** Create `docs/research_plan/` as the canonical documentation location for the new research campaign. Retire `docs/agent_trace.md` as the primary record.

**Reason:** Prior session accounting was stored in `docs/agent_trace.md`, which is not structured for agent handoff and does not contain experiment protocols, decision gates, or hypothesis framing. The new structure provides entry point (`README.md`), current state (`STATUS.md`), campaign plan with gates (`CAMPAIGN_PLAN.md`), hypothesis framing (`HYPOTHESIS.md`), and per-experiment briefs — sufficient for a fresh Claude instance to continue without losing context.

**Evidence:** Contents of `docs/agent_trace.md` summarized in `SESSION_LOG.md`. Old `handoff/` campaign left untouched.

**Next action:** Begin EXP01.
