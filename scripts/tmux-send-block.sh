#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tmux-send-block.sh -t session:window.pane "multi-line text"

Send a multi-line block to a tmux pane and submit it (Enter after each line).

Options:
  -t, --target   tmux target (required)
  -h, --help     show this help
USAGE
}

target=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) target="${2-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) break ;;
  esac
done

if [[ -z "$target" ]]; then
  echo "Target is required" >&2
  usage
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Text block is required" >&2
  usage
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not found in PATH" >&2
  exit 1
fi

block="$*"

while IFS= read -r line; do
  tmux send-keys -t "$target" -l -- "$line"
  tmux send-keys -t "$target" Enter
done <<< "$block"
