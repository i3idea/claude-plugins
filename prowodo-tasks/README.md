# prowodo-tasks

Manage [ProWoDo](https://prowodo.com) tasks, backlog, sprints and Daily Resumes
directly from Claude Code. The skill auto-triggers on task / planning / sprint
mentions in any language and routes work through the ProWoDo MCP server.

## What it does

- Detects when you talk about tasks, planning, todos, backlog, sprints, story
  points (IT / EN / mixed)
- Loads a workflow guide that tells Claude how to use the ProWoDo MCP tools
  idiomatically
- Manages project defaults per working directory (company / project / Scrum mode)
  so you don't have to repeat them every session
- Encodes verified API gotchas (4096-char description cap, order renormalize
  behavior, mass-tag race conditions) so Claude doesn't trip on them

## Install

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
/plugin install prowodo-tasks@i3idea
```

## Prerequisite — connect the ProWoDo MCP server

```
claude mcp add --transport http prowodo https://mcp.prowodo.com/mcp/
```

ProWoDo's MCP server supports OAuth 2.0 Dynamic Client Registration — your first
use opens a browser to grant access, no manual API key handling. Don't have an
account? Sign up at [prowodo.com](https://prowodo.com) (free Early Access in beta).

## Usage

Just talk to Claude Code naturally about tasks:

- "Cosa c'è in backlog?" → lists open root tasks
- "Segna che ho finito X" → marks task DONE + updates progress + status
- "Aggiungi task: fix bug login + 3 SP feature ux" → creates task with tags & story points
- "Pianifichiamo lo sprint" → builds the backlog prioritization flow

## License

MIT — see [../LICENSE](../LICENSE).
