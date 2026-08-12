---
name: i3deploy-release
description: Create and publish i3deploy releases — ServiceRelease (one service's version + changelog) and ProjectRelease (a project version that bundles service releases, with user-facing and technical changelogs). Use this skill whenever the user wants to cut, publish, draft, or record a release or changelog for an i3idea/i3deploy-tracked project or service — e.g. "nuova release", "rilascia pwd-backend", "pubblica una release di i3school", "crea la project release", "changelog di rilascio", "facciamo una release", "bump version and release", or /i3deploy-release. Trigger even when the user doesn't say "i3deploy" explicitly, as long as they're cutting a release in a repo that has an i3version/deploy.json. Drafts the changelog from git + the current session + memory + whichever task manager the user has, dedups against existing releases, and creates everything through the i3deploy MCP tools after your confirmation.
---

# i3deploy — Release Population

Create **ServiceRelease** and **ProjectRelease** records on i3deploy, with good
changelogs, through the i3deploy **MCP tools** (never raw curl). The skill drafts
the notes for you from everything it can see, checks you're not duplicating an
existing version, and only writes after you confirm.

Two record types, related:
- **ServiceRelease** — one service at one version (e.g. `pwd-backend@2.3.0`), with
  a technical changelog and the git commit range it covers.
- **ProjectRelease** — a *product* version (e.g. project `pwd` `v2.3.0`) that
  **bundles** one or more ServiceReleases and carries two audiences of notes:
  `markdown_users` (user-facing) and `markdown_techies` (technical).

A typical flow: cut a ServiceRelease in each changed service repo, then cut one
ProjectRelease that bundles them.

## Prerequisite: the i3deploy MCP must be connected

This skill calls i3deploy MCP tools (`list_*`, `retrieve_*`, `create_*`). If those
tools are not available in your session, **stop and set up the connector** — do
not fall back to curl (the MCP exists precisely so releases aren't hand-rolled
HTTP).

When installed as a plugin, the i3deploy MCP server **ships with the skill**: the
user only runs `/mcp`, picks `i3deploy`, and completes the browser login (OAuth
2.0 with Dynamic Client Registration + PKCE — no API key stored anywhere). The
other ways to connect still work:

- **Claude Code (API key)** — right for CI or a shared machine:
  ```
  claude mcp add --transport http i3deploy https://mcp.i3deploy.com/mcp/ \
    --header "Authorization: Bearer <KEY>"
  ```
  `<KEY>` is the org's i3deploy API key — in a wired client repo it's already in the
  gitignored `.env.i3deploy` (`I3DEPLOY_API_KEY=...`). **One key = one org.**
- **claude.ai (OAuth):** Settings → Connectors → Add custom connector → URL
  `https://mcp.i3deploy.com/mcp/`. The browser OAuth flow signs you in; the
  org(s) come from your account's memberships.

**Tool names depend on how it's connected** — this skill uses the bare names
(`list_service_releases`, …); the real prefix in your session is one of:

| Connection | Actual tool name |
|---|---|
| MCP bundled with the plugin (default) | `mcp__plugin_i3deploy-release_i3deploy__list_service_releases` |
| `claude mcp add ... i3deploy` (manual) | `mcp__i3deploy__list_service_releases` |
| claude.ai connector | `mcp__claude_ai_i3deploy__list_service_releases` |

If two of these are authenticated at once you'll see duplicate tool sets — use
either one, but tell the user so they can drop the redundant connection.

**Which org a release lands in:**
- API key → that key's single org (org `i3` covers pwd / i3school / i3deploy; org
  `hg` is hoopygang).
- OAuth → your org membership(s). If you belong to **multiple** orgs, `list_*`
  span all of them (filter results by slug), and the target org is inferred from
  the `project`/`service` slug you pick — except `create_projects`, which then
  needs an explicit `organization` (see `references/mcp-tools.md`).

Always tell the user which org you're about to write to, so there's no cross-org
surprise.

> **Argument envelope:** i3deploy MCP tools wrap their arguments under a `body`
> key. Always call them as `create_service_releases({"body": {...}})`,
> `list_project_releases({"body": {"project": "pwd"}})`, etc. See
> `references/mcp-tools.md` for the exact field list of every tool.

## Core principles

- **Read before you write (dedup).** Always `list_*` (and `retrieve_*` if needed)
  the existing releases first. **Both release types are unique**: `ServiceRelease`
  per `(service, version)`, `ProjectRelease` per `(project, version_numeric)`. The
  server enforces both, so reusing a version is a `400`, never a silent duplicate:
  `"This project already has a release with this version_numeric. A project
  version names exactly one release — bump the version instead of reusing it."`
  Reading first is still the point: not to dodge an error, but to propose the
  *right* next version instead of guessing. If the version you'd use already
  exists, don't try to create it — show the latest and propose the next semver
  bump. Reading also gives you the previous release's `commit_sha`, which anchors
  the new git range.
- **No releases yet → this is the FIRST release.** If the filtered list is empty
  for this service/project, don't get stuck looking for a "latest": say so and
  **propose creating the initial release**. Default to **`0.1.0`** (or `1.0.0` if
  the user says it's production-ready) — confirm with the user. With no previous
  release there's no `commit_sha` anchor: use the **whole history** as the range
  (`<first-commit>..HEAD`, e.g. `git rev-list --max-parents=0 HEAD` for the root,
  or just omit `commit_range`) and draft the changelog from the full history +
  session + memory + tasks.
- **Draft, then gate.** You compose the changelog; the human owns the final call.
  Never create silently — confirm the version and show the full payload before
  every `create_*` (creation is a write).
- **Explain the bump.** Show `latest → proposed` and why (feat → minor, fix →
  patch, breaking → major), so the human can correct it in one word.

## Step 1 — Gather context for the draft

Pull from all of these (they complement each other; git tells you *what changed*,
the others tell you *why it matters*):

1. **git** — the commits and diff since the last release. The range is
   `<sha of the latest release>..HEAD`; `commit_sha` for the new release is `HEAD`.
   Use `git log --oneline <range>` and skim the diff for user-visible vs internal
   changes.
2. **the current session** — what was actually built/fixed in this conversation.
   You often have richer context here than the commit messages do.
3. **memory** — `~/.claude/projects/<cwd-slug>/memory/` for decisions, constraints,
   or follow-ups worth surfacing in the notes.
4. **the task manager** — recently completed or related tasks for this project.
   **Use whichever one this user actually has**; i3deploy doesn't assume any
   particular tracker. Detect it from the session and the repo:
   - ProWoDo tools available (`list_tasks`, any prefix) → use them, filtered to the
     project with `is_completed=true`.
   - Jira keys in commit messages (`PROJ-123`), an Atlassian connector in session →
     use the Atlassian tools.
   - A Linear or GitHub Issues workflow (`gh issue list`, issue refs in commits) →
     use that.
   - Ambiguous or nothing detected → **ask the user which task manager they use**
     rather than guessing.

   Tasks are the canonical "what we set out to do"; reference or summarize them.
   If there's no task manager, just skip this source — git + session + memory still
   give a solid draft.

Synthesize, don't dump: a changelog is a curated story, not a commit log paste.

## Step 2 — ServiceRelease (run from inside the service's repo)

1. Read `i3version/deploy.json` in the repo root → `service`, `base_url`, and the
   env. The org comes from the connector's key.
2. `list_service_releases({"body": {"service": "<slug>", "page_size": 100}})` →
   a **paginated object**; read the rows from **`.results`**, then take the highest
   `version` to find the latest and its `commit_sha`. (Dedup + range anchor.)
   **Filter on the server, never by scanning page 1**: the default page is 25 rows
   out of hundreds, so a client-side scan finds nothing for your service and you
   would read that as "first release". **If the filtered `.results` is empty → it
   really is the first release** (see Core principles): propose `0.1.0`/`1.0.0` and
   use the full history.
3. Build `commit_range` (`<latest sha>..HEAD`) and gather the four sources
   (Step 1). Draft `changelog_markdown` (**technical**, markdown), and — when the
   change is user-visible — `markdown_users` (**user-facing**, plain language);
   plus a one-line `short_summary`. (A ServiceRelease carries both audiences, like
   a ProjectRelease; leave `markdown_users` empty for purely internal changes.)
4. **Gate:** present `latest → proposed` version with the bump rationale; let the
   user adjust the version and edit the notes. Refuse a version that already
   exists.
5. Show the final payload, get a yes, then create:
   `create_service_releases({"body": {service, version, commit_sha, commit_range, changelog_markdown, markdown_users, short_summary, authored_by}})`.

## Step 3 — ProjectRelease (bundle service releases into a product version)

1. `list_projects` / `list_services` to confirm the project and its services.
2. Decide which ServiceReleases this product version bundles — the ones you just
   cut and/or ones the user names, identified by `(service, version)`. Service
   releases that live in **other repos** must already exist (cut them with Step 2
   there first); the project release only *references* them.
3. Draft the product notes, **separating the two audiences**:
   - `markdown_users` — what a user/customer would care about (features, fixes,
     visible changes), in plain language.
   - `markdown_techies` — migration notes, internal/infra changes, breaking API
     details.
   Aggregate from the bundled service releases + the Step 1 sources. Draft a
   `title` and a short `short`.
4. `list_project_releases({"body": {"project": "<slug>", "page_size": 100}})` for
   dedup — **if the filtered `.results` is empty, it's the first project release**
   (propose `0.1.0`/`1.0.0`) → **gate** on
   `version_numeric` (bump) and on the user-vs-technical split (this split is the
   whole point of a ProjectRelease — get the human's sign-off on it).
5. Show the final payload, confirm, then create:
   `create_project_releases({"body": {project, title, short, markdown_users, markdown_techies, version_numeric, authored_by, service_releases: [{service, version}, ...]}})`.

## Step 4 (optional) — restrict a release to an audience

Only when the user asks for it — "questa la vedono solo i beta tester", "uguale
ma con una nota in più per lo staff". A project can define **audiences** (`beta`,
`staff`, …), each with its own feed URL that the user has configured in their
frontend.

1. `list_release_audiences({"body": {}})` and filter `.results` by the project
   slug. **No audiences for this project → stop and ask**: creating one is a
   deliberate act with a setup step on the frontend, not something to infer from
   a release request.
2. Decide what the tag means here:
   - **restricted** — only that audience sees it: tag it *and* set
     `published: false`, so it stays out of the open feed.
   - **same release, different text** — leave `published: true` and give the tag
     its own `markdown_users` (and `title`/`short` if they differ). The open feed
     keeps the base text; the audience's feed shows the override.
3. **Gate on this explicitly.** Restricting a release is a visibility decision, so
   say plainly which feed each version of the text lands in, and get a yes.
   Show the `published` value — it's the difference between "everyone sees this"
   and "only they do".
4. Pass `audiences: [{audience: "<slug>", markdown_users?, title?, short?}]` in the
   same `create_project_releases` call. Fields you leave out inherit the release's.

Two things to say out loud when this comes up, because they surprise people:
- The restricted feed contains the published releases **too**, not only the
  tagged ones — so the frontend fetches one URL, not two.
- The protection is the unguessable filename on a public bucket, not a login.
  Don't put anything in there that would be a real problem if it leaked.

## `authored_by`

Set it to reflect who really wrote the notes:
- **`ai`** (default) — the skill drafted them and the human only lightly tweaked.
- **`human`** — the human rewrote the notes substantially at the gate.

The model only has `human | ai` today; if a "mixed" (AI-drafted + human-reviewed)
value is wanted, that's a small backend enum change — out of scope for this skill,
mention it as a possible follow-up rather than faking it.

## What this skill does NOT do

- **No discovery** (where i3deploy is wired / a feed of recent releases) — that's a
  separate piece.
- **No update or delete of releases** — for projects, services and both release
  types the MCP only lists, retrieves, and creates. (Audiences are the one
  exception: they can be updated and deleted, since rotating a leaked feed URL
  has to be possible from here.)
- **No curl fallback** — if the MCP isn't connected, set it up (above) and retry.

## Field reference

Exact fields, types, and required-ness for each tool are in
`references/mcp-tools.md`. Read it before composing a `create_*` payload so you
don't guess field names.
