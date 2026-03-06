# Next Task

## Single Bounded Task
Execute one paired realistic-scale profiler run for campaign row `gfm-20260304-r02 / TR-B1 / baseline_validation` (`nsys` mode, GPU3 only) using the same bounded arguments as the canonical smoke chain, then generate the required analysis bundle and sync campaign/handoff docs.

## Why This Is Immediate Priority
- Canonical detached smoke-chain evidence for `TR-B1` is now complete (`trb1-realistic-20260306b`).
- The next required baseline-validation artifact is the paired realistic-scale `nsys` capture.
- Policy requires an analysis bundle for every successful new `nsys` run.

## Exact Outputs Expected
- Run preconditions in order:
  - activate `griffin-profiling`
  - `make profiling-preflight`
  - `nvidia-smi`
  - `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`
- If GPU3 is occupied, do not run; document blocker in `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md`.
- If GPU3 is clear, execute one `nsys` run with:
  - `CUDA_VISIBLE_DEVICES=3`
  - `hmaintask_completion.py`
  - dataset `datasets/single-pretrain-v3-hf`
  - bounded args matching chain shape (`--max_train_steps 8`, `--max_eval_steps 4`, plus current baseline flags)
- Generate analysis bundle:
  - `scripts/analyze_nsys_run.sh --run-id <new_run_id>`
  - verify outputs under `artifacts/profiles/analysis/<new_run_id>/`
- Update docs:
  - append run record in `profiling/RUNS.md` (with `analysis_artifacts_path` and `analysis_status`)
  - update `profiling/CAMPAIGN_PLAN.md` `TR-B1` row `nsys_run_id`
  - update `handoff/CURRENT_STATUS.md` and append `handoff/SESSION_LOG.md`
  - keep `handoff/NEXT_TASK.md` rotated to exactly one bounded follow-up.

## Must Not Change
- No model semantic changes.
- No NVTX instrumentation expansion beyond current coarse schema.
- No optimization recommendations.

## Stopping Criteria
- Exactly one new realistic-scale `TR-B1` `nsys` run attempt is recorded and fully documented.
- If successful, analysis bundle exists and is referenced in profiling docs.
- Campaign + handoff state is synchronized.
- `handoff/NEXT_TASK.md` remains one bounded action.

## Definition Of Done (Template Style)
- [ ] Preconditions executed (`preflight` + GPU3 occupancy checks).
- [ ] One new `TR-B1` realistic-scale `nsys` run attempted on GPU3 (or blocker documented if occupied).
- [ ] `scripts/analyze_nsys_run.sh --run-id <new_run_id>` executed for successful run.
- [ ] `profiling/RUNS.md` and `profiling/CAMPAIGN_PLAN.md` updated.
- [ ] `handoff/CURRENT_STATUS.md` and `handoff/SESSION_LOG.md` updated.
- [ ] `handoff/NEXT_TASK.md` rotated to one bounded follow-up action.
