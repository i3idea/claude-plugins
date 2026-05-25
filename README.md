# i3idea Claude Code plugins

Claude Code plugins published by [i3idea](https://prowodo.com).

## Available plugins

### `prowodo-tasks`

Manage ProWoDo tasks, backlog, sprints and Daily Resumes directly from Claude Code. The skill auto-triggers on task / planning / sprint mentions in any language and routes work through the ProWoDo MCP server.

**What it does:**
- Detects when you talk about tasks, planning, todos, backlog, sprints, story points (IT / EN / mixed)
- Loads a workflow guide that tells Claude how to use the ProWoDo MCP tools idiomatically
- Manages project defaults per working directory (company / project / Scrum mode) so you don't have to repeat them every session
- Encodes verified API gotchas (4096-char description cap, order renormalize behavior, mass-tag race conditions) so Claude doesn't trip on them

## Installation

In Claude Code:

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
/plugin install prowodo-tasks@i3idea
```

## Prerequisite — connect the ProWoDo MCP server

The skill drives the ProWoDo MCP server. If you don't already have it connected, add it once:

```
/mcp add https://backend.prowodo.com/mcp/
```

ProWoDo's MCP server supports OAuth 2.0 Dynamic Client Registration — your Claude Code session will open a browser to grant access, no manual API key handling. See the [MCP setup blog post](https://prowodo.com/it/blog/configurare-mcp-clients) for client-specific tips (Claude Desktop, Cursor, Windsurf, ChatGPT, Gemini, Cline, etc.).

Don't have a ProWoDo account yet? Sign up at [prowodo.com](https://prowodo.com) — free Early Access while in beta.

## Usage

After install, just talk to Claude Code naturally about tasks:

- "Cosa c'è in backlog?" → lists open root tasks
- "Segna che ho finito X" → marks task DONE + updates progress + status
- "Aggiungi task: fix bug login + 3 SP feature ux" → creates task with tags & story points
- "Pianifichiamo lo sprint" → builds the backlog prioritization flow

The skill triggers automatically on these phrases (IT / EN / any language) and on related concepts: "todo", "planning", "scrum", "story points", "grooming", "what do I need to do", "dimmi i task", and many more.

## License

MIT — see [LICENSE](./LICENSE).

## Issues & contributions

Bug reports and feature requests welcome:
[github.com/i3idea/claude-plugins/issues](https://github.com/i3idea/claude-plugins/issues).
