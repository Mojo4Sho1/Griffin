# Run Scale Profiles

This document is the canonical reference for run-scale semantics in this profiling fork.

It exists so humans can quickly understand what previous runs represent, what qualifies as realistic-scale evidence, and what decisions are valid at each evidence class.

## Why This Document Exists

Campaign `gfm-20260303-r01` was executed with staged/minimal assets to verify command paths, profiler wiring, representativeness mechanics, and NVTX labeling flow. Those runs are valid for pipeline confidence and workflow gating, but they are not treated as production-representative hotspot evidence.

Without explicit run-scale definitions, users can incorrectly compare or over-interpret staged traces.

## Definitions

- `minimal_staged`
  - A bounded, synthetic/minimal setup used to validate profiler workflow and trace health.
- `realistic_scale`
  - A run setup that uses production-equivalent assets and runtime windows intended to reflect real workload behavior.
- `production_equivalent_assets`
  - Dataset and checkpoint assets that reflect the real deployment/training distribution and size (not synthetic or toy staging).
- `iteration`
  - One loader-step unit in the task loop (one `for data in loader` step in train/eval paths).
- `window_warmup_iterations`
  - Number of initial iterations excluded from hotspot stability evaluation.
- `window_profile_iterations`
  - Number of iterations used for profiler-based representativeness and hotspot share calculations.

## What Was Done Previously (Explicit Staged Setup)

### Asset Context
- Dataset: `datasets/single-pretrain-v3` staged minimal synthetic structure for command-path verification.
- Checkpoints: staged/generated bounded checkpoints under:
  - `checkpoints/single-completion/best_checkpoint`
  - `checkpoints/single-sft/best_checkpoint`

### Bounded Command Shape
- Typical run settings in staged campaign used bounded parameters such as:
  - `--maxepoch 1`
  - `--batchsize 64`
  - smoke + `nsys` wrappers
- Scenario commands were from `profiling/COMMANDS.md` and recorded in `profiling/RUNS.md`.

### Representativeness Policy Applied
- Iteration-window policy used:
  - warmup/profile `5/25` (with documented expansion policy if needed).
- Stability checks used:
  - top-3 overlap `>= 2/3`
  - timeshare drift `<= 20%`

### Interpretation Caveat
- Staged campaign hotspot rankings and percentage shares are not assumed production-faithful by default.

## Strict Criteria For Realistic-Scale Runs

A run can be classified as `realistic_scale` only if all items below are satisfied.

1. Asset provenance:
- Must use production-equivalent dataset and checkpoint assets.
- Exact asset paths must be documented in run metadata (`profiling/RUNS.md`).

2. Environment and host guardrails:
- `make profiling-preflight` passes.
- GPU3 occupancy checks pass immediately before run launch.

3. Scenario coverage:
- Run coverage includes `train`, `finetune`, and `inference`, unless any narrowing is explicitly documented with rationale.

4. Runtime/window criteria:
- Target runtime window budget: `60-90` minutes per steady-state run.
- Paired-window representativeness checks must be recorded and evaluated with existing overlap/drift criteria.

5. Analysis artifact requirements:
- Every successful `nsys` run must generate:
  - `artifacts/profiles/analysis/<run_id>/summary.md`
  - `artifacts/profiles/analysis/<run_id>/metrics.json`
  - raw report outputs listed in `profiling/COMMANDS.md`

6. Documentation evidence:
- `profiling/RUNS.md` must include run class and relevant caveat context.
- `profiling/RESULTS.md` must state evidence class and caveats before conclusions.

## Evidence Class Quick Reference

| Run class | Primary purpose | Asset expectation | Allowed decisions | Not allowed decisions |
|---|---|---|---|---|
| `minimal_staged` | Pipeline/profiler/NVTX validation and workflow confidence | Synthetic/minimal staging acceptable | Toolchain health, label coverage, run reproducibility in staged setup | Production hotspot ranking claims, optimization prioritization for real workloads |
| `realistic_scale` | Representative hotspot and phase-behavior evidence | Production-equivalent assets required | Hotspot prioritization, realistic review decisions, post-review `ncu` targeting | None beyond global policy gates (still requires review completion before `ncu`) |

## Transition Workflow

1. Complete staged campaign review (`RV-G1`) and document outcome.
2. Start a realistic-scale campaign with explicit run class and asset provenance.
3. Complete realistic-scale baseline/steady-state/annotated captures.
4. Perform realistic-scale review gate and approve hotspot shortlist.
5. Run targeted `ncu` only after realistic review approval.

`ncu` target selection should be based on realistic-scale review outcomes, not solely staged hotspot ordering.

## Worked Examples

### Staged Campaign Example (Historical)
- campaign: `gfm-20260303-r01`
- representative staged run IDs:
  - `20260303-2049-train-completion-01`
  - `20260303-2058-finetune-combine-01`
  - `20260303-2134-inference-combine-01`

### Realistic Campaign Asset-Provenance Template

Use this snippet in future `profiling/RUNS.md` entries:

```markdown
- run_class: realistic_scale
- asset_provenance:
  - dataset_path: <production_equivalent_dataset_path>
  - checkpoint_path: <production_equivalent_checkpoint_path_or_na>
  - rationale: Assets reflect production distribution/scale for this scenario.
- runtime_window_target_minutes: 60-90
```

