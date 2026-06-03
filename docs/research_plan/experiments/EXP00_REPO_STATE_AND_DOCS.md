# EXP00 — Repo State Assessment and Research Documentation Setup

**Status:** Complete (2026-06-03)

---

## Purpose

Establish durable human- and agent-readable documentation for the Griffin fragmentation-and-packing research campaign so future Claude instances can continue without losing context.

---

## Prerequisite Docs / Artifacts

- `docs/agent_trace.md` (legacy session accounting)
- `profiling/RESULTS.md`
- `profiling/NCU_COVERAGE.md`
- Root `README.md`
- `handoff/` directory (old campaign reference only)

---

## Allowed Changes

- Create new files under `docs/research_plan/`.
- Archive `docs/agent_trace.md` content.

## Disallowed Changes

- No modifications to `handoff/`, `profiling/`, or Griffin source files.
- No profiling jobs.
- No model code changes.

---

## Deliverables

- [x] `docs/research_plan/README.md`
- [x] `docs/research_plan/STATUS.md`
- [x] `docs/research_plan/CAMPAIGN_PLAN.md`
- [x] `docs/research_plan/HYPOTHESIS.md`
- [x] `docs/research_plan/EVIDENCE_SUMMARY.md`
- [x] `docs/research_plan/ARTIFACT_INDEX.md`
- [x] `docs/research_plan/DECISION_LOG.md`
- [x] `docs/research_plan/SESSION_LOG.md`
- [x] `docs/research_plan/HANDOFF_TEMPLATE.md`
- [x] `docs/research_plan/EXPERIMENT_PROTOCOLS.md`
- [x] `docs/research_plan/GLOSSARY.md`
- [x] `docs/research_plan/archive/agent_trace_legacy.md`
- [x] `docs/research_plan/experiments/EXP00_REPO_STATE_AND_DOCS.md` (this file)
- [x] `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`
- [x] `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md`
- [x] `docs/research_plan/experiments/EXP03_PACKING_MICROBENCHMARK.md`
- [x] `docs/research_plan/experiments/EXP04_GRIFFIN_PROTOTYPE.md`
- [x] `docs/research_plan/experiments/EXP05_REPROFILE_DECISION.md`

---

## Success Criteria

A fresh Claude instance can read `README.md`, `STATUS.md`, and `CAMPAIGN_PLAN.md` and understand: (1) the project, (2) what has happened, (3) evidence, (4) next experiment, (5) files that matter, (6) what not to modify, (7) how to report findings.

**Result:** Pass.

---

## Decision Gate

Documentation complete. `STATUS.md` names EXP01 as the next experiment. `CAMPAIGN_PLAN.md` provides gates for all five experiments.

Proceed to EXP01 Source Localization.

---

## Required Handoff Update

Session entry added to `SESSION_LOG.md`. Decision entries added to `DECISION_LOG.md`. `STATUS.md` updated.
