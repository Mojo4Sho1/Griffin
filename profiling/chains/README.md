# Chain Summaries

Directory layout:

- `profiling/chains/active/`: current chain summaries used for ongoing campaign decisions.
- `profiling/chains/archive/`: archived/superseded chain summaries kept for provenance.
- `profiling/chains/archive/ARCHIVE_INDEX.md`: append-only archive ledger.

Policy:

- Chain summaries are append-only evidence; do not delete summary history.
- If a chain is rerun with a new `chain_id`, mark the older chain as superseded in docs.
- Keep only decision-relevant summaries in `active`; archive old/superseded summaries.

Archival command:

```bash
scripts/archive_chain_summary.sh --chain-id <chain_id> --reason "<short reason>"
```
