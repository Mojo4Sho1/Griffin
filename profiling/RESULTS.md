# Profiling Results Summary

This file stores concise, version-controlled findings and comparisons.  
It is for conclusions and interpretation, not raw logs.

## Baseline Scenario Summary Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: baseline_validation
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

## Steady-State Representativeness Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: <steady_unannotated|steady_annotated>
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <window_run_id_a>
  - <window_run_id_b>
- question: Is the scenario representative/stable enough for downstream analysis?
- summary: <2-5 sentences>
- stability_checks:
  - top3_overlap: <ratio>
  - timeshare_drift_pct: <value>
  - thresholds: overlap>=2/3, drift<=20%
  - representative_pass: <true|false>
- runtime_policy:
  - planned_soft_cap_minutes: 45
  - actual_runtime_minutes: <value>
  - overrun_reason_if_any: <none|reason>
- confidence: <low|medium|high>
- caveats:
  - <limitations>
- next_action: <single bounded follow-up action>
```

## Annotated Scenario Summary Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: steady_annotated
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <annotated_nsys_run_id>
  - <optional_steady_unannotated_run_id>
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
- profile_stage: <baseline_validation|steady_unannotated|steady_annotated>
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

## Capture Completion Gate Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- profile_stage: capture_gate
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- question: Are all baseline + steady-state captures complete (or non-actionably blocked)?
- capture_gate:
  - baseline_validation_complete: <true|false>
  - steady_unannotated_complete: <true|false>
  - steady_annotated_complete: <true|false>
  - non_actionable_blockers_documented: <true|false>
  - capture_complete: <true|false>
- summary: <2-5 sentences>
- confidence: <low|medium|high>
- next_action: <single bounded follow-up action>
```

## Human Review Summary Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- profile_stage: review_gate
- date_time_utc: <YYYY-MM-DDTHH:MM:SSZ>
- related_runs:
  - <capture_result_ids_or_run_ids>
- question: Has human review approved progression to post-review deep dives?
- review_outcome:
  - review_complete: <true|false>
  - ncu_allowed: <true|false>
  - optimization_discussion_allowed: <true|false>
- summary: <2-5 sentences>
- approved_hotspots_or_focus: <list_or_none>
- next_action: <single bounded follow-up action>
```

## NCU Hotspot Result Template

```markdown
## Result: <result_id>
- campaign_id: <campaign_id>
- scenario: <train|finetune|inference>
- profile_stage: ncu_post_review
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
- `ncu` results are valid only after human review gate marks `ncu_allowed: true`.

## Exclusions
- No raw trace text dumps.
- No large metric tables copied from profiler outputs.
- No unbounded backlog items.
- No optimization proposal content before a completed human review summary explicitly allows it.

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

## Result: gfm-20260303-r01-finetune-baseline-unannotated-01
- campaign_id: gfm-20260303-r01
- scenario: finetune
- profile_stage: baseline_unannotated
- date_time_utc: 2026-03-03T17:40:13Z
- related_runs:
  - 20260303-1738-finetune-combine-02
  - 20260303-1741-finetune-combine-01
- question: Can FT-S1 complete a bounded unannotated finetune slice under smoke and `nsys` wrappers?
- summary: FT-S1 did not complete because both smoke and `nsys` hit the same post-validation runtime error in `hmaintask_combine.py`. The run path is otherwise healthy through training and validation metric production, and `nsys` artifact generation is confirmed. Finetune baseline gate progress remains blocked by a script-level device-allocation bug, not by environment, dataset, or GPU occupancy.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - Smoke and `nsys` both reach `valid_metric/toy_rmse/rmse=-1.7689979076385498` before failure.
  - Failure is deterministic at `hmaintask_combine.py:238` (`model.device` AttributeError).
  - `artifacts/profiles/nsys/20260303-1741-finetune-combine-01.nsys-rep` was generated.
- comparison:
  - baseline: 20260303-1738-finetune-combine-02
  - variant: 20260303-1741-finetune-combine-01
  - delta: no behavior change; both fail at identical gather-device boundary
- confidence: high
- caveats:
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Apply the same non-semantic gather-device fix pattern used in `hmaintask_completion.py` to `hmaintask_combine.py`, then rerun FT-S1 smoke and `nsys`.

## Result: gfm-20260303-r01-finetune-baseline-unannotated-02
- campaign_id: gfm-20260303-r01
- scenario: finetune
- profile_stage: baseline_unannotated
- date_time_utc: 2026-03-03T17:48:04Z
- related_runs:
  - 20260303-1744-finetune-combine-01
  - 20260303-1745-finetune-combine-01
- question: Did the minimal gather-device compatibility fix unblock FT-S1 baseline finetune smoke and `nsys` runs?
- summary: Yes. After replacing `model.device` with `accelerator.device` at the validation gather site in `hmaintask_combine.py`, both smoke and `nsys` FT-S1 reruns completed end-to-end on GPU3. The finetune baseline path is now unblocked, and a fresh baseline `nsys` artifact has been captured.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - Smoke and `nsys` both completed train/valid/test plus best-checkpoint save flow.
  - Metrics were stable across both reruns (`valid=-1.7689979076385498`, `test=-2.278367519378662`).
  - `checkpoints/single-sft/best_checkpoint` now exists, removing the prior inference-checkpoint prerequisite blocker.
- comparison:
  - baseline: 20260303-1741-finetune-combine-01
  - variant: 20260303-1745-finetune-combine-01
  - delta: blocker resolved; run now completes and emits artifact
- confidence: high
- caveats:
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Execute `gfm-20260303-r01 / FT-S2 / baseline_unannotated` (smoke then `nsys`) to advance Phase 4b toward the `2/2` finetune gate.

## Result: gfm-20260303-r01-finetune-baseline-validation-01
- campaign_id: gfm-20260303-r01
- scenario: finetune
- profile_stage: baseline_validation
- date_time_utc: 2026-03-03T19:46:31Z
- related_runs:
  - 20260303-1745-finetune-combine-01
  - 20260303-1945-finetune-combine-01
- question: Is the bounded finetune baseline validation trace reproducible across FT-B1 and FT-B2?
- summary: Yes. Both FT-B1 and FT-B2 `nsys` finetune baseline-validation slices completed end-to-end on GPU3 with matching validation/test metrics. No new blockers were observed, and FT-B2 reproduces FT-B1 behavior under the same command/config surface. This closes the Phase 4b finetune baseline-validation `2/2` gate.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - FT-B1 (`20260303-1745-finetune-combine-01`) and FT-B2 (`20260303-1945-finetune-combine-01`) both produced `.nsys-rep` artifacts.
  - Metrics were stable across both slices (`valid=-1.7689979076385498`, `test=-2.278367519378662`).
  - Smoke prerequisite for FT-B2 succeeded after rerunning outside sandbox constraints.
- comparison:
  - baseline: 20260303-1745-finetune-combine-01
  - variant: 20260303-1945-finetune-combine-01
  - delta: no observed behavior change in bounded finetune baseline-validation completion or reported metrics
- confidence: medium
- caveats:
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Execute `gfm-20260303-r01 / IF-B1 / baseline_validation` (smoke then `nsys`) on GPU3.

## Result: gfm-20260303-r01-inference-baseline-validation-01
- campaign_id: gfm-20260303-r01
- scenario: inference
- profile_stage: baseline_validation
- date_time_utc: 2026-03-03T20:15:47Z
- related_runs:
  - 20260303-1953-inference-combine-01
  - 20260303-1954-inference-combine-01
- question: Can the first bounded inference baseline-validation slice (`IF-B1`) complete under smoke and `nsys` wrappers on GPU3?
- summary: Yes. Both smoke and `nsys` IF-B1 runs completed end-to-end in combine test mode with matching test metric output and no runtime blockers. This confirms inference command-path health for baseline validation and advances Phase 4c progress to `1/2`.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - `nsys` artifact was generated at `artifacts/profiles/nsys/20260303-1954-inference-combine-01.nsys-rep`.
  - Smoke and `nsys` both reported `test_metric/toy_rmse=-2.278367519378662`.
  - GPU3 occupancy checks passed immediately before execution; active compute was present only on GPU0.
- comparison:
  - baseline: 20260303-1953-inference-combine-01
  - variant: 20260303-1954-inference-combine-01
  - delta: no observed behavior change between smoke and profiler-wrapped bounded inference slice
- confidence: medium
- caveats:
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Execute `gfm-20260303-r01 / IF-B2 / baseline_validation` (smoke then `nsys`) to close the Phase 4c inference baseline-validation `2/2` gate.

## Result: gfm-20260303-r01-inference-baseline-validation-02
- campaign_id: gfm-20260303-r01
- scenario: inference
- profile_stage: baseline_validation
- date_time_utc: 2026-03-03T20:32:54Z
- related_runs:
  - 20260303-1954-inference-combine-01
  - 20260303-2031-inference-combine-01
- question: Is the bounded inference baseline-validation trace reproducible across IF-B1 and IF-B2?
- summary: Yes. Both IF-B1 and IF-B2 `nsys` inference baseline-validation slices completed end-to-end on GPU3 with matching test metrics and no runtime blockers. IF-B2 reproduces IF-B1 behavior under the same command/config surface, closing the Phase 4c inference baseline-validation `2/2` gate. With this run, baseline validation gates for train, finetune, and inference are all complete.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - IF-B1 (`20260303-1954-inference-combine-01`) and IF-B2 (`20260303-2031-inference-combine-01`) both produced `.nsys-rep` artifacts.
  - Metrics were stable across both slices (`test=-2.278367519378662`).
  - IF-B2 smoke prerequisite required an out-of-sandbox rerun due expected sandbox CUDA/multiprocessing restrictions.
- comparison:
  - baseline: 20260303-1954-inference-combine-01
  - variant: 20260303-2031-inference-combine-01
  - delta: no observed behavior change in bounded inference baseline-validation completion or reported metrics
- confidence: medium
- caveats:
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Start Phase 5 by executing `gfm-20260303-r01 / TR-SU1 / steady_unannotated` with paired train windows for representativeness checks.

## Result: gfm-20260303-r01-train-steady-unannotated-01
- campaign_id: gfm-20260303-r01
- scenario: train
- profile_stage: steady_unannotated
- date_time_utc: 2026-03-03T20:50:44Z
- related_runs:
  - 20260303-2049-train-completion-01
  - 20260303-2050-train-completion-01
- question: Is the train scenario representative/stable enough for downstream analysis?
- summary: Yes for the first steady-state unannotated pair. Both TR-SU1 runs completed end-to-end on GPU3 with identical top-3 hotspot membership and low time-share drift. Representativeness thresholds are met (`top3_overlap >= 2/3`, `timeshare_drift_pct <= 20%`), so the train steady-state unannotated gate contribution is valid.
- stability_checks:
  - top3_overlap: 3/3
  - timeshare_drift_pct: 1.72
  - thresholds: overlap>=2/3, drift<=20%
  - representative_pass: true
- runtime_policy:
  - planned_soft_cap_minutes: 45
  - actual_runtime_minutes: 0.50
  - overrun_reason_if_any: none
- confidence: medium
- caveats:
  - Current task CLI does not expose explicit warmup/profile iteration controls; policy window metadata is tracked in run records for consistency.
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Execute `gfm-20260303-r01 / FT-SU1 / steady_unannotated` paired finetune windows.
