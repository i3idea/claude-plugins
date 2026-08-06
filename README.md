# i3idea Claude Code plugins

Claude Code plugins published by [i3idea](https://i3idea.com).

| Plugin | What it does | Needs |
|---|---|---|
| [`prowodo-tasks`](#prowodo-tasks) | Tasks, backlog, sprints, reminders, Daily Resumes | a [ProWoDo](https://prowodo.com) account |
| [`i3deploy-release`](#i3deploy-release) | Releases & changelogs (ServiceRelease + ProjectRelease) | an [i3deploy](https://i3deploy.com) account |

The two are **independent**: install either one on its own. Add the marketplace
once, then install what you need:

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
```

---

## `prowodo-tasks`

Manage [ProWoDo](https://prowodo.com) tasks, backlog, sprints and Daily Resumes
directly from Claude Code. The skill auto-triggers on task / planning / sprint
mentions in any language and routes work through the ProWoDo MCP server.

**What it does:**
- Detects when you talk about tasks, planning, todos, backlog, sprints, story points (IT / EN / mixed)
- Loads a workflow guide that tells Claude how to use the ProWoDo MCP tools idiomatically
- Manages project defaults per working directory (company / project / Scrum mode) so you don't have to repeat them every session
- Encodes verified API gotchas (4096-char description cap, order renormalize behavior, mass-tag race conditions) so Claude doesn't trip on them

**Install:**

```
/plugin install prowodo-tasks@i3idea
```

**Authenticate — one step, no API key.** The ProWoDo MCP server ships with the
plugin, so there's no `claude mcp add`. Run `/mcp`, pick `prowodo`, and complete
the browser login (OAuth 2.0 Dynamic Client Registration — no API key is ever
stored in config). See the [MCP setup blog post](https://prowodo.com/it/blog/configurare-mcp-clients)
for other clients (Claude Desktop, Cursor, Windsurf, ChatGPT, Gemini, Cline, …),
which still connect manually.

Already have ProWoDo connected by hand or via the claude.ai connector? Either drop
yours (`claude mcp remove prowodo`) and use the bundled server, or simply **don't
authenticate** the bundled one — an unauthenticated server exposes no tools, so it
stays inert and the skill uses your existing connection. Trade-offs in the
[plugin README](./prowodo-tasks/README.md#already-have-prowodo-connected).

No ProWoDo account yet? Sign up at [prowodo.com](https://prowodo.com) — free Early
Access while in beta.

**Usage** — just talk to Claude Code naturally about tasks:

- "Cosa c'è in backlog?" → lists open root tasks
- "Segna che ho finito X" → marks task DONE + updates progress + status
- "Aggiungi task: fix bug login + 3 SP feature ux" → creates task with tags & story points
- "Pianifichiamo lo sprint" → builds the backlog prioritization flow

The skill triggers automatically on these phrases (IT / EN / any language) and on
related concepts: "todo", "planning", "scrum", "story points", "grooming", "what do
I need to do", "dimmi i task", and many more.

Full details: [prowodo-tasks/README.md](./prowodo-tasks/README.md).

---

## `i3deploy-release`

Cut [i3deploy](https://i3deploy.com) releases from Claude Code — `ServiceRelease`
(one service's version + technical changelog) and `ProjectRelease` (a product
version that bundles service releases, with separate user-facing and technical
changelogs). The skill drafts the notes for you and publishes through the i3deploy
MCP server. **Standalone — no ProWoDo required.**

**What it does:**
- Auto-triggers on release / changelog mentions ("nuova release", "rilascia X", "publish a release", `/i3deploy-release`)
- Drafts the changelog from four sources: git (commits/diff since the last release), the current Claude Code session, memory, and whichever task manager you use (ProWoDo, Jira, Linear, GitHub Issues — it asks if it can't tell, and skips the source if you don't use one)
- Dedups against existing releases (reads before writing) and proposes the next semver bump instead of colliding
- Separates user-facing vs technical notes for project releases, with interactive confirmation before every write
- Publishes via the i3deploy MCP tools (never raw curl)

**Install:**

```
/plugin install i3deploy-release@i3idea
```

**Authenticate — one step, no API key.** The i3deploy MCP server ships with the
plugin. Run `/mcp`, pick `i3deploy`, and complete the browser login (OAuth 2.0
with Dynamic Client Registration + PKCE). An org API key still works and is the
right choice for CI or a shared machine:

```
claude mcp add --transport http i3deploy https://mcp.i3deploy.com/mcp/ \
  --header "Authorization: Bearer <YOUR_I3DEPLOY_API_KEY>"
```

One key authenticates exactly one organization; in a wired client repo it's
already in the gitignored `.env.i3deploy`.

**Usage** — from inside a service repo, say "nuova release" / "rilascia": the skill
reads the service from `i3version/deploy.json`, drafts the changelog, confirms the
version bump, and creates the release. Ask for a "project release" to bundle
service releases into a product version.

Full details: [i3deploy-release/README.md](./i3deploy-release/README.md).

---

## License

MIT — see [LICENSE](./LICENSE).

## Issues & contributions

Bug reports and feature requests welcome:
[github.com/i3idea/claude-plugins/issues](https://github.com/i3idea/claude-plugins/issues).
