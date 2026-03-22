#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# utils/model_helper.sh
# Show classifier-specific options for a Weka classifier.
# Usage: ./utils/model_helper.sh <weka.classifier.ClassName>
# Example: ./utils/model_helper.sh weka.classifiers.lazy.IBk
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEKA_JAR="$PROJECT_DIR/weka.jar"
MTJ_JAR="$PROJECT_DIR/mtj-1.0.4.jar"
WEKA_CP="$WEKA_JAR${MTJ_JAR:+:$MTJ_JAR}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <weka.classifier.ClassName>" >&2
  echo ""
  echo "Examples:"
  echo "  $0 weka.classifiers.lazy.IBk"
  echo "  $0 weka.classifiers.trees.J48"
  echo "  $0 weka.classifiers.bayes.NaiveBayes"
  echo "  $0 weka.classifiers.trees.RandomForest"
  echo "  $0 weka.classifiers.functions.SMO"
  exit 1
fi

CLASSIFIER="$1"

if [[ ! -f "$WEKA_JAR" ]]; then
  echo "[ERROR] Weka JAR not found at: $WEKA_JAR" >&2
  exit 1
fi

# Run --help and try to extract the "Options specific to <class>:" section.
# Classifiers use that heading; filters print options directly without it.
# If the section is not found, fall back to printing the full help output.
HELP_OUTPUT=$(java --add-opens java.base/java.lang=ALL-UNNAMED -cp "$WEKA_CP" "$CLASSIFIER" --help 2>&1)

SPECIFIC=$(echo "$HELP_OUTPUT" \
  | awk '/^Options specific to '"$CLASSIFIER"'/{found=1} found{print}')

if [[ -n "$SPECIFIC" ]]; then
  echo "$SPECIFIC"
else
  echo "$HELP_OUTPUT"
fi
