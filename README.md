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
claude mcp add --transport http prowodo https://mcp.prowodo.com/mcp/
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

---

### `relations-mcp`

Guidance skill for the **Relation** (Hoopygang) MCP tools — influencer, campaign and audience analytics — from Claude Code or claude.ai. No bundled MCP transport: the connector is configured on claude.ai via OAuth.

**What it does:**
- Detects when you ask about Relation influencers, campaigns, deals, organizations, or audience/demographic analytics (IT / EN / mixed)
- Loads a workflow guide for the read-only tools: `list_campaigns`/`retrieve_campaigns`, `list_influencers`/`retrieve_influencers`, `list_organizations`/`retrieve_organizations`, `lookup_influencer`, `get_influencer_audience`
- Documents the constraints: everything read-only, no paid-provider calls (no HypeAuditor/Apify refresh), results scoped by `organization`

**Install:**

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
/plugin install relations-mcp@i3idea
```

**Prerequisite — connect the Relation MCP server:**

On claude.ai, add a custom connector pointed at `https://mcp.hoopygang.com/mcp/` and authenticate via the OAuth flow (Firebase login). Requires an `is_dev` account with the per-service access flag enabled for Relation.

> **Preview:** the connector goes live once the OAuth connector and per-service access flag are deployed to production; the skill itself is ready to use today.

## License

MIT — see [LICENSE](./LICENSE).

## Issues & contributions

Bug reports and feature requests welcome:
[github.com/i3idea/claude-plugins/issues](https://github.com/i3idea/claude-plugins/issues).
