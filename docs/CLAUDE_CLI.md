Claude CLI (Repo-Local)

Overview
- Provides a lightweight `claude` command in `bin/claude` (Python).
- Works with the Anthropic API using either the official SDK (if installed) or stdlib HTTP.
- No global install required; available automatically inside the dev container.

Setup
- Set your API key: `export ANTHROPIC_API_KEY=sk-ant-...`
- Optional env:
  - `CLAUDE_MODEL` (default: `claude-3-5-sonnet-latest`)
  - `CLAUDE_MAX_TOKENS` (default: `1024`)

Usage
- Ask a question: `claude "What’s the plan for Visionary?"`
- Pipe input: `echo "Summarize ROADMAP.md" | claude`
- Raw JSON: `claude "Hello" --json`
- Choose model: `claude "Draft a README" --model claude-3-5-sonnet-latest`

Dev Container Notes
- The devcontainer adds `${workspaceFolder}/bin` to PATH and makes the script executable on create.
- If `claude` isn’t found, rebuild the container or run `chmod +x bin/claude`.

Troubleshooting
- Error: `ANTHROPIC_API_KEY is not set` → export your key.
- Network errors inside the dev container → run from host, or ensure outbound HTTPS is allowed.
- SDK import errors are harmless; the CLI falls back to stdlib HTTP.
