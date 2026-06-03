# Griffin Research Plan — Entry Point

## Project Summary

This repository is a profiling-focused fork of Griffin, a graph foundation model for relational databases. The current research campaign investigates whether Griffin's relational schema structures cause fragmented dense GPU computation — many small GEMM launches that individually underfill the GPU — and whether a schema-aware packing or batching strategy can combine equivalent operations into fewer, larger, more hardware-efficient launches while preserving model semantics. Profiling is complete through NCU hotspot deep-dive for `hotspot_1`; the next step is EXP01 source localization.

---

## Read These Files First

| Order | File | Purpose |
|---|---|---|
| 1 | `docs/research_plan/STATUS.md` | Current state, next action, do-not-do list |
| 2 | `docs/research_plan/CAMPAIGN_PLAN.md` | Staged experiment sequence and decision gates |
| 3 | `docs/research_plan/HYPOTHESIS.md` | Precise research framing — read before any code work |
| 4 | `docs/research_plan/EVIDENCE_SUMMARY.md` | What profiling has shown (facts vs interpretations) |
| 5 | `docs/research_plan/ARTIFACT_INDEX.md` | Where the data lives |
| 6 | `docs/research_plan/EXPERIMENT_PROTOCOLS.md` | How to run each experiment |
| 7 | `docs/research_plan/HANDOFF_TEMPLATE.md` | Required reporting format at end of each experiment |

---

## Two Separate Campaigns

### Old campaign: `handoff/`

The root `handoff/` directory belongs to an earlier automated GPU profiling campaign. It contains `CHECKLIST.md`, `CURRENT_STATUS.md`, `NEXT_TASK.md`, and `SESSION_LOG.md` from that campaign.

**Do not modify `handoff/`.** It is a historical record. Inspect it for context only.

### New campaign: `docs/research_plan/` (this directory)

This is the current research documentation. All canonical state for the new research campaign lives here:

- `SESSION_LOG.md` — append-only session history
- `STATUS.md` — current phase and next action
- `DECISION_LOG.md` — append-only research decisions

The old `docs/agent_trace.md` is a legacy file from a previous Claude instance. It has been summarized into `SESSION_LOG.md` and archived at `docs/research_plan/archive/agent_trace_legacy.md`. Do not use `docs/agent_trace.md` as the canonical record going forward.

---

## Current Next Step

**EXP01 — Source Localization**

Goal: identify which lines of Griffin's model/data code produce the fragmented small-GEMM launches observed in profiling. Read the experiment brief at `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` before proceeding.

Do not run profiling, modify model code, or implement optimizations until EXP01 is complete and its decision gate is passed.

---

## Warning

Do not modify Griffin model source files (`hmodel.py`, `hloaderwrapper.py`, `hmaintask_*.py`, `hdataset.py`, etc.) until EXP04 explicitly permits it. Code modifications are only appropriate after EXP02 shape census and EXP03 microbenchmark establish a clear, tested case.

---

## Key Contacts and Provenance

- Profiling hardware: GPU3 on a shared 4-GPU server
- Profiling scale: `slice_size_tier=8/4` (max 8 train steps, 4 eval steps) for all bounded captures
- Original Griffin paper: arXiv:2505.05568
- Original Griffin repo: https://github.com/yanxwb/Griffin
