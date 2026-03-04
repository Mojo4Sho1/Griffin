# Next Task

## Single Bounded Task
Execute campaign row `gfm-20260303-r01 / IF-SA1 / steady_annotated`: run one steady-state annotated `nsys` inference capture on `hmaintask_combine.py` using the current coarse NVTX ranges.

## Why This Is Immediate Priority
- `TR-SA1` and `FT-SA1` capture rows are complete and Phase 7 is still in progress.
- `IF-SA1` is the remaining required `steady_annotated` scenario row before capture-complete evaluation.
- Workflow order requires completing annotated capture rows before review gate and any post-review deep-dive work.

## Exact Outputs Expected
- Required preconditions in `griffin-profiling` environment:
  - `make profiling-preflight`
  - `nvidia-smi`
  - `nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv`
- If GPU3 has active compute processes, do not run profiling; document blocker in `profiling/RUNS.md`, `handoff/CURRENT_STATUS.md`, and `handoff/SESSION_LOG.md`.
- If GPU3 is clear, execute one annotated `nsys` run on GPU3 with:
  - `CUDA_VISIBLE_DEVICES=3`
  - `hconfig_profiling_single_gpu.yaml`
  - combine inference test path (`hmaintask_combine.py --mode test`)
  - load path `checkpoints/single-sft/best_checkpoint`
  - run ID format `YYYYMMDD-HHMM-inference-annotated-...`
- Record/update:
  - `profiling/CAMPAIGN_PLAN.md` row `IF-SA1` (`status`, `nsys_run_id`, blocker field)
  - append run record in `profiling/RUNS.md`
  - append summary in `profiling/RESULTS.md` with NVTX coverage fields
  - for NVTX verification evidence, use `nsys stats --force-export=true --report nvtx_sum <run>.nsys-rep`; if initial NVTX output is empty, retry forced-export before documenting anomaly/blocker
  - update `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md` (if phase status changes), and append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No expansion into targeted-fine NVTX labels.
- No `ncu` execution.
- No optimization recommendations before review gate completion.

## Stopping Criteria
- `IF-SA1` has either:
  - a completed annotated `nsys` capture with artifact path recorded, or
  - a documented non-actionable blocker captured consistently across profiling and handoff docs.
- Documentation/handoff files are synchronized for fresh-session continuity.

## Definition Of Done (Template Style)
- [ ] Preconditions executed and GPU3 occupancy checked.
- [ ] `IF-SA1` annotated `nsys` capture attempted/executed per policy.
- [ ] `profiling/CAMPAIGN_PLAN.md`, `profiling/RUNS.md`, and `profiling/RESULTS.md` updated.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md` (if needed), and `handoff/SESSION_LOG.md` updated.
