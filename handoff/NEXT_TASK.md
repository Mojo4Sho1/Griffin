# Next Task

## Single Bounded Task
Verify and document one minimal, representative baseline profiling slice command for training, and confirm the safest future coarse annotation insertion points plus profiling output destinations.

## Why This Is Immediate Priority
- Profiling infrastructure is scaffolded, but no command is yet environment-validated.
- A confirmed minimal slice is required before any reliable baseline measurements or annotation work.

## Exact Outputs Expected
- Activate the project environment, then run `make profiling-preflight`, then execute the readiness checklist in `profiling/PREFLIGHT.md`; document pass/fail at the top of the run record.
- Update `profiling/ASSETS_STATUS.md` with current path availability for assets required by the selected minimal slice.
- Update `profiling/COMMANDS.md` with one verified baseline profiling command (including resolved script, required args, and output path conventions).
- Fill the `Known-Good Commands` section in `profiling/COMMANDS.md` (status and concrete commands).
- Update `handoff/CURRENT_STATUS.md` with confirmed safe coarse annotation insertion points (file and function-level references) and confirmed runtime output destinations.
- Append a concise outcome entry to `handoff/SESSION_LOG.md`.
- Add one run record to `profiling/RUNS.md` for the verification attempt (success or failure), including command, commit hash, and notes.

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No deep training-loop refactor.
- No detailed NVTX instrumentation yet.

## Stopping Criteria
- A single minimal baseline profiling slice command is verified or fails with a clearly documented blocker.
- `profiling/COMMANDS.md` contains concrete values in `Known-Good Commands` (or explicit blocker text).
- The command and artifact paths are documented clearly enough for a fresh agent to rerun without extra discovery.
- Handoff files (`CURRENT_STATUS.md`, `SESSION_LOG.md`, and if needed `CHECKLIST.md`) are updated before stopping.

## Definition Of Done (Template Style)
- [ ] `make profiling-preflight` executed and pass/fail documented.
- [ ] `profiling/ASSETS_STATUS.md` updated for required paths.
- [ ] `profiling/RUNS.md` contains a run record with canonical `run_id`.
- [ ] `profiling/COMMANDS.md` `Known-Good Commands` section updated (or explicit blocker text added).
- [ ] `handoff/CURRENT_STATUS.md` updated to reflect latest outcomes/blockers.
- [ ] `handoff/SESSION_LOG.md` appended with this session's outcome.
