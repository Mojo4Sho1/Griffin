# EXP03 — Packing / Batching Microbenchmark

**Status:** Not started

---

## Purpose

Demonstrate on a controlled synthetic workload that packing small GEMMs of the shapes observed in EXP02 into a single larger GEMM (or a grouped GEMM call) reduces per-element compute time and improves GPU utilization, without changing numerical output.

---

## Prerequisite Docs / Artifacts

| Required | Where |
|---|---|
| `docs/research_plan/experiments/EXP02_SHAPE_CENSUS.md` | Must be complete with shape distribution |
| `artifacts/exp02_shape_census.csv` | Input shape parameters for the benchmark |
| `docs/research_plan/HYPOTHESIS.md` | Packing/batching/padding terminology |
| `docs/research_plan/GLOSSARY.md` | Definitions of packing strategies |

---

## Allowed Changes

- Write `scripts/exp03_packing_bench.py` (new file, standalone benchmark).
- Run the benchmark with `CUDA_VISIBLE_DEVICES=3` on GPU3.
- Write output CSV to `artifacts/exp03_bench_results.csv`.
- Update this file, `SESSION_LOG.md`, `STATUS.md`, `DECISION_LOG.md`.

## Disallowed Changes

- Do not modify Griffin model code.
- Do not run full training or profiling campaigns.
- Do not use GPU3 for extended benchmark runs without checking `nvidia-smi` first.

---

## Exact Deliverables

1. `scripts/exp03_packing_bench.py` — benchmark with `argparse` for (M, N, K, N_mats) parameters.
2. `artifacts/exp03_bench_results.csv` — timing results for all conditions at all tested shapes.
3. Numerical correctness check: max absolute difference between fragmented and packed must be < 1e-5.
4. Summary: which strategy gives ≥1.5× speedup at EXP02 shapes? At what shape threshold?
5. Updated `EXP03_PACKING_MICROBENCHMARK.md` with findings.
6. `DECISION_LOG.md` entry and `STATUS.md` update.

---

## Benchmark Conditions

| Condition | Description |
|---|---|
| (a) Fragmented | N independent `torch.mm(A_i, W_i)` calls |
| (b) Same-weight packed | Single `torch.mm(A_stacked, W)` where `A_stacked = torch.cat(A_i)` |
| (c) Batched BMM | `torch.bmm(A_batched, W_batched)` |
| (d) Grouped GEMM | `torch._grouped_mm(...)` if available |

Use `torch.cuda.Event` for timing. Report mean over 20 warm-up + 100 timed iterations.

---

## Success Criteria

- At least one packing strategy shows ≥1.5× throughput improvement over fragmented at representative EXP02 shapes.
- Numerical correctness passes (max delta < 1e-5).
- Results are reproducible across two runs.

---

## Decision Gate

- **Clear speedup (≥1.5×) for at least one strategy** → proceed to EXP04.
- **Marginal speedup (1.1–1.5×)** → reassess; consider whether the overall optimization is still worth the implementation complexity; document and discuss before EXP04.
- **No speedup** → fragmentation hypothesis weakened at the GEMM level; investigate whether bottleneck is elsewhere (memory? overhead?); document and reassess.
- **Numerical mismatch** → identify cause; fix before EXP04.

---

## Required Handoff Update

After completing:
1. Fill in Findings below.
2. Add entry to `SESSION_LOG.md`.
3. Add entry to `DECISION_LOG.md`.
4. Update `STATUS.md`.

---

## Findings

*(Fill in after experiment is run)*

### Benchmark Results Summary

| Shape (M, N, K, N) | Fragmented (µs) | Packed (µs) | BMM (µs) | Speedup (packed) | Correctness |
|---|---|---|---|---|---|
| | | | | | |

### Best Strategy

### Decision Gate Outcome
