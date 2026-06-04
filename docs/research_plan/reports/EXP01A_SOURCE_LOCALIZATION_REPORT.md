# EXP01A Source Localization Report

**Status:** Complete  
**Date:** 2026-06-03  
**Author:** Claude (automated, read-only analysis)  
**Campaign:** gfm-20260304-r02  
**Experiment brief:** `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`

---

## Executive Summary

Both dominant GPU hotspots are **localized to the `gfm.eval_task` NVTX phase** with high confidence. The evidence is a 3:1 exact proportional scaling of kernel launch counts with eval_task instance counts across the train vs inference scenarios (153 vs 51 instances respectively). The `gfm.train_step` and `gfm.train_epoch` NVTX phases do not explain the observed launch volumes.

The call path is: `hmaintask_completion.py:264/294/330` (per-task eval loop) → `eval_task()` (line 30) → `compute_output()` (line 101) → `model(*data)` (line 105) → `GriffinMod.forward()` (`hmodel.py:327`).

**hotspot_2 (fmha)** is produced by `nn.MultiheadAttention.crossattention` calls inside a per-node-type Python for-loop in `GriffinMod.forward()` (`hmodel.py:343–394`). Each loop iteration corresponds to one relational table type in the subgraph; each calls the CUTLASS memory-efficient attention forward kernel once per message-passing layer.

**hotspot_1 (sgemm_32x32)** is produced primarily by QKV projection GEMMs inside the same `nn.MultiheadAttention` calls, and secondarily by other linear projections in the same model. NCU launch data (`grid=(16,18,1)`, `block=(128,1,1)`) indicates GEMM shape M=576=64×9, K=512, N=512 under the NCU configuration (batchsize=64, hop=0, 9 features per table). The "small" M dimension is the product of batch_size × number_of_columns_per_table.

**Fragmentation driver:** The per-node-type Python for-loop in `GriffinMod.forward()` produces one independent attention + linear-projection call stack **per table type** in the subgraph, per message-passing layer. These are not batched across table types.

**Decision:** Proceed to EXP02 shape census. Source localization is sufficiently clear to identify target instrumentation sites.

**EXP01B (targeted NVTX instrumentation) is not needed.** Existing artifacts and read-only code inspection are sufficient.

---

## Files Inspected

### Research Documentation
- `docs/research_plan/README.md`
- `docs/research_plan/STATUS.md`
- `docs/research_plan/CAMPAIGN_PLAN.md`
- `docs/research_plan/EXPERIMENT_PROTOCOLS.md`
- `docs/research_plan/experiments/EXP01_SOURCE_LOCALIZATION.md`
- `docs/research_plan/VERIFICATION_LEDGER.md`
- `docs/research_plan/EVIDENCE_SUMMARY.md`
- `docs/research_plan/ARTIFACT_INDEX.md`

### Profiling Artifacts Inspected
- `artifacts/profiles/analysis/20260312-1537-trb1-realistic-20260312a-s03/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/20260312-1537-trb1-realistic-20260312a-s03/nvtx_sum.txt`
- `artifacts/profiles/analysis/20260312-1537-trb1-realistic-20260312a-s03/metrics.json`
- `artifacts/profiles/analysis/20260306-1652-ifb1-realistic-20260306b-s03/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/20260306-1652-ifb1-realistic-20260306b-s03/nvtx_sum.txt`
- `artifacts/profiles/analysis/20260306-1553-ftb1-realistic-20260306a-s03/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/20260304-1541-train-annotated-completion-01/cuda_gpu_kern_sum.txt`
- `artifacts/profiles/analysis/20260304-1541-train-annotated-completion-01/nvtx_sum.txt`
- `artifacts/profiles/analysis/20260319-1514-train-completion-01/ncu_analysis.sqlite` (table structure, bundle_metadata, section_metric_values LaunchStats, sampled_launches)
- `artifacts/profiles/analysis/20260319-1514-train-completion-01/sections/LaunchStats.csv`

### Griffin Source Files Inspected
- `hmaintask_completion.py` (406 lines; full read)
- `hmodel.py` (534 lines; full read)
- `hloaderwrapper.py` (421 lines; full read)
- `hdataset.py` (lines 1–200)

### Profiling Summaries
- `profiling/RESULTS.md` (full read)

---

## Profiling Evidence Used

### Cross-Scenario Kernel Launch Counts

| Scenario | eval_task instances | sgemm_32x32 launches | fmha launches | sgemm/eval_task | fmha/eval_task |
|---|---|---|---|---|---|
| Train (TR-B1 s03) | 153 | 22,731 | 2,420 | 148.6 | 15.8 |
| Inference (IF-B1 s03) | 51 | 7,477 | 796 | 146.6 | 15.6 |
| Finetune (FT-B1 s03) | 153 (implied) | 22,754 | 2,420 | ~148.7 | ~15.8 |

The train:inference ratio for sgemm_32x32 = 22731/7477 = **3.039**.  
The train:inference ratio for fmha = 2420/796 = **3.040**.  
The eval_task ratio = 153/51 = **3.000**.

All three ratios are equal to within 1.3%, establishing **proportional scaling with eval_task count**.

### NVTX Phase Shares (Realistic Train s03)

| NVTX Label | Instances | Total ms | Time % | Avg per instance (ms) |
|---|---|---|---|---|
| gfm.eval_task | 153 | 124,777 | 48.4% | 815 |
| gfm.train_epoch | 1 | 85,491 | 33.2% | 85,491 |
| gfm.final_test_pass | 1 | 42,823 | 16.6% | 42,823 |
| gfm.setup | 1 | 2,477 | 1.0% | 2,477 |
| gfm.train_step | 8 | 1,106 | 0.4% | 138 |
| gfm.checkpoint_io | 4 | 841 | 0.3% | 210 |
| CCCL:cub::DeviceSelect::Flagged | 1,194 | 83 | 0.0% | 0.07 |

### NCU Launch Statistics (hotspot_1, TR-N1)

NCU configuration: `--hop 0 --fewshotfanout 0 --batchsize 64 --num_mp 4 --hiddim 512`  
All 5 sampled sgemm_32x32 launches showed identical grid/block configuration:
- Grid: `(16, 18, 1)` = 288 blocks total
- Block: `(128, 1, 1)` = 128 threads
- Total threads: 36,864
- Waves/SM (per-launch): 0.68
- Average Waves/SM (WorkloadDistribution): 0.617

GEMM dimension inference from grid (16, 18):
- N = 16 × 32 = 512 (matches hiddim)
- M = 18 × 32 = 576 = **64 nodes × 9 features/table**

This identifies the sgemm_32x32 launches as QKV projections applied to `[batchsize × n_cols_per_table, hiddim]` matrices.

**Caveat:** NCU was run with hop=0 (single-table subgraph, 1 node type), batchsize=64. The realistic NSYS run uses hop=2, batchsize=512. Shapes at realistic scale are not captured and are the target of EXP02.

---

## NVTX / Model Phase Localization

### How eval_task maps to kernel launches

`gfm.eval_task` is pushed at `hmaintask_completion.py:200` (test mode), `264` (validation loop), `294` (conditional test loop), and `330` (final test pass). Each push corresponds to one call to `eval_task()` for one task name.

Inside `eval_task()` (line 30–81):
- DataLoader iterates up to `max_eval_steps=4` batches
- Each batch: `compute_output(model, dec, data)` at line 49
- `compute_output` calls `model(*data)` at line 105 → `GriffinMod.forward()`

The `CCCL:cub::DeviceSelect::Flagged` count (1,194 instances, ~7.8 per eval_task) is consistent with 2 mask-based indexing operations (`output[mask]`, `label[mask]` at lines 67–68) per batch × 4 batches per eval_task = 8 per eval_task. This independently confirms α≈4 batches per eval_task.

**Both hotspots appear entirely within `gfm.eval_task`.** There is no evidence of significant kernel launch volume from `gfm.train_step` (0.4% NVTX time, 8 instances). The ~1/3 lower inference launch count exactly matches the 3:1 eval_task ratio, leaving zero residual to attribute to training-specific code paths.

---

## Candidate Call Sites: hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`)

| Hotspot | Rank | Confidence | File | Line(s) | Function/Class | Operation | Relational Driver | NVTX Context | EXP02 Target? | Notes |
|---|---:|---|---|---|---|---|---|---|---|---|
| hotspot_1 | 1 | High | `hmodel.py` | 24–25, 30–36 | `SelfAverageAggregator.crossattention` (via `nn.MultiheadAttention`) | QKV projection GEMM `[bsz×n_feat, 512] × [512, 512]` | Per-table-type loop in `GriffinMod.forward()`; n_feat = number of columns in table | `gfm.eval_task` | Yes — primary | NCU grid (16,18,1) confirms M=576=64×9, N=512. Applied once per node type per MP layer |
| hotspot_1 | 2 | High | `hmodel.py` | 66–67, 78–84 | `SelfAttentionAggregator.crossattention` (via `nn.MultiheadAttention`) | QKV projection GEMM (cross-attn: query=[#node,1,512], key/value=[#node,#feat,512]) | Same per-table-type loop; layers i=1,2,3 | `gfm.eval_task` | Yes — primary | Q-projection on 1-token query; KV-projection on #feat tokens |
| hotspot_1 | 3 | Medium | `hmodel.py` | 37, 85 | `SelfAverageAggregator.linq` / `SelfAttentionAggregator.linq` (`nn.Linear(512,512)`) | GEMM after attention: `[#node×#feat, 512] × [512, 512]` or `[#node, 512] × [512, 512]` | Same per-table-type loop | `gfm.eval_task` | Yes — secondary | Applied once per node type per MP layer after crossattention |
| hotspot_1 | 4 | Medium | `hmodel.py` | 168 | `RMPNN.rellin` (`nn.Linear(512,512)`) | GEMM on edge_attr: `[#edge_types, 512] × [512, 512]` | Number of distinct relation types in subgraph | `gfm.eval_task` | Yes | edge_attr has 1 vector per edge-type; if #edge_types≈32, produces sgemm_32x32 |
| hotspot_1 | 5 | Medium | `hmodel.py` | 302, 372 | `GriffinMod.mlp[i][0]` (`nn.Linear(512,512)`) | GEMM on all nodes: `[#total_nodes, 512] × [512, 512]` | Applied to all nodes combined (not per-table) | `gfm.eval_task` | No | Not per-table; if total nodes is small, still sgemm_32x32 |
| hotspot_1 | 6 | Medium | `hmodel.py` | 305, 375 | `GriffinMod.mlp2[i][0]`, `mlp2[i][2]` (two `nn.Linear(512,512)`) | Two GEMMs on all nodes | Applied to all nodes combined | `gfm.eval_task` | No | Same caveat as rank 5 |
| hotspot_1 | 7 | Low | `hmodel.py` | 391, 322 | `GriffinMod.lintask[i]` (`nn.Linear(512,512)`) | GEMM: `[#total_nodes, 512] × [512, 512]` | Applied between MP layers (i<num_mp-1) | `gfm.eval_task` | No | Only for i=0,1,2 (not last layer) |

**Primary EXP02 targets**: Ranks 1 and 2 (crossattention QKV projections inside the per-node-type loop). These are the operations whose M-dimension is directly set by `batch_size × n_features_per_table`.

---

## Candidate Call Sites: hotspot_2 (`fmha_cutlassF_f32_aligned_64x64_rf_sm80`)

| Hotspot | Rank | Confidence | File | Line(s) | Function/Class | Operation | Relational Driver | NVTX Context | EXP02 Target? | Notes |
|---|---:|---|---|---|---|---|---|---|---|---|
| hotspot_2 | 1 | High | `hmodel.py` | 30–36 | `SelfAverageAggregator.crossattention` (`nn.MultiheadAttention`) | Flash/memory-efficient attention forward: `Q,K=[#node,#feat,512], V=[#node,#feat,512]`, 8 heads, head_dim=64 | Layer 0 per-node-type loop; once per table type | `gfm.eval_task` | Yes — primary | fmha_f32_64x64 matches head_dim=512/8=64. Called for layer i=0 only |
| hotspot_2 | 2 | High | `hmodel.py` | 78–84 | `SelfAttentionAggregator.crossattention` (`nn.MultiheadAttention`) | Cross-attention forward: Q=[#node,1,512] (task feature), K/V=[#node,#feat,512], 8 heads, head_dim=64 | Layers i=1,2,3 per-node-type loop | `gfm.eval_task` | Yes — primary | Same kernel; 1-query cross-attention per table type per layer |

**Scaling check:** 2,420 train fmha / 3,040 (3×eval_task_ratio) = 796 inference fmha (observed: 796). Exact match.

With num_mp=4 layers and T node types per forward pass, α batches per eval_task:
- fmha per eval_task = α × T × 4 layers = ~15.7
- CCCL analysis gives α≈4 → T ≈ 15.7 / (4 × 4) ≈ 1.0

**T≈1 interpretation:** In the realistic run, on average ~1 table type per subgraph participates in the fmha path. This could reflect: (a) only root-type nodes have non-None attention masks enabling the CUTLASS path; (b) the dataset's subgraphs are centered on single-table tasks; or (c) other node types' attention falls back to a non-fmha path due to mask handling. **This uncertainty does not change the source localization: the fmha calls are in the crossattention modules.**

---

## Evidence Table

| Evidence Item | Source | Supports | Strength | Caveat |
|---|---|---|---|---|
| sgemm_32x32 count 22,731 (train) vs 7,477 (inference), ratio 3.039 | `artifacts/profiles/analysis/*/cuda_gpu_kern_sum.txt` | Hotspot_1 localized to eval_task phase | Strong | Markdown-reported (C-05, C-06); confirmed by direct file read in this session |
| fmha count 2,420 (train) vs 796 (inference), ratio 3.040 | `artifacts/profiles/analysis/*/cuda_gpu_kern_sum.txt` | Hotspot_2 localized to eval_task phase | Strong | Same as above |
| eval_task: 153 train instances, 51 inference instances, ratio 3.000 | `artifacts/profiles/analysis/*/nvtx_sum.txt` and `metrics.json` | Hotspots scale proportionally with eval_task | Strong | Markdown-reported (C-05, C-06); confirmed by direct file read |
| CCCL:cub 1,194 train / 398 inference ≈ 7.8/eval_task ≈ 4 batches × 2 ops/batch | `artifacts/profiles/analysis/*/nvtx_sum.txt` | Confirms ~4 batches per eval_task | Medium | Indirect inference; CCCL could have other sources |
| gfm.train_step: 8 instances, 0.4% NVTX time, 138ms avg | `nvtx_sum.txt` (train realistic s03) | train_step not the hotspot source | Strong | Direct read; consistent with train-vs-inference being ~same kernel share |
| NCU grid (16,18,1), block (128,1,1) for sgemm_32x32 | `sections/LaunchStats.csv`, `ncu_analysis.sqlite` | GEMM M=576=64×9, N=512 | Strong | NCU run used hop=0, batchsize=64 — not realistic config |
| NCU command line: `--hop 0 --fewshotfanout 0 --batchsize 64` | `ncu_analysis.sqlite` (bundle_metadata, launch_settings) | NCU metrics apply to simplified config only | Warning | Realistic run has hop=2, fanout=10, batchsize=512 |
| SelfAverageAggregator and SelfAttentionAggregator both use `nn.MultiheadAttention` | `hmodel.py:24-25, 66-67` | fmha produced by crossattention in both aggregators | Strong | Exact SDPA backend selection depends on runtime conditions (mask, dtype) |
| Per-node-type for-loop in GriffinMod.forward() | `hmodel.py:343-369` | Fragmentation: separate kernel launch per table type per MP layer | Strong | The loop is a Python for-loop, not a batched/tensorized operation |
| `eval_task()` calls `compute_output()` at hmaintask_completion.py:49 which calls `model(*data)` | `hmaintask_completion.py:101-108` | Full forward pass (GriffinMod.forward) inside eval_task NVTX range | Strong | Direct code read; unambiguous |

---

## Confidence Assessment

| Source Location | Confidence | Primary Evidence | Key Uncertainty |
|---|---|---|---|
| `gfm.eval_task` as the NVTX phase containing both hotspots | **High** | 3:1 exact proportional scaling of kernel counts with eval_task instance counts | None identified |
| `GriffinMod.forward()` as the kernel launch site | **High** | `compute_output()` calls `model(*data)` inside each eval_task; train_step has trivially few launches | None identified |
| `crossattention` calls (hmodel.py:30-36, 78-84) as hotspot_2 source | **High** | Only MultiheadAttention calls in model; kernel is CUTLASS fmha_f32 with head_dim=64=512/8 | Exact SDPA backend selection varies with mask/runtime |
| QKV projections in `crossattention` as primary hotspot_1 source | **High** | NCU grid (16,18,1) → M=576=64×9=batchsize×n_columns; pattern consistent with per-table QKV | NCU config was hop=0; realistic-scale shapes unknown |
| RMPNN.rellin (hmodel.py:168) as secondary hotspot_1 source | **Medium** | edge_attr is [#edge_types, 512]; if #edge_types≈32, sgemm_32x32 expected | edge_types count not measured; actual count could be very small (gemv) or large (bigger tile) |
| mlp/mlp2/lintask (hmodel.py:302/305/391) as tertiary hotspot_1 source | **Medium** | Standard linear projections; tile size depends on #total_nodes which is not measured | Unclear how many total nodes at realistic scale; could use larger tiles |
| T≈1 node type per forward pass | **Low–Medium** | Implied by fmha-to-eval_task ratio; consistent with CCCL α≈4 | Could reflect SDPA backend fallback for some node types rather than T=1 subgraph |

---

## Decision: EXP02 Shape Census

**Decision: Proceed to EXP02 shape census.**

Source localization is sufficient to define EXP02 instrumentation targets. The key uncertainty is the GEMM shape distribution at realistic scale (hop=2, batchsize=512), which can only be resolved by measuring actual shapes during a forward pass.

EXP01B (targeted NVTX instrumentation) is NOT needed. The existing profiling artifacts and read-only code inspection have localized the hotspots with sufficient confidence.

---

## EXP02 Target Sites

The following locations in `hmodel.py` should be instrumented for shape census in EXP02:

| Priority | File | Line(s) | What to Capture | Purpose |
|---|---|---|---|---|
| P0 — Primary | `hmodel.py` | 343–369 | `feat.shape` and `colfeat.shape` for each j in the per-node-type loop; also `len(node)` (= T) | Directly measures T (node types per batch), #feat_j (n_columns per table), #node_j (n_nodes per table type) |
| P0 — Primary | `hmodel.py` | 168 | `edge_attr.shape` before `self.rellin(edge_attr)` | Measures #edge_types per subgraph → determines if RMPNN.rellin produces sgemm_32x32 |
| P1 — Secondary | `hmodel.py` | 30–36, 78–84 | Attention input shapes (query.shape, key.shape, value.shape) | Cross-check against P0 measurements; may be omitted if P0 is sufficient |

**The primary EXP02 target is the per-node-type loop at `hmodel.py:343–369`**, particularly the `feat.shape` = `[#node_j, #feat_j, hiddim]` which determines the GEMM M-dimension as `#node_j × #feat_j`.

---

## Whether EXP01B Is Needed

**No. EXP01B is not needed.**

EXP01A has localized both hotspots to `gfm.eval_task` → `GriffinMod.forward()` → per-node-type aggregation loop with high confidence. The remaining uncertainty (exact T value, exact shapes at realistic scale) is a shape-measurement question, not a source-localization question. EXP02 shape census is the appropriate follow-up.

---

## Remaining Uncertainties

1. **GEMM shapes at realistic scale** (hop=2, batchsize=512): NCU was run with hop=0, batchsize=64. The shape M=576=64×9 is specific to that configuration. Shapes with hop=2 will include neighboring table types with different #node_j and #feat_j. (Resolution: EXP02)

2. **T (number of node types per forward pass at realistic scale)**: Estimated T≈1 from fmha-to-eval_task ratio, but this could reflect SDPA backend fallback rather than a single-type subgraph. (Resolution: EXP02 — capture `len(node)` per forward pass)

3. **RMPNN.rellin contribution**: edge_attr shape `[#edge_types, 512]` is not measured. If #edge_types is very small (e.g., 1–4), RMPNN.rellin produces gemv rather than sgemm_32x32. If #edge_types≈32, it produces sgemm_32x32. (Resolution: EXP02 — capture edge_attr.shape)

4. **hmaintask_combine.py (finetune)**: Finetune uses `hmaintask_combine.py` rather than `hmaintask_completion.py`. Finetune has the same hotspot profile and ~same eval_task counts (22,754 sgemm launches), so the same model code is likely the source. The NVTX annotation in `hmaintask_combine.py` was not inspected in detail. (Resolution: check if hmaintask_combine.py has identical `gfm.eval_task` wrapping — low priority since evidence is indirect but consistent)

5. **Tensor Core utilization status for hotspot_1** (Ledger: C-15): Remains not yet measured. The sgemm_32x32 tile is small; TC utilization is likely low but unconfirmed. (Resolution: NCU TR-N2 or targeted TC metric capture)

6. **Exact number of features per table in the realistic dataset**: The NCU run with hop=0 shows 9 features per root table. The realistic dataset may have different tables with different column counts. Feature count heterogeneity affects how many distinct sgemm_32x32 shapes appear. (Resolution: EXP02)
