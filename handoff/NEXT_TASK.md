# Next Task

## Single Bounded Task
Execute Phase 6a: draft the minimal coarse NVTX taxonomy spec and insertion map for `hmaintask_completion.py` and `hmaintask_combine.py`, without inserting code yet.

## Why This Is Immediate Priority
- Phase 5 (`steady_unannotated`) is now complete across all scenarios (`TR-SU1`, `FT-SU1`, `IF-SU1`) with `representative_pass=true`.
- Workflow order requires a human-readable annotation spec before Phase 6b code edits and Phase 7 steady-state annotated captures.
- Captures are complete enough to define stable high-level label boundaries without touching model semantics.

## Exact Outputs Expected
- Create/update one profiling doc section with a minimal NVTX taxonomy proposal containing:
  - label names
  - start/end boundary definitions
  - per-script insertion points (`hmaintask_completion.py`, `hmaintask_combine.py`)
  - explicit non-goals (no detailed per-kernel tagging)
- Confirm taxonomy is reversible/minimal and aligned with existing policy gates.
- Update documentation/state:
  - `profiling/_PROFILING_GUIDE.md` (or a dedicated annotation spec doc referenced from it)
  - `handoff/CURRENT_STATUS.md` snapshot and active phase note
  - `handoff/CHECKLIST.md` Phase 6a status/note
  - append `handoff/SESSION_LOG.md`

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No NVTX code insertion yet (that is Phase 6b).
- No optimization recommendations before review gate completion (`review_complete: true`).

## Stopping Criteria
- A concrete, minimal, reversible Phase 6a NVTX taxonomy spec exists with script-level insertion mapping.
- Handoff and profiling docs are synchronized so Phase 6b can begin immediately in a fresh session.

## Definition Of Done (Template Style)
- [ ] Phase 6a taxonomy labels and boundaries are documented.
- [ ] `hmaintask_completion.py` and `hmaintask_combine.py` insertion points are mapped in docs.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
