# Profiling Assets Status

Use this file to track whether required local datasets and checkpoints are available for profiling runs.

Status values: `present` | `missing` | `unknown`

## Paths Matrix

| Asset | Typical Path | Status | Last Checked (UTC) | Notes |
|---|---|---|---|---|
| Single-table pretraining dataset | `datasets/single-pretrain-v3` | missing | 2026-03-02 | Required by selected baseline completion slice; missing required file `metanode.yaml`. |
| Joint dataset | `datasets/joint-v65` | missing | 2026-03-02 | Not required for this slice, but absent. |
| Completion checkpoint | `checkpoints/single-completion/best_checkpoint` | missing | 2026-03-02 | Not required for completion pretraining smoke slice. |
| SFT checkpoint | `checkpoints/single-sft` | missing | 2026-03-02 | Optional for combine/finetune paths; absent. |
| Transfer checkpoint root | `checkpoints/transfer` | missing | 2026-03-02 | Transfer assets absent. |

## Update Rule
- Update this matrix when running preflight or before launching a profiling slice.
- If any required asset is `missing`, record blocker details in:
  - `profiling/RUNS.md`
  - `handoff/CURRENT_STATUS.md`
  - `handoff/SESSION_LOG.md`
