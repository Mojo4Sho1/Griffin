# Profiling Project Checklist

Status values: `not started` | `in progress` | `done`

| Phase | Status | Notes |
|---|---|---|
| Phase 1: Repo reconnaissance (entry points, launch flow, outputs) | done | Initial mapping completed. |
| Phase 2: Stable governance and handoff scaffolding | done | `AGENTS.md`, `handoff/`, and `profiling/` initialized. |
| Phase 2b: Environment and preflight readiness scaffolding | done | `environment.yml` and `profiling/PREFLIGHT.md` added. |
| Phase 2c: Session continuity and asset-status scaffolding | done | `handoff/SESSION_LOG.md` and `profiling/ASSETS_STATUS.md` added. |
| Phase 3: Baseline profiling slice command verification | done | `datasets/single-pretrain-v3` staged for command-path verification; smoke and nsys runs both progress beyond `Graph(args.dataset)` initialization. |
| Phase 4: Baseline profiling run capture and summary | in progress | Smoke and `nsys` completion reruns now succeed end-to-end after gather-device fix; next step is extracting a concise artifact-level baseline summary from `20260302-1637-train-completion-01.nsys-rep`. |
| Phase 5: Coarse annotation plan and insertion (minimal/reversible) | not started | Only after baseline profile quality is confirmed. |
| Phase 6: Hotspot analysis and prioritized optimization candidates | not started | Analysis-first; no kernel changes unless requested. |
| Phase 7: Deep kernel investigation (if justified by hotspots) | not started | Requires prior hotspot confirmation. |
