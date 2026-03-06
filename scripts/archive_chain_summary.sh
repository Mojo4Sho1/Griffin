#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/archive_chain_summary.sh --chain-id <id> --reason <short_reason>
EOF
}

CHAIN_ID=""
REASON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chain-id) CHAIN_ID="$2"; shift 2 ;;
    --reason) REASON="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$CHAIN_ID" || -z "$REASON" ]]; then
  usage
  exit 2
fi

ACTIVE_DIR="profiling/chains/active"
ARCHIVE_DIR="profiling/chains/archive"
INDEX_PATH="${ARCHIVE_DIR}/ARCHIVE_INDEX.md"
SRC_PATH="${ACTIVE_DIR}/CHAIN_SUMMARY_${CHAIN_ID}.md"

if [[ ! -f "$SRC_PATH" ]]; then
  echo "error: chain summary not found: $SRC_PATH" >&2
  exit 1
fi

mkdir -p "$ACTIVE_DIR" "$ARCHIVE_DIR"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
DST_PATH="${ARCHIVE_DIR}/CHAIN_SUMMARY_${CHAIN_ID}.${ts}.md"

mv "$SRC_PATH" "$DST_PATH"

if [[ ! -f "$INDEX_PATH" ]]; then
  cat > "$INDEX_PATH" <<'EOF'
# Chain Summary Archive Index

Append-only archive log for chain summaries moved out of active set.
EOF
fi

{
  echo
  echo "## ${ts} - ${CHAIN_ID}"
  echo "- chain_id: ${CHAIN_ID}"
  echo "- archived_from: \`${SRC_PATH}\`"
  echo "- archived_to: \`${DST_PATH}\`"
  echo "- reason: ${REASON}"
} >> "$INDEX_PATH"

echo "Archived: ${SRC_PATH} -> ${DST_PATH}"
