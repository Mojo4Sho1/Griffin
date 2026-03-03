# Profiling Project Checklist

Status values: `not started` | `in progress` | `done`

Policy gate: no optimization recommendations are permitted before Phase 8 (`Human analysis/review`) is complete.

| Phase | Status | Notes |
|---|---|---|
| Phase 1: Repo reconnaissance (entry points, launch flow, outputs) | done | Initial mapping completed. |
| Phase 2: Stable governance and handoff scaffolding | done | `AGENTS.md`, `handoff/`, and `profiling/` initialized. |
| Phase 2b: Environment and preflight readiness scaffolding | done | `environment.yml` and `profiling/PREFLIGHT.md` added. |
| Phase 2c: Session continuity and asset-status scaffolding | done | `handoff/SESSION_LOG.md` and `profiling/ASSETS_STATUS.md` added. |
| Phase 3: Baseline validation command-path verification (short slices) | done | Validation-only scope; confirms profiling pipeline and command/runtime health. |
| Phase 4a: Baseline validation `nsys` capture (`train`) | done | Gate met: `2/2` successful short validation slices. |
| Phase 4b: Baseline validation `nsys` capture (`finetune`) | done | Gate met: `2/2` successful short validation slices (`FT-B1`, `FT-B2`). |
| Phase 4c: Baseline validation `nsys` capture (`inference`) | done | Gate met: `2/2` successful short validation slices (`IF-B1`, `IF-B2`). |
| Phase 5: Steady-state unannotated representativeness gate | done | `TR-SU1`, `FT-SU1`, and `IF-SU1` paired windows completed with `representative_pass=true` for all three scenarios. |
| Phase 6a: Coarse annotation spec (minimal NVTX taxonomy) | not started | Define human-readable labels and insertion points before code edits. |
| Phase 6b: Coarse annotation insertion (`hmaintask_completion.py`, `hmaintask_combine.py`) | not started | Minimal, reversible NVTX ranges at high-level boundaries only; no model semantic changes. |
| Phase 7: Steady-state annotated profiling capture (final capture set) | not started | Capture complete only after baseline + steady-state (unannotated + annotated) rows are finished or documented as non-actionable blockers. |
| Phase 8: Human analysis/review gate | not started | Review captured logs/results; no optimization recommendations before this phase is complete. |
| Phase 9: Post-review targeted deep kernel investigation (`ncu`) | not started | Allowed only after Phase 8 review gate is complete and approved. |
| Phase 10: Post-review optimization strategy discussion | not started | Discussion/planning only after capture and review gates are complete. |
