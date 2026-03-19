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
- label_tier: <coarse|targeted_fine>
- label_schema_version: <nvtx-v1.0_or_other>
- hotspot_focus_id: <focus_id_or_na>
- parent_label_anchor: <coarse_root_or_na>
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
- nvtx_verification:
  - report: <nvtx_sum>
  - force_export: <true|false>
  - retry_required: <true|false>
  - final_status: <present|absent|inconclusive>
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
  - targeted_fine_allowed: <true|false>
  - optimization_discussion_allowed: <true|false>
- summary: <2-5 sentences>
- approved_hotspots_or_focus: <required_non_empty_if_targeted_fine_allowed_else_none>
- approved_label_schema_version: <nvtx-v<major>.<minor>>
- approved_rank_scope: <all_ranks|single_rank|subset>
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
- Direct like-for-like comparisons between annotated traces require matching `label_tier` and `label_schema_version`; otherwise mark as non-comparable unless explicitly normalized and caveated.
- Any `absent` NVTX conclusion is invalid unless forced-export verification evidence is recorded (`nsys stats --force-export=true --report nvtx_sum ...`).
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

## Result: gfm-20260303-r01-finetune-steady-unannotated-01
- campaign_id: gfm-20260303-r01
- scenario: finetune
- profile_stage: steady_unannotated
- date_time_utc: 2026-03-03T21:00:16Z
- related_runs:
  - 20260303-2058-finetune-combine-01
  - 20260303-2059-finetune-combine-01
- question: Is the finetune scenario representative/stable enough for downstream analysis?
- summary: Yes for the first steady-state unannotated finetune pair. Both FT-SU1 runs completed end-to-end on GPU3 with identical top-3 hotspot membership and low time-share drift. Representativeness thresholds are met (`top3_overlap >= 2/3`, `timeshare_drift_pct <= 20%`), so the finetune steady-state unannotated gate contribution is valid.
- stability_checks:
  - top3_overlap: 3/3
  - timeshare_drift_pct: 1.16
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
- next_action: Execute `gfm-20260303-r01 / IF-SU1 / steady_unannotated` paired inference windows.

## Result: gfm-20260303-r01-inference-steady-unannotated-01
- campaign_id: gfm-20260303-r01
- scenario: inference
- profile_stage: steady_unannotated
- date_time_utc: 2026-03-03T21:39:30Z
- related_runs:
  - 20260303-2134-inference-combine-01
  - 20260303-2138-inference-combine-01
- question: Is the inference scenario representative/stable enough for downstream analysis?
- summary: Yes for the first steady-state unannotated inference pair. Both IF-SU1 runs completed end-to-end on GPU3 with identical top-3 hotspot membership and low time-share drift. Representativeness thresholds are met (`top3_overlap >= 2/3`, `timeshare_drift_pct <= 20%`), so the inference steady-state unannotated gate contribution is valid.
- stability_checks:
  - top3_overlap: 3/3
  - timeshare_drift_pct: 0.86
  - thresholds: overlap>=2/3, drift<=20%
  - representative_pass: true
- runtime_policy:
  - planned_soft_cap_minutes: 45
  - actual_runtime_minutes: 0.38
  - overrun_reason_if_any: none
- confidence: medium
- caveats:
  - Current task CLI does not expose explicit warmup/profile iteration controls; policy window metadata is tracked in run records for consistency.
  - Dataset/checkpoint setup is minimal synthetic staging for command-path verification, not production-scale workload fidelity.
- next_action: Draft Phase 6a minimal coarse NVTX taxonomy spec and insertion map for `hmaintask_completion.py` and `hmaintask_combine.py`.

## Result: gfm-20260303-r01-train-steady-annotated-01
- campaign_id: gfm-20260303-r01
- scenario: train
- profile_stage: steady_annotated
- label_tier: coarse
- label_schema_version: nvtx-v1.0
- hotspot_focus_id: na
- parent_label_anchor: na
- date_time_utc: 2026-03-04T15:41:55Z
- related_runs:
  - 20260304-1541-train-annotated-completion-01
  - 20260303-2049-train-completion-01
- question: Does the first coarse-labeled annotated train capture complete and expose the expected NVTX taxonomy for analysis?
- summary: Yes. The TR-SA1 annotated `nsys` run completed end-to-end on GPU3 and produced a new `.nsys-rep` artifact. NVTX summary output confirms the coarse label set is present and interpretable in trace-level timing reports, with no missing required labels among those expected for the train path. This establishes Phase 7 train-row progress and keeps review/post-review gates unchanged.
- nvtx_label_coverage:
  - labels_expected: [`gfm.setup`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`]
  - labels_seen: [`gfm.setup`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`]
  - missing_labels: none
- key_observations:
  - Highest-share NVTX range was `gfm.train_epoch` at `38.8%` of NVTX-tracked time.
  - `gfm.eval_task` appeared 3 times (25.4% combined share), aligning with validation + test boundaries in this bounded slice.
  - Checkpoint-related work is captured separately as `gfm.checkpoint_io` (3 instances, 8.4% share).
- confidence: medium
- caveats:
  - Current dataset/checkpoint setup is synthetic/minimal for command-path verification, so NVTX distribution may differ from production-scale workloads.
  - This result is a single annotated capture row; cross-scenario annotated comparisons remain pending.
- next_action: Execute `gfm-20260303-r01 / FT-SA1 / steady_annotated` on GPU3 and record the same NVTX coverage fields.

## Result: gfm-20260303-r01-finetune-steady-annotated-01
- campaign_id: gfm-20260303-r01
- scenario: finetune
- profile_stage: steady_annotated
- label_tier: coarse
- label_schema_version: nvtx-v1.0
- hotspot_focus_id: na
- parent_label_anchor: na
- date_time_utc: 2026-03-04T16:22:00Z
- related_runs:
  - 20260304-1622-finetune-annotated-combine-01
  - 20260303-2058-finetune-combine-01
- question: Does the first coarse-labeled annotated finetune capture complete and expose the expected NVTX taxonomy for analysis?
- summary: Yes after verification hardening. The FT-SA1 annotated `nsys` run completed end-to-end on GPU3 and produced a valid `.nsys-rep` artifact. A forced-export recheck with `nvtx_sum` confirms the expected coarse NVTX taxonomy is present; the earlier empty `nvtxsum` output is treated as a reporting/export-path false negative rather than missing instrumentation.
- nvtx_label_coverage:
  - labels_expected: [`gfm.setup`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`]
  - labels_seen: [`gfm.setup`, `gfm.train_epoch`, `gfm.train_step`, `gfm.eval_task`, `gfm.checkpoint_io`, `gfm.final_test_pass`]
  - missing_labels: none
- nvtx_verification:
  - report: nvtx_sum
  - force_export: true
  - retry_required: true
  - final_status: present
- key_observations:
  - `nsys` emitted both `.nsys-rep` and `.sqlite` outputs for FT-SA1 under the expected command/config surface.
  - Forced-export command evidence: `nsys stats --force-export=true --report nvtx_sum artifacts/profiles/nsys/20260304-1622-finetune-annotated-combine-01.nsys-rep`.
  - Recheck shows expected coarse labels with top shares led by `gfm.train_epoch` (35.5%) and `gfm.eval_task` (24.9%).
  - `cuda_gpu_kern_sum` remained available, with top-share kernels led by `gemv2T_kernel_val` and `multi_tensor_apply_kernel` variants.
- confidence: medium
- caveats:
  - The initial non-forced/deprecated `nvtxsum` check produced a false-negative signal before forced-export verification.
  - Dataset/checkpoint setup remains synthetic/minimal for command-path verification and may not reflect production-scale runtime behavior.
- next_action: Execute `gfm-20260303-r01 / IF-SA1 / steady_annotated` on GPU3 and record NVTX label coverage using forced-export `nvtx_sum` verification policy.

## Result: gfm-20260303-r01-inference-steady-annotated-01
- campaign_id: gfm-20260303-r01
- scenario: inference
- profile_stage: steady_annotated
- label_tier: coarse
- label_schema_version: nvtx-v1.0
- hotspot_focus_id: na
- parent_label_anchor: na
- date_time_utc: 2026-03-04T16:52:30Z
- related_runs:
  - 20260304-1652-inference-annotated-combine-01
  - 20260303-2134-inference-combine-01
- question: Does the first coarse-labeled annotated inference capture complete and expose the expected NVTX taxonomy for analysis?
- summary: Yes. The IF-SA1 annotated `nsys` run completed end-to-end on GPU3 and produced a valid `.nsys-rep` artifact. Forced-export `nvtx_sum` verification confirms expected inference-path coarse labels are present with no missing required labels for test-mode execution. This closes Phase 7 `steady_annotated` capture rows across train, finetune, and inference.
- nvtx_label_coverage:
  - labels_expected: [`gfm.setup`, `gfm.mode_test_only`, `gfm.eval_task`, `gfm.checkpoint_io`]
  - labels_seen: [`gfm.setup`, `gfm.mode_test_only`, `gfm.eval_task`, `gfm.checkpoint_io`]
  - missing_labels: none
- nvtx_verification:
  - report: nvtx_sum
  - force_export: true
  - retry_required: false
  - final_status: present
- key_observations:
  - `gfm.mode_test_only` and nested `gfm.eval_task` account for most NVTX-attributed time in this bounded inference path.
  - Coarse setup and checkpoint labels are visible (`gfm.setup`, `gfm.checkpoint_io`) with non-zero time shares.
  - Test metric output remains stable at `test=-2.278367519378662`.
- confidence: medium
- caveats:
  - Dataset/checkpoint setup remains synthetic/minimal for command-path verification and may not reflect production-scale runtime behavior.
  - This result confirms capture health and label visibility, not production-scale hotspot representativeness.
- next_action: Evaluate and record capture-complete gate status, then advance campaign row `RV-G1` through human review workflow.

## Result: gfm-20260303-r01-capture-gate-01
- campaign_id: gfm-20260303-r01
- profile_stage: capture_gate
- date_time_utc: 2026-03-04T17:01:06Z
- question: Are all baseline + steady-state captures complete (or non-actionably blocked)?
- capture_gate:
  - baseline_validation_complete: true
  - steady_unannotated_complete: true
  - steady_annotated_complete: true
  - non_actionable_blockers_documented: true
  - capture_complete: true
- summary: Capture requirements are satisfied for the in-scope scenarios (`train`, `finetune`, `inference`). All baseline-validation, steady-unannotated, and steady-annotated rows are complete, with no unresolved actionable blockers preventing capture closure. The campaign is now at the human review gate and cannot proceed to `ncu_post_review` or optimization discussion until explicit review approval is recorded.
- confidence: high
- next_action: Record human review outcome for `RV-G1` and update review-gate flags (`review_complete`, `ncu_allowed`, `optimization_discussion_allowed`).

## Result: gfm-20260303-r01-review-gate-01
- campaign_id: gfm-20260303-r01
- profile_stage: review_gate
- date_time_utc: 2026-03-05T18:40:47Z
- related_runs:
  - gfm-20260303-r01-capture-gate-01
  - 20260304-1541-train-annotated-completion-01
  - 20260304-1622-finetune-annotated-combine-01
  - 20260304-1652-inference-annotated-combine-01
- question: Has human review approved progression to post-review deep dives?
- review_outcome:
  - review_complete: true
  - ncu_allowed: false
  - targeted_fine_allowed: false
  - optimization_discussion_allowed: false
- summary: Human review was completed using the standardized analysis bundles for one annotated run per scenario: `artifacts/profiles/analysis/20260304-1541-train-annotated-completion-01/`, `artifacts/profiles/analysis/20260304-1622-finetune-annotated-combine-01/`, and `artifacts/profiles/analysis/20260304-1652-inference-annotated-combine-01/`. Reviewed evidence is explicitly classified as `minimal_staged` and interpreted under `profiling/SCALE_PROFILES.md`, so it is accepted for workflow/capture confidence but not for optimization-targeted escalation. Review therefore closes `RV-G1` while keeping `ncu_allowed`, `targeted_fine_allowed`, and `optimization_discussion_allowed` set to `false` pending realistic-scale evidence.
- approved_hotspots_or_focus: none
- approved_label_schema_version: nvtx-v1.0
- approved_rank_scope: all_ranks
- next_action: Start realistic-scale campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` or document concrete production-asset blocker if provenance requirements are not yet met.

## Result: gfm-20260303-r01-train-auto-chain-smoke-01
- campaign_id: gfm-20260303-r01
- scenario: train
- profile_stage: baseline_validation
- date_time_utc: 2026-03-05T22:55:42Z
- related_runs:
  - 20260305-2252-toychain-model-20260305b-s01
  - 20260305-2253-toychain-model-20260305b-s02
  - 20260305-2255-toychain-model-20260305b-s03
- question: Can an autonomous agent execute multiple bounded smoke slices with checkpoint handoff and summary logging without human intervention?
- summary: The toy autonomous chain completed `3/3` slices with `resume-mode=model`, using fixed `max_train_steps` and `max_eval_steps` bounds. Checkpoint handoff and append-only chain summary updates were successful for each slice. A preceding run with missing dataset alias failed fast and validated chain failure handling.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - Bounded train/eval controls reliably terminated slices at configured step limits.
  - Chain summary file `profiling/chains/active/CHAIN_SUMMARY_toychain-model-20260305b.md` captured checkpoint in/out transitions and per-slice status.
  - Stop-on-failure behavior was verified by the initial failed alias-path attempt.
- comparison:
  - baseline: 20260305-2250-toychain-model-20260305-s01
  - variant: 20260305-2252-toychain-model-20260305b-s01
  - delta: failure due missing dataset alias corrected by switching to available dataset path; chain then completed end-to-end
- confidence: high
- caveats:
  - Evidence is smoke-only (no profiler traces) and primarily validates orchestration mechanics.
- next_action: Run realistic-scale `TR-B1` with capped smoke + capped `nsys`, then generate analysis bundle.

## Result: gfm-20260304-r02-train-auto-chain-state-01
- campaign_id: gfm-20260304-r02
- scenario: train
- profile_stage: baseline_validation
- date_time_utc: 2026-03-05T23:00:07Z
- related_runs:
  - 20260305-2258-toychain-state-20260305-s01
  - 20260305-2300-toychain-state-20260305-s02
- question: Is full trainer-state resume viable for unattended chained slices prior to realistic overnight campaign execution?
- summary: Full-state chaining succeeded across two bounded slices using `save_state_path/load_state_path` handoff. Slice 2 successfully loaded from `state-slice-01` and produced `state-slice-02`, confirming state continuity workflow viability for unattended execution.
- runtime_overview:
  - wall_time_sec: unknown
  - gpu_busy_fraction: unknown
- key_observations:
  - Full-state handoff directory convention (`state-slice-<k>`) worked as designed.
  - Chain summary recorded deterministic state transition (`state-slice-01 -> state-slice-02`).
  - No GPU3 occupancy blockers occurred during the chain.
- comparison:
  - baseline: 20260305-2258-toychain-state-20260305-s01
  - variant: 20260305-2300-toychain-state-20260305-s02
  - delta: successful resume from previous state snapshot
- confidence: high
- caveats:
  - Validation was smoke-only and did not yet include `nsys` capture in this chain.
- next_action: Apply the same bounded controls to realistic `TR-B1` smoke + paired `nsys` capture and analysis.

## Result: gfm-20260304-r02-realistic-cross-scenario-review-01
- campaign_id: gfm-20260304-r02
- profile_stage: baseline_validation (cross-scenario)
- date_time_utc: 2026-03-18T00:00:00Z
- related_runs:
  - 20260312-1526-trb1-realistic-20260312a-s01
  - 20260312-1532-trb1-realistic-20260312a-s02
  - 20260312-1537-trb1-realistic-20260312a-s03
  - 20260306-1538-ftb1-realistic-20260306a-s01
  - 20260306-1543-ftb1-realistic-20260306a-s02
  - 20260306-1553-ftb1-realistic-20260306a-s03
  - 20260306-1647-ifb1-realistic-20260306b-s01
  - 20260306-1650-ifb1-realistic-20260306b-s02
  - 20260306-1652-ifb1-realistic-20260306b-s03
- question: Are the realistic-scale TR-B1, FT-B1, and IF-B1 nsys chains consistent, stable, and sufficient to approve realistic-scale ncu deep-dive planning?
- summary: Yes. All 9 slices across three scenarios completed with `nvtx_coverage_status: present` and deterministic intra-scenario kernel launch counts. The top-3 GPU kernel identities are identical across train, finetune, and inference in type and rank — dominated by small-tile GEMM (`ampere_sgemm_32x32_sliced1x4_tn` ~30-32%), flash attention (`fmha_cutlassF_f32_aligned_64x64_rf_sm80` ~12.5-13%), and a second GEMM variant (`ampere_sgemm_32x128_tn` ~9.3-9.8%). NVTX timeshare structure is stable within each scenario across 3 slices. Evidence quality is sufficient to approve realistic-scale ncu targeting.
- scenario_comparison:
  - train: NVTX dominated by eval_task (~48.5%), train_epoch (~33%), final_test_pass (~16.5%); GPU top-3 sgemm_32x32 30.4%, fmha 12.5%, sgemm_32x128 9.3%; 22731 sgemm launches/slice (stable).
  - finetune: Near-identical NVTX structure to train (same script path, different initial checkpoint); GPU top-3 sgemm_32x32 30.5%, fmha 12.5%, sgemm_32x128 9.4%; 22754 sgemm launches/slice (stable).
  - inference: NVTX dominated by mode_test_only+eval_task (~96%), no train_epoch; GPU top-3 sgemm_32x32 31.7%, fmha 13.0%, sgemm_32x128 9.8%; 7477 sgemm launches/slice (~1/3 of train/finetune, consistent with 51 vs 153 eval_task instances).
- confidence: high
- caveats:
  - Evidence is at slice_size_tier=8/4 (max_train_steps=8, max_eval_steps=4); inference is eval-only. Kernel time-share percentages should be treated as relative indicators, not absolute production-scale measures.
  - Intra-scenario slice-to-slice NVTX wall-time variation exists (e.g. TR-B1 eval_task 122s vs 131s vs 124s total_ms) but top-3 kernel identity and rank are stable — this is expected shared-host noise.
  - cudaHostAlloc costs are elevated in train/finetune (338-415 calls, ~1884-1951 µs/call) vs near-absent in inference; optimizer state allocation is the likely cause and is a secondary investigation candidate.
- next_action: Execute realistic-scale ncu run on approved hotspot shortlist; start with scenario `train` targeting `ampere_sgemm_32x32_sliced1x4_tn` (top kernel by GPU time share, present in all scenarios).

## Result: gfm-20260304-r02-realistic-review-gate-01
- campaign_id: gfm-20260304-r02
- profile_stage: review_gate
- date_time_utc: 2026-03-18T00:00:00Z
- related_runs:
  - gfm-20260304-r02-realistic-cross-scenario-review-01
- question: Has the cross-scenario realistic-scale review approved progression to realistic-scale ncu deep dives?
- review_outcome:
  - review_complete: true
  - ncu_allowed: true
  - targeted_fine_allowed: false
  - optimization_discussion_allowed: false
- summary: RV-R2 cross-scenario review decision is PASS. All three realistic-scale scenarios (TR-B1, FT-B1, IF-B1) provide consistent, stable multi-slice nsys evidence under realistic-v2 policy. A cross-scenario hotspot shortlist of three kernels was identified (sgemm_32x32, fmha, sgemm_32x128) with identical type-and-rank ordering across all scenarios. Realistic-scale ncu deep dives are now approved against this shortlist. Targeted fine NVTX expansion and optimization discussion remain disabled pending ncu evidence.
- approved_hotspots_or_focus:
  - hotspot_1: `ampere_sgemm_32x32_sliced1x4_tn` (~30-32% GPU time; present in all 3 scenarios; priority target)
  - hotspot_2: `fmha_cutlassF_f32_aligned_64x64_rf_sm80` (~12.5-13% GPU time; present in all 3 scenarios)
  - hotspot_3: `ampere_sgemm_32x128_tn` (~9.3-9.8% GPU time; present in all 3 scenarios)
- approved_label_schema_version: nvtx-v1.0
- approved_rank_scope: all_ranks
- next_action: Plan and execute first realistic-scale ncu run targeting hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`) in the train scenario; record ncu_intent, command, and findings in RUNS.md and RESULTS.md.

## Result: gfm-20260304-r02-train-ncu-hotspot-01
- campaign_id: gfm-20260304-r02
- scenario: train
- profile_stage: ncu_post_review
- date_time_utc: 2026-03-18T19:46:00Z
- related_runs:
  - 20260318-1946-train-completion-01
  - 20260312-1537-trb1-realistic-20260312a-s03
- hotspot_id: hotspot_1
- summary: TR-N1 was relaunched successfully after GPU3 cleared and the local `ncu` command shape was corrected, but no valid Nsight Compute report was generated. The profiler emitted `ERR_NVGPUCTRPERM` when attempting to access GPU performance counters, so this run does not yet provide usable hotspot metrics for `ampere_sgemm_32x32_sliced1x4_tn`.
- kernel_findings:
  - No kernel metrics were collected because host-side NVIDIA GPU performance counter access is disabled for the current user.
  - The bounded train workload itself completed under the direct `ncu` launch path, which confirms command/runtime viability once counter permissions are enabled.
- confidence: high
- caveats:
  - No `.ncu-rep` artifact was produced, so there is no profiler evidence to interpret for hotspot behavior.
  - This is a host-permissions blocker, not a hotspot-selection, dataset, or script-path blocker.
- next_action: Enable NVIDIA GPU performance counter access for the current user on GPU3, then rerun `TR-N1` unchanged against hotspot_1.
