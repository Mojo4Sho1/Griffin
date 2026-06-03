# Experiment Protocols

Detailed technical protocols for each experiment. Read the corresponding experiment brief in `experiments/` before starting. Do not implement these experiments until the preceding experiment's decision gate has been passed.

---

## EXP01A — Source Localization from Existing Artifacts

**This is the default authorized next step. It is strictly read-only.**

**Goal:** Map hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`) and hotspot_2 (`fmha`) launches back to Griffin source code locations, using only existing artifacts (profiling outputs, analysis bundles, Markdown summaries) and read-only code inspection.

### Step 1: Read NVTX structure from profiling

Read `profiling/notebooks/nsys_cross_scenario_dashboard.ipynb` (code inspection only — do not execute). Also inspect existing analysis bundles under `artifacts/profiles/analysis/` (particularly `nvtx_sum.txt` and `cuda_gpu_kern_sum.txt`) to identify:
- Which NVTX labels (`gfm.*`) contain the majority of hotspot_1 kernel time.
- Whether hotspot_1 appears within `gfm.train_step`, `gfm.eval_task`, or elsewhere.
- Whether hotspot_1 launch counts scale with number of eval tasks (consistent with relational schema iteration).

This narrows the source to a specific model phase before reading code.

### Step 2: Read Griffin model code

Start with `hmodel.py`. Look for:
- `torch.mm`, `torch.matmul`, `F.linear`, `nn.Linear`, `einsum` calls.
- Loops over tables, features, schema elements, graph nodes, or relation types.
- Any attention computation that would map to `fmha`.

Then read `hloaderwrapper.py` and the relevant `hmaintask_*.py` entry points for context on how data flows into `hmodel.py`.

### Step 3: Cross-reference with NVTX labels

Map the code paths you identify to the NVTX label boundaries seen in profiling. The NVTX labels were inserted at the boundaries listed in `profiling/RESULTS.md` (result: `gfm-20260303-r01-train-steady-annotated-01`): `gfm.setup`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`.

### Step 4: Form candidate call sites

List specific file:line locations that plausibly produce the small-GEMM launches. For each candidate:
- File path and line number range.
- Which NVTX label context it falls under.
- Which relational structure (table iteration, feature aggregation, attention) it corresponds to.
- Why you believe it maps to hotspot_1 vs hotspot_2.

### Step 5: Record and report

Update `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md` with your findings. Update `VERIFICATION_LEDGER.md` for C-16. Add a `DECISION_LOG.md` entry. Update `STATUS.md`.

### EXP01A Allowed

- Read-only code inspection (grep, find, file reads).
- Reading existing artifacts and notebooks (do not execute notebooks).
- Writing to `docs/research_plan/`.
- Running lightweight shell commands: `find`, `grep`, `ls`, `git status`, `git diff --name-only`.

### EXP01A Disallowed

- Modifying any Griffin source file.
- Adding print statements, logging hooks, or NVTX instrumentation.
- Running profiling jobs, training jobs, or notebooks.
- Writing any script that modifies model behavior.

### EXP01A Decision Gate

- If clear source locations are found → proceed to EXP02 shape census.
- If Griffin's computation is already batched and non-fragmentable → document finding, reassess hypothesis, do not proceed to EXP02 without user discussion.
- **If source location is ambiguous** → stop. Document the ambiguity in `EXP01_SOURCE_LOCALIZATION.md`. Request explicit user approval for EXP01B before any instrumentation.

---

## EXP01B — Optional Targeted Instrumentation Follow-Up

**EXP01B is NOT automatically authorized.**

**EXP01B may only proceed after:**
1. EXP01A is documented as inconclusive in `EXP01_SOURCE_LOCALIZATION.md`.
2. Explicit user approval is recorded in `DECISION_LOG.md`.

**Goal:** Add minimal NVTX ranges to narrow down which code paths produce hotspot_1 launches, then run one bounded re-profile to confirm.

### EXP01B Steps

1. Document the specific ambiguity from EXP01A (which candidate sites are uncertain and why).
2. Obtain explicit user approval. Record approval in `DECISION_LOG.md`.
3. Add the minimum NVTX ranges needed — no broader than necessary to resolve the ambiguity.
4. Run one bounded nsys slice (`slice_size_tier=8/4`). Do not run NCU.
5. Inspect the new NVTX output to resolve the ambiguity.
6. Document all source changes and profiling commands in `EXP01_SOURCE_LOCALIZATION.md`.
7. Update `SESSION_LOG.md`, `DECISION_LOG.md`, and `VERIFICATION_LEDGER.md`.
8. Revert instrumentation or commit it clearly as profiling-only annotation.

### EXP01B Allowed (after approval)

- Minimal NVTX annotations in Griffin source files (profiling-only; no semantic changes).
- One bounded nsys profiling slice.
- Commits labeled as instrumentation-only.

### EXP01B Disallowed

- Changing model semantics, loss functions, attention mechanisms, or data pipeline logic.
- Running multiple profiling chains or NCU captures.
- Treating EXP01B approval as authorization for EXP02 or beyond.

### EXP01B Decision Gate

Same as EXP01A. After EXP01B resolves the ambiguity, the EXP01 decision gate is applied as if EXP01A had succeeded.

---

## EXP02 — Shape Census Protocol

**Goal:** Measure actual GEMM matrix dimensions (M, N, K) at the call sites identified in EXP01.

### Step 1: Confirm EXP01 output

Verify that at least one plausible call site for hotspot_1 is documented in `EXP01_SOURCE_LOCALIZATION.md` before proceeding.

### Step 2: Write a shape-logging script

Create `scripts/exp02_shape_census.py`. This script should:
- Import Griffin model components minimally (no full training run required if possible).
- Run a single forward pass on a small representative input.
- At each EXP01-identified call site, capture (M, N, K) of the GEMM arguments using a PyTorch hook or minimal wrapper.
- Log results to `artifacts/exp02_shape_census.csv`.
- Use `argparse` for dataset/checkpoint paths; no hardcoded paths.

### Step 3: Run the script

Check GPU availability first: `nvidia-smi`
Specify `CUDA_VISIBLE_DEVICES=3` for all runs on this machine.
Run in a tmux session if the forward pass takes more than 5 minutes.

### Step 4: Analyze results

Inspect the shape distribution:
- Are the matrices small (M, N < 128)?
- Are there many distinct shapes?
- Is the K dimension (inner) consistent with a specific embedding dimension?
- Does the shape distribution explain the 32×32 tile dominance?

### Step 5: Record and report

Update `EXP02_SHAPE_CENSUS.md`. Add a `DECISION_LOG.md` entry. Archive the CSV in `artifacts/`.

---

## EXP03 — Packing / Batching Microbenchmark Protocol

**Goal:** Measure whether packing EXP02-shaped GEMMs into fewer calls reduces compute time and improves Waves/SM on this GPU.

### Step 1: Confirm EXP02 output

Verify that `artifacts/exp02_shape_census.csv` exists and shows a meaningful distribution of small shapes.

### Step 2: Write a benchmark script

Create `scripts/exp03_packing_bench.py`. The script should:
- Accept shape parameters (M, N, K, batch size N) via argparse.
- Implement three conditions:
  - (a) Fragmented: N independent `torch.mm(A_i, W_i)` calls.
  - (b) Packed (same-weight): single `torch.mm(A_stacked, W)` where A_stacked = torch.cat(A_i).
  - (c) Batched BMM: `torch.bmm(A_batched, W_batched)`.
  - Optionally: grouped GEMM if available (`torch._grouped_mm`).
- Verify numerical correctness: max absolute difference between fragmented and packed outputs must be < 1e-5.
- Time each condition using `torch.cuda.Event` (not `time.time()`).
- Log results to `artifacts/exp03_bench_results.csv`.

### Step 3: Run with EXP02 shapes

Use `CUDA_VISIBLE_DEVICES=3`. Run with representative shape values from EXP02. Use tmux for safety.

### Step 4: Interpret results

- Is there a ≥1.5× speedup for at least one strategy?
- Does the packed/batched condition improve Waves/SM?
- Is there a shape threshold below which packing helps?

### Step 5: Record and report

Update `EXP03_PACKING_MICROBENCHMARK.md`. Add a `DECISION_LOG.md` entry.

---

## EXP04 — Local Griffin Prototype Protocol

**Goal:** Implement a minimal schema-aware packing change in Griffin's model code and verify correctness + profiling improvement.

### Prerequisites

- EXP01, EXP02, EXP03 all complete with positive decision gates.
- Explicit `DECISION_LOG.md` entry authorizing EXP04.

### Step 1: Commit baseline

Commit the current working state before making any modifications: `git commit -m "EXP04 baseline: before packing prototype"`.

### Step 2: Implement packing at identified sites

Modify only the call sites identified in EXP01 and validated by EXP02/EXP03. Changes should:
- Replace a loop of small GEMMs with a single packed/batched call.
- Preserve exact numerical outputs (test with a fixed seed and assert max delta < 1e-5).
- Not change loss functions, attention mechanisms, or optimizer logic.

### Step 3: Smoke test

Run a smoke (no profiler) slice and confirm: (a) run completes to end, (b) metrics match baseline to within expected variance.

### Step 4: Profile

Run a bounded nsys slice: `CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh` (or equivalent command from `profiling/COMMANDS.md`). Generate analysis bundle. Compare launch count and GPU time share for hotspot_1 against the baseline bundle.

### Step 5: Record and report

Update `EXP04_GRIFFIN_PROTOTYPE.md`. Commit changes. Add `DECISION_LOG.md` entry.

---

## EXP05 — Re-Profile and Research Decision Protocol

**Goal:** Run full realistic-scale profiling on the EXP04 prototype and produce a before/after comparison.

### Prerequisites

- EXP04 complete with positive decision gate.
- Baseline profiles from `gfm-20260304-r02` available for comparison.

### Step 1: Run realistic-scale chains

Follow `profiling/COMMANDS.md`. Use tmux. Target GPU3 (`CUDA_VISIBLE_DEVICES=3`). Run the same chain configuration as the `gfm-20260304-r02` baseline (TR-B1 equivalent for the prototype branch).

### Step 2: Generate analysis bundles

Run `scripts/analyze_nsys_run.sh` for each new run. Add entries to `profiling/RUNS.md`.

### Step 3: Compare

Compute before/after:
- Launch count for hotspot_1 per slice
- GPU time share for hotspot_1
- Wall-time per slice
- Metric values (must match baseline)

### Step 4: Write decision report

In `EXP05_REPROFILE_DECISION.md`, document:
- Quantitative before/after table
- Statistical confidence (is the improvement reproducible across slices?)
- Whether the result supports, weakens, or falsifies the hypothesis

Add final entry to `DECISION_LOG.md`.
