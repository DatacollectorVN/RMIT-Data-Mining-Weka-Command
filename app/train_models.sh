#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# app/train_models.sh
# General-purpose Weka CLI runner — supports multiple models in one config.
# Usage: bash app/train_models.sh <path/to/config.json>
#
# Supported tasks: classification, regression, clustering, association
#
# Config format:
#   {
#     "task": "classification",
#     "evaluation": { "mode": "cross-validation", "folds": 10, "dataset": "..." },
#     "models": [
#       { "name": "OneR",   "algorithm": "weka.classifiers.rules.OneR", "options": [] },
#       { "name": "OneR_2", "algorithm": "weka.classifiers.rules.OneR", "options": ["-B","6"] }
#     ]
#   }
#
# Output per model:
#   .rmit_reports/YYYYMMDD/YYYYMMDD_HHMMSS/<name>/
#     config.json   — copy of full config
#     <name>.txt    — evaluation report
#     <name>.model  — serialized Weka model (unless save_model is false)
#   Top-level "save_model" (default true) can be overridden per model in models[].save_model
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
# Parse shared config fields
# ---------------------------------------------------------------------------
TASK=$(jq -r '.task' "$CONFIG_FILE")
EVAL_MODE=$(jq -r '.evaluation.mode' "$CONFIG_FILE")
MODEL_COUNT=$(jq -r '.models | length' "$CONFIG_FILE")
# Note: cannot use ".save_model // true" — in jq, `false // true` evaluates to true.

if [[ "$TASK" == "null" || -z "$TASK" ]]; then
  echo "[ERROR] 'task' is required in config (classification | regression | clustering | association)." >&2
  exit 1
fi
if [[ "$EVAL_MODE" == "null" || -z "$EVAL_MODE" ]]; then
  echo "[ERROR] 'evaluation.mode' is required in config." >&2
  exit 1
fi
if [[ "$MODEL_COUNT" -eq 0 ]]; then
  echo "[ERROR] 'models' array is empty or missing in config." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Validate evaluation inputs (shared across all models)
# ---------------------------------------------------------------------------
case "$TASK" in
  classification|regression)
    case "$EVAL_MODE" in
      cross-validation)
        DATASET=$(jq -r '.evaluation.dataset' "$CONFIG_FILE")
        FOLDS=$(jq -r '.evaluation.folds // 10' "$CONFIG_FILE")
        if [[ "$DATASET" == "null" || -z "$DATASET" ]]; then
          echo "[ERROR] 'evaluation.dataset' is required for cross-validation mode." >&2; exit 1
        fi
        if [[ ! -f "$DATASET" ]]; then
          echo "[ERROR] Dataset file not found: $DATASET" >&2; exit 1
        fi
        ;;
      train-test)
        TRAIN_FILE=$(jq -r '.evaluation.train_file' "$CONFIG_FILE")
        TEST_FILE=$(jq -r '.evaluation.test_file' "$CONFIG_FILE")
        if [[ "$TRAIN_FILE" == "null" || -z "$TRAIN_FILE" ]]; then
          echo "[ERROR] 'evaluation.train_file' is required for train-test mode." >&2; exit 1
        fi
        if [[ "$TEST_FILE" == "null" || -z "$TEST_FILE" ]]; then
          echo "[ERROR] 'evaluation.test_file' is required for train-test mode." >&2; exit 1
        fi
        if [[ ! -f "$TRAIN_FILE" ]]; then
          echo "[ERROR] Train file not found: $TRAIN_FILE" >&2; exit 1
        fi
        if [[ ! -f "$TEST_FILE" ]]; then
          echo "[ERROR] Test file not found: $TEST_FILE" >&2; exit 1
        fi
        ;;
      *)
        echo "[ERROR] Unknown evaluation.mode '$EVAL_MODE' for task '$TASK'. Must be 'cross-validation' or 'train-test'." >&2
        exit 1
        ;;
    esac
    ;;
  clustering|association)
    if [[ "$EVAL_MODE" != "dataset" ]]; then
      echo "[ERROR] evaluation.mode for task '$TASK' must be 'dataset'." >&2; exit 1
    fi
    DATASET=$(jq -r '.evaluation.dataset' "$CONFIG_FILE")
    if [[ "$DATASET" == "null" || -z "$DATASET" ]]; then
      echo "[ERROR] 'evaluation.dataset' is required for task '$TASK'." >&2; exit 1
    fi
    if [[ ! -f "$DATASET" ]]; then
      echo "[ERROR] Dataset file not found: $DATASET" >&2; exit 1
    fi
    ;;
  *)
    echo "[ERROR] Unknown task: '$TASK'. Must be one of: classification, regression, clustering, association." >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Shared timestamp for the whole run (all models share the same run folder)
# ---------------------------------------------------------------------------
DATE=$(date +"%Y%m%d")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_DIR="$PROJECT_DIR/.rmit_reports/$DATE/$TIMESTAMP"

echo "=================================================================="
echo "  Weka Multi-model Run"
echo "=================================================================="
echo "  Date        : $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Config      : $(realpath "$CONFIG_FILE")"
echo "  Task        : $TASK"
echo "  Eval Mode   : $EVAL_MODE"
case "$TASK" in
  classification|regression)
    case "$EVAL_MODE" in
      cross-validation) echo "  Dataset     : $DATASET"; echo "  Folds       : $FOLDS" ;;
      train-test)       echo "  Train File  : $TRAIN_FILE"; echo "  Test File   : $TEST_FILE" ;;
    esac
    ;;
  clustering|association)
    echo "  Dataset     : $DATASET"
    ;;
esac
echo "  Models      : $MODEL_COUNT"
echo "  Run Dir     : $RUN_DIR"
echo "=================================================================="
echo ""

# Track results for the final summary
SUCCEEDED=()
FAILED=()

# ---------------------------------------------------------------------------
# Loop over each model
# ---------------------------------------------------------------------------
for (( i=0; i<MODEL_COUNT; i++ )); do
  MODEL_NAME=$(jq -r ".models[$i].name" "$CONFIG_FILE")
  ALGORITHM=$(jq -r ".models[$i].algorithm" "$CONFIG_FILE")

  if [[ "$MODEL_NAME" == "null" || -z "$MODEL_NAME" ]]; then
    echo "[WARN] models[$i].name is missing — skipping." >&2
    FAILED+=("models[$i] (no name)")
    continue
  fi
  if [[ "$ALGORITHM" == "null" || -z "$ALGORITHM" ]]; then
    echo "[WARN] models[$i].algorithm is missing — skipping $MODEL_NAME." >&2
    FAILED+=("$MODEL_NAME")
    continue
  fi

  # Parse per-model options into a bash array
  OPTIONS=()
  while IFS= read -r opt; do
    [[ -n "$opt" ]] && OPTIONS+=("$opt")
  done < <(jq -r ".models[$i].options[]? // empty" "$CONFIG_FILE")

  # Effective save_model: per-model overrides top-level (default: save models)
  SAVE_MODEL=$(jq -r --argjson idx "$i" '
    if (.models[$idx] | has("save_model")) then
      (if .models[$idx].save_model then "true" else "false" end)
    elif has("save_model") then
      (if .save_model then "true" else "false" end)
    else
      "true"
    end
  ' "$CONFIG_FILE")

  # Output directory for this model
  MODEL_DIR="$RUN_DIR/$MODEL_NAME"
  REPORT_FILE="$MODEL_DIR/${MODEL_NAME}.txt"
  MODEL_FILE="$MODEL_DIR/${MODEL_NAME}.model"

  mkdir -p "$MODEL_DIR"
  # Write a per-model config: same task/evaluation block, but models[] contains only this model
  jq --argjson idx "$i" '
    . + { "models": [ .models[$idx] ] }
  ' "$CONFIG_FILE" > "$MODEL_DIR/config.json"

  # Build the Weka command
  case "$TASK" in
    classification|regression)
      case "$EVAL_MODE" in
        cross-validation)
          WEKA_CMD=(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$ALGORITHM"
            -t "$DATASET"
            -x "$FOLDS"
            "${OPTIONS[@]+"${OPTIONS[@]}"}")
          ;;
        train-test)
          WEKA_CMD=(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$ALGORITHM"
            -t "$TRAIN_FILE"
            -T "$TEST_FILE"
            "${OPTIONS[@]+"${OPTIONS[@]}"}")
          ;;
      esac
      ;;
    clustering|association)
      WEKA_CMD=(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$ALGORITHM"
        -t "$DATASET"
        "${OPTIONS[@]+"${OPTIONS[@]}"}")
      ;;
  esac

  # Append -d flag to save the trained model (classifiers and clusterers only)
  if [[ "$SAVE_MODEL" == "true" && "$TASK" != "association" ]]; then
    WEKA_CMD+=(-d "$MODEL_FILE")
  fi

  # Write report header
  {
    echo "=================================================================="
    echo "  Weka Run Report — $MODEL_NAME"
    echo "=================================================================="
    echo "  Date        : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Config      : $(realpath "$CONFIG_FILE")"
    echo "  Task        : $TASK"
    echo "  Algorithm   : $ALGORITHM"
    echo "  Eval Mode   : $EVAL_MODE"
    case "$TASK" in
      classification|regression)
        case "$EVAL_MODE" in
          cross-validation) echo "  Dataset     : $DATASET"; echo "  Folds       : $FOLDS" ;;
          train-test)       echo "  Train File  : $TRAIN_FILE"; echo "  Test File   : $TEST_FILE" ;;
        esac
        ;;
      clustering|association)
        echo "  Dataset     : $DATASET"
        ;;
    esac
    if [[ ${#OPTIONS[@]} -gt 0 ]]; then
      echo "  Options     : ${OPTIONS[*]}"
    fi
    echo "  Report      : $REPORT_FILE"
    if [[ "$SAVE_MODEL" == "true" && "$TASK" != "association" ]]; then
      echo "  Model       : $MODEL_FILE"
    fi
    echo "=================================================================="
    echo ""
  } | tee "$REPORT_FILE"

  echo "[INFO] [$MODEL_NAME] Running: ${WEKA_CMD[*]}"
  echo ""

  if "${WEKA_CMD[@]}" 2>&1 | tee -a "$REPORT_FILE"; then
    echo ""
    echo "[INFO] [$MODEL_NAME] Completed successfully."
    SUCCEEDED+=("$MODEL_NAME")
  else
    EXIT_CODE=$?
    echo ""
    echo "[WARN] [$MODEL_NAME] Weka exited with code $EXIT_CODE. Partial output saved to: $REPORT_FILE" >&2
    FAILED+=("$MODEL_NAME")
  fi

  echo ""
done

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
echo "=================================================================="
echo "  Run Summary"
echo "=================================================================="
echo "  Run Dir : $RUN_DIR"
echo ""

if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
  echo "  Succeeded (${#SUCCEEDED[@]}):"
  for name in "${SUCCEEDED[@]}"; do
    echo "    ✓  $RUN_DIR/$name/"
  done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo ""
  echo "  Failed (${#FAILED[@]}):"
  for name in "${FAILED[@]}"; do
    echo "    ✗  $name"
  done
fi

echo "=================================================================="

if [[ ${#FAILED[@]} -gt 0 ]]; then
  exit 1
fi
