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
| Phase 6a: Coarse annotation spec (minimal NVTX taxonomy) | done | Minimal taxonomy + script-level insertion map documented in `profiling/_PROFILING_GUIDE.md`. |
| Phase 6b: Coarse annotation insertion (`hmaintask_completion.py`, `hmaintask_combine.py`) | done | Coarse ranges inserted (`gfm.setup`, `gfm.mode_test_only`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`) with reversible helper wrapper; syntax sanity check passed. |
| Phase 7: Steady-state annotated profiling capture (final capture set) | done | `TR-SA1` (`20260304-1541-train-annotated-completion-01`), `FT-SA1` (`20260304-1622-finetune-annotated-combine-01`), and `IF-SA1` (`20260304-1652-inference-annotated-combine-01`) are complete with forced-export `nvtx_sum` coverage confirmation; capture gate now evaluates as complete. |
| Phase 8: Human analysis/review gate | in progress | Capture set is complete; next task is to document capture-gate evidence and advance `RV-G1` through human review decisioning. |
| Phase 9: Post-review targeted deep kernel investigation (`ncu`) | not started | Allowed only after Phase 8 review gate is complete and approved. |
| Phase 10: Post-review optimization strategy discussion | not started | Discussion/planning only after capture and review gates are complete. |
