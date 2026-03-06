#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run_slice_chain.sh \
    --chain-id <id> \
    --campaign-id <campaign_id> \
    --slice-id <slice_id> \
    --run-class <minimal_staged|realistic_scale> \
    --task-script <task_script.py> \
    --dataset <dataset_path> \
    --log-dir <log_dir> \
    --log-name-prefix <prefix> \
    --savepath <checkpoint_dir> \
    --num-slices <n> \
    --max-train-steps <n> \
    [--max-eval-steps <n>] \
    [--mode <smoke|nsys>] \
    [--resume-mode <model|state|fixed>] \
    [--initial-loadpath <path>] \
    [--profile-stage <stage>] \
    [--scenario <scenario>] \
    [--config-file <path>] \
    [--summary-path <path>] \
    [-- <extra task args...>]
EOF
}

CHAIN_ID=""
CAMPAIGN_ID=""
SLICE_ID=""
RUN_CLASS=""
TASK_SCRIPT=""
DATASET=""
LOG_DIR="logs/prof"
LOG_NAME_PREFIX=""
SAVEPATH=""
NUM_SLICES=3
MAX_TRAIN_STEPS=-1
MAX_EVAL_STEPS=-1
MODE="smoke"
RESUME_MODE="model"
INITIAL_LOADPATH=""
PROFILE_STAGE="baseline_validation"
SCENARIO="train"
CONFIG_FILE="hconfig_profiling_single_gpu.yaml"
SUMMARY_PATH=""
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chain-id) CHAIN_ID="$2"; shift 2 ;;
    --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
    --slice-id) SLICE_ID="$2"; shift 2 ;;
    --run-class) RUN_CLASS="$2"; shift 2 ;;
    --task-script) TASK_SCRIPT="$2"; shift 2 ;;
    --dataset) DATASET="$2"; shift 2 ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    --log-name-prefix) LOG_NAME_PREFIX="$2"; shift 2 ;;
    --savepath) SAVEPATH="$2"; shift 2 ;;
    --num-slices) NUM_SLICES="$2"; shift 2 ;;
    --max-train-steps) MAX_TRAIN_STEPS="$2"; shift 2 ;;
    --max-eval-steps) MAX_EVAL_STEPS="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --resume-mode) RESUME_MODE="$2"; shift 2 ;;
    --initial-loadpath) INITIAL_LOADPATH="$2"; shift 2 ;;
    --profile-stage) PROFILE_STAGE="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --config-file) CONFIG_FILE="$2"; shift 2 ;;
    --summary-path) SUMMARY_PATH="$2"; shift 2 ;;
    --)
      shift
      EXTRA_ARGS=("$@")
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$CHAIN_ID" || -z "$CAMPAIGN_ID" || -z "$SLICE_ID" || -z "$RUN_CLASS" || -z "$TASK_SCRIPT" || -z "$DATASET" || -z "$LOG_NAME_PREFIX" || -z "$SAVEPATH" ]]; then
  usage
  exit 2
fi
if [[ "$MODE" != "smoke" && "$MODE" != "nsys" ]]; then
  echo "error: --mode must be smoke or nsys" >&2
  exit 2
fi
if [[ "$RESUME_MODE" != "model" && "$RESUME_MODE" != "state" && "$RESUME_MODE" != "fixed" ]]; then
  echo "error: --resume-mode must be model, state, or fixed" >&2
  exit 2
fi
if [[ "$MAX_TRAIN_STEPS" -le 0 ]]; then
  echo "error: --max-train-steps must be > 0 for slice chaining" >&2
  exit 2
fi
if [[ "$RESUME_MODE" == "fixed" && -z "$INITIAL_LOADPATH" ]]; then
  echo "error: --initial-loadpath is required when --resume-mode=fixed" >&2
  exit 2
fi
if [[ "$RESUME_MODE" == "fixed" ]]; then
  for arg in "${EXTRA_ARGS[@]}"; do
    if [[ "$arg" == "--loadpath" || "$arg" == --loadpath=* ]]; then
      echo "error: do not pass --loadpath in extra args when --resume-mode=fixed; use --initial-loadpath" >&2
      exit 2
    fi
  done
fi

mkdir -p "$SAVEPATH" "$LOG_DIR" profiling/chains/active profiling/chains/archive
if [[ -z "$SUMMARY_PATH" ]]; then
  SUMMARY_PATH="profiling/chains/active/CHAIN_SUMMARY_${CHAIN_ID}.md"
fi

CURRENT_LOADPATH="$INITIAL_LOADPATH"

gpu3_is_busy() {
  local gpu3_uuid
  gpu3_uuid="$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' '$1=="3"{print $2}')"
  if [[ -z "$gpu3_uuid" ]]; then
    echo "error: unable to resolve GPU3 UUID" >&2
    return 2
  fi
  if nvidia-smi --query-compute-apps=gpu_uuid --format=csv,noheader | grep -Fxq "$gpu3_uuid"; then
    return 0
  fi
  return 1
}

{
  echo "# Chain Summary: $CHAIN_ID"
  echo
  echo "- campaign_id: $CAMPAIGN_ID"
  echo "- slice_id: $SLICE_ID"
  echo "- run_class: $RUN_CLASS"
  echo "- scenario: $SCENARIO"
  echo "- profile_stage: $PROFILE_STAGE"
  echo "- mode: $MODE"
  echo "- resume_mode: $RESUME_MODE"
  echo "- num_slices: $NUM_SLICES"
  echo "- max_train_steps: $MAX_TRAIN_STEPS"
  echo "- max_eval_steps: $MAX_EVAL_STEPS"
  echo
} > "$SUMMARY_PATH"

echo "[slice-chain] running preflight once..."
make profiling-preflight

for ((i=1; i<=NUM_SLICES; i++)); do
  slice_num="$(printf "%02d" "$i")"
  ts="$(date -u +%Y%m%d-%H%M)"
  run_id="${ts}-${CHAIN_ID}-s${slice_num}"
  log_name="${LOG_NAME_PREFIX}-s${slice_num}"
  state_path="${SAVEPATH}/state-slice-${slice_num}"
  cmd_extra=(
    --savepath "$SAVEPATH"
    --maxepoch 1
    --max_train_steps "$MAX_TRAIN_STEPS"
    --max_eval_steps "$MAX_EVAL_STEPS"
  )

  if [[ "$RESUME_MODE" == "model" && -n "$CURRENT_LOADPATH" ]]; then
    cmd_extra+=(--loadpath "$CURRENT_LOADPATH")
  fi
  if [[ "$RESUME_MODE" == "fixed" ]]; then
    cmd_extra+=(--loadpath "$CURRENT_LOADPATH")
  fi
  if [[ "$RESUME_MODE" == "state" ]]; then
    cmd_extra+=(--save_state_path "$state_path")
    if [[ -n "$CURRENT_LOADPATH" ]]; then
      cmd_extra+=(--load_state_path "$CURRENT_LOADPATH")
    fi
  fi
  if [[ "${#EXTRA_ARGS[@]}" -gt 0 ]]; then
    cmd_extra+=("${EXTRA_ARGS[@]}")
  fi

  echo "[slice-chain] checking GPU3 occupancy before slice $slice_num ..."
  nvidia-smi
  nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
  if gpu3_is_busy; then
    {
      echo "## Slice $slice_num"
      echo "- run_id: $run_id"
      echo "- status: blocked"
      echo "- reason: GPU3 has active compute process; slice not started."
      echo
    } >> "$SUMMARY_PATH"
    echo "SLICE_RESULT|$i|$run_id|blocked|gpu3_occupied|na|na"
    exit 1
  fi

  echo "[slice-chain] starting slice $slice_num (run_id=$run_id)"
  set +e
  CONFIG_FILE="$CONFIG_FILE" CUDA_VISIBLE_DEVICES=3 scripts/profile_baseline.sh \
    "$MODE" "$run_id" "$TASK_SCRIPT" "$DATASET" "$LOG_DIR" "$log_name" -- "${cmd_extra[@]}"
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    {
      echo "## Slice $slice_num"
      echo "- run_id: $run_id"
      echo "- status: failed"
      echo "- return_code: $rc"
      echo "- checkpoint_in: ${CURRENT_LOADPATH:-na}"
      echo "- checkpoint_out: na"
      echo
    } >> "$SUMMARY_PATH"
    echo "SLICE_RESULT|$i|$run_id|failed|rc_${rc}|${CURRENT_LOADPATH:-na}|na"
    exit $rc
  fi

  if [[ "$RESUME_MODE" == "model" ]]; then
    newest_ckpt="$(ls -dt "$SAVEPATH"/checkpoint-* 2>/dev/null | head -n1 || true)"
    if [[ -z "$newest_ckpt" ]]; then
      {
        echo "## Slice $slice_num"
        echo "- run_id: $run_id"
        echo "- status: failed"
        echo "- reason: no checkpoint-* directory found after successful slice."
        echo "- checkpoint_in: ${CURRENT_LOADPATH:-na}"
        echo "- checkpoint_out: na"
        echo
      } >> "$SUMMARY_PATH"
      echo "SLICE_RESULT|$i|$run_id|failed|missing_checkpoint|${CURRENT_LOADPATH:-na}|na"
      exit 1
    fi
    checkpoint_out="$newest_ckpt"
  elif [[ "$RESUME_MODE" == "state" ]]; then
    if [[ ! -d "$state_path" ]]; then
      {
        echo "## Slice $slice_num"
        echo "- run_id: $run_id"
        echo "- status: failed"
        echo "- reason: state directory missing after successful slice."
        echo "- state_in: ${CURRENT_LOADPATH:-na}"
        echo "- state_out: na"
        echo
      } >> "$SUMMARY_PATH"
      echo "SLICE_RESULT|$i|$run_id|failed|missing_state|${CURRENT_LOADPATH:-na}|na"
      exit 1
    fi
    checkpoint_out="$state_path"
  else
    checkpoint_out="$CURRENT_LOADPATH"
  fi

  {
    echo "## Slice $slice_num"
    echo "- run_id: $run_id"
    echo "- status: success"
    echo "- checkpoint_in: ${CURRENT_LOADPATH:-na}"
    echo "- checkpoint_out: $checkpoint_out"
    echo "- log_name: $log_name"
    echo
  } >> "$SUMMARY_PATH"
  echo "SLICE_RESULT|$i|$run_id|success|none|${CURRENT_LOADPATH:-na}|$checkpoint_out"
  CURRENT_LOADPATH="$checkpoint_out"
done

echo "CHAIN_RESULT|$CHAIN_ID|success|$SUMMARY_PATH|$CURRENT_LOADPATH"
