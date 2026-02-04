#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tmux-find-agents.sh [-L socket-name|-S socket-path|-A]

Scan tmux panes for known coding agent patterns and report their status.

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under OPENCLAW_TMUX_SOCKET_DIR
  -h, --help         show this help
USAGE
}

socket_name=""
socket_path=""
scan_all=false
socket_dir="${OPENCLAW_TMUX_SOCKET_DIR:-${CLAWDBOT_TMUX_SOCKET_DIR:-${TMPDIR:-/tmp}/openclaw-tmux-sockets}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -L|--socket)      socket_name="${2-}"; shift 2 ;;
    -S|--socket-path) socket_path="${2-}"; shift 2 ;;
    -A|--all)         scan_all=true; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$scan_all" == true && ( -n "$socket_name" || -n "$socket_path" ) ]]; then
  echo "Cannot combine --all with -L or -S" >&2
  exit 1
fi

if [[ -n "$socket_name" && -n "$socket_path" ]]; then
  echo "Use either -L or -S, not both" >&2
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not found in PATH" >&2
  exit 1
fi

print_header() {
  printf '%-20s %-8s %s\n' "SESSION:WINDOW.PANE" "AGENT" "STATUS"
}

analyze_pane() {
  local target="$1"; shift
  local tmux_cmd=(tmux "$@")

  local content
  if ! content="$(${tmux_cmd[@]} capture-pane -p -J -t "$target" -S -200 2>/dev/null)"; then
    return 1
  fi

  local last_line
  last_line="$(printf '%s\n' "$content" | tail -n 1)"

  local agent="generic"
  local status="running"

  local context_pct=""
  if printf '%s\n' "$content" | grep -qi "context left"; then
    context_pct="$(printf '%s\n' "$content" | grep -Eoi '[0-9]{1,3}% context left' | head -n 1 | awk '{print $1}')"
  fi

  if printf '%s\n' "$content" | grep -q "› "; then
    agent="codex"
  elif printf '%s\n' "$content" | grep -qi "codex"; then
    agent="codex"
  elif printf '%s\n' "$content" | grep -qi "gemini"; then
    agent="gemini"
  elif printf '%s\n' "$content" | grep -q "❯"; then
    agent="claude"
  elif printf '%s\n' "$content" | grep -qi "claude"; then
    agent="claude"
  elif printf '%s\n' "$content" | grep -qi "opencode"; then
    agent="opencode"
  fi

  if [[ "$agent" == "gemini" ]]; then
    if [[ "$last_line" =~ ">$" ]]; then
      status="ready"
    fi
  elif [[ "$last_line" =~ (›\ |❯\ |\$\ |#\ |%\ )$ ]]; then
    status="ready"
  fi

  if [[ "$status" == "ready" && -n "$context_pct" ]]; then
    status="ready (${context_pct} context)"
  fi

  printf '%-20s %-8s %s\n' "$target" "$agent" "$status"
}

scan_socket() {
  local label="$1"; shift
  local tmux_cmd=(tmux "$@")

  if ! panes="$(${tmux_cmd[@]} list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)"; then
    echo "No tmux server found on $label" >&2
    return 1
  fi

  print_header
  while IFS= read -r target; do
    analyze_pane "$target" "${tmux_cmd[@]:1}" || true
  done <<< "$panes"
}

if [[ "$scan_all" == true ]]; then
  if [[ ! -d "$socket_dir" ]]; then
    echo "Socket directory not found: $socket_dir" >&2
    exit 1
  fi

  shopt -s nullglob
  sockets=("$socket_dir"/*)
  shopt -u nullglob

  if [[ "${#sockets[@]}" -eq 0 ]]; then
    echo "No sockets found under $socket_dir" >&2
    exit 1
  fi

  exit_code=0
  for sock in "${sockets[@]}"; do
    if [[ ! -S "$sock" ]]; then
      continue
    fi
    scan_socket "socket path '$sock'" -S "$sock" || exit_code=$?
  done
  exit "$exit_code"
fi

tmux_cmd=(tmux)
socket_label="default socket"

if [[ -n "$socket_name" ]]; then
  tmux_cmd+=(-L "$socket_name")
  socket_label="socket name '$socket_name'"
elif [[ -n "$socket_path" ]]; then
  tmux_cmd+=(-S "$socket_path")
  socket_label="socket path '$socket_path'"
fi

scan_socket "$socket_label" "${tmux_cmd[@]:1}"
