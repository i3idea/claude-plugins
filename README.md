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

## Authenticate — one step, no API key

The ProWoDo MCP server **ships with the plugin** — no `claude mcp add` needed. After installing, run:

```
/mcp
```

Pick `prowodo` and complete the browser login. The server supports OAuth 2.0 Dynamic Client Registration, so no API key is ever stored in config. See the [MCP setup blog post](https://prowodo.com/it/blog/configurare-mcp-clients) for other clients (Claude Desktop, Cursor, Windsurf, ChatGPT, Gemini, Cline, etc.), which still connect manually.

If you already had ProWoDo connected by hand, drop it (`claude mcp remove prowodo`) so you don't load the same ~65 tools twice — see the [plugin README](./prowodo-tasks/README.md#authenticate--one-step-no-api-key).

Don't have a ProWoDo account yet? Sign up at [prowodo.com](https://prowodo.com) — free Early Access while in beta.

## Usage

After install, just talk to Claude Code naturally about tasks:

- "Cosa c'è in backlog?" → lists open root tasks
- "Segna che ho finito X" → marks task DONE + updates progress + status
- "Aggiungi task: fix bug login + 3 SP feature ux" → creates task with tags & story points
- "Pianifichiamo lo sprint" → builds the backlog prioritization flow

The skill triggers automatically on these phrases (IT / EN / any language) and on related concepts: "todo", "planning", "scrum", "story points", "grooming", "what do I need to do", "dimmi i task", and many more.

---

### `i3deploy-release`

Cut **i3deploy** releases from Claude Code — `ServiceRelease` (one service's version + technical changelog) and `ProjectRelease` (a product version that bundles service releases, with separate user-facing and technical changelogs). The skill drafts the notes for you and publishes through the i3deploy MCP server.

**What it does:**
- Auto-triggers on release / changelog mentions ("nuova release", "rilascia X", "publish a release", `/i3deploy-release`)
- Drafts the changelog from four sources: git (commits/diff since the last release), the current Claude Code session, memory, and your task manager (ProWoDo by default — or it asks if you use Jira/Linear/another)
- Dedups against existing releases (reads before writing) and proposes the next semver bump instead of colliding
- Separates user-facing vs technical notes for project releases, with interactive confirmation before every write
- Publishes via the i3deploy MCP tools (never raw curl)

**Install:**

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
/plugin install i3deploy-release@i3idea
```

**Prerequisite — connect the i3deploy MCP server:**

```
claude mcp add --transport http i3deploy https://mcp.i3deploy.com/mcp/ \
  --header "Authorization: Bearer <YOUR_I3DEPLOY_API_KEY>"
```

The key authenticates one organization; in a wired client repo it's already in the gitignored `.env.i3deploy`.

## License

MIT — see [LICENSE](./LICENSE).

## Issues & contributions

Bug reports and feature requests welcome:
[github.com/i3idea/claude-plugins/issues](https://github.com/i3idea/claude-plugins/issues).
