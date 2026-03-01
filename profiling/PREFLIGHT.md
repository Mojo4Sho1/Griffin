# Profiling Preflight

Use this checklist before executing the task in `handoff/NEXT_TASK.md`.

## 0) Create And Activate Conda Environment

```bash
conda env create -f environment.yml
conda activate griffin-profiling
```

If the env already exists:

```bash
conda activate griffin-profiling
```

## 1) Install GPU-Coupled Runtime Packages

Install PyTorch matching this server's CUDA/runtime stack first, then PyG.
Example pattern (adjust CUDA index URL if needed):

```bash
pip install --index-url https://download.pytorch.org/whl/cu121 torch torchvision torchaudio
pip install torch_geometric
```

## 2) Run The One-Command Preflight (Preferred)

```bash
make profiling-preflight
```

If this fails, resolve the first failing check, then rerun.

## 3) Verify Core Tooling (Optional Manual Check)

```bash
command -v nsys
command -v ncu
command -v accelerate
python -c "import torch, accelerate, datasets, evaluate, sentence_transformers, einops, torchmetrics, yaml; print('python deps ok')"
python -c "import torch_geometric; print('pyg ok')"
```

The command above is automated by `make profiling-preflight`.

## 4) Verify Expected Local Paths

```bash
ls -d datasets checkpoints logs 2>/dev/null || true
```

Update `profiling/ASSETS_STATUS.md` with current `present/missing/unknown` values.

If datasets/checkpoints are missing, document that blocker in:
- `profiling/RUNS.md` (attempt status `failed` or `partial`)
- `handoff/CURRENT_STATUS.md`
- `handoff/SESSION_LOG.md`

## 5) Confirm Minimal Launch Mechanics Without Profiler

Before profiler wrapping, run one minimal no-profiler smoke launch with the exact script/args selected for the baseline slice.  
Use `--config_file hconfig_profiling_single_gpu.yaml` for this verification slice.
Use a bounded slice (for example one epoch and small batch size) and keep outputs under existing `logs/` + `checkpoints/` conventions.

## 6) Then Run Baseline Profiler Slice

After smoke launch success, run the baseline `nsys` or `ncu` command and write raw outputs to:
- `artifacts/profiles/nsys/`
- `artifacts/profiles/ncu/`

For first-pass reproducibility, keep `--config_file hconfig_profiling_single_gpu.yaml` unless explicitly validating multi-process behavior.
Record the full command and outcome in `profiling/RUNS.md`.
