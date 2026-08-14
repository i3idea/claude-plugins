# Community marketplace — submission dossier

Testo pronto da incollare nel form Console: **platform.claude.com/plugins/submit**
(la via per autori individuali; il form su claude.ai richiede un'org Team/Enterprise).

Sono **due submission separate**, una per plugin.

Prima di mandare, rilancia:

```bash
claude plugin validate ./prowodo-tasks --strict
claude plugin validate ./i3deploy-release --strict
```

Il pipeline di review esegue lo stesso controllo più uno screening di sicurezza
automatico. Assicurati che `master` sia pushato: l'approvazione pinna uno **SHA**
specifico, e la CI poi avanza il pin da sola sui commit successivi.

---

## Submission 1 — `prowodo-tasks`

**Plugin name (slug, immutabile):** `prowodo-tasks`
**Repository:** https://github.com/i3idea/claude-plugins
**Path nel repo:** `./prowodo-tasks`
**Marketplace di origine:** `i3idea` (`.claude-plugin/marketplace.json`)
**Category:** productivity
**License:** MIT
**Homepage:** https://prowodo.com
**Author / contatto:** i3idea — hello@prowodo.com
**Versione al momento della submission:** 0.5.2

### One-liner

Manage ProWoDo tasks, backlog, sprints, reminders and Daily Resumes from Claude
Code — in any language, without leaving the terminal.

### Description

ProWoDo is a project and task management app. This plugin lets Claude Code work
against it directly: you talk about your work in plain language and Claude keeps
the backlog in sync.

The skill auto-triggers on task/planning/sprint mentions (Italian, English, or
mixed) and routes everything through the ProWoDo MCP server, which **ships with
the plugin** — after `/plugin install` the user runs `/mcp`, completes a browser
login, and is done.

What it adds beyond raw MCP access:

- Recognises task/planning intent in any language, so there is no command to remember
- Encodes the idiomatic call sequences (closing a task sets `is_completed`,
  `progress` and `status` together, because the backend treats them as one invariant)
- Remembers per-directory defaults (company / project / Scrum on-off) so you
  don't restate them every session
- Encodes verified API gotchas — the 4096-char description cap, the fact that
  `order` is renormalised on every write, mass-tagging race conditions — so
  Claude doesn't rediscover them by failing

### Authentication and data

- Bundled MCP server: `https://mcp.prowodo.com/mcp/` (HTTP transport)
- **OAuth 2.0 with Dynamic Client Registration + PKCE.** No API key or secret is
  ever written to the user's config: the plugin ships only the server URL.
- An unauthenticated server exposes **no tools**, so a user who installs but never
  logs in gets an inert plugin rather than an error state.
- Data flows only between the user's Claude Code session and their own ProWoDo
  account. The plugin adds no telemetry, no analytics, no third-party endpoint.
- The plugin runs **no local executables**: no `bin/`, no hooks, no scripts. It is
  a skill (Markdown) plus one MCP server declaration.

### Prerequisites

A ProWoDo account (free Early Access during beta — https://prowodo.com). The
plugin is useless without one, and says so in its README.

### Testing

```
/plugin marketplace add i3idea/claude-plugins
/plugin install prowodo-tasks@i3idea
/mcp          # pick "prowodo", complete the browser login
```

Then say "what's in my backlog?" or "add a task: fix login bug, 3 SP".

---

## Submission 2 — `i3deploy-release`

**Plugin name (slug, immutabile):** `i3deploy-release`
**Repository:** https://github.com/i3idea/claude-plugins
**Path nel repo:** `./i3deploy-release`
**Marketplace di origine:** `i3idea` (`.claude-plugin/marketplace.json`)
**Category:** development
**License:** MIT
**Homepage:** https://i3deploy.com
**Author / contatto:** i3deploy — hello@i3deploy.com
**Versione al momento della submission:** 0.5.0

### One-liner

Cut i3deploy releases from Claude Code — drafts the changelog from your actual
work, dedups against what's already published, and writes it only after you say yes.

### Description

i3deploy tracks deploys and releases. This plugin turns "facciamo una release"
into a finished, reviewed changelog.

It handles two record types: a **ServiceRelease** (one service at one version,
with the technical changelog and the git commit range it covers) and a
**ProjectRelease** (a product version that bundles service releases and carries
user-facing and technical notes separately).

What it does that a raw MCP call doesn't:

- **Drafts from four sources at once** — the git range since the last release, the
  current Claude Code session, memory, and whichever task manager the user has
  (ProWoDo, Jira/Atlassian, Linear, GitHub Issues — it detects, and asks rather
  than guessing when ambiguous). The commit log alone tells you *what* changed;
  the others tell you *why it mattered*.
- **Reads before writing.** It lists existing releases, refuses a version that
  already exists, and proposes the next semver bump with the reasoning shown
  (feat → minor, fix → patch, breaking → major) so a human can correct it in one word.
- **Separates the two audiences** — user-facing vs technical notes — and gates on
  that split, because it's the part a human should own.
- **Never writes silently.** Every `create_*` is preceded by the full payload and
  an explicit confirmation.
- Optionally targets a release at a named **audience** (beta testers, staff) with
  its own changelog text and its own feed.

**Standalone:** it needs an i3deploy account and nothing else — no ProWoDo, no
other i3idea product.

### Authentication and data

- Bundled MCP server: `https://mcp.i3deploy.com/mcp/` (HTTP transport)
- **OAuth 2.0 with Dynamic Client Registration + PKCE.** The plugin ships only the
  server URL; no key or secret is written to the user's config. An org API key
  remains supported for CI and shared machines, but is never required and never
  bundled.
- Data flows only between the user's session and their own i3deploy organization.
  No telemetry, no analytics, no third-party endpoint.
- The plugin runs **no local executables**: no `bin/`, no hooks, no scripts —
  a skill plus one MCP server declaration. It reads the repo's
  `i3version/deploy.json` and local git history to draft notes.
- One security note the skill itself enforces: an audience feed URL is a
  credential (a world-readable bucket path protected only by an unguessable
  filename). The skill tells the user to treat it like a password and never to
  paste it into a ticket or a public channel.

### Prerequisites

An i3deploy account and organization (https://i3deploy.com), plus a repo
containing `i3version/deploy.json` for the service-release flow.

### Testing

```
/plugin marketplace add i3idea/claude-plugins
/plugin install i3deploy-release@i3idea
/mcp          # pick "i3deploy", complete the browser login
```

From inside a tracked service repo, say "nuova release": the skill reads the
service from `i3version/deploy.json`, drafts the changelog, shows the proposed
version bump, and waits for confirmation before writing anything.

---

## Note sui campi

Non conosco il layout esatto del form Console, quindi il dossier è organizzato per
argomento invece che campo per campo. Le sezioni **Authentication and data** e
**Prerequisites** sono quelle che nessun form del genere omette e che l'automated
safety screening guarda per prime: teniamole anche se il form non le chiede
esplicitamente, incollandole nel campo descrizione lungo.
