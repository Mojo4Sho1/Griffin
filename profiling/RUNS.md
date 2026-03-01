# Profiling Run Records

Use one record per profiling run attempt (including failed attempts).  
Keep records concise and reproducible.

## Canonical Run ID (Required)

Run IDs must follow:

`<YYYYMMDD>-<HHMM>-<mode>-<entry>-<seq>`

Where:
- `<mode>` is one of: `train` | `finetune` | `inference`
- `<entry>` is one of: `completion` | `combine` | `downsample` | `transfer`
- `<seq>` is a two-digit sequence for collisions within the same minute (for example `01`, `02`)

Example:
- `20260228-1640-train-completion-01`

## Required Record Fields
- Date/time (UTC)
- Mode (`train` / `fine-tune` / `inference`)
- Dataset
- Exact command
- Git commit hash
- Config used
- Slice definition
- Profiler used
- Output file paths
- Short notes on findings

## Run Template

```markdown
### Run: <run_id>
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- mode: <train|fine-tune|inference>
- dataset: <dataset_id_or_path>
- command: `<exact_command>`
- git_commit: `<commit_hash>`
- config: `<config_file_or_inline_key_flags>`
- slice_definition: <what subset/epochs/steps/tasks were profiled>
- profiler: <none|nsys|ncu|other>
- outputs:
  - <artifacts/profiles/...>
  - <logs/...> (if relevant)
- findings_notes: <1-5 concise bullets or sentences>
- status: <success|failed|partial>
- blocker_if_any: <none or short blocker statement>
```

## Conventions
- Use the canonical run ID format above for every run record.
- For reruns of the same slice, keep separate records and reference prior `run_id`.
- Do not paste raw profiler dumps; link paths only.
