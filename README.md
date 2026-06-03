# Griffin Profiling Fork

This is a profiling-focused fork of [Griffin](https://arxiv.org/abs/2505.05568), a graph foundation model for relational databases. The current purpose of this repository is to study GPU execution behavior during Griffin training, finetuning, and inference using NVIDIA Nsight Systems (nsys) and Nsight Compute (ncu).

Original Griffin training, finetuning, and inference functionality is preserved. See [Original Griffin usage](#original-griffin-usage) below.

---

## What this repository is

This fork builds on the original Griffin implementation. The current focus is:

- Profiling Griffin's GPU execution across train, finetune, and inference scenarios using bounded, reproducible slice captures.
- Identifying stable hotspot kernels and generating hypothesis-driven evidence for potential optimization directions.
- Maintaining a structured, version-controlled record of profiling runs, results, and analysis artifacts.

The original Griffin modeling code, dataset pipeline, and training/finetuning/inference CLI remain intact and usable.

---

## Quick orientation

| What you need | Where to look |
|---|---|
| Visual hotspot review (NCU) | [`profiling/notebooks/ncu_sqlite_review.ipynb`](profiling/notebooks/ncu_sqlite_review.ipynb) |
| Visual cross-scenario review (NSYS) | [`profiling/notebooks/nsys_cross_scenario_dashboard.ipynb`](profiling/notebooks/nsys_cross_scenario_dashboard.ipynb) |
| Summary of profiling findings | [`profiling/RESULTS.md`](profiling/RESULTS.md) |
| Run registry (all attempts) | [`profiling/RUNS.md`](profiling/RUNS.md) |
| NCU section coverage and workflow | [`profiling/NCU_COVERAGE.md`](profiling/NCU_COVERAGE.md) |
| Command patterns and workflow order | [`profiling/COMMANDS.md`](profiling/COMMANDS.md) |
| Full profiling guide | [`profiling/_PROFILING_GUIDE.md`](profiling/_PROFILING_GUIDE.md) |
| Run scale definitions | [`profiling/SCALE_PROFILES.md`](profiling/SCALE_PROFILES.md) |
| Analysis bundles (per-run) | [`artifacts/profiles/analysis/`](artifacts/profiles/analysis/) |
| NSYS trace files | `artifacts/profiles/nsys/` |
| NCU report files | `artifacts/profiles/ncu/` |
| Profiling scripts | [`scripts/`](scripts/) |
| Original Griffin setup/training/inference | [Original Griffin usage](#original-griffin-usage) |

---

## Current profiling status

All three scenarios — **train**, **finetune**, and **inference** — have completed the full capture pipeline at realistic scale:

- **Baseline validation** (2×): reproducible bounded slice pairs confirmed, no unresolved blockers.
- **Steady-state unannotated**: representativeness gate passed for all three scenarios (top-3 overlap = 3/3; timeshare drift ≤ 1.72%).
- **Steady-state annotated** (coarse NVTX, `nvtx-v1.0`): all expected labels confirmed present across all scenarios via forced-export verification.
- **Cross-scenario review gate** (`RV-R2`): passed. Top-3 GPU hotspot kernels are identical in type and rank across train, finetune, and inference.
- **NCU deep dive**: approved and in progress. `TR-N1` (hotspot_1, `ampere_sgemm_32x32_sliced1x4_tn`) has a validated analysis bundle with all 8 core NCU sections imported into SQLite. `TR-N2` (hotspot_2, fmha) is the approved next step.

**Known caveats:**

- All slice captures use `slice_size_tier=8/4` (max 8 train steps, 4 eval steps). These are bounded slices on a shared GPU server, not production-scale full training runs. Kernel time-share percentages should be read as relative indicators, not production throughput measures.
- Runs are constrained to GPU3 on a shared 4-GPU host; intra-scenario wall-time variation (e.g., ±10s across slices) is expected shared-host noise.
- The `TR-N1` NCU report was captured with a legacy `--set full` flag and no launch cap, producing a 7.8 GB oversized report. Future NCU runs use `--sections-profile core --launch-count 5` by default.
- No `artifacts/profiles/dashboard_exports/` directory exists yet; notebook outputs have not been bulk-exported.

See [`profiling/RESULTS.md`](profiling/RESULTS.md) for the full versioned result log.

---

## Key findings so far

| Status | Claim | Evidence |
|---|---|---|
| Observed | Top-3 GPU hotspots are identical in type and rank across train, finetune, and inference: `ampere_sgemm_32x32_sliced1x4_tn` (~30–32%), `fmha_cutlassF_f32_aligned_64x64_rf_sm80` (~12.5–13%), `ampere_sgemm_32x128_tn` (~9.3–9.8%) | [`profiling/RESULTS.md`](profiling/RESULTS.md) — `gfm-20260304-r02-realistic-cross-scenario-review-01` |
| Observed | Hotspot stability is high: top-3 overlap = 3/3 and timeshare drift ≤ 1.72% across paired slices for all three scenarios | [`profiling/RESULTS.md`](profiling/RESULTS.md) — steady-unannotated results |
| Observed | Inference has ~1/3 the GEMM kernel launches of train/finetune (7477 vs 22731–22754 per slice), consistent with eval-only execution | [`profiling/RESULTS.md`](profiling/RESULTS.md) — `gfm-20260304-r02-realistic-cross-scenario-review-01` |
| Observed | NCU analysis of `ampere_sgemm_32x32_sliced1x4_tn` (hotspot_1) shows `full_waves=0.617`, `eligible_warps_per_cycle=0.387`, suggesting underfilled / low-eligibility execution | [`profiling/RESULTS.md`](profiling/RESULTS.md) — `gfm-20260304-r02-train-ncu-hotspot-01`; [`profiling/NCU_COVERAGE.md`](profiling/NCU_COVERAGE.md) |
| Observed | All 8 NCU core sections (`LaunchStats`, `Occupancy`, `SchedulerStats`, `WarpStateStats`, `ComputeWorkloadAnalysis`, `MemoryWorkloadAnalysis`, `SpeedOfLight`, `WorkloadDistribution`) imported successfully into SQLite | [`profiling/NCU_COVERAGE.md`](profiling/NCU_COVERAGE.md) |
| Hypothesis | The small-tile GEMM dominance and underfilled execution metrics may reflect fragmented dense computation driven by Griffin's variable relational schema dimensions | Derived from profiling evidence; not yet verified by controlled experiment |
| Not yet proven | Whether a schema-aware packing or tensorization strategy would improve GPU utilization or end-to-end throughput while preserving model semantics | Requires a future optimization experiment |
| Not yet proven | Whether Tensor Cores are bypassed due to irregular matrix dimensions | Current NCU evidence shows low wave occupancy but does not directly confirm or deny TC utilization; a targeted NCU metric capture would be needed |

---

## Visual review notebooks

Two notebooks support the profiling workflow:

### [`profiling/notebooks/nsys_cross_scenario_dashboard.ipynb`](profiling/notebooks/nsys_cross_scenario_dashboard.ipynb)

The cross-scenario NSYS dashboard. Use this as the first entry point for comparing GPU kernel time-share, NVTX structure, and hotspot identity across train, finetune, and inference scenarios. Reads from `artifacts/profiles/analysis/<run_id>/` bundles.

### [`profiling/notebooks/ncu_sqlite_review.ipynb`](profiling/notebooks/ncu_sqlite_review.ipynb)

The Nsight Compute hotspot deep-dive notebook. Reads from the SQLite bundle at `artifacts/profiles/analysis/<run_id>/ncu_analysis.sqlite` and surfaces structured views for all 8 imported core sections: Launch Statistics, Occupancy, Compute Workload, Memory Workload, Speed-of-Light, WorkloadDistribution, Scheduler Statistics, Warp State, per-launch distributions, and guidance cards.

### Intended notebook workflow

1. Use the **NSYS dashboard** to compare kernel time-share across scenarios and confirm hotspot stability.
2. Use the **NCU notebook** to inspect selected hotspot kernels in depth: occupancy limits, wave counts, scheduler eligibility, memory bottlenecks.
3. Use [`profiling/RESULTS.md`](profiling/RESULTS.md) and [`profiling/RUNS.md`](profiling/RUNS.md) for provenance, gate decisions, and written analysis records.

---

## Profiling workflow

The enforced workflow order is:

1. **Baseline validation** — run short bounded slices to confirm command-path and profiler health.
2. **Steady-state unannotated** — run paired NSYS captures; check top-3 kernel overlap and timeshare drift.
3. **Coarse NVTX annotation** — insert `gfm.*` NVTX labels; rerun; verify label visibility with forced-export `nvtx_sum`.
4. **Human review / hotspot shortlist approval** — review analysis bundles; approve or deny NCU escalation.
5. **NCU hotspot capture** — run `scripts/run_ncu_hotspot.sh <scenario> <hotspot>` for approved kernels.
6. **NCU bundle analysis** — run `python scripts/analyze_ncu_run.py --run-id <run_id>` in `tmux`; review via the NCU notebook.
7. **Decide on optimization experiment** — only after NCU evidence and explicit review-gate approval.

Key scripts:

| Script | Purpose |
|---|---|
| [`scripts/profile_baseline.sh`](scripts/profile_baseline.sh) | Run a baseline bounded NSYS slice |
| [`scripts/run_slice_chain.sh`](scripts/run_slice_chain.sh) | Run a multi-slice chained NSYS capture |
| [`scripts/analyze_nsys_run.sh`](scripts/analyze_nsys_run.sh) | Generate a per-run analysis bundle from an NSYS artifact |
| [`scripts/run_ncu_hotspot.sh`](scripts/run_ncu_hotspot.sh) | Run a targeted NCU capture for an approved hotspot |
| [`scripts/analyze_ncu_run.py`](scripts/analyze_ncu_run.py) | Import NCU sections into SQLite and generate structured bundle |
| [`scripts/archive_chain_summary.sh`](scripts/archive_chain_summary.sh) | Archive a completed chain summary |

See [`profiling/COMMANDS.md`](profiling/COMMANDS.md) for canonical command patterns and guardrails (GPU assignment, NVTX verification policy, etc.).

**Hardware note:** All profiling runs in this repo target GPU3 on a shared 4-GPU server. Check GPU availability with `nvidia-smi` before running. Use `CUDA_VISIBLE_DEVICES=3` for all profiling commands.

---

## Artifact layout

```
artifacts/profiles/
├── nsys/                              # Raw .nsys-rep trace files
│   └── <run_id>.nsys-rep
├── ncu/                               # Raw .ncu-rep report files
│   └── <run_id>.ncu-rep
└── analysis/                          # Per-run analysis bundles
    └── <run_id>/
        ├── summary.md                 # Human-readable summary
        ├── metrics.json               # Machine-readable metric snapshot
        ├── cuda_gpu_kern_sum.txt      # Top GPU kernel summary
        ├── cuda_api_sum.txt           # CUDA API call summary
        ├── nvtx_sum.txt               # NVTX range summary
        ├── ncu_analysis.sqlite        # NCU structured bundle (where captured)
        ├── ncu_summary.md             # NCU human-readable summary
        ├── ncu_metrics.json           # NCU metrics JSON
        └── sections/                  # Per-section CSV sidecars (NCU)
            └── <section_id>.csv

profiling/
├── RESULTS.md                         # Versioned findings and gate decisions
├── RUNS.md                            # Run registry (all attempts)
├── NCU_COVERAGE.md                    # NCU section coverage tracker
├── COMMANDS.md                        # Canonical command patterns
├── SCALE_PROFILES.md                  # Run-scale definitions (staged vs realistic)
├── MANUAL_ANALYSIS.md                 # Manual analysis playbook
├── _PROFILING_GUIDE.md                # Full profiling guide
├── CAMPAIGN_PLAN.md                   # Campaign execution plan
├── chains/                            # Slice-chain summaries
│   ├── active/                        # In-progress chains
│   └── archive/                       # Completed/retired chains
├── notebooks/
│   ├── ncu_sqlite_review.ipynb        # NCU deep-dive notebook
│   └── nsys_cross_scenario_dashboard.ipynb  # Cross-scenario NSYS dashboard
└── sql/
    ├── manual_queries.sql             # NSYS manual analysis queries
    └── manual_queries_ncu.sql         # NCU manual analysis queries
```

---

## Research direction

Griffin's relational execution involves graph-structured attention over variable-schema relational tables. The current profiling evidence shows that GPU hotspots are stable and consistent across all three execution scenarios: the same small-tile GEMM and flash-attention kernels dominate by time share regardless of whether the model is training, finetuning, or inferring.

The NCU analysis of the top GEMM hotspot shows low wave counts and low scheduler eligibility, suggesting that individual kernel launches are not filling the GPU. The current evidence motivates investigating whether Griffin's variable relational schema dimensions produce fragmented dense computation — repeated small kernels with irregular shapes — and whether schema-aware packing, batching, or tensorization strategies could improve GPU utilization while preserving model semantics.

This remains a research hypothesis. The current repository does not yet prove that any such strategy would improve end-to-end throughput or preserve accuracy; that requires a future controlled optimization experiment. The next step is completing NCU deep dives for hotspot_2 (flash attention) and hotspot_3 (second GEMM variant) before drawing optimization conclusions.

---

## Reproducing existing profiling results

All profiling evidence in this repository was captured on a shared GPU server targeting GPU3. To reproduce:

1. Check GPU availability: `nvidia-smi`
2. Review canonical command patterns: [`profiling/COMMANDS.md`](profiling/COMMANDS.md)
3. Run a baseline slice: `scripts/profile_baseline.sh`
4. Generate an analysis bundle: `scripts/analyze_nsys_run.sh --run-id <run_id>`
5. Review output in `artifacts/profiles/analysis/<run_id>/`

For NCU deep dives, see [`profiling/NCU_COVERAGE.md`](profiling/NCU_COVERAGE.md) for current section defaults and capture policy.

For full run provenance (datasets, checkpoints, exact commands, git hashes), see individual run records in [`profiling/RUNS.md`](profiling/RUNS.md).

**Artifact size warning:** The legacy `TR-N1` NCU report (`20260319-1514-train-completion-01`) is a 7.8 GB file captured with `--set full` and no launch cap. It is valid source evidence but not the preferred default. New NCU runs use `--sections-profile core --launch-count 5` and produce much smaller reports.

---

## Original Griffin usage

> The sections below are inherited from the original Griffin implementation and remain useful for running the model. The profiling-specific workflow for this fork is documented above.

### Getting Started

#### Prerequisites

Install [torch_geometric](https://pytorch-geometric.readthedocs.io/en/latest/index.html) first.

Then install the following dependencies:

```bash
pip install datasets pqdm accelerate evaluate sentence_transformers einops torchmetrics seaborn
```

### Dataset Preparation

#### Using Provided Processed Datasets

We provide already processed datasets for your convenience. You can download them from [Hugging Face RDB datasets collection](https://huggingface.co/datasets/yamboo/Griffin_datasets_joint_v65) and [Hugging Face Single datasets collection](https://huggingface.co/datasets/yamboo/Griffin_datasets_single_pretrain_v3).
The datasets are organized as follows:

```bash
./datasets/
├── joint-v65 # Major dataset, including all RDB datasets. Used for main experiments.
└── single-pretrain-v3 # Single-table dataset, including all single-table datasets. Used for pretraining.
```

#### Processing Raw Data

If you wish to process the raw data yourself, the scripts and instructions are available in a separate branch: [processing_data](https://github.com/yanxwb/Griffin/tree/processing_data).

### Pretraining & Finetuning

#### Using Provided Pretrained Checkpoints

We provide pretrained model checkpoints to get you started quickly. You can download them from [Hugging Face checkpoints collection](https://huggingface.co/yamboo/Griffin_models).

The checkpoints are organized as follows:

```bash
./checkpoints/
├── single-completion # Pretrained single table completion model.
├── single-sft # Pretrained single table SFT model. Used in main experiments.
└── transfer # Pretrained transfer model. Used in transfer experiments.
    ├── commerce-1
       ├── FULL
       ├── MIXED
       └── LIMITED
    ├── commerce-2
       ├── FULL
       ├── MIXED
       └── LIMITED
    ├── others-1
       ├── FULL
       ├── MIXED
       └── LIMITED
    └── others-2
       ├── FULL
       ├── MIXED
       └── LIMITED
```

#### Pretraining from Scratch

```bash
# Step 1: Completion Pretraining
accelerate launch --config_file hconfig.yaml hmaintask_completion.py datasets/single-pretrain-v3-hf logs/single-completion log --savepath checkpoints/single-completion --hop 0 --fanout 10 --fewshotfanout 0 --maxepoch 5 --batchsize 4096 --lr 0.00010178976613680036 --wd 0.008749895419888909 --num_mp 4 --use_rev True --use_gate True --eval_per_epoch 1 --hiddim 512

# Step 2: SFT Pretraining
accelerate launch --config_file hconfig.yaml hmaintask_combine.py datasets/single-pretrain-v3-hf logs/single-sft log --loadpath checkpoints/single-completion/best_checkpoint --savepath checkpoints/single-sft --task ALLTASK --hop 0 --fanout 10 --fewshotfanout 0 --maxepoch 40 --batchsize 4096 --lr 0.00042364843314963003 --wd 2.423189169972981e-05 --num_mp 4 --use_rev True --use_gate True --eval_per_epoch 2 --hiddim 512
```

#### Finetuning on Specific Datasets

```bash
accelerate launch --config_file hconfig.yaml hmaintask_combine.py $dataset $log_path $log_name --loadpath $load_path --savepath $save_path --tasks $TASK --hop 2 --fanout 20 --maxepoch 50 --patience 15 --eval_per_epoch 2 --batchsize 256 --lr 3e-4 --wd 2e-4 --num_mp 4 --use_rev True --use_gate False --fewshotfanout 3 --hiddim 512
```

### Transfer Experiments

The experiment involves four data splits and three types of pretrained models trained on each split. Each split contains six tasks defined in `task_names.yaml`. The goal is to evaluate the transferability of models pretrained on one split to another.

#### Data Splits

- **commerce-1**
- **commerce-2**
- **others-1**
- **others-2**

#### Pretrained Models

- **FULL** (index `1`)
- **MIXED** (index `2`)
- **LIMITED** (index `3`)

#### Run Command

```bash
bash transfer.sh $GPU $SPLIT_1 $SPLIT_2 $TASK $MODEL $EVAL_SAMPLE_RATIO $SEED_START $SEED_END
```

Example with two GPUs:

```bash
bash transfer.sh 0,1 commerce-1 others-1 rel-f1-driver-dnf 1 42 43
```

---

## Citation and attribution

This repository is a profiling-focused fork used for systems analysis and optimization exploration of Griffin. The original Griffin paper and implementation are the work of the original authors.

If you use Griffin, please cite the original paper:

```
@article{griffin2025,
  title={Griffin: Towards a Graph-Centric Relational Database Foundation Model},
  author={...},
  journal={arXiv preprint arXiv:2505.05568},
  year={2025}
}
```

Original repository: [https://github.com/yanxwb/Griffin](https://github.com/yanxwb/Griffin)
