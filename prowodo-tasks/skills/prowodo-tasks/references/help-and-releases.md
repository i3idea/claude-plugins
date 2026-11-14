# Tool guide and product news

← [Skill index](../SKILL.md) · [full tools](tools.md)

Two read-only tools, useful above all to those who use ProWoDo as a connector without this skill.

| Tool | Purpose |
|------|---------|
| `help` | Without `topic`: introduction and list of the areas (with how many tools each). With `topic` (`tasks`, `notes`, `rhythm`, `sprints`, …): the tools of that area with title and one sentence. The list is generated from the MCP registry, so a new tool shows up on its own (under `other` until it has an area). An unknown `topic` gives an error with the valid areas. |
| `list_release_notes` | The latest ProWoDo releases from the public feed, most recent first: `version`, `name`, `released_at`, `short_summary`, `changelog_markdown`. `limit` (1–20, default 5), `since_version` (e.g. `1.18.0`: only newer releases, numeric comparison). |

When to use them:
- **"What's new in ProWoDo?"** ("Cosa c'è di nuovo in ProWoDo?") → `list_release_notes`. If the user says the latest version they know, pass `since_version`.
- **You do not know which tool to use, or the user asks what you can do** → `help`, then `help(topic=…)` only for the area you need.
- **A tool you expected is not there** → first `list_release_notes` (it might be new, or this skill might be behind), then `help`.

Things to know:
- The feed is public and cached for five minutes on the backend. If it is unreachable `list_release_notes` still responds with `results: []`, `feed_available: false` and a `note`: it is not a user error, retry later.
- The feed has only the published releases, without technical notes or SHAs. It does not replace the i3deploy tools (`list_project_releases`, …), which are for those who publish the releases.
