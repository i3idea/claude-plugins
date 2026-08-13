# i3deploy MCP tools — field reference (phase 1)

Endpoint: `POST https://mcp.i3deploy.com/mcp/` (Streamable HTTP).
Auth: OAuth 2.0 (Dynamic Client Registration + PKCE) — what the plugin-bundled
server uses — or `Authorization: Bearer <org key>`. Either way you never pass an
org/company argument: with a key the organization is implied by the key, with
OAuth it comes from your account's memberships (see the org notes in `SKILL.md`).

**Every tool wraps its arguments under a `body` key.** Example:
`create_service_releases({"body": { ... }})`.

There are 15 tools: `{list,retrieve,create}` × `{projects, service_releases,
project_releases}`, plus `{list,create}_services`, plus
`{list,create,update,destroy}_release_audiences`. The four you need for releases
are documented below; the project/service create+list tools are summarized at the
end, and audiences have their own section.

## Important: list tools are PAGINATED — always filter server-side

The `list_*` tools return a **paginated object**, not a bare array:
`{"count": N, "page_size": 25, "max_page_size": 100, "pages": P, "links": {...}, "results": [ ... ]}`.
**Read the rows from `.results`** (in both `structuredContent` and the parsed
`content[0].text`).

**Never scan `.results` client-side to find a service's releases.** The default
page holds 25 rows out of hundreds, so a client-side scan of page 1 usually finds
nothing for your service — and "nothing" is exactly what the skill reads as *this
is the first release, propose `0.1.0`*. That failure mode is silent and it has
happened. Filter on the server instead:

| tool | filters |
|---|---|
| `list_service_releases` | `service`, `project`, `version`, `include_stubs` |
| `list_project_releases` | `project`, `version_numeric`, `published` |
| `list_release_audiences` | `project`, `slug`, `is_active` |
| `list_services` | `project`, `slug` |
| `list_projects` | `slug` |

Every list tool also takes `page`, `page_size` (max 100) and `organization`. So the
right call is `{"body": {"service": "pwd-backend", "page_size": 100}}`, not a bare
`{"body": {}}` followed by filtering.

### `version` is free text — never sort it yourself

Rows are returned newest-version-first, so **the latest release is `.results[0]`**.
Do not rank them client-side: `version` is a `CharField`, not a semver type. A
deploy auto-creates a `ServiceRelease` for whatever version it reports, and with no
tag in the repo `git describe --tags --always` reports a bare commit sha — compared
as strings, `9323285` sorts above `1.0.0`. That is how "the latest release of
`pwd-site`" once came back as a July commit instead of the August `1.0.0`.

Those deploy-created rows are flagged `is_deploy_stub` and **excluded by default**
(they carry an empty changelog). Pass `include_stubs: true` only when you actually
want deploy bookkeeping. So an empty filtered result really does mean "no release
yet" — a stub can no longer masquerade as one.

### `count` depends on how you are connected

The connector is an OAuth user and sees **every organization you belong to**; an API
key is bound to exactly one. The same query can therefore report a different `count`
over MCP than over REST, with neither being wrong. Pass `organization: "<slug>"` to
pin one.

**Only after a filtered call comes back empty is it the first release** (propose
`0.1.0`/`1.0.0`). Check `count` and `pages` in the response to be sure you have
everything; the `links.next`/`links.previous` URLs are not usable over MCP (they
are built from the MCP endpoint's host) — page with `page` instead.

`retrieve_*` look up a single row by its id:
- `retrieve_service_releases` → `{"body": {"id": <pk>}}`
- `retrieve_project_releases` → `{"body": {"version_uuid": "<uuid>"}}`
- `retrieve_projects` → `{"body": {"slug": "<slug>"}}`

## create_service_releases

`create_service_releases({"body": { ... }})`

| field | type | required | notes |
|---|---|---|---|
| `service` | string (slug) | yes | service slug, must exist in the org |
| `version` | string | yes | semver, e.g. `2.3.0` (unique per service — dedup!) |
| `commit_sha` | string | yes | the released commit (`HEAD`) |
| `commit_range` | string | no | e.g. `abc1234..def5678` |
| `changelog_markdown` | string (markdown) | no | **technical** changelog |
| `markdown_users` | string (markdown) | no | **user-facing** notes (mirrors ProjectRelease.markdown_users) |
| `short_summary` | string | no | one line, ≤256 chars |
| `authored_by` | `"human"` \| `"ai"` | no | default `human`; set `ai` when drafted by the skill |

> A ServiceRelease now carries BOTH audiences, like a ProjectRelease:
> `changelog_markdown` (technical) and `markdown_users` (user-facing). Draft both
> when the change is user-visible; technical-only changes can leave `markdown_users` empty.

Returns the created service release. `version_major/minor/patch` are derived from
`version` server-side (don't send them).

## create_project_releases

`create_project_releases({"body": { ... }})`

| field | type | required | notes |
|---|---|---|---|
| `project` | string (slug) | yes | project slug, must exist in the org |
| `title` | string | yes | release title, ≤256 chars |
| `short` | string | no | short blurb, ≤512 chars |
| `markdown_users` | string (markdown) | no | **user-facing** notes |
| `markdown_techies` | string (markdown) | no | **technical** notes |
| `version_numeric` | string | yes | semver, e.g. `2.3.0` (**unique per project** — dedup!) |
| `authored_by` | `"human"` \| `"ai"` | no | default `human` |
| `service_releases` | array of `{service, version}` | no | the ServiceReleases this bundles; each must already exist in the org |
| `audiences` | array of `{audience, title?, short?, markdown_users?}` | no | tags the release for those audiences (see below); `audience` is the audience slug, and it must belong to **this** project |
| `published` | bool | no | default `true`; `false` keeps it out of the open public feed |

Returns the created project release (with `version_uuid` and derived
`version_major/minor/patch`). The nested `service_releases` are resolved by
`(service slug, version)` within the org — referencing a release from another org
fails (by design).

Reusing a `version_numeric` inside the same project is a **400**, not a duplicate:
`{"non_field_errors": ["This project already has a release with this
version_numeric. A project version names exactly one release — bump the version
instead of reusing it."]}`. The reason it is enforced rather than merely
discouraged: the public feed exposes `version` and **no uuid**, so the version is
the only identifier a consumer has — two releases sharing one makes every
version-keyed changelog ambiguous. (It happened twice in production before the
constraint existed.) Same version in a *different* project is fine.

The nested `audiences` follow the same replace semantics as `service_releases`:
passing the key **replaces** the release's whole set of tags, omitting it leaves
the existing ones untouched, and `[]` clears them. Each text field left empty
inherits the release's own — so tagging without rewriting anything is the cheap
default.

## list_service_releases / list_project_releases

`list_service_releases({"body": {}})` → array of service releases in the org
(filter client-side by `service`).
`list_project_releases({"body": {}})` → array of project releases in the org
(filter client-side by `project`).

Each item carries `version` / `version_numeric`, `created_at`, and (for service
releases) `commit_sha` — which you use to anchor the next `commit_range`.

## Audiences — `{list,create,update,destroy}_release_audiences`

An **Audience** is a named public for a project's releases (`beta`, `staff`,
`enterprise`). The vocabulary is **per project**: the same slug can exist in
several projects and they are different audiences.

Each active audience owns its own feed on the public bucket, at a path whose
filename embeds a secret `feed_key`. That feed carries the project's published
releases **plus** the releases tagged for that audience — including unpublished
ones — each rendered with its per-audience text when one was written. So a
frontend does a single fetch and gets "the public stuff plus mine".

| field | type | required | notes |
|---|---|---|---|
| `project` | string (slug) | yes on create | **create-only** — an update never moves an audience to another project |
| `slug` | string | yes on create | unique per project, e.g. `beta` |
| `name` | string | yes on create | human label, e.g. "Beta tester" |
| `is_active` | bool | no | default `true`; `false` stops the feed file being written (and deletes the existing one) |
| `feed_url` | string | read-only | the URL to paste into the customer's frontend |
| `rotate_feed_key` | bool | write-only, update only | `true` → new secret URL; the previous one stops working |

`update_release_audiences` and `destroy_release_audiences` take the audience's
`id`: `{"body": {"id": <pk>, ...}}`.

> **`feed_url` is a credential, not a link.** The feed sits on a world-readable
> bucket and the only thing protecting it is that its filename is unguessable.
> Treat the URL like a password: hand it to the user, don't paste it into a
> ticket, a commit message or a public channel. Never put in a restricted feed
> anything that would be a real problem if it leaked — the use case is the
> early changelog, not the industrial secret. Rotation revokes from that moment
> on, never retroactively.

Typical use from this skill: the user asks for a release "solo per i beta
tester", or "uguale ma con una nota in più per lo staff". Read the project's
audiences with `list_release_audiences`, then pass `audiences` to
`create_project_releases`. Creating a *new* audience is a rarer, deliberate act —
confirm the slug and name with the user first, and tell them the resulting
`feed_url` has to be configured in their frontend before the feed is of any use.

## Supporting tools

- `list_projects({"body": {}})` / `retrieve_projects({"body": {"slug": ...}})` —
  projects (with their active services).
- `list_services({"body": {}})` — services in the org (each has `project`, `slug`,
  `valid_envs`).
- `create_projects({"body": {slug, title, description, organization?}})` — create a
  project (rare; usually projects already exist). `organization` (slug) is optional:
  omit it for an API key or a single-org OAuth user (resolved automatically);
  **required** for a multi-org OAuth user (it's the one tool with no parent to imply
  the org). Passing an org you don't belong to → 403.
- `create_services({"body": {slug, project, display_name, repo_url, valid_envs}})` —
  create a service (rare). Org is implied by `project`.

If a project or service doesn't exist yet, create it first, then the releases.

## Organization resolution

You never pass an org on the release tools — it's resolved from the principal:
- **API key** → the key's single org.
- **OAuth** → your `OrganizationMembership`(s). Single membership → that org;
  multiple → `list_*` span them all (filter client-side by slug) and the org is
  inferred from the `project`/`service` slug. Bundled `service_releases` in a
  `create_project_releases` call **must belong to the same org as the project**
  (cross-org bundling is rejected).
