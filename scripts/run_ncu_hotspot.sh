#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run_ncu_hotspot.sh <scenario> <hotspot> [options]

Scenarios:
  train
  finetune
  inference

Hotspots:
  hotspot_1
  hotspot_2
  hotspot_3
  <kernel_name>   Raw kernel name/regex fragment if needed

Options:
  --run-id <id>        Override the auto-generated UTC run ID.
  --set <set_name>     Nsight Compute set to collect (default: full).
  --metrics <csv>      Explicit metrics list to collect instead of --set.
  --no-sudo            Launch without sudo (useful only when counters are already accessible).
  --skip-preflight     Skip `make profiling-preflight`.
  --print-only         Print the resolved command after checks but do not launch it.
  -h, --help           Show this help text.

Examples:
  conda activate griffin-profiling
  scripts/run_ncu_hotspot.sh train hotspot_1
  scripts/run_ncu_hotspot.sh finetune hotspot_2 --print-only
  scripts/run_ncu_hotspot.sh inference fmha_cutlassF_f32_aligned_64x64_rf_sm80 --run-id 20260319-2140-inference-combine-01
EOF
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
  esac
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

SCENARIO="$1"
HOTSPOT_INPUT="$2"
shift 2

RUN_ID=""
METRIC_MODE="set"
METRIC_VALUE="full"
USE_SUDO=1
SKIP_PREFLIGHT=0
PRINT_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --set)
      if [[ "$METRIC_MODE" == "metrics" ]]; then
        echo "error: --set and --metrics are mutually exclusive" >&2
        exit 2
      fi
      METRIC_MODE="set"
      METRIC_VALUE="$2"
      shift 2
      ;;
    --metrics)
      if [[ "$METRIC_MODE" == "set" && "$METRIC_VALUE" != "full" ]]; then
        echo "error: --set and --metrics are mutually exclusive" >&2
        exit 2
      fi
      METRIC_MODE="metrics"
      METRIC_VALUE="$2"
      shift 2
      ;;
    --no-sudo)
      USE_SUDO=0
      shift
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT=1
      shift
      ;;
    --print-only)
      PRINT_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

resolve_hotspot_kernel() {
  case "$1" in
    hotspot_1)
      printf '%s\n' "ampere_sgemm_32x32_sliced1x4_tn"
      ;;
    hotspot_2)
      printf '%s\n' "fmha_cutlassF_f32_aligned_64x64_rf_sm80"
      ;;
    hotspot_3)
      printf '%s\n' "ampere_sgemm_32x128_tn"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

HOTSPOT_KERNEL="$(resolve_hotspot_kernel "$HOTSPOT_INPUT")"
CONFIG_FILE="${CONFIG_FILE:-hconfig_profiling_single_gpu.yaml}"
DATASET="datasets/single-pretrain-v3-hf"
LOG_DIR="logs/prof"
GPU_INDEX="3"

case "$SCENARIO" in
  train)
    TASK_SCRIPT="hmaintask_completion.py"
    RUN_STEM="train-completion"
    LOG_NAME="train-hotspot-ncu"
    TASK_ARGS=(
      --savepath checkpoints/single-completion
      --maxepoch 1
      --max_train_steps 8
      --max_eval_steps 4
      --batchsize 64
      --eval_per_epoch 1
      --hop 0
      --fanout 10
      --fewshotfanout 0
      --num_mp 4
      --use_rev True
      --use_gate True
      --hiddim 512
    )
    ;;
  finetune)
    TASK_SCRIPT="hmaintask_combine.py"
    RUN_STEM="finetune-combine"
    LOG_NAME="finetune-hotspot-ncu"
    TASK_ARGS=(
      --mode train
      --loadpath checkpoints/single-completion/best_checkpoint
      --savepath checkpoints/single-sft
      --tasks ALLTASK
      --maxepoch 1
      --max_train_steps 8
      --max_eval_steps 4
      --patience 5
      --eval_per_epoch 1
      --batchsize 64
      --hop 0
      --fanout 10
      --fewshotfanout 0
      --lr 3e-4
      --wd 2e-4
      --num_mp 4
      --use_rev True
      --use_gate True
      --hiddim 512
    )
    ;;
  inference)
    TASK_SCRIPT="hmaintask_combine.py"
    RUN_STEM="inference-combine"
    LOG_NAME="inference-hotspot-ncu"
    TASK_ARGS=(
      --mode test
      --loadpath checkpoints/single-sft/best_checkpoint
      --tasks ALLTASK
      --max_eval_steps 4
      --batchsize 64
      --hop 0
      --fanout 10
      --fewshotfanout 0
      --num_mp 4
      --use_rev True
      --use_gate True
      --hiddim 512
    )
    ;;
  *)
    echo "error: unknown scenario '$SCENARIO' (expected train|finetune|inference)" >&2
    exit 2
    ;;
esac

if [[ ! -f "$TASK_SCRIPT" ]]; then
  echo "error: task script not found: $TASK_SCRIPT" >&2
  exit 1
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: config file not found: $CONFIG_FILE" >&2
  exit 1
fi

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date -u +"%Y%m%d-%H%M")-$RUN_STEM-01"
fi

command -v nvidia-smi >/dev/null
command -v ncu >/dev/null
command -v accelerate >/dev/null

echo "Checking GPU occupancy on GPU${GPU_INDEX}..."
nvidia-smi
COMPUTE_APPS_OUTPUT="$(nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv,noheader || true)"
if [[ -n "$COMPUTE_APPS_OUTPUT" ]]; then
  printf '%s\n' "$COMPUTE_APPS_OUTPUT"
fi

GPU_UUID="$(nvidia-smi --query-gpu=index,gpu_uuid --format=csv,noheader | awk -F', *' -v gpu_idx="$GPU_INDEX" '$1 == gpu_idx {print $2}')"
if [[ -z "$GPU_UUID" ]]; then
  echo "error: could not resolve GPU${GPU_INDEX} UUID from nvidia-smi output" >&2
  exit 1
fi

GPU_BUSY_LINES="$(printf '%s\n' "$COMPUTE_APPS_OUTPUT" | awk -F', *' -v gpu_uuid="$GPU_UUID" 'NF > 1 && $1 == gpu_uuid {print}')"
if [[ -n "$GPU_BUSY_LINES" ]]; then
  echo "error: GPU${GPU_INDEX} has active compute processes attached; refusing to launch profiling." >&2
  printf '%s\n' "$GPU_BUSY_LINES" >&2
  exit 1
fi

if [[ "$SKIP_PREFLIGHT" -eq 0 ]]; then
  echo "Running make profiling-preflight..."
  make profiling-preflight
fi

NCU_CMD=(ncu -k "regex:${HOTSPOT_KERNEL}" --kernel-name-base function)
if [[ "$METRIC_MODE" == "set" ]]; then
  NCU_CMD+=(--set "$METRIC_VALUE")
else
  NCU_CMD+=(--metrics "$METRIC_VALUE")
fi
NCU_CMD+=(
  --export "artifacts/profiles/ncu/$RUN_ID"
  --target-processes all
  accelerate launch
  --config_file "$CONFIG_FILE"
  "$TASK_SCRIPT"
  "$DATASET"
  "$LOG_DIR"
  "$LOG_NAME"
)
NCU_CMD+=("${TASK_ARGS[@]}")

CMD=()
if [[ "$USE_SUDO" -eq 1 ]]; then
  CMD=(sudo env "PATH=$PATH")
  if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
    CMD+=("LD_LIBRARY_PATH=$LD_LIBRARY_PATH")
  fi
  CMD+=("CUDA_VISIBLE_DEVICES=$GPU_INDEX")
else
  CMD=("env" "CUDA_VISIBLE_DEVICES=$GPU_INDEX")
fi
CMD+=("${NCU_CMD[@]}")

echo "Resolved run metadata:"
echo "  scenario: $SCENARIO"
echo "  hotspot:  $HOTSPOT_INPUT"
echo "  kernel:   $HOTSPOT_KERNEL"
echo "  run_id:   $RUN_ID"
echo "  output:   artifacts/profiles/ncu/$RUN_ID.ncu-rep"
echo
echo "Resolved command:"
printf '%q ' "${CMD[@]}"
echo

if [[ "$PRINT_ONLY" -eq 1 ]]; then
  echo
  echo "Print-only mode enabled; command not launched."
  exit 0
fi

exec "${CMD[@]}"
