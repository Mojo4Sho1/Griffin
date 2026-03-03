# Profiling Project Checklist

Status values: `not started` | `in progress` | `done`

| Phase | Status | Notes |
|---|---|---|
| Phase 1: Repo reconnaissance (entry points, launch flow, outputs) | done | Initial mapping completed. |
| Phase 2: Stable governance and handoff scaffolding | done | `AGENTS.md`, `handoff/`, and `profiling/` initialized. |
| Phase 2b: Environment and preflight readiness scaffolding | done | `environment.yml` and `profiling/PREFLIGHT.md` added. |
| Phase 2c: Session continuity and asset-status scaffolding | done | `handoff/SESSION_LOG.md` and `profiling/ASSETS_STATUS.md` added. |
| Phase 3: Baseline profiling slice command verification | done | `datasets/single-pretrain-v3` staged for command-path verification; smoke and nsys runs both progress beyond `Graph(args.dataset)` initialization. |
| Phase 4a: Baseline `nsys` run capture (`train`) | in progress | Gate: `>=2` successful `baseline_unannotated` `nsys` slices. Current: `1/2` (`20260302-1637-train-completion-01`). |
| Phase 4b: Baseline `nsys` run capture (`finetune`) | not started | Gate: `>=2` successful `baseline_unannotated` `nsys` slices for finetune path. |
| Phase 4c: Baseline `nsys` run capture (`inference`) | not started | Gate: `>=2` successful `baseline_unannotated` `nsys` slices; canonical path is `hmaintask_combine.py --mode test --loadpath checkpoints/single-sft/best_checkpoint`. |
| Phase 4d: Cross-scenario baseline comparison (`train` vs `finetune` vs `inference`) | not started | Starts only after 4a/4b/4c are done; summarize in `profiling/RESULTS.md`. |
| Phase 5a: Coarse annotation spec (minimal NVTX taxonomy) | not started | Define human-interpretable label taxonomy and insertion points before any annotation code changes. |
| Phase 5b: Coarse annotation insertion (`hmaintask_completion.py`, `hmaintask_combine.py`) | not started | Minimal, reversible NVTX ranges at high-level boundaries only; no model semantic changes. |
| Phase 5c: Annotated validation `nsys` runs | not started | Gate: `>=1` successful `baseline_annotated` `nsys` slice per scenario (`train`, `finetune`, `inference`). |
| Phase 5d: Annotated comparison + hotspot shortlist | not started | Compare annotated traces across scenarios and produce shortlist for targeted deep dives. |
| Phase 6: Hotspot analysis and prioritized optimization candidates | not started | Rank one primary hotspot per scenario from annotated `nsys` evidence. |
| Phase 7: Deep kernel investigation (`ncu` targeted) | not started | Gate: `>=1` successful `ncu_hotspot` slice per scenario after Phase 5d/6 gates are met. |
