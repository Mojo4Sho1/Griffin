# Profiling Results Summary

This file stores concise, version-controlled findings and comparisons.  
It is for conclusions and interpretation, not raw logs.

## Baseline Scenario Summary Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: baseline_unannotated
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <run_id_1>
  - <run_id_2>
- question: <what performance question was tested>
- summary: <2-5 sentences>
- runtime_overview:
  - wall_time_sec: <value_or_unknown>
  - gpu_busy_fraction: <value_or_unknown>
- key_observations:
  - <observation_1>
  - <observation_2>
- comparison:
  - baseline: <run_id_or_none>
  - variant: <run_id_or_none>
  - delta: <high-level effect>
- confidence: <low|medium|high>
- caveats:
  - <data limitations or confounders>
- next_action: <single bounded follow-up action>
```

## Annotated Scenario Summary Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: baseline_annotated
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <annotated_nsys_run_id>
  - <optional_baseline_unannotated_run_id>
- question: <what label interpretability question was tested>
- summary: <2-5 sentences>
- nvtx_label_coverage:
  - labels_expected: <list>
  - labels_seen: <list>
  - missing_labels: <list_or_none>
- key_observations:
  - <observation_1>
  - <observation_2>
- confidence: <low|medium|high>
- caveats:
  - <data limitations or confounders>
- next_action: <single bounded follow-up action>
```

## Cross-Scenario Comparison Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- profile_stage: <baseline_unannotated|baseline_annotated>
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <train_run_id>
  - <finetune_run_id>
  - <inference_run_id>
- question: <cross-scenario comparison objective>
- summary: <2-6 sentences>
- scenario_comparison:
  - train: <key runtime/top hotspot summary>
  - finetune: <key runtime/top hotspot summary>
  - inference: <key runtime/top hotspot summary>
- confidence: <low|medium|high>
- caveats:
  - <data limitations or confounders>
- next_action: <single bounded follow-up action>
```

## NCU Hotspot Result Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: ncu_hotspot
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <ncu_run_id>
  - <hotspot_source_nsys_run_id>
- hotspot_id: <id_from_hotspot_shortlist>
- summary: <2-5 sentences>
- kernel_findings:
  - <kernel_1_summary>
  - <kernel_2_summary>
- confidence: <low|medium|high>
- caveats:
  - <data limitations or confounders>
- next_action: <single bounded follow-up action>
```

## Comparison Rules
- Always identify baseline and variant explicitly.
- Report both absolute and relative changes when available.
- If a result is uncertain, mark confidence low and capture the blocker.
- Cross-scenario comparisons are valid only after required scenario gates are complete for the selected stage.
- `ncu` hotspot results must reference hotspot candidates from annotated `nsys` analysis.

## Exclusions
- No raw trace text dumps.
- No large metric tables copied from profiler outputs.
- No unbounded backlog items.

## Result: gfm-20260303-r01-train-baseline-unannotated-01
- campaign_id: gfm-20260303-r01
- scenario: train
- profile_stage: baseline_unannotated
- date_time_utc: 2026-03-03T17:28:30Z
- related_runs:
  - 20260302-1637-train-completion-01
  - 20260303-1727-train-completion-01
- question: Is the bounded unannotated train baseline trace reproducible across two independent slices?
- summary: Both baseline unannotated `nsys` train slices completed end-to-end with matching validation and test metrics on the staged dataset. No new runtime blockers appeared in TR-S2 after enforcing GPU3 occupancy checks. This satisfies the Phase 4a reproducibility gate for the train scenario.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - TR-S1 and TR-S2 completed full train/valid/test flow under `nsys`.
  - Metric outputs were stable across slices (`valid=-1.7689979076385498`, `test=-2.278367757797241`).
  - Artifact paths are present for both runs in `artifacts/profiles/nsys/`.
- comparison:
  - baseline: 20260302-1637-train-completion-01
  - variant: 20260303-1727-train-completion-01
  - delta: no observed behavior change in bounded slice completion or reported metrics
- confidence: medium
- caveats:
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Start Phase 4b by executing campaign row `gfm-20260303-r01 / FT-S1 / baseline_unannotated`.
