#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# app/run.sh
# General-purpose Weka CLI runner.
# Usage: bash app/run.sh <path/to/config.json>
#
# Supported tasks: classification, regression, clustering, association
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
# Parse common config fields
# ---------------------------------------------------------------------------
TASK=$(jq -r '.task' "$CONFIG_FILE")
ALGORITHM=$(jq -r '.algorithm' "$CONFIG_FILE")
EVAL_MODE=$(jq -r '.evaluation.mode' "$CONFIG_FILE")

if [[ "$TASK" == "null" || -z "$TASK" ]]; then
  echo "[ERROR] 'task' is required in config (classification | regression | clustering | association)." >&2
  exit 1
fi
if [[ "$ALGORITHM" == "null" || -z "$ALGORITHM" ]]; then
  echo "[ERROR] 'algorithm' is required in config." >&2
  exit 1
fi
if [[ "$EVAL_MODE" == "null" || -z "$EVAL_MODE" ]]; then
  echo "[ERROR] 'evaluation.mode' is required in config." >&2
  exit 1
fi

# Parse options array into a bash array (bash 3.x-compatible)
OPTIONS=()
while IFS= read -r opt; do
  [[ -n "$opt" ]] && OPTIONS+=("$opt")
done < <(jq -r '.options[]? // empty' "$CONFIG_FILE")

# ---------------------------------------------------------------------------
# Build Weka command based on task and evaluation mode
# ---------------------------------------------------------------------------
case "$TASK" in

  classification|regression)
    case "$EVAL_MODE" in

      cross-validation)
        DATASET=$(jq -r '.evaluation.dataset' "$CONFIG_FILE")
        FOLDS=$(jq -r '.evaluation.folds // 10' "$CONFIG_FILE")

        if [[ "$DATASET" == "null" || -z "$DATASET" ]]; then
          echo "[ERROR] 'evaluation.dataset' is required for cross-validation mode." >&2
          exit 1
        fi
        if [[ ! -f "$DATASET" ]]; then
          echo "[ERROR] Dataset file not found: $DATASET" >&2
          exit 1
        fi

        WEKA_CMD=(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$ALGORITHM"
          -t "$DATASET"
          -x "$FOLDS"
          "${OPTIONS[@]+"${OPTIONS[@]}"}")
        ;;

      train-test)
        TRAIN_FILE=$(jq -r '.evaluation.train_file' "$CONFIG_FILE")
        TEST_FILE=$(jq -r '.evaluation.test_file' "$CONFIG_FILE")

        if [[ "$TRAIN_FILE" == "null" || -z "$TRAIN_FILE" ]]; then
          echo "[ERROR] 'evaluation.train_file' is required for train-test mode." >&2
          exit 1
        fi
        if [[ "$TEST_FILE" == "null" || -z "$TEST_FILE" ]]; then
          echo "[ERROR] 'evaluation.test_file' is required for train-test mode." >&2
          exit 1
        fi
        if [[ ! -f "$TRAIN_FILE" ]]; then
          echo "[ERROR] Train file not found: $TRAIN_FILE" >&2
          exit 1
        fi
        if [[ ! -f "$TEST_FILE" ]]; then
          echo "[ERROR] Test file not found: $TEST_FILE" >&2
          exit 1
        fi

        WEKA_CMD=(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$ALGORITHM"
          -t "$TRAIN_FILE"
          -T "$TEST_FILE"
          "${OPTIONS[@]+"${OPTIONS[@]}"}")
        ;;

      *)
        echo "[ERROR] Unknown evaluation.mode '$EVAL_MODE' for task '$TASK'. Must be 'cross-validation' or 'train-test'." >&2
        exit 1
        ;;
    esac
    ;;

  clustering|association)
    if [[ "$EVAL_MODE" != "dataset" ]]; then
      echo "[ERROR] evaluation.mode for task '$TASK' must be 'dataset'." >&2
      exit 1
    fi

    DATASET=$(jq -r '.evaluation.dataset' "$CONFIG_FILE")

    if [[ "$DATASET" == "null" || -z "$DATASET" ]]; then
      echo "[ERROR] 'evaluation.dataset' is required for task '$TASK'." >&2
      exit 1
    fi
    if [[ ! -f "$DATASET" ]]; then
      echo "[ERROR] Dataset file not found: $DATASET" >&2
      exit 1
    fi

    WEKA_CMD=(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$ALGORITHM"
      -t "$DATASET"
      "${OPTIONS[@]+"${OPTIONS[@]}"}")
    ;;

  *)
    echo "[ERROR] Unknown task: '$TASK'. Must be one of: classification, regression, clustering, association." >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Prepare output path: .rmit_reports/YYYYMMDD/YYYYMMDD_HHMMSS/report_{task}_{model}.txt
# ---------------------------------------------------------------------------
DATE=$(date +"%Y%m%d")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Derive short model name from the last segment of the algorithm class name
MODEL_NAME="${ALGORITHM##*.}"

OUTPUT_DIR="$PROJECT_DIR/.rmit_reports/$DATE/$TIMESTAMP"
OUTPUT_FILE="$OUTPUT_DIR/report_${TASK}_${MODEL_NAME}.txt"
MODEL_FILE="$OUTPUT_DIR/model_${TASK}_${MODEL_NAME}.model"

mkdir -p "$OUTPUT_DIR"

# Copy the config file into the report folder for reproducibility
cp "$(realpath "$CONFIG_FILE")" "$OUTPUT_DIR/config.json"

# Read optional save_model flag from config (default: true)
SAVE_MODEL=$(jq -r '.save_model // true' "$CONFIG_FILE")

# Append -d flag to save the trained model (classifiers and clusterers only)
if [[ "$SAVE_MODEL" == "true" && "$TASK" != "association" ]]; then
  WEKA_CMD+=(-d "$MODEL_FILE")
fi

# ---------------------------------------------------------------------------
# Write header into the report file
# ---------------------------------------------------------------------------
{
  echo "=================================================================="
  echo "  Weka Run Report"
  echo "=================================================================="
  echo "  Date        : $(date '+%Y-%m-%d %H:%M:%S')"
  echo "  Config      : $(realpath "$CONFIG_FILE")"
  echo "  Task        : $TASK"
  echo "  Algorithm   : $ALGORITHM"
  echo "  Eval Mode   : $EVAL_MODE"
  case "$TASK" in
    classification|regression)
      case "$EVAL_MODE" in
        cross-validation)
          echo "  Dataset     : $DATASET"
          echo "  Folds       : $FOLDS"
          ;;
        train-test)
          echo "  Train File  : $TRAIN_FILE"
          echo "  Test File   : $TEST_FILE"
          ;;
      esac
      ;;
    clustering|association)
      echo "  Dataset     : $DATASET"
      ;;
  esac
  if [[ ${#OPTIONS[@]} -gt 0 ]]; then
    echo "  Options     : ${OPTIONS[*]}"
  fi
  echo "  Output      : $OUTPUT_FILE"
  if [[ "$SAVE_MODEL" == "true" && "$TASK" != "association" ]]; then
    echo "  Model       : $MODEL_FILE"
  fi
  echo "=================================================================="
  echo ""
} | tee "$OUTPUT_FILE"

# ---------------------------------------------------------------------------
# Run Weka and stream output to both console and report file
# ---------------------------------------------------------------------------
echo "[INFO] Running: ${WEKA_CMD[*]}"
echo ""

if "${WEKA_CMD[@]}" 2>&1 | tee -a "$OUTPUT_FILE"; then
  echo ""
  echo "[INFO] Completed successfully."
  echo "[INFO] Report saved to: $OUTPUT_FILE"
  if [[ "$SAVE_MODEL" == "true" && "$TASK" != "association" ]]; then
    echo "[INFO] Model  saved to: $MODEL_FILE"
    echo "[INFO] To visualize: open Weka Explorer → Classify tab → right-click result → Load model"
  fi
else
  EXIT_CODE=$?
  echo ""
  echo "[ERROR] Weka exited with code $EXIT_CODE. Partial output saved to: $OUTPUT_FILE" >&2
  exit $EXIT_CODE
fi
