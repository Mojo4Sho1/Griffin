# EXP01B Targeted Hotspot Confirmation Report

**Status:** Complete  
**Date:** 2026-06-03  
**Author:** Claude (automated)  
**Campaign:** gfm-20260304-r02 (confirmation supplement)  
**Run ID:** `exp01b-nvtx-confirm-20260603-2100`  
**Prior report:** [EXP01A Source Localization Report](EXP01A_SOURCE_LOCALIZATION_REPORT.md)

---

## 1. Executive Summary

EXP01B added fine-grained environment-gated NVTX ranges to the suspected hotspot source regions in `hmodel.py` and ran one bounded Nsight Systems capture. Kernel-by-NVTX time-range analysis of the resulting trace confirms the EXP01A localization at the sub-module level:

- **hotspot_2 (fmha):** 100% of all 2,420 fmha launches fall inside `SelfAverageAggregator.crossattention` or `SelfAttentionAggregator.crossattention` ranges. **Strong confirmation.**
- **hotspot_1 (sgemm_32x32):** 55.1% of hotspot_1 GPU time is captured inside aggregator NVTX ranges. The remaining 44.9% falls in uninstrumented but expected regions (GriffinMod MLP/lintask layers and backward-pass GEMMs). **Partial confirmation; consistent with EXP01A.**
- **linq layers** contribute materially to hotspot_1: `SelfAttentionAggregator.linq` accounts for 5.8% of total hotspot_1 GPU time (10.5% of the instrumented fraction).
- **RMPNN.rellin** cannot be assessed: the capture used `hop=0`, so all edge_index arrays were `None` or empty and the RMPNN.rellin NVTX range never fired (0 instances).
- **Decision:** Proceed to EXP02 shape census. Source localization is confirmed at the sub-module level. EXP02 primary targets remain `hmodel.py:343–369` (per-node-type loop) and `hmodel.py:168` (RMPNN.rellin, must use hop ≥ 1).

---

## 2. Why EXP01B Was Run

EXP01A completed source localization through read-only artifact inspection and code reading. STATUS.md (written by the EXP01A session) concluded EXP01B was not required. The user explicitly authorized EXP01B as an additional direct confirmation step before proceeding to EXP02, overriding the prior EXP01A session's recommendation.

The explicit user authorization satisfies the CAMPAIGN_PLAN.md requirement: "EXP01B requires explicit user approval before any instrumentation changes are made."

This run did not change the EXP01A decision gate outcome (EXP02 remains the correct next step). It adds direct NVTX evidence to supplement the EXP01A inference-based localization.

---

## 3. Files Changed

| File | Change | Type |
|---|---|---|
| `hmodel.py` | Added `_EXP01B_NVTX` flag + `_nvtx` context manager class (lines 13–29) | Instrumentation-only |
| `hmodel.py` | Added `_nvtx` ranges to `SelfAverageAggregator.forward()` | Instrumentation-only |
| `hmodel.py` | Added `_nvtx` ranges to `SelfAttentionAggregator.forward()` | Instrumentation-only |
| `hmodel.py` | Added `_nvtx` range to `RMPNN.forward()` (non-degenerate path only) | Instrumentation-only |

No model semantics, tensor shapes, loss functions, or attention mechanisms were changed. The instrumentation is a pure no-op when `GFM_EXP01B_NVTX` is not set to `1`.

---

## 4. Exact Instrumentation Added

### Helper (hmodel.py lines 13–29)

```python
# ---------------------------------------------------------------------------
# EXP01B: Environment-gated NVTX instrumentation helper
# Enable with: GFM_EXP01B_NVTX=1  (no-op when unset or CUDA unavailable)
# ---------------------------------------------------------------------------
_EXP01B_NVTX = (
    os.environ.get("GFM_EXP01B_NVTX", "0") == "1"
    and torch.cuda.is_available()
)

class _nvtx:
    """Lightweight NVTX push/pop context manager, active only when _EXP01B_NVTX is True."""
    __slots__ = ("_label",)
    def __init__(self, label: str) -> None: self._label = label
    def __enter__(self):
        if _EXP01B_NVTX: torch.cuda.nvtx.range_push(self._label)
    def __exit__(self, *_):
        if _EXP01B_NVTX: torch.cuda.nvtx.range_pop()
```

The `_EXP01B_NVTX` flag is evaluated once at module import time, so there is zero overhead per call when the env var is not set.

### Instrumentation Table

| Label | File | Region | Lines (approx, post-edit) | Enabled by env var? | Notes |
|---|---|---|---|---|---|
| `gfm.exp01b.SelfAverageAggregator.forward` | `hmodel.py` | Entire `SelfAverageAggregator.forward()` body | 48–59 | Yes (`GFM_EXP01B_NVTX=1`) | Outer wrapper; contains crossattention + linq sub-ranges |
| `gfm.exp01b.SelfAverageAggregator.crossattention` | `hmodel.py` | `self.crossattention(...)` call inside forward | 50–57 | Yes | Sub-range of .forward |
| `gfm.exp01b.SelfAverageAggregator.linq` | `hmodel.py` | `self.linq(ret)` call at end of forward | 58–59 | Yes | Sub-range of .forward; includes return |
| `gfm.exp01b.SelfAttentionAggregator.forward` | `hmodel.py` | Entire `SelfAttentionAggregator.forward()` body | 97–111 | Yes | Outer wrapper; contains crossattention + linq sub-ranges |
| `gfm.exp01b.SelfAttentionAggregator.crossattention` | `hmodel.py` | `self.crossattention(...)` call inside forward | 101–108 | Yes | Sub-range of .forward |
| `gfm.exp01b.SelfAttentionAggregator.linq` | `hmodel.py` | `linq_val = self.linq(tar)` inside forward | 109–110 | Yes | Sub-range of .forward; excludes `ret * linq_val` multiply |
| `gfm.exp01b.RMPNN.rellin` | `hmodel.py` | `self.rellin(edge_attr)` — non-degenerate RMPNN path | ~195 | Yes | Only fires when `edge_index is not None and len > 0` |

---

## 5. Exact Profiling Commands Run

### Smoke test (no profiler, instrumentation health check)

```bash
CUDA_VISIBLE_DEVICES=3 GFM_EXP01B_NVTX=1 \
scripts/profile_baseline.sh smoke \
  exp01b-nvtx-smoke-20260603-2100 \
  hmaintask_completion.py \
  datasets/single-pretrain-v3-hf \
  logs/prof exp01b-smoke \
  -- \
  --savepath checkpoints/single-completion \
  --maxepoch 1 --max_train_steps 4 --max_eval_steps 2 \
  --batchsize 64 --eval_per_epoch 1 \
  --hop 0 --fanout 10 --fewshotfanout 0 \
  --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

Result: completed without error; model metrics normal.

### Bounded nsys capture (EXP01B confirmation)

```bash
CUDA_VISIBLE_DEVICES=3 GFM_EXP01B_NVTX=1 \
scripts/profile_baseline.sh nsys \
  exp01b-nvtx-confirm-20260603-2100 \
  hmaintask_completion.py \
  datasets/single-pretrain-v3-hf \
  logs/prof exp01b-nvtx-nsys \
  -- \
  --savepath checkpoints/single-completion \
  --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 \
  --batchsize 64 --eval_per_epoch 1 \
  --hop 0 --fanout 10 --fewshotfanout 0 \
  --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

### Analysis bundle generation

```bash
scripts/analyze_nsys_run.sh --run-id exp01b-nvtx-confirm-20260603-2100
```

### Kernel-by-NVTX SQLite queries (run post-capture)

Time-range join: `CUPTI_ACTIVITY_KIND_KERNEL.start >= NVTX_EVENTS.start AND end <= NVTX_EVENTS.end`, filtered to `gfm.exp01b.*` labels.

---

## 6. Run IDs and Artifact Paths

| Artifact | Path |
|---|---|
| Confirmation nsys trace | `artifacts/profiles/nsys/exp01b-nvtx-confirm-20260603-2100.nsys-rep` |
| nsys SQLite (generated by analyze script) | `artifacts/profiles/nsys/exp01b-nvtx-confirm-20260603-2100.sqlite` |
| Analysis bundle | `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/` |
| NVTX range summary (raw text) | `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/nvtx_sum.txt` |
| Kernel summary (raw text) | `artifacts/profiles/analysis/exp01b-nvtx-confirm-20260603-2100/cuda_gpu_kern_sum.txt` |

**Note on summary.md / metrics.json:** The `analyze_nsys_run.sh` parser did not successfully parse the text output for this run (`nvtx_coverage_status: inconclusive`). The raw text files and direct SQLite queries are the authoritative data source. This is a known parser limitation of the analysis script and does not indicate a problem with the trace.

---

## 7. NVTX Range Summary

From `nvtx_sum.txt`:

| NVTX Label | Instances | Total (ms) | Avg (ms) |
|---|---:|---:|---:|
| `gfm.eval_task` | 153 | 62,455 | 408.2 |
| `gfm.train_epoch` | 1 | 43,020 | 43,020 |
| `gfm.final_test_pass` | 1 | 21,291 | 21,291 |
| `gfm.setup` | 1 | 2,257 | 2,257 |
| `gfm.exp01b.SelfAttentionAggregator.forward` | 1,815 | 800.1 | 0.441 |
| `gfm.exp01b.SelfAttentionAggregator.crossattention` | 1,815 | 686.7 | 0.378 |
| `gfm.train_step` | 8 | 553.7 | 69.2 |
| `gfm.exp01b.SelfAverageAggregator.forward` | 605 | 553.5 | 0.915 |
| `gfm.exp01b.SelfAverageAggregator.crossattention` | 605 | 509.4 | 0.842 |
| `gfm.checkpoint_io` | 3 | 466.6 | 155.5 |
| `gfm.exp01b.SelfAttentionAggregator.linq` | 1,815 | 71.2 | 0.039 |
| `gfm.exp01b.SelfAverageAggregator.linq` | 605 | 33.9 | 0.056 |
| `CCCL:cub::DeviceSelect::Flagged` | 1,194 | 16.9 | 0.014 |
| `CCCL:cub::DeviceReduce::Sum` | 1,194 | 13.8 | 0.012 |
| `gfm.exp01b.RMPNN.rellin` | **0** | — | — |

**Instance count analysis (T=1 confirmation):**
- SelfAverageAggregator.forward: 605 instances → layer i=0 only
- SelfAttentionAggregator.forward: 1,815 instances → layers i=1,2,3 (×3)
- Ratio: 1,815 / 605 = 3.0 = num_mp − 1 layers with SelfAttentionAggregator
- Total aggregation calls per GriffinMod forward pass: (605 + 1815) / 605 = 4.0 → T=1 node type per forward pass (confirms EXP01A estimate)
- Forward passes per eval_task: 605 / 153 = 3.95 ≈ 4 batches per eval_task (confirms CCCL-based estimate)

**RMPNN.rellin:** 0 instances. At hop=0, all `edge_index` arrays are None or empty. The RMPNN non-degenerate path (`edge_index is not None and shape[1] > 0`) was never reached in this capture.

---

## 8. Top GPU Kernels (Overall)

From `cuda_gpu_kern_sum.txt`:

| Rank | Kernel | Launches | Total (ms) | GPU Time % | Avg (µs) |
|---:|---|---:|---:|---:|---:|
| 1 | `ampere_sgemm_32x32_sliced1x4_tn` (**hotspot_1**) | 22,731 | 137.1 | 30.4% | 6.03 |
| 2 | `fmha_cutlassF_f32_aligned_64x64_rf_sm80` (**hotspot_2**) | 2,420 | 56.3 | 12.5% | 23.3 |
| 3 | `ampere_sgemm_32x128_tn` (**hotspot_3**) | 1,370 | 42.4 | 9.4% | 30.9 |

These launch counts match the realistic-scale campaign exactly (22,731 and 2,420 per slice at slice_size_tier=8/4). The kernel rankings and percentages are consistent with prior profiling.

---

## 9. Hotspot_1 Confirmation Table

**Kernel:** `ampere_sgemm_32x32_sliced1x4_tn` | **Total:** 22,731 launches, 137.1 ms GPU time

| NVTX Range | Launches | GPU Time (ms) | % of Total h1 Time | Attribution |
|---|---:|---:|---:|---|
| `SelfAttentionAggregator.crossattention` | 5,436 | 46.85 | 34.2% | QKV + output projection GEMMs; cross-attention layers i=1,2,3 |
| `SelfAverageAggregator.crossattention` | 1,216 | 20.66 | 15.1% | QKV + output projection GEMMs; self-average layer i=0 |
| `SelfAttentionAggregator.linq` | 1,806 | 7.97 | 5.8% | Post-attention output projection (SelfAttentionAggregator) |
| `SelfAverageAggregator.linq` | 2 | 0.04 | ~0% | Post-attention output projection (SelfAverageAggregator); near-zero contribution |
| **Total inside EXP01B ranges** | **8,460** | **75.52** | **55.1%** | |
| Outside EXP01B ranges | 14,271 | 61.58 | 44.9% | Expected: GriffinMod MLP/mlp2/lintask (forward) + backward-pass GEMMs; not instrumented |
| **RMPNN.rellin** | 0 | 0 | 0% | **Cannot assess at hop=0** (no edges in this capture) |

**Confirmation level:** Partial confirmation.

- The crossattention regions (combined) account for **49.3% of total hotspot_1 GPU time**.
- The aggregator forward regions (combined) account for **55.1% of total hotspot_1 GPU time**.
- The remaining 44.9% is in uninstrumented regions that are consistent with expected GriffinMod MLP layers and backward-pass GEMMs — not a contradiction of the EXP01A localization.
- The instrumentation does not cover the GriffinMod-level MLP/lintask layers or backward passes. Those contribute sgemm_32x32 launches but were not instrumented in EXP01B.

---

## 10. Hotspot_2 Confirmation Table

**Kernel:** `fmha_cutlassF_f32_aligned_64x64_rf_sm80` | **Total:** 2,420 launches, 56.3 ms GPU time

| NVTX Range | Launches | GPU Time (ms) | % of Total h2 Time | Attribution |
|---|---:|---:|---:|---|
| `SelfAttentionAggregator.crossattention` | 1,815 | 42.0 | 74.6% | Cross-attention layers i=1,2,3 |
| `SelfAverageAggregator.crossattention` | 605 | 14.3 | 25.4% | Self-average layer i=0 |
| **Total inside EXP01B ranges** | **2,420** | **56.3** | **100.0%** | |
| Outside EXP01B ranges | 0 | 0 | 0% | None |

**Confirmation level:** Strong confirmation.

ALL fmha launches are accounted for by the crossattention NVTX ranges. The split (74.6% in SelfAttentionAggregator, 25.4% in SelfAverageAggregator) is consistent with num_mp=4 layers: 3 layers use SelfAttentionAggregator and 1 uses SelfAverageAggregator, so we expect 3:1 = 75%:25%, which matches precisely.

No fmha launches occur outside the instrumented crossattention ranges.

---

## 11. Post-Attention Linq Contribution

| Aggregator | NVTX Range | sgemm_32x32 Launches | GPU Time (ms) | % of Total h1 | % of Instrumented h1 |
|---|---|---:|---:|---:|---:|
| SelfAttentionAggregator | `.linq` | 1,806 | 7.97 | 5.8% | 10.6% |
| SelfAverageAggregator | `.linq` | 2 | 0.04 | ~0% | ~0% |

**Assessment:** `SelfAttentionAggregator.linq` contributes materially — 5.8% of total hotspot_1 GPU time. Within the instrumented aggregator fraction (55.1% of total), linq accounts for 10.6% of the instrumented hotspot_1 time. This is non-negligible.

`SelfAverageAggregator.linq` contributes negligibly (2 launches = ~0%). This makes structural sense: SelfAverageAggregator returns `self.linq(ret)` where `ret` has shape `[batchsize, n_cols, hiddim]`, a smaller tensor than SelfAttentionAggregator's `linq_val = self.linq(tar)` where `tar` has shape `[batchsize, 1, hiddim]`. Wait — actually the opposite: SelfAverageAggregator.linq gets `ret` with full column dimensionality, while SelfAttentionAggregator.linq operates on the 1-token query. The near-zero SelfAverageAggregator.linq launches may reflect that the SelfAverageAggregator.linq GEMM has a different dimension that produces a larger kernel (different tile). EXP02 will clarify shapes.

**Answer:** YES, post-attention linq layers contribute materially to hotspot_1, specifically through `SelfAttentionAggregator.linq`.

---

## 12. RMPNN.rellin Contribution

**Answer:** Cannot assess from this capture.

The `gfm.exp01b.RMPNN.rellin` NVTX range fired 0 times. At `hop=0`, the Griffin dataloader produces subgraphs with no multi-hop edges, so `edge_index` is None or empty for all batches. The RMPNN.forward() early-return path (`if edge_index is None or edge_index.shape[1] == 0: return 0 * self.rellin(x[0])`) was taken for all calls.

EXP02 at `hop=2` (realistic configuration) is required to measure RMPNN.rellin's contribution.

---

## 13. Decision Table

| Decision Question | Answer | Evidence | Confidence |
|---|---|---|---|
| Do hotspot_1 kernels occur inside SelfAverageAggregator / SelfAttentionAggregator crossattention ranges? | YES | 6,652 launches, 67.51 ms = 49.3% of h1 time inside crossattention ranges; 8,460 total in all aggregator ranges = 55.1% of h1 time | High |
| Do hotspot_2 kernels occur inside crossattention ranges? | YES, 100% | 2,420/2,420 fmha launches inside crossattention ranges; split 74.6% / 25.4% matches 3:1 layer ratio | Strong |
| Are hotspot_1 and hotspot_2 co-localized? | YES | Both appear inside the crossattention sub-ranges; hotspot_2 is exclusively there | High |
| Does post-attention linq contribute materially to hotspot_1? | YES (SelfAttentionAggregator.linq) | 1,806 launches, 7.97 ms = 5.8% of total h1 time | Medium-High |
| Does RMPNN.rellin contribute materially to hotspot_1? | Cannot assess | 0 RMPNN.rellin range instances at hop=0 (no edges) | N/A |
| Proceed to EXP02? | YES | Source localization confirmed at sub-module level; EXP02 required to measure shapes and assess RMPNN.rellin | High |

---

## 14. Next-Step Table

| Next Step | Proceed? | Reason | Required Target Sites |
|---|---|---|---|
| EXP02 shape census | YES — authorized | Shapes at realistic scale (hop=2, batchsize=512) are unmeasured; EXP01B confirms sites but does not measure sizes | P0: `hmodel.py:343–369` per-node-type loop (`feat.shape`, `colfeat.shape`); P0: `hmodel.py:168` RMPNN.rellin (`edge_attr.shape`, requires hop≥1); P1: crossattention input shapes optional |
| NCU deep dive for hotspot_2 (fmha) | Deferred — approved but not yet run | EXP02 first per campaign plan | N/A |
| NCU deep dive for hotspot_3 (sgemm_32x128) | Deferred — approved but not yet run | EXP02 first per campaign plan | N/A |
| EXP03 microbenchmark | Not yet — wait for EXP02 | EXP02 shapes needed as input | N/A |

---

## 15. Remaining Uncertainties

1. **RMPNN.rellin contribution at hop=2:** Cannot be assessed from the hop=0 capture. EXP02 must use `hop=2` to exercise multi-hop edges and fire the RMPNN.rellin NVTX range (if the range is left active) or measure `edge_attr.shape` directly.

2. **GriffinMod MLP/lintask contribution to hotspot_1:** The 44.9% of hotspot_1 time outside aggregator ranges includes GriffinMod.mlp, mlp2, lintask forward-pass GEMMs plus backward-pass GEMMs. These were not instrumented in EXP01B. They are consistent with the EXP01A hotspot_1 table (ranks 5–7) but not directly measured here.

3. **Scale difference:** This EXP01B capture used `hop=0`, `batchsize=64`. The realistic campaign used `hop=2`, `batchsize=512`. The hotspot_1 and hotspot_2 launch counts happen to match between the two runs (both are determined by the eval_task count, not the model scale), but the kernel shapes and GPU time fractions may differ at realistic scale. EXP02 will capture the realistic-scale shapes.

4. **SelfAverageAggregator.linq shapes:** Only 2 sgemm_32x32 launches inside SelfAverageAggregator.linq. The near-zero count suggests that `self.linq(ret)` in SelfAverageAggregator may produce a different kernel depending on the output tensor shape at this hop=0 configuration. EXP02 shapes will clarify.

5. **Backward-pass attribution:** Backward-pass sgemm_32x32 launches are not attributed to specific layers by this instrumentation. They constitute part of the 44.9% outside EXP01B ranges. This is expected and not a blocker for EXP02.

---

## 16. Rollback / Disable Instructions

### Disable instrumentation without removing it

Set `GFM_EXP01B_NVTX=0` (or simply do not set it). The `_EXP01B_NVTX` flag evaluates to `False` at import time, and all `_nvtx` context managers become no-ops. No performance impact.

### Remove instrumentation from source

Revert `hmodel.py` to the pre-EXP01B state:

```bash
git diff HEAD hmodel.py   # review changes
git checkout HEAD -- hmodel.py   # revert if desired
```

Or use `git revert` on the EXP01B commit if one has been made.

The changes are isolated to:
- Lines 13–29: `_EXP01B_NVTX` flag and `_nvtx` class definition
- `SelfAverageAggregator.forward()`: added `with _nvtx(...)` wrappers
- `SelfAttentionAggregator.forward()`: added `with _nvtx(...)` wrappers; changed `return ret * self.linq(tar)` to two statements
- `RMPNN.forward()`: added `with _nvtx(...)` around `self.rellin(edge_attr)`

Removing all `with _nvtx(...)` blocks and the helper definition restores the original behavior exactly.

---

## 17. Scale Caveat

This confirmation capture was run at `hop=0`, `batchsize=64`, `slice_size_tier=8/4`. The realistic-scale campaign used `hop=2`, `fanout=10`, `batchsize=512`. The per-launch kernel identity and the eval_task-proportional launch counts are preserved across scales, but:

- Kernel shapes (M, N, K) will differ at realistic scale — measuring them is the purpose of EXP02.
- The T=1 node-type-per-forward-pass finding may change at hop=2 (more diverse subgraphs, potentially T > 1).
- RMPNN.rellin was not exercised at hop=0 and cannot be characterized from this capture.

Do not over-interpret this confirmation trace as evidence about realistic-scale behavior. It is a targeted confirmation of source localization, not a representative performance measurement.
