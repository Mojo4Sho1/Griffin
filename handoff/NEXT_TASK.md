
# Next Task

## Single Bounded Task
Complete `gfm-20260304-r02 / TR-N1 / ncu_post_review` via user-run privileged execution and post-run analysis — the human operator should run the bounded `sudo ncu` hotspot capture for hotspot_1 (`ampere_sgemm_32x32_sliced1x4_tn`) in the `train` scenario, then the next agent should analyze the produced artifact and finish the documentation updates.
- next_action: `continue_scenario`

## Why This Is Immediate Priority
- `RV-R2` cross-scenario realistic review is complete with decision PASS (`realistic_cross_scenario_review_complete=true`, `ncu_allowed=true`).
- Approved hotspot shortlist is recorded in `gfm-20260304-r02-realistic-review-gate-01` (see `profiling/RESULTS.md`).
- `ampere_sgemm_32x32_sliced1x4_tn` is the top GPU kernel by time share (~30-32%) across all three scenarios and is the required first ncu target.
- Realistic-scale `ncu` is now the only remaining source of optimization-oriented deep-dive evidence blocking optimization discussion.
- Prior attempt at `2026-03-18T17:52:01Z` was blocked correctly by shared-host policy because GPU3 had active compute processes attached.
- Follow-up attempt at `2026-03-18T19:46:00Z` launched successfully after GPU3 cleared, but valid `ncu` capture failed with `ERR_NVGPUCTRPERM`.
- The agreed path forward is to avoid host-wide policy changes on the shared server: the human will run the same bounded hotspot capture under `sudo`, and the next agent will analyze the artifact afterward.

## Approved Hotspot Shortlist (from RV-R2)
1. `ampere_sgemm_32x32_sliced1x4_tn` (~30-32% GPU time; all scenarios; **priority target**)
2. `fmha_cutlassF_f32_aligned_64x64_rf_sm80` (~12.5-13%; all scenarios)
3. `ampere_sgemm_32x128_tn` (~9.3-9.8%; all scenarios)

## Exact Outputs Expected
- Check GPU3 occupancy: `nvidia-smi` and `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`.
- Run `make profiling-preflight` in the `griffin-profiling` conda environment.
- Human operator runs one realistic-scale bounded `sudo ncu` capture targeting `ampere_sgemm_32x32_sliced1x4_tn` in the train scenario.
- Preferred command shape is direct `ncu [options] [program] [program-arguments]` form, not the older wrapper form with an extra `--`.
- Use `--kernel-name ampere_sgemm_32x32_sliced1x4_tn` (or equivalent filter) and appropriate metric sets (e.g. `--set full` or `--metrics sm__throughput,l1tex__throughput,dram__throughput,sm__warps_active`).
- After the run completes, the next agent must:
  - inspect the resulting `.ncu-rep` artifact
  - update `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md`
  - record findings in `profiling/RESULTS.md` using the NCU Hotspot Result Template
  - update `handoff/CURRENT_STATUS.md` ncu_success counters if the run is valid
  - append to `handoff/SESSION_LOG.md` and rotate `handoff/NEXT_TASK.md`

## Canonical Manual Command
```bash
sudo CUDA_VISIBLE_DEVICES=3 ncu -k regex:ampere_sgemm_32x32_sliced1x4_tn --kernel-name-base function --set full --export artifacts/profiles/ncu/20260318-1946-train-completion-01 --target-processes all accelerate launch --config_file hconfig_profiling_single_gpu.yaml hmaintask_completion.py datasets/single-pretrain-v3-hf logs/prof train-hotspot-ncu --savepath checkpoints/single-completion --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

If the human prefers a fresh run ID, the next agent may substitute a new canonical run ID and must then update all docs consistently.

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
