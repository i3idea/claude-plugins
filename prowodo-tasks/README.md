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

### Already have ProWoDo connected?

If you connected it manually (`claude mcp add ... prowodo`) or use the claude.ai
connector, the bundled server is a *separate* registration — authenticating it too
would load two equivalent tool sets (~65 tools each). Pick one:

- **Switch to the bundled server** — drop your own connection with
  `claude mcp remove prowodo`, then `/mcp` to log in. If you had allowlisted tool
  permissions in settings, repoint them at the new prefix
  (`mcp__plugin_prowodo-tasks_prowodo__*`) or read-only calls will start prompting
  again.
- **Keep your own connection** — just **don't authenticate** the bundled server.
  An unauthenticated server exposes no tools, so it sits inert and the skill uses
  whichever ProWoDo connection is live. It shows up in `/mcp` as
  "needs authentication"; that's cosmetic.

There is **no way to keep the skill while disabling the bundled server**:
`disabledMcpjsonServers` only applies to project `.mcp.json` files, not to
plugin-bundled servers, and `/plugin disable` removes the skill along with it.
Leaving it unauthenticated is the supported way to opt out.

## Usage

Just talk to Claude Code naturally about tasks:

- "Cosa c'è in backlog?" → lists open root tasks
- "Segna che ho finito X" → marks task DONE + updates progress + status
- "Aggiungi task: fix bug login + 3 SP feature ux" → creates task with tags & story points
- "Pianifichiamo lo sprint" → builds the backlog prioritization flow

## License

MIT — see [../LICENSE](../LICENSE).
