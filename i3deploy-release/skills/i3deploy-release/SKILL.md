---
name: i3deploy-release
description: Create and publish i3deploy releases — ServiceRelease (one service's version + changelog) and ProjectRelease (a project version that bundles service releases, with user-facing and technical changelogs). Use this skill whenever the user wants to cut, publish, draft, or record a release or changelog for an i3idea/i3deploy-tracked project or service — e.g. "nuova release", "rilascia pwd-backend", "pubblica una release di i3school", "crea la project release", "changelog di rilascio", "facciamo una release", "bump version and release", or /i3deploy-release. Trigger even when the user doesn't say "i3deploy" explicitly, as long as they're cutting a release in a repo that has an i3version/deploy.json. Drafts the changelog from git + the current session + memory + ProWoDo tasks, dedups against existing releases, and creates everything through the i3deploy MCP tools after your confirmation.
trigger: /i3deploy-release
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
HTTP):

```
claude mcp add --transport http i3deploy https://i3deploy-back.i3idea.com/mcp/ \
  --header "Authorization: Bearer <KEY>"
```

The `<KEY>` is the org's i3deploy API key. In a wired client repo it's already in
the gitignored `.env.i3deploy` (`I3DEPLOY_API_KEY=...`); read it from there. **One
key = one org** — releases are created in that key's organization (org `i3` covers
pwd / i3school / i3deploy; org `hg` is hoopygang). Tell the user which org you're
about to write to so there's no cross-org surprise.

> **Argument envelope:** i3deploy MCP tools wrap their arguments under a `body`
> key. Always call them as `create_service_releases({"body": {...}})`,
> `list_project_releases({"body": {"project": "pwd"}})`, etc. See
> `references/mcp-tools.md` for the exact field list of every tool.

## Core principles

- **Read before you write (dedup).** Always `list_*` (and `retrieve_*` if needed)
  the existing releases first. `ServiceRelease` is unique per `(service, version)`
  and a `ProjectRelease.version_numeric` shouldn't collide — if the version you'd
  use already exists, don't try to create it; show the latest and propose the next
  semver bump instead. This also gives you the previous release's `commit_sha`,
  which anchors the new git range.
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
   **ProWoDo is the default** (use its MCP tools, e.g. `list_tasks` filtered to the
   project, `is_completed=true`). But don't assume it's the only one: if you don't
   see ProWoDo in use, or the repo/user hints at another tracker (a `.jira`/Jira
   key like `PROJ-123` in commit messages, a Linear/GitHub Issues workflow, an
   Atlassian connector in your session), **ask the user which task manager they
   use** and pull completed/related items from there instead (e.g. the Atlassian
   tools for Jira). Tasks are the canonical "what we set out to do"; reference or
   summarize them. If no task manager is available, just skip this source — git +
   session + memory still give a solid draft.

Synthesize, don't dump: a changelog is a curated story, not a commit log paste.

## Step 2 — ServiceRelease (run from inside the service's repo)

1. Read `i3version/deploy.json` in the repo root → `service`, `base_url`, and the
   env. The org comes from the connector's key.
2. `list_service_releases({"body": {}})` → it returns the org's service releases
   (no server-side filter in phase 1), so **filter the result by your `service`
   slug client-side**, then take the highest `version` to find the latest and its
   `commit_sha`. (Dedup + range anchor.)
3. Build `commit_range` (`<latest sha>..HEAD`) and gather the four sources
   (Step 1). Draft `changelog_markdown` (technical, markdown) and a one-line
   `short_summary`.
4. **Gate:** present `latest → proposed` version with the bump rationale; let the
   user adjust the version and edit the notes. Refuse a version that already
   exists.
5. Show the final payload, get a yes, then create:
   `create_service_releases({"body": {service, version, commit_sha, commit_range, changelog_markdown, short_summary, authored_by}})`.

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
4. `list_project_releases({"body": {}})` (filter the result by your `project` slug
   client-side) for dedup → **gate** on
   `version_numeric` (bump) and on the user-vs-technical split (this split is the
   whole point of a ProjectRelease — get the human's sign-off on it).
5. Show the final payload, confirm, then create:
   `create_project_releases({"body": {project, title, short, markdown_users, markdown_techies, version_numeric, authored_by, service_releases: [{service, version}, ...]}})`.

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
- **No update or delete** — the phase-1 MCP only lists, retrieves, and creates.
- **No curl fallback** — if the MCP isn't connected, set it up (above) and retry.

## Field reference

Exact fields, types, and required-ness for each tool are in
`references/mcp-tools.md`. Read it before composing a `create_*` payload so you
don't guess field names.
