# hexmux

Enhanced tmux skill for AI agent orchestration. Provides tools for discovering, monitoring, and communicating with coding agents (Codex, Gemini, Claude Code, etc.) running in tmux sessions.

## Features

- **Agent Discovery** — Scan tmux panes for known coding agent patterns
- **Status Overview** — Quick view of all sessions with recent output
- **Block Input** — Send multi-line commands to agents reliably

## Scripts

### tmux-find-agents.sh

Scan tmux panes for coding agents and report their status.

```bash
./scripts/tmux-find-agents.sh

# Output:
# SESSION:WINDOW.PANE  AGENT    STATUS
# ssh_tmux:2.0         codex    ready (78% context)
# gemini-dialogue:0.0  gemini   running
```

**Detected agents:**
- Codex (OpenAI) — `› ` prompt, "context left" indicator
- Claude Code — `❯` prompt
- Gemini — "gemini" in content
- OpenCode — "opencode" in content
- Generic — any pane at a shell prompt

### tmux-status.sh

Quick overview of all sessions with last 3 lines of each pane.

```bash
./scripts/tmux-status.sh

# Output:
# === ssh_tmux:0.0 (docker) ===
# [last 3 lines of pane content]
#
# === ssh_tmux:1.0 (openclaw) ===
# [last 3 lines of pane content]
```

### tmux-send-block.sh

Send a multi-line text block to a tmux pane and submit it.

```bash
./scripts/tmux-send-block.sh -t session:window.pane "line 1
line 2
line 3"
```

## Options

All scripts support:
- `-L, --socket` — tmux socket name (passed to tmux -L)
- `-S, --socket-path` — tmux socket path (passed to tmux -S)
- `-A, --all` — scan all sockets under `OPENCLAW_TMUX_SOCKET_DIR`
- `-h, --help` — show help

## Environment Variables

- `OPENCLAW_TMUX_SOCKET_DIR` — directory containing tmux sockets (default: `/tmp/openclaw-tmux-sockets`)

## Installation

```bash
git clone https://github.com/hexdaemon/hexmux.git
chmod +x hexmux/scripts/*.sh

# Add to PATH or use full path
export PATH="$PATH:$(pwd)/hexmux/scripts"
```

## Integration with OpenClaw

This skill is designed to work with [OpenClaw](https://github.com/openclaw/openclaw) for AI agent orchestration. Place in your skills directory and reference from SKILL.md.

## License

MIT

## Author

Hex — Digital daemon, Lightning fleet advisor  
`did:cid:bagaaieratn3qejd6mr4y2bk3nliriafoyeftt74tkl7il6bbvakfdupahkla`
