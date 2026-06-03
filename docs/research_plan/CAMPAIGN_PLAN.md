# Research Campaign Plan

This document defines the staged experiment sequence, success criteria, and decision gates for the Griffin fragmentation-and-packing research campaign.

---

## EXP00 — Repo State Assessment and Research Documentation Setup

**Goal:** Establish durable human- and agent-readable documentation of the current research state so future Claude instances can continue without context loss.

**Inputs:**
- Existing repo files: `profiling/RESULTS.md`, `profiling/NCU_COVERAGE.md`, notebooks, `docs/agent_trace.md`, root `README.md`

**Allowed changes:** Create new files under `docs/research_plan/`. Summarize and archive `docs/agent_trace.md`.

**Disallowed changes:** Modify Griffin source code, `handoff/`, `profiling/` files, or run any profiling jobs.

**Expected outputs:** All files under `docs/research_plan/` created and populated.

**Success criteria:** A fresh Claude instance can read `README.md`, `STATUS.md`, `CAMPAIGN_PLAN.md` and understand the project, evidence, and next step without any additional context.

**Decision gate:** Proceed to EXP01 once documentation is in place and current repo state is accurately described.

---

## EXP01A — Source Localization from Existing Artifacts (Default Next Step)

**EXP01A is the default and currently authorized next step. It is strictly read-only.**

**Goal:** Identify which specific Griffin source code locations produce the dominant small-GEMM launches observed in profiling. Map hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`) and hotspot_2 (`fmha_cutlassF_f32_aligned_64x64_rf_sm80`) back to model/data-pipeline call sites, using only existing artifacts and code inspection.

**Inputs:**
- `profiling/RESULTS.md` — hotspot identities and launch counts
- `hmodel.py`, `hloaderwrapper.py`, `hmaintask_completion.py`, `hmaintask_combine.py`, `hdataset.py`
- `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` — NVTX structure showing which model phases contain the hotspots
- `profiling/notebooks/ncu_sqlite_review.ipynb` — launch-level NCU data for hotspot_1
- `docs/research_plan/VERIFICATION_LEDGER.md` — claim provenance tracker

**Allowed changes:**
- Read-only code inspection (grep, find, file reads).
- Reading existing artifacts (analysis bundles, RESULTS.md, notebooks).
- Write experiment report at `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`.
- Write documentation updates under `docs/research_plan/`.

**Disallowed in EXP01A:**
- Do not modify any Griffin source files.
- Do not add NVTX instrumentation or print statements.
- Do not run profiling jobs, notebooks, or training jobs.
- Do not write any script that modifies model behavior.

**Expected outputs:**
- List of call sites responsible for hotspot_1 (small-GEMM) launches, with file and line numbers.
- List of call sites responsible for hotspot_2 (fmha) launches.
- Identification of which relational structure (table iteration, feature aggregation, attention over schema elements) drives the fragmentation.
- Updated `EXP01_SOURCE_LOCALIZATION.md`.
- DECISION_LOG.md entry.
- VERIFICATION_LEDGER.md updates for C-16 (source locations).

**Success criteria:** At least one plausible source location identified for each hotspot, supported by code reading and cross-referenced with NVTX labels from profiling.

**Decision gate:**
- If clear source locations are found → proceed to EXP02 shape census, targeting those sites.
- If Griffin's computation turns out to be non-fragmentable by schema (e.g., all ops are already batched) → document finding and reassess hypothesis.
- **If source location is ambiguous after EXP01A** → stop. Do not add instrumentation. Request explicit user approval for EXP01B before proceeding.

---

## EXP01B — Optional Targeted Instrumentation Follow-Up (Not Automatically Authorized)

**EXP01B is only executed if EXP01A cannot localize the hotspot with sufficient confidence.**

**EXP01B requires explicit user approval before any instrumentation changes are made.**

**Goal:** If EXP01A is inconclusive, add minimal targeted NVTX ranges to narrow down which code paths produce hotspot_1 launches, then run one bounded re-profile to confirm.

**Trigger condition:** EXP01A completes but cannot identify a plausible call site with sufficient confidence. Ambiguity must be documented in `EXP01_SOURCE_LOCALIZATION.md` and approved.

**Allowed in EXP01B (after explicit approval only):**
- Add minimal NVTX instrumentation ranges to Griffin source files at identified candidate sites.
- Run one bounded profiling slice (nsys only; no NCU).
- Source changes must be limited to NVTX annotation; no semantic model changes.
- All source changes and profiling commands must be documented.

**Disallowed in EXP01B:**
- Do not change model semantics, loss functions, attention mechanisms, or data pipeline logic.
- Do not run multiple profiling chains.
- Do not run NCU captures.

**Required documentation updates:**
- `docs/research_plan/SESSION_LOG.md`
- `docs/research_plan/DECISION_LOG.md` (must include the approval record)
- `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`

**Decision gate:** Same as EXP01A.

---

## EXP02 — Shape Census

**Goal:** Measure the actual matrix dimensions produced at the identified call sites during a representative Griffin forward pass. Determine whether the shapes are consistent with the small-tile GEMM kernels seen in profiling.

**Inputs:**
- EXP01 output: identified call sites
- Griffin model code, dataset, checkpoints
- `profiling/SCALE_PROFILES.md` for run-scale guidance

**Allowed changes:** Add lightweight shape-logging hooks (print or CSV) to identified call sites in a separate script under `scripts/`. Do not modify `hmodel.py` or training entry points directly. If a minimal instrumented copy is needed, create it under `scripts/`.

**Disallowed changes:** Do not modify core model logic. Do not run full training or profiling campaigns.

**Expected outputs:**
- CSV or table of observed matrix shapes (M, N, K) at each identified call site per forward pass
- Frequency distribution of shapes
- Comparison against hotspot_1 tile size (`32x32`) to confirm or reject the shape-fragmentation hypothesis
- Updated `EXP02_SHAPE_CENSUS.md`
- DECISION_LOG.md entry

**Success criteria:** Observed shapes are consistent with the profiled small-tile GEMM kernel. The distribution shows a large number of distinct small shapes, not a few large uniform shapes.

**Decision gate:**
- If shapes are small and diverse → hypothesis is supported; proceed to EXP03.
- If shapes are large or uniform → the fragmentation hypothesis is weakened; reassess before EXP03.
- If shapes are large but few → packing may already be happening; document and reassess.

---

## EXP03 — Packing / Batching Microbenchmark

**Goal:** Demonstrate on a controlled synthetic workload that packing small GEMMs of the shapes observed in EXP02 into a single larger GEMM (or a grouped GEMM call) reduces per-element compute time and improves Waves/SM, without changing numerical output.

**Inputs:**
- EXP02 output: shape distribution
- PyTorch, CUDA, optionally `torch._grouped_mm` or `torch.baddbmm`
- No Griffin model code in this experiment

**Allowed changes:** Write a standalone microbenchmark script under `scripts/exp03_packing_bench.py`. No Griffin model modifications.

**Disallowed changes:** Do not modify Griffin training or model code. Do not use GPU3 for extended runs without checking availability (`nvidia-smi`).

**Expected outputs:**
- Benchmark comparing: (a) N independent small GEMMs of EXP02 shapes, (b) a single padded GEMM, (c) a grouped GEMM call (if available)
- Timing results (microseconds), Waves/SM or occupancy estimates, numerical correctness check
- CSV of results logged to `artifacts/` or `scripts/` output
- Updated `EXP03_PACKING_MICROBENCHMARK.md`
- DECISION_LOG.md entry

**Success criteria:** At least one packing strategy shows ≥1.5× speedup over the fragmented baseline at realistic EXP02 shapes, with numerically identical results.

**Decision gate:**
- If packing shows clear speedup → proceed to EXP04 Griffin prototype.
- If packing shows marginal or no speedup → reassess approach; consider padding-only vs true packing; document and discuss before EXP04.
- If packing changes numerical output → identify why and resolve before EXP04.

---

## EXP04 — Local Griffin Prototype

**Goal:** Implement a minimal schema-aware packing or batching change in a local copy of Griffin's model code. Verify that training/inference runs to completion, produces matching metrics, and reduces the small-GEMM launch count in profiling.

**Inputs:**
- EXP01 source locations, EXP02 shape census, EXP03 microbenchmark results
- Griffin source: `hmodel.py`, relevant call sites
- `profiling/COMMANDS.md` for profiling workflow

**Allowed changes:** Modify Griffin model code only at identified call sites. Run bounded profiling slices (smoke + nsys). Record changes in git.

**Disallowed changes:** Do not change model semantics. Do not modify loss functions, attention mechanisms, or dataset pipeline in ways that could affect accuracy.

**Expected outputs:**
- Modified Griffin code with schema-aware packing/batching at identified sites
- Smoke run confirming training/inference completes and metrics match baseline
- Profiling comparison: launch count and GPU time share before vs after
- Updated `EXP04_GRIFFIN_PROTOTYPE.md`
- DECISION_LOG.md entry

**Success criteria:** Modified Griffin runs to completion with matching metrics. Launch count for hotspot_1 decreases. GPU time share for hotspot_1 decreases or wall-time improves.

**Decision gate:**
- If metrics match and profiling improves → proceed to EXP05 re-profile and decision.
- If metrics match but profiling is unchanged → investigate why packing is not reducing launch count; reassess.
- If metrics diverge → identify the semantic change and fix before proceeding.

---

## EXP05 — Re-profile and Research Decision

**Goal:** Run the full realistic-scale profiling pipeline on the EXP04 prototype and produce a structured before/after comparison report. Make a final research decision: publish, extend, or abandon the optimization direction.

**Inputs:**
- EXP04 modified Griffin code
- Existing baseline profiles from campaign `gfm-20260304-r02`
- `profiling/COMMANDS.md`, `profiling/SCALE_PROFILES.md`

**Allowed changes:** Run profiling campaigns on GPU3. Modify `profiling/RESULTS.md` with new findings. Update `docs/research_plan/DECISION_LOG.md`.

**Disallowed changes:** Do not force-push or overwrite existing baseline artifacts.

**Expected outputs:**
- New profiling run IDs in `profiling/RUNS.md`
- New result entries in `profiling/RESULTS.md` comparing baseline vs prototype
- Before/after table: launch counts, GPU time share, wall-time
- Updated `EXP05_REPROFILE_DECISION.md`
- Final research decision in DECISION_LOG.md

**Success criteria:** Clear before/after comparison with quantified improvement or a documented negative result. Either outcome is a valid research finding.

**Decision gate:**
- If improvement is clear and reproducible → write up findings for publication or further development.
- If improvement is marginal → document tradeoffs and decide whether further optimization is worth pursuing.
- If result is negative → document the falsified hypothesis and redirect research.
