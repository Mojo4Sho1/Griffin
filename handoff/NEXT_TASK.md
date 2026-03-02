# Next Task

## Single Bounded Task
Generate a concise baseline summary from successful `nsys` run `20260302-1637-train-completion-01` (top time consumers and runtime-domain breakdown), and record findings in profiling docs.

## Why This Is Immediate Priority
- The bounded completion smoke/`nsys` command path is now verified end-to-end.
- Phase 4 requires converting the fresh successful artifact into a short actionable baseline summary before any annotation or hotspot prioritization work.

## Exact Outputs Expected
- Use `nsys` CLI reporting tools against:
  - `artifacts/profiles/nsys/20260302-1637-train-completion-01.nsys-rep`
- Produce a lightweight summary covering:
  - overall runtime duration for the profiled run
  - top CUDA kernels / API calls by time share (coarse, not deep kernel dive)
  - high-level CPU/CUDA time-domain distribution sufficient to guide next instrumentation decisions
- Record summary in profiling docs (`profiling/RUNS.md` and/or `profiling/COMMANDS.md` notes section), with commands used.
- Update `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and append `handoff/SESSION_LOG.md` to reflect findings and next blocker/next step.

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No deep training-loop refactor.
- No detailed NVTX instrumentation yet.

## Stopping Criteria
- A concise baseline summary exists for `20260302-1637-train-completion-01.nsys-rep`, or an actionable blocker to obtaining summary output is documented.
- Handoff and profiling docs are updated so a fresh agent can resume without additional discovery.

## Definition Of Done (Template Style)
- [ ] `nsys` report commands run successfully on `artifacts/profiles/nsys/20260302-1637-train-completion-01.nsys-rep` (or blocker documented).
- [ ] Baseline runtime + top-time-consumer summary is written in profiling docs.
- [ ] `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
