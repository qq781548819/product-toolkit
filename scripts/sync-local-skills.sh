#!/usr/bin/env bash
set -euo pipefail

SRC_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$SRC_DEFAULT}"

TARGETS=(
  "$HOME/.agents/skills/product-toolkit"
  "$HOME/.claude/skills/product-toolkit"
  "$HOME/.codex/skills/product-toolkit"
)

echo "Source: $SRC"

if [[ ! -d "$SRC" ]]; then
  echo "Error: source directory not found: $SRC" >&2
  exit 1
fi

for target in "${TARGETS[@]}"; do
  echo "Sync -> $target"
  if [[ -L "$target" || -f "$target" ]]; then
    rm -rf "$target"
  fi
  mkdir -p "$target"
  rsync -a --delete "$SRC"/ "$target"/
done

echo
echo "Verification:"
for target in "${TARGETS[@]}"; do
  if [[ -L "$target" ]]; then
    echo "  $target : symlink (unexpected)"
  elif [[ -d "$target" ]]; then
    head_ref="$(git -C "$target" rev-parse --short HEAD 2>/dev/null || echo "no-git")"
    echo "  $target : directory (ok), HEAD=$head_ref"
  else
    echo "  $target : missing"
  fi
done

echo
echo "Done."
