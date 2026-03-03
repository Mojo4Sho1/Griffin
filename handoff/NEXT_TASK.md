# Next Task

## Single Bounded Task
Execute Phase 6b: insert the minimal coarse NVTX ranges in `hmaintask_completion.py` and `hmaintask_combine.py` using the Phase 6a taxonomy spec, with no model semantic changes.

## Why This Is Immediate Priority
- Phase 6a taxonomy/insertion-map spec is now documented in `profiling/_PROFILING_GUIDE.md`.
- Workflow order requires Phase 6b code insertion before Phase 7 steady-state annotated captures.
- Existing steady-state unannotated representativeness evidence is complete, so annotation can proceed without changing workload semantics.

## Exact Outputs Expected
- Insert minimal NVTX range wrappers at the documented high-level boundaries only:
  - `gfm.setup`
  - `gfm.mode_test_only`
  - `gfm.train_epoch`
  - `gfm.train_step`
  - `gfm.eval_task`
  - `gfm.checkpoint_io`
  - `gfm.final_test_pass`
- Keep insertion symmetric across `hmaintask_completion.py` and `hmaintask_combine.py` where paths are equivalent.
- Keep instrumentation reversible and isolated (single-purpose helper/context usage; no broad refactor).
- Run a lightweight syntax/import sanity check after edits (no profiling capture in this task).
- Update documentation/state:
  - `handoff/CURRENT_STATUS.md` snapshot and active phase note
  - `handoff/CHECKLIST.md` Phase 6b status/note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No expansion into detailed per-kernel/per-op tagging.
- No steady-state annotated run execution in this task.
- No optimization recommendations before review gate completion (`review_complete: true`).

## Stopping Criteria
- NVTX instrumentation is inserted in both target scripts at the documented coarse boundaries only.
- Instrumentation remains minimal and reversible.
- Handoff docs are synchronized so Phase 7 annotated capture work can begin immediately in a fresh session.

## Definition Of Done (Template Style)
- [ ] Phase 6a label set is implemented as coarse NVTX ranges in `hmaintask_completion.py`.
- [ ] Phase 6a label set is implemented as coarse NVTX ranges in `hmaintask_combine.py`.
- [ ] Basic syntax/import sanity check passes after insertion edits.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
