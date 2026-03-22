#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# app/utils/convert_csv.sh
# Converts semicolon-separated CSV (common from European exports) to
# comma-separated CSV for Weka and other tools that expect commas.
#
# Usage:
#   bash app/utils/convert_csv.sh --file <input.csv> --output <output.csv>
#   (from app/) bash utils/convert_csv.sh --file <input.csv> --output <out.csv>
# ---------------------------------------------------------------------------

usage() {
  cat <<'EOF' >&2
Convert semicolon-separated CSV to comma-separated (Weka-friendly).

Usage: bash app/utils/convert_csv.sh --file <input.csv> --output <output.csv>
EOF
}

FILE=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$FILE" || -z "$OUTPUT" ]]; then
  echo "[ERROR] Both --file and --output are required." >&2
  usage
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "[ERROR] Input file not found: $FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

# Semicolon → comma (Weka-friendly CSV). Same path: write via temp file.
if [[ "$FILE" == "$OUTPUT" ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  sed 's/;/,/g' "$FILE" > "$tmp"
  mv "$tmp" "$OUTPUT"
  trap - EXIT
else
  sed 's/;/,/g' "$FILE" > "$OUTPUT"
fi

echo "Wrote: $OUTPUT"
