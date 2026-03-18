
# Next Task

## Single Bounded Task
Execute `gfm-20260304-r02 / TR-N1 / ncu_post_review` — the first realistic-scale `ncu` deep-dive run targeting hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`) in the `train` scenario, using the approved hotspot shortlist from `gfm-20260304-r02-realistic-review-gate-01`.
- next_action: `continue_scenario`

## Why This Is Immediate Priority
- `RV-R2` cross-scenario realistic review is complete with decision PASS (`realistic_cross_scenario_review_complete=true`, `ncu_allowed=true`).
- Approved hotspot shortlist is recorded in `gfm-20260304-r02-realistic-review-gate-01` (see `profiling/RESULTS.md`).
- `ampere_sgemm_32x32_sliced1x4_tn` is the top GPU kernel by time share (~30-32%) across all three scenarios and is the required first ncu target.
- Realistic-scale `ncu` is now the only remaining source of optimization-oriented deep-dive evidence blocking optimization discussion.

## Approved Hotspot Shortlist (from RV-R2)
1. `ampere_sgemm_32x32_sliced1x4_tn` (~30-32% GPU time; all scenarios; **priority target**)
2. `fmha_cutlassF_f32_aligned_64x64_rf_sm80` (~12.5-13%; all scenarios)
3. `ampere_sgemm_32x128_tn` (~9.3-9.8%; all scenarios)

## Exact Outputs Expected
- Check GPU3 occupancy: `nvidia-smi` and `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`.
- Run `make profiling-preflight` in the `griffin-profiling` conda environment.
- Execute one realistic-scale `ncu` bounded run with `CUDA_VISIBLE_DEVICES=3` targeting `ampere_sgemm_32x32_sliced1x4_tn` in the train scenario.
- Use `--kernel-name ampere_sgemm_32x32_sliced1x4_tn` (or equivalent filter) and appropriate metric sets (e.g. `--set full` or `--metrics sm__throughput,l1tex__throughput,dram__throughput,sm__warps_active`).
- Record a new campaign row for this ncu run in `profiling/CAMPAIGN_PLAN.md` (profile_stage: `ncu_post_review`).
- Record a run entry in `profiling/RUNS.md` with `ncu_intent: hotspot_deep_dive`, kernel target, command, and findings.
- Record findings in `profiling/RESULTS.md` using the NCU Hotspot Result Template.
- Update `handoff/CURRENT_STATUS.md` ncu_success counters.
- Append to `handoff/SESSION_LOG.md` and rotate `handoff/NEXT_TASK.md`.

## next_action Contract
- `continue_scenario`: current state; use while planning and executing ncu runs within this ncu scenario.
- `scenario_done`: use after all approved hotspots have been targeted and findings recorded.
- `ready_for_cross_scenario_review`: not applicable to ncu phase.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema (`targeted_fine_allowed=false`).
- No optimization recommendations before `optimization_discussion_allowed=true`.
- Do not target kernels outside the approved hotspot shortlist without recording rationale.

## Stopping Criteria
- At least one realistic-scale `ncu` run is complete, recorded in `profiling/RUNS.md` and `profiling/RESULTS.md`, and `ncu_success` counter is incremented in `handoff/CURRENT_STATUS.md`.
- `handoff/NEXT_TASK.md` is rotated to exactly one bounded next action (either next hotspot or human review gate for optimization discussion).
