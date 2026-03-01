# Profiling Results Summary

This file stores concise, version-controlled findings and comparisons.  
It is for conclusions and interpretation, not raw logs.

## Result Entry Template

```markdown
## Result: <result_id>
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <run_id_1>
  - <run_id_2>
- question: <what performance question was tested>
- summary: <2-5 sentences>
- key_observations:
  - <observation_1>
  - <observation_2>
- comparison:
  - baseline: <run_id>
  - variant: <run_id>
  - delta: <high-level effect>
- confidence: <low|medium|high>
- caveats:
  - <data limitations or confounders>
- next_action: <single bounded follow-up action>
```

## Comparison Rules
- Always identify baseline and variant explicitly.
- Report both absolute and relative changes when available.
- If a result is uncertain, mark confidence low and capture the blocker.

## Exclusions
- No raw trace text dumps.
- No large metric tables copied from profiler outputs.
- No unbounded backlog items.
