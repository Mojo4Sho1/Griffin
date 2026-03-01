.PHONY: profiling-preflight

profiling-preflight:
	@echo "[profiling-preflight] checking required binaries"
	@command -v conda >/dev/null
	@command -v nsys >/dev/null
	@command -v ncu >/dev/null
	@command -v accelerate >/dev/null
	@echo "[profiling-preflight] checking required files"
	@test -f environment.yml
	@test -f hconfig_profiling_single_gpu.yaml
	@echo "[profiling-preflight] checking Python imports in current environment"
	@python -c "import torch, accelerate, datasets, evaluate, sentence_transformers, einops, torchmetrics, yaml, torch_geometric; print('python deps ok')"
	@echo "[profiling-preflight] probing expected local paths"
	@ls -d datasets checkpoints logs 2>/dev/null || true
	@echo "[profiling-preflight] ok"
