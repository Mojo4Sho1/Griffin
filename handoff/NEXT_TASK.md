# Next Task

## Single Bounded Task
Complete `gfm-20260304-r02 / TR-N2 / ncu_post_review` for hotspot_2 (`fmha_cutlassF_f32_aligned_64x64_rf_sm80`) in the `train` scenario using the user-started `tmux` workflow and the new default `core + cap` capture path via `scripts/run_ncu_hotspot.sh train hotspot_2`.
- next_action: `continue_scenario`

## Why This Is Immediate Priority
- `RV-R2` cross-scenario realistic review is complete with decision PASS (`realistic_cross_scenario_review_complete=true`, `ncu_allowed=true`).
- `TR-N1` validation is complete: `20260319-1514-train-completion-01` was re-analyzed successfully on `2026-03-24` with the no-timeout, resumable SQLite-first bundle workflow.
- The pause on `TR-N2` is now lifted because `TR-N1` bundle validation passed.
- Hotspot_2 (`fmha_cutlassF_f32_aligned_64x64_rf_sm80`) is the next approved cross-scenario kernel class and gives us a non-GEMM comparison point after hotspot_1.
- The oversized March 19 `--set full` report is now treated as legacy evidence; future default capture policy is `core + cap` unless the run record explicitly justifies escalation.
- The agreed trust boundary remains unchanged: the human owns `sudo` and starts the `tmux` session; the agent monitors progress and performs post-run analysis.

## Approved Hotspot Shortlist (from RV-R2)
1. `ampere_sgemm_32x32_sliced1x4_tn` (~30-32% GPU time; all scenarios; priority target)
2. `fmha_cutlassF_f32_aligned_64x64_rf_sm80` (~12.5-13%; all scenarios)
3. `ampere_sgemm_32x128_tn` (~9.3-9.8%; all scenarios)

## Exact Outputs Expected
- Check GPU3 occupancy: `nvidia-smi` and `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`.
- Run `make profiling-preflight` in the `griffin-profiling` conda environment.
- Human operator creates an attached `tmux` session, launches one realistic-scale bounded `sudo ncu` capture targeting hotspot_2 in the train scenario via `scripts/run_ncu_hotspot.sh train hotspot_2`, then detaches once the command is running cleanly.
- Default evidence-grade capture path is `--sections-profile core --launch-count 5`; optional `ncu_intent: tooling_smoke` validation should generally use `--launch-count 1`.
- Preferred invocation path is `scripts/run_ncu_hotspot.sh train hotspot_2`, which performs occupancy checks, runs preflight, generates a fresh UTC run ID when omitted, prints the fully resolved command, and launches the bounded `sudo ncu` capture.
- After the run completes, derive the SQLite-first bundle with `python scripts/analyze_ncu_run.py --run-id <run_id>`; if the report is large, do this in `tmux` and do not add timeout flags by default.
- Then inspect the resulting `.ncu-rep` artifact and `artifacts/profiles/analysis/<run_id>/ncu_analysis.sqlite`, update `profiling/CAMPAIGN_PLAN.md` and `profiling/RUNS.md`, record findings in `profiling/RESULTS.md`, update `handoff/CURRENT_STATUS.md` counters if the run is valid, append to `handoff/SESSION_LOG.md`, and rotate `handoff/NEXT_TASK.md`.

## Canonical User-Started `tmux` Flow
```bash
tmux new -s tr-ncu-h2-<YYYYMMDD-HHMM>
cd /home/jxc02713/projects/GFM/Griffin
conda activate griffin-profiling
scripts/run_ncu_hotspot.sh train hotspot_2 |& tee artifacts/profiles/ncu/tr-ncu-h2-<YYYYMMDD-HHMM>.log
```

After the command starts cleanly, detach with `Ctrl-b d`.

Monitor or reattach later with:

```bash
tmux capture-pane -pt tr-ncu-h2-<YYYYMMDD-HHMM> | tail -n 80
tmux attach -t tr-ncu-h2-<YYYYMMDD-HHMM>
```

After the run finishes, derive the SQLite-first bundle with:

```bash
python scripts/analyze_ncu_run.py --run-id <run_id>
```

## Direct Command Shape (Reference)
```bash
sudo env PATH="$PATH" CUDA_VISIBLE_DEVICES=3 ncu -k regex:fmha_cutlassF_f32_aligned_64x64_rf_sm80 --kernel-name-base function -c 5 --section LaunchStats --section Occupancy --section SchedulerStats --section WarpStateStats --section ComputeWorkloadAnalysis --section MemoryWorkloadAnalysis --section SpeedOfLight --section WorkloadDistribution --export artifacts/profiles/ncu/<run_id> --target-processes all accelerate launch --config_file hconfig_profiling_single_gpu.yaml hmaintask_completion.py datasets/single-pretrain-v3-hf logs/prof train-hotspot-ncu --savepath checkpoints/single-completion --maxepoch 1 --max_train_steps 8 --max_eval_steps 4 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512
```

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
- `TR-N2` either completes as an evidence-grade `hotspot_deep_dive` or is explicitly recorded as a shorter `ncu_intent: tooling_smoke` validation step with a follow-up full run still queued.
- `handoff/NEXT_TASK.md` is rotated to exactly one bounded next action (either next hotspot or human review gate for optimization discussion).
