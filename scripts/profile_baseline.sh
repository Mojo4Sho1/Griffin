#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/profile_baseline.sh <mode> <run_id> <task_script> <dataset> <log_dir> <log_name> [-- <extra_task_args...>]

Modes:
  smoke   Run without profiler.
  nsys    Wrap run with Nsight Systems.
  ncu     Wrap run with Nsight Compute.

Defaults:
  CONFIG_FILE defaults to hconfig_profiling_single_gpu.yaml
  NSYS_FLAGS and NCU_FLAGS can be provided as space-separated env vars.

Examples:
  scripts/profile_baseline.sh smoke 20260228-1640-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof smoke -- --maxepoch 1 --batchsize 64
  scripts/profile_baseline.sh nsys  20260228-1641-train-completion-01 hmaintask_completion.py datasets/single-pretrain-v3 logs/prof nsys  -- --maxepoch 1 --batchsize 64
EOF
}

if [[ $# -lt 6 ]]; then
  usage
  exit 2
fi

MODE="$1"
RUN_ID="$2"
TASK_SCRIPT="$3"
DATASET="$4"
LOG_DIR="$5"
LOG_NAME="$6"
shift 6

EXTRA_ARGS=()
if [[ $# -gt 0 ]]; then
  if [[ "$1" != "--" ]]; then
    echo "error: optional task args must follow '--'" >&2
    usage
    exit 2
  fi
  shift
  EXTRA_ARGS=("$@")
fi

CONFIG_FILE="${CONFIG_FILE:-hconfig_profiling_single_gpu.yaml}"

if [[ ! -f "$TASK_SCRIPT" ]]; then
  echo "error: task script not found: $TASK_SCRIPT" >&2
  exit 2
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: config file not found: $CONFIG_FILE" >&2
  exit 2
fi
command -v accelerate >/dev/null

ACCEL_CMD=(accelerate launch --config_file "$CONFIG_FILE" "$TASK_SCRIPT" "$DATASET" "$LOG_DIR" "$LOG_NAME")
ACCEL_CMD+=("${EXTRA_ARGS[@]}")

CMD=()
case "$MODE" in
  smoke)
    CMD=("${ACCEL_CMD[@]}")
    ;;
  nsys)
    command -v nsys >/dev/null
    OUT_PATH="artifacts/profiles/nsys/$RUN_ID"
    NSYS_FLAG_ARR=()
    if [[ -n "${NSYS_FLAGS:-}" ]]; then
      read -r -a NSYS_FLAG_ARR <<< "${NSYS_FLAGS}"
    fi
    CMD=(nsys profile "${NSYS_FLAG_ARR[@]}" --output "$OUT_PATH" --force-overwrite true "${ACCEL_CMD[@]}")
    ;;
  ncu)
    command -v ncu >/dev/null
    OUT_PATH="artifacts/profiles/ncu/$RUN_ID"
    NCU_FLAG_ARR=()
    if [[ -n "${NCU_FLAGS:-}" ]]; then
      read -r -a NCU_FLAG_ARR <<< "${NCU_FLAGS}"
    fi
    CMD=(ncu "${NCU_FLAG_ARR[@]}" --export "$OUT_PATH" --target-processes all "${ACCEL_CMD[@]}")
    ;;
  *)
    echo "error: unknown mode '$MODE' (expected smoke|nsys|ncu)" >&2
    usage
    exit 2
    ;;
esac

echo "Resolved command:"
printf '%q ' "${CMD[@]}"
echo

exec "${CMD[@]}"
