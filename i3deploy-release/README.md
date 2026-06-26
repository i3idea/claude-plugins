# i3deploy-release

Cut [i3deploy](https://prowodo.com) releases from Claude Code — `ServiceRelease`
(one service's version + technical changelog) and `ProjectRelease` (a product
version that bundles service releases, with separate user-facing and technical
changelogs). The skill drafts the notes for you and publishes through the
i3deploy MCP server.

## What it does

- Auto-triggers on release / changelog mentions ("nuova release", "rilascia X",
  "publish a release", `/i3deploy-release`)
- Drafts the changelog from four sources: git (commits/diff since the last
  release), the current Claude Code session, memory, and your task manager
  (ProWoDo by default — or it asks if you use Jira / Linear / another)
- Dedups against existing releases (reads before writing) and proposes the next
  semver bump instead of colliding
- Separates user-facing vs technical notes for project releases, with interactive
  confirmation before every write
- Publishes via the i3deploy MCP tools (never raw curl)

## Install

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
/plugin install i3deploy-release@i3idea
```

## Prerequisite — connect the i3deploy MCP server

```
claude mcp add --transport http i3deploy https://i3deploy-back.i3idea.com/mcp/ \
  --header "Authorization: Bearer <YOUR_I3DEPLOY_API_KEY>"
```

The key authenticates one organization; in a wired client repo it's already in
the gitignored `.env.i3deploy` (`I3DEPLOY_API_KEY=...`).

## Usage

From inside a service repo, just say "nuova release" / "rilascia": the skill
finds the service from `i3version/deploy.json`, drafts the changelog, confirms the
version bump with you, and creates the release. For a product version, ask for a
"project release" and it bundles the relevant service releases with user + technical
notes.

## License

MIT — see [../LICENSE](../LICENSE).
