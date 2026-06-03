# Artifact Index

Map of important files and directories in this repository. Verify existence with `ls` before relying on an entry.

---

## Research Documentation (New Campaign)

| Path | Purpose |
|---|---|
| `docs/research_plan/README.md` | Entry point — read first |
| `docs/research_plan/STATUS.md` | Current phase, next action, blockers |
| `docs/research_plan/CAMPAIGN_PLAN.md` | Staged experiment sequence and decision gates |
| `docs/research_plan/HYPOTHESIS.md` | Precise research framing |
| `docs/research_plan/EVIDENCE_SUMMARY.md` | Profiling facts vs interpretations |
| `docs/research_plan/ARTIFACT_INDEX.md` | This file |
| `docs/research_plan/DECISION_LOG.md` | Append-only research decisions |
| `docs/research_plan/SESSION_LOG.md` | Append-only session history |
| `docs/research_plan/HANDOFF_TEMPLATE.md` | Template for end-of-experiment reports |
| `docs/research_plan/EXPERIMENT_PROTOCOLS.md` | Detailed protocols for EXP01A, EXP01B, EXP02–EXP05 |
| `docs/research_plan/GLOSSARY.md` | Terminology definitions |
| `docs/research_plan/VERIFICATION_LEDGER.md` | Claim-by-claim provenance tracker (17 claims as of EXP00 housekeeping) |
| `docs/research_plan/experiments/EXP0*.md` | Per-experiment briefs |
| `docs/research_plan/archive/agent_trace_legacy.md` | Archived copy of old `docs/agent_trace.md` |

---

## Profiling Documentation

| Path | Purpose |
|---|---|
| `profiling/RESULTS.md` | Versioned profiling results and gate decisions — primary evidence source |
| `profiling/RUNS.md` | Run registry (all attempts, all scenarios) |
| `profiling/NCU_COVERAGE.md` | NCU section coverage tracker; TR-N1 import status |
| `profiling/COMMANDS.md` | Canonical command patterns and guardrails |
| `profiling/SCALE_PROFILES.md` | Run-scale definitions (staged vs realistic) |
| `profiling/MANUAL_ANALYSIS.md` | Manual analysis playbook |
| `profiling/_PROFILING_GUIDE.md` | Full profiling guide |
| `profiling/CAMPAIGN_PLAN.md` | The older profiling campaign plan (separate from `docs/research_plan/CAMPAIGN_PLAN.md`) |

---

## Notebooks

| Path | Purpose |
|---|---|
| `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` | Cross-scenario NSYS dashboard: kernel time-share, launch count, NVTX, advisor summary across train/finetune/inference. Reads from `artifacts/profiles/analysis/*/metrics.json`. Created 2026-06-03. |
| `profiling/notebooks/ncu_sqlite_review.ipynb` | NCU deep-dive for hotspot_1: all 8 core sections from SQLite. Reads from `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite`. |

---

## Raw Profile Artifacts

| Path | Contents |
|---|---|
| `artifacts/profiles/nsys/` | Raw `.nsys-rep` trace files (one per run) |
| `artifacts/profiles/ncu/` | Raw `.ncu-rep` report files (one per run); TR-N1 is 7.8 GB (legacy oversized) |
| `artifacts/profiles/analysis/` | Per-run analysis bundles (see below) |
| `artifacts/profiles/dashboard_exports/` | **Planned / not yet generated.** Future exports from `nsys_cross_scenario_dashboard.ipynb` should include: `cross_scenario_kernel_summary.csv`, `cross_scenario_launch_counts.csv`, `cross_scenario_top3_validation.csv`, `optimization_opportunity_matrix.csv`, `advisor_summary.md`. Once generated, these will upgrade several `Markdown-reported` claims in `VERIFICATION_LEDGER.md` to `Verified by exported notebook output`. |

### Analysis Bundle Structure

Each bundle at `artifacts/profiles/analysis/<run_id>/` contains:

```
summary.md                  — Human-readable summary
metrics.json                — Machine-readable metric snapshot
cuda_gpu_kern_sum.txt       — Top GPU kernel summary
cuda_api_sum.txt            — CUDA API call summary
nvtx_sum.txt                — NVTX range summary
ncu_analysis.sqlite         — NCU structured bundle (TR-N1 only, as of EXP00)
ncu_summary.md              — NCU human-readable summary
ncu_metrics.json            — NCU metrics JSON
ncu_progress.log            — Long-running import log
sections/                   — Per-section CSV sidecars
    <section_id>.csv
```

### Key Analysis Bundles

| Run ID | Scenario | Stage | Contents |
|---|---|---|---|
| `20260304-1541-train-annotated-completion-01` | train | steady_annotated | NSYS bundle, NVTX confirmed |
| `20260304-1622-finetune-annotated-combine-01` | finetune | steady_annotated | NSYS bundle, NVTX confirmed |
| `20260304-1652-inference-annotated-combine-01` | inference | steady_annotated | NSYS bundle, NVTX confirmed |
| `20260312-1537-trb1-realistic-20260312a-s03` | train | realistic baseline | NSYS bundle |
| `20260306-1553-ftb1-realistic-20260306a-s03` | finetune | realistic baseline | NSYS bundle |
| `20260306-1652-ifb1-realistic-20260306b-s03` | inference | realistic baseline | NSYS bundle |
| `20260319-1514-train-completion-01` | train | NCU hotspot_1 | Full NCU bundle + SQLite (7.8 GB raw) |

---

## Scripts

| Path | Purpose |
|---|---|
| `scripts/profile_baseline.sh` | Run a baseline bounded NSYS slice |
| `scripts/run_slice_chain.sh` | Run a multi-slice chained NSYS capture |
| `scripts/analyze_nsys_run.sh` | Generate per-run analysis bundle from NSYS artifact |
| `scripts/run_ncu_hotspot.sh` | Run a targeted NCU capture for an approved hotspot |
| `scripts/analyze_ncu_run.py` | Import NCU sections into SQLite and generate structured bundle |
| `scripts/archive_chain_summary.sh` | Archive a completed chain summary |

---

## Griffin Model Source (Do Not Modify Until EXP04)

| Path | Purpose |
|---|---|
| `hmodel.py` | Core Griffin model |
| `hloaderwrapper.py` | Data loader wrapper |
| `hmaintask_completion.py` | Pretraining entry point |
| `hmaintask_combine.py` | Finetuning/transfer entry point |
| `hdataset.py` | Dataset pipeline |
| `hFloatEmb.py` | Float embedding |

---

## Old Profiling Campaign (Do Not Modify)

| Path | Note |
|---|---|
| `handoff/CHECKLIST.md` | Old campaign checklist — do not modify |
| `handoff/CURRENT_STATUS.md` | Old campaign status — do not modify |
| `handoff/NEXT_TASK.md` | Old campaign next task — do not modify |
| `handoff/SESSION_LOG.md` | Old campaign session log — do not modify |

---

## Legacy Documentation (Archived)

| Path | Note |
|---|---|
| `docs/research_plan/archive/agent_trace_legacy.md` | Archived full text of the old `docs/agent_trace.md`. The root file was deleted during EXP00 housekeeping (2026-06-03) after being summarized into `SESSION_LOG.md`. Do not use as canonical. |
