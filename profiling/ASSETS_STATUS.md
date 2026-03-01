# Profiling Assets Status

Use this file to track whether required local datasets and checkpoints are available for profiling runs.

Status values: `present` | `missing` | `unknown`

## Paths Matrix

| Asset | Typical Path | Status | Last Checked (UTC) | Notes |
|---|---|---|---|---|
| Single-table pretraining dataset | `datasets/single-pretrain-v3` | unknown | 2026-02-28 | Expected by README commands. |
| Joint dataset | `datasets/joint-v65` | unknown | 2026-02-28 | Expected by transfer workflow. |
| Completion checkpoint | `checkpoints/single-completion/best_checkpoint` | unknown | 2026-02-28 | Needed for SFT from pretrained completion. |
| SFT checkpoint | `checkpoints/single-sft` | unknown | 2026-02-28 | Optional depending on run slice. |
| Transfer checkpoint root | `checkpoints/transfer` | unknown | 2026-02-28 | Needed for transfer experiments. |

## Update Rule
- Update this matrix when running preflight or before launching a profiling slice.
- If any required asset is `missing`, record blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
