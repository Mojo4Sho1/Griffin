# Profiling Assets Status

Use this file to track whether required local datasets and checkpoints are available for profiling runs.

Status values: `production_equivalent_verified` | `present_but_unverified` | `missing`

Strict provenance manifest: `profiling/ASSET_PROVENANCE.md`

## Paths Matrix

| Asset | Typical Path | Status | Last Checked (UTC) | Notes |
|---|---|---|---|---|
| Single-table pretraining dataset (staged toy) | `datasets/single-pretrain-v3` | present_but_unverified | 2026-03-05 | Minimal synthetic staging for command-path verification (`toy_rmse`, tiny metadata footprint); explicitly non-production. |
| Single-table pretraining dataset (HF realistic candidate) | `datasets/single-pretrain-v3-hf` | production_equivalent_verified | 2026-03-05 | Full required metadata/embedding files present; repo revision pinned to SHA `dbb31254586361eaf271db0d1d9bfed6292b820d` in cache metadata. |
| Joint dataset | `datasets/joint-v65` | production_equivalent_verified | 2026-03-05 | Full dataset tree staged; repo revision pinned to SHA `e0c54ceada75317b06f11f8dcda7aa8304fbb593` in cache metadata. |
| Completion checkpoint (official HF) | `checkpoints/single-completion/model.safetensors` | production_equivalent_verified | 2026-03-05 | Official checkpoint file + config staged; HF cache metadata pins revision SHA `bd8c5be5130f34e7faa31099d0bd81d95d0aa995`. |
| SFT checkpoint (official HF) | `checkpoints/single-sft/model.safetensors` | production_equivalent_verified | 2026-03-05 | Official checkpoint file + config staged; HF cache metadata pins revision SHA `bd8c5be5130f34e7faa31099d0bd81d95d0aa995`. |
| Completion checkpoint (local staged-run output) | `checkpoints/single-completion/best_checkpoint` | present_but_unverified | 2026-03-05 | Historical staged campaign output retained for trace continuity; not used as canonical realistic-scale provenance source. |
| SFT checkpoint (local staged-run output) | `checkpoints/single-sft/best_checkpoint` | present_but_unverified | 2026-03-05 | Historical staged campaign output retained for trace continuity; not used as canonical realistic-scale provenance source. |
| Transfer checkpoint root | `checkpoints/transfer` | missing | 2026-03-05 | Not required for immediate realistic-scale train/finetune/inference baseline rows, but absent. |

## Update Rule
- Update this matrix when running preflight or before launching a profiling slice.
- If any required asset is not `production_equivalent_verified`, record blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
