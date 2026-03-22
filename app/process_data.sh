#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# app/process_data.sh
# Weka data pipeline runner — handles two tasks:
#   preprocess  : apply a sequential chain of Weka filters to an ARFF file
#   combine     : sequentially append one or more ARFF files to a base file
#
# Usage: bash app/process_data.sh <path/to/config.json>
#
# Output is always written to .rmit_datasets/YYYYMMDD/<basename>_<uuid>/
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEKA_JAR="$SCRIPT_DIR/weka.jar"
MTJ_JAR="$SCRIPT_DIR/mtj-1.0.4.jar"
WEKA_CP="$WEKA_JAR${MTJ_JAR:+:$MTJ_JAR}"

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo "[ERROR] Required dependency '$1' not found." >&2
    case "$1" in
      jq)      echo "  Install via: brew install jq" >&2 ;;
      java)    echo "  Install via: brew install --cask temurin  (or any JDK/JRE)" >&2 ;;
      uuidgen) echo "  'uuidgen' is built-in on macOS. Ensure you are on macOS or install uuid-runtime." >&2 ;;
    esac
    exit 1
  fi
}

check_dep java
check_dep jq
check_dep uuidgen

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path/to/config.json>" >&2
  exit 1
fi

CONFIG_FILE="$1"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[ERROR] Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

if [[ ! -f "$WEKA_JAR" ]]; then
  echo "[ERROR] Weka JAR not found at: $WEKA_JAR" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Parse shared config fields
# ---------------------------------------------------------------------------
TASK=$(jq -r '.task // empty' "$CONFIG_FILE")
INPUT=$(jq -r '.input' "$CONFIG_FILE")
IS_DEBUG=$(jq -r '.is_debug // false' "$CONFIG_FILE")
STEP_COUNT=$(jq '.steps | length' "$CONFIG_FILE")

if [[ -z "$TASK" || "$TASK" == "null" ]]; then
  echo "[ERROR] 'task' is required in config (preprocess | combine)." >&2
  exit 1
fi

case "$TASK" in
  preprocess|combine) ;;
  *)
    echo "[ERROR] Unknown task: '$TASK'. Must be 'preprocess' or 'combine'." >&2
    exit 1
    ;;
esac

if [[ "$INPUT" == "null" || -z "$INPUT" ]]; then
  echo "[ERROR] 'input' is required in config." >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "[ERROR] Input file not found: $INPUT" >&2
  exit 1
fi

if [[ "${INPUT##*.}" != "arff" ]]; then
  echo "[ERROR] Input file must have .arff extension: $INPUT" >&2
  exit 1
fi

if [[ "$STEP_COUNT" -eq 0 ]]; then
  echo "[ERROR] 'steps' array is empty. At least one step is required." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Prepare output paths
# ---------------------------------------------------------------------------
DATE=$(date +"%Y%m%d")
RUN_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BASENAME=$(basename "$INPUT" .arff)

OUTPUT_DIR="$PROJECT_DIR/.rmit_datasets/$DATE/${BASENAME}_${RUN_UUID}"
FINAL_FILE="$OUTPUT_DIR/${BASENAME}_${TIMESTAMP}.arff"

mkdir -p "$OUTPUT_DIR"

if [[ "$IS_DEBUG" == "true" ]]; then
  mkdir -p "$OUTPUT_DIR/steps"
fi

# ---------------------------------------------------------------------------
# Set up temp directory for intermediate files
# ---------------------------------------------------------------------------
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PREV_FILE="$INPUT"

# ---------------------------------------------------------------------------
# Print run header
# ---------------------------------------------------------------------------
echo "=================================================================="
echo "  Weka Data Pipeline"
echo "=================================================================="
echo "  Date        : $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Config      : $(realpath "$CONFIG_FILE")"
echo "  Task        : $TASK"
echo "  Input       : $INPUT"
echo "  Steps       : $STEP_COUNT"
echo "  Debug       : $IS_DEBUG"
echo "  Output      : $FINAL_FILE"
echo "=================================================================="
echo ""

# ---------------------------------------------------------------------------
# Task: preprocess — apply sequential Weka filters
# ---------------------------------------------------------------------------
run_preprocess() {
  local i=0
  while [[ $i -lt $STEP_COUNT ]]; do
    local STEP_NAME FILTER NEXT_FILE STEP_NUM
    STEP_NAME=$(jq -r ".steps[$i].name" "$CONFIG_FILE")
    FILTER=$(jq -r ".steps[$i].filter" "$CONFIG_FILE")

    if [[ "$FILTER" == "null" || -z "$FILTER" ]]; then
      echo "[ERROR] Step $((i+1)): 'filter' is required for preprocess steps." >&2
      exit 1
    fi

    if [[ "$STEP_NAME" == "null" || -z "$STEP_NAME" ]]; then
      STEP_NAME="${FILTER##*.}"
    fi

    NEXT_FILE="$WORK_DIR/step_$((i+1)).arff"

    local STEP_OPTIONS=()
    while IFS= read -r opt; do
      [[ -n "$opt" ]] && STEP_OPTIONS+=("$opt")
    done < <(jq -r ".steps[$i].options[]? // empty" "$CONFIG_FILE")

    STEP_NUM=$(printf "%03d" $((i+1)))
    echo "[INFO] Step $STEP_NUM — $STEP_NAME"
    echo "         Filter  : $FILTER"
    if [[ ${#STEP_OPTIONS[@]} -gt 0 ]]; then
      echo "         Options : ${STEP_OPTIONS[*]}"
    fi

    if java --add-opens java.base/java.lang=ALL-UNNAMED \
        -cp "$WEKA_CP" "$FILTER" \
        -i "$PREV_FILE" \
        -o "$NEXT_FILE" \
        "${STEP_OPTIONS[@]+"${STEP_OPTIONS[@]}"}" 2>&1; then
      echo "         [OK]"
    else
      echo "[ERROR] Step $STEP_NUM failed (filter: $FILTER)." >&2
      exit 1
    fi

    if [[ "$IS_DEBUG" == "true" ]]; then
      local DEBUG_FILE="$OUTPUT_DIR/steps/${STEP_NUM}_${STEP_NAME}_${TIMESTAMP}.arff"
      cp "$NEXT_FILE" "$DEBUG_FILE"
      echo "         [DEBUG] Saved: $DEBUG_FILE"
    fi

    echo ""
    PREV_FILE="$NEXT_FILE"
    i=$((i+1))
  done
}

# ---------------------------------------------------------------------------
# Task: combine — sequentially append ARFF files to the base file
# ---------------------------------------------------------------------------
run_combine() {
  local i=0
  while [[ $i -lt $STEP_COUNT ]]; do
    local STEP_NAME STEP_TYPE STEP_FILE NEXT_FILE STEP_NUM
    STEP_NAME=$(jq -r ".steps[$i].name" "$CONFIG_FILE")
    STEP_TYPE=$(jq -r ".steps[$i].type" "$CONFIG_FILE")
    STEP_FILE=$(jq -r ".steps[$i].file" "$CONFIG_FILE")

    if [[ "$STEP_TYPE" == "null" || -z "$STEP_TYPE" ]]; then
      echo "[ERROR] Step $((i+1)): 'type' is required for combine steps." >&2
      exit 1
    fi
    if [[ "$STEP_TYPE" != "append" ]]; then
      echo "[ERROR] Step $((i+1)): unsupported type '$STEP_TYPE'. Currently only 'append' is supported." >&2
      exit 1
    fi
    if [[ "$STEP_FILE" == "null" || -z "$STEP_FILE" ]]; then
      echo "[ERROR] Step $((i+1)): 'file' is required for append steps." >&2
      exit 1
    fi
    if [[ ! -f "$STEP_FILE" ]]; then
      echo "[ERROR] Step $((i+1)): file not found: $STEP_FILE" >&2
      exit 1
    fi

    if [[ "$STEP_NAME" == "null" || -z "$STEP_NAME" ]]; then
      STEP_NAME="append_$(basename "$STEP_FILE" .arff)"
    fi

    NEXT_FILE="$WORK_DIR/step_$((i+1)).arff"
    STEP_NUM=$(printf "%03d" $((i+1)))

    echo "[INFO] Step $STEP_NUM — $STEP_NAME"
    echo "         Type    : append"
    echo "         File    : $STEP_FILE"

    if java --add-opens java.base/java.lang=ALL-UNNAMED \
        -cp "$WEKA_CP" weka.core.Instances \
        -append "$PREV_FILE" "$STEP_FILE" \
        > "$NEXT_FILE" 2>&1; then
      echo "         [OK]"
    else
      echo "[ERROR] Step $STEP_NUM failed (append: $STEP_FILE)." >&2
      exit 1
    fi

    if [[ "$IS_DEBUG" == "true" ]]; then
      local DEBUG_FILE="$OUTPUT_DIR/steps/${STEP_NUM}_${STEP_NAME}_${TIMESTAMP}.arff"
      cp "$NEXT_FILE" "$DEBUG_FILE"
      echo "         [DEBUG] Saved: $DEBUG_FILE"
    fi

    echo ""
    PREV_FILE="$NEXT_FILE"
    i=$((i+1))
  done
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$TASK" in
  preprocess) run_preprocess ;;
  combine)    run_combine    ;;
esac

# ---------------------------------------------------------------------------
# Copy final result to output directory
# ---------------------------------------------------------------------------
cp "$PREV_FILE" "$FINAL_FILE"

echo "=================================================================="
echo "[INFO] Pipeline completed successfully."
echo "[INFO] Output saved to: $FINAL_FILE"
if [[ "$IS_DEBUG" == "true" ]]; then
  echo "[INFO] Step files saved in: $OUTPUT_DIR/steps/"
fi
echo "=================================================================="
