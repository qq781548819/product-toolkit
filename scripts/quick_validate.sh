#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR_DEFAULT="${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py"
VALIDATOR="${QUICK_VALIDATE_PY:-$VALIDATOR_DEFAULT}"

if [[ ! -f "$VALIDATOR" ]]; then
  echo "Error: quick_validate.py not found: $VALIDATOR" >&2
  echo "Tip: export QUICK_VALIDATE_PY=/absolute/path/to/quick_validate.py" >&2
  exit 1
fi

echo "Using validator: $VALIDATOR"
echo "Project root: $ROOT_DIR"
echo

total=0
failed=0

run_validate() {
  local dir="$1"
  ((total += 1))
  if python3 "$VALIDATOR" "$dir"; then
    echo "[PASS] ${dir#$ROOT_DIR/}"
  else
    echo "[FAIL] ${dir#$ROOT_DIR/}"
    ((failed += 1))
  fi
}

run_validate "$ROOT_DIR"

for dir in "$ROOT_DIR"/skills/*; do
  [[ -d "$dir" && -f "$dir/SKILL.md" ]] || continue
  run_validate "$dir"
done

echo
echo "Summary: total=$total failed=$failed"
if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
