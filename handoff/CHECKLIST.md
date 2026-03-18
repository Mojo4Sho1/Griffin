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
| Phase 3b: Autonomous slice-chaining workflow validation | done | Step-bounded chain runner + summary generation validated (`toychain-model-20260305b` 3/3 model-resume slices; `toychain-state-20260305` 2/2 full-state slices). |
| Phase 3c: Adaptive autonomous-slice policy documentation | done | Campaign + handoff docs now codify adaptive slice depth (`3 -> 5 -> 7 -> +2`), deterministic continuation contract (`slice N+1`), and required per-chain aggregate summary. |
| Phase 4a: Baseline validation `nsys` capture (`train`) | done | Gate met: `2/2` successful short validation slices. |
| Phase 4b: Baseline validation `nsys` capture (`finetune`) | done | Gate met: `2/2` successful short validation slices (`FT-B1`, `FT-B2`). |
| Phase 4c: Baseline validation `nsys` capture (`inference`) | done | Gate met: `2/2` successful short validation slices (`IF-B1`, `IF-B2`). |
| Phase 5: Steady-state unannotated representativeness gate | done | `TR-SU1`, `FT-SU1`, and `IF-SU1` paired windows completed with `representative_pass=true` for all three scenarios. |
| Phase 6a: Coarse annotation spec (minimal NVTX taxonomy) | done | Minimal taxonomy + script-level insertion map documented in `profiling/_PROFILING_GUIDE.md`. |
| Phase 6b: Coarse annotation insertion (`hmaintask_completion.py`, `hmaintask_combine.py`) | done | Coarse ranges inserted (`gfm.setup`, `gfm.mode_test_only`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`) with reversible helper wrapper; syntax sanity check passed. |
| Phase 7: Steady-state annotated profiling capture (final capture set) | done | `TR-SA1` (`20260304-1541-train-annotated-completion-01`), `FT-SA1` (`20260304-1622-finetune-annotated-combine-01`), and `IF-SA1` (`20260304-1652-inference-annotated-combine-01`) are complete with forced-export `nvtx_sum` coverage confirmation; capture gate now evaluates as complete. |
| Phase 8: Human analysis/review gate | done | `RV-G1` decision recorded in `gfm-20260303-r01-review-gate-01`; evidence class is `minimal_staged` (per `profiling/SCALE_PROFILES.md`) and post-review escalation permissions remain disabled. |
| Phase 9: Post-review targeted deep kernel investigation (`ncu`) | in progress | `RV-R2` cross-scenario realistic review PASSED (`gfm-20260304-r02-realistic-review-gate-01`); `ncu_allowed=true`; approved hotspot shortlist: (1) `ampere_sgemm_32x32_sliced1x4_tn`, (2) `fmha_cutlassF_f32_aligned_64x64_rf_sm80`, (3) `ampere_sgemm_32x128_tn`; first realistic-scale `ncu` run pending. |
| Phase 10: Post-review optimization strategy discussion | not started | Discussion/planning only after capture and review gates are complete. |
| Phase 11: Scenario-chain aggregate summary execution discipline | in progress | Scenario-chain summary discipline remains active under `realistic-v2` (single-agent, full-scenario multi-slice `nsys` chains with per-slice analysis bundles and explicit `next_action` handoff states). |
