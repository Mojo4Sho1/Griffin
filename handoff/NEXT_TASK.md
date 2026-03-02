# Next Task

## Single Bounded Task
Stage `datasets/single-pretrain-v3` with required metadata files (including `metanode.yaml`), then rerun one smoke and one `nsys` baseline slice to verify execution progresses beyond `Graph(args.dataset)` initialization.

## Why This Is Immediate Priority
- Environment and dependency gates are now validated (`make profiling-preflight` passes and smoke/nsys launch).
- Dataset content is now the primary blocker preventing meaningful baseline progression.

## Exact Outputs Expected
- Stage `datasets/single-pretrain-v3` so required files exist for `Graph(args.dataset)` initialization (`metanode.yaml` minimum, plus any other required metadata/files in that dataset tree).
- Reconfirm asset availability in `profiling/ASSETS_STATUS.md`.
- Execute:
  - smoke: `scripts/profile_baseline.sh smoke <run_id> hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --savepath checkpoints/single-completion --maxepoch 1 --batchsize 64 --eval_per_epoch 1 --hop 0 --fanout 10 --fewshotfanout 0 --num_mp 4 --use_rev True --use_gate True --hiddim 512`
  - nsys: same command with mode `nsys` and distinct `<run_id>`
- Add run records for both attempts in `profiling/RUNS.md` with command, commit hash, outputs, status, and concise findings.
- Update `profiling/COMMANDS.md` `Known-Good Commands` with the latest status (`verified` if progression succeeds; `blocked` with precise blocker details if not).
- Update `profiling/ASSETS_STATUS.md`, `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and append `handoff/SESSION_LOG.md`.

## Must Not Change
- No model semantic changes.
- No kernel optimization.
- No deep training-loop refactor.
- No detailed NVTX instrumentation yet.

## Stopping Criteria
- Smoke command progresses beyond dataset initialization (`Graph(args.dataset)`), or failure is documented with actionable blocker detail.
- `nsys` baseline command generates artifact and workload progresses beyond dataset initialization, or failure is documented with actionable blocker detail.
- Handoff and profiling docs are updated so a fresh agent can resume without additional discovery.

## Definition Of Done (Template Style)
- [ ] `make profiling-preflight` passes in `griffin-profiling`.
- [ ] Required dataset path/content for completion smoke slice is present (`datasets/single-pretrain-v3/metanode.yaml` exists).
- [ ] Smoke run progresses past `Graph(args.dataset)` initialization.
- [ ] `nsys` run progresses past `Graph(args.dataset)` initialization and emits artifact.
- [ ] `profiling/COMMANDS.md` `Known-Good Commands` reflects latest verified/blocked state.
- [ ] `profiling/ASSETS_STATUS.md`, `handoff/CURRENT_STATUS.md`, `handoff/CHECKLIST.md`, and `handoff/SESSION_LOG.md` updated.
