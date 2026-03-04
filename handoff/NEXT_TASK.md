# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / FT-SA1 / steady_annotated`: run one steady-state annotated `nsys` finetune capture on `hmaintask_combine.py` using the current coarse NVTX ranges.

## Why This Is Immediate Priority
- `TR-SA1` is complete and Phase 7 is in progress.
- `FT-SA1` is the next required `steady_annotated` row in the campaign matrix.
- Workflow order requires annotated capture rows before review gate and any post-review deep-dive work.

## Exact Outputs Expected
- Required preconditions in `griffin-profiling` environment:
  - `make profiling-preflight`
  - `nvidia-smi`
  - `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`
- If GPU3 has active compute processes, do not run profiling; document blocker in `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md`.
- If GPU3 is clear, execute one annotated `nsys` run on GPU3 with:
  - `CUDA_VISIBLE_DEVICES=3`
  - `hconfig_profiling_single_gpu.yaml`
  - combine finetune train path (`hmaintask_combine.py --mode train`)
  - load path `checkpoints/single-completion/best_checkpoint`
  - save path `checkpoints/single-sft`
  - run ID format `YYYYMMDD-HHMM-finetune-annotated-...`
- Record/update:
  - `profiling/CAMPAIGN_PLAN.md` row `FT-SA1` (`status`, `nsys_run_id`, blocker field)
  - append run record in `profiling/RUNS.md`
  - append summary in `profiling/RESULTS.md`
  - update `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md` (if phase status changes), and append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No expansion into targeted-fine NVTX labels.
- No `ncu` execution.
- No optimization recommendations before review gate completion.

## Stopping Criteria
- `FT-SA1` has either:
  - a completed annotated `nsys` capture with artifact path recorded, or
  - a documented non-actionable blocker captured consistently across profiling and handoff docs.
- Documentation/handoff files are synchronized for fresh-session continuity.

## Definition Of Done (Template Style)
- [ ] Preconditions executed and GPU3 occupancy checked.
- [ ] `FT-SA1` annotated `nsys` capture attempted/executed per policy.
- [ ] `profiling/CAMPAIGN_PLAN.md`, `profiling/RUNS.md`, and `profiling/RESULTS.md` updated.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md` (if needed), and `handoff/SESSION_LOG.md` updated.
