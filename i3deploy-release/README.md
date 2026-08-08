# i3deploy-release

Cut [i3deploy](https://i3deploy.com) releases from Claude Code — `ServiceRelease`
(one service's version + technical changelog) and `ProjectRelease` (a product
version that bundles service releases, with separate user-facing and technical
changelogs). The skill drafts the notes for you and publishes through the
i3deploy MCP server.

**Standalone.** i3deploy-release needs an i3deploy account and nothing else — no
ProWoDo, no other i3idea product.

## What it does

- Auto-triggers on release / changelog mentions ("nuova release", "rilascia X",
  "publish a release", `/i3deploy-release`)
- Drafts the changelog from four sources: git (commits/diff since the last
  release), the current Claude Code session, memory, and your task manager —
  whichever you use (ProWoDo, Jira, Linear, GitHub Issues; it asks if it can't
  tell, and skips the source entirely if you don't use one)
- Dedups against existing releases (reads before writing) and proposes the next
  semver bump instead of colliding
- Separates user-facing vs technical notes for project releases, with interactive
  confirmation before every write
- Can target a release at a named **audience** (beta testers, staff), with its own
  changelog text and its own feed — on request, behind an explicit confirmation
- Publishes via the i3deploy MCP tools (never raw curl)

## Install

```
/plugin marketplace add https://github.com/i3idea/claude-plugins
/plugin install i3deploy-release@i3idea
```

## Authenticate — one step, no API key

The i3deploy MCP server **ships with the plugin**; there's nothing to add by hand.
After installing, authenticate once:

```
/mcp
```

Pick `i3deploy` and complete the browser login. The server supports OAuth 2.0
Dynamic Client Registration (PKCE), so no API key is ever stored in config, and
the release lands in the org(s) your account belongs to.

Don't have an i3deploy account yet? See [i3deploy.com](https://i3deploy.com).

### Already have i3deploy connected?

If you connected it manually (`claude mcp add ... i3deploy`) or use the claude.ai
connector, the bundled server is a *separate* registration — authenticating it too
would load two equivalent tool sets. Pick one:

- **Switch to the bundled server** — drop your own connection with
  `claude mcp remove i3deploy`, then `/mcp` to log in. If you had allowlisted tool
  permissions in settings, repoint them at the new prefix
  (`mcp__plugin_i3deploy-release_i3deploy__*`) or read-only calls will start
  prompting again.
- **Keep your own connection** — just **don't authenticate** the bundled server.
  An unauthenticated server exposes no tools, so it sits inert and the skill uses
  whichever i3deploy connection is live. It shows up in `/mcp` as
  "needs authentication"; that's cosmetic.

There is **no way to keep the skill while disabling the bundled server**:
`disabledMcpjsonServers` only applies to project `.mcp.json` files, not to
plugin-bundled servers, and `/plugin disable` removes the skill along with it.
Leaving it unauthenticated is the supported way to opt out.

### API key instead of OAuth

An org API key still works and is the right choice for CI or a shared machine —
one key authenticates exactly one org:

```
claude mcp add --transport http i3deploy https://mcp.i3deploy.com/mcp/ \
  --header "Authorization: Bearer <YOUR_I3DEPLOY_API_KEY>"
```

In a wired client repo the key is already in the gitignored `.env.i3deploy`
(`I3DEPLOY_API_KEY=...`). Leave the bundled server unauthenticated if you go this
route.

## Usage

From inside a service repo, just say "nuova release" / "rilascia": the skill
finds the service from `i3version/deploy.json`, drafts the changelog, confirms the
version bump with you, and creates the release. For a product version, ask for a
"project release" and it bundles the relevant service releases with user +
technical notes.

## License

MIT — see [../LICENSE](../LICENSE).
