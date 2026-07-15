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

## Authenticate — one step, no API key

The ProWoDo MCP server **ships with the plugin**; there's nothing to add by hand.
After installing, authenticate once:

```
/mcp
```

Pick `prowodo` and complete the browser login. ProWoDo's MCP server supports
OAuth 2.0 Dynamic Client Registration, so no API key is ever stored in config.
Don't have an account? Sign up at [prowodo.com](https://prowodo.com) (free Early
Access in beta).

**Already connected ProWoDo manually** (`claude mcp add ... prowodo`) or via the
claude.ai connector? The bundled server is a *separate* registration, so you'd load
two equivalent tool sets (~65 tools each). Remove the manual one to avoid the
duplication:

```
claude mcp remove prowodo
```

Prefer to keep your own connection and skip the bundled server? Add it to
`disabledMcpjsonServers` in your settings — the skill works with whichever
ProWoDo connection is present.

## Usage

Just talk to Claude Code naturally about tasks:

- "Cosa c'è in backlog?" → lists open root tasks
- "Segna che ho finito X" → marks task DONE + updates progress + status
- "Aggiungi task: fix bug login + 3 SP feature ux" → creates task with tags & story points
- "Pianifichiamo lo sprint" → builds the backlog prioritization flow

## License

MIT — see [../LICENSE](../LICENSE).
