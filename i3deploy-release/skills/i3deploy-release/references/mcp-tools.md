# i3deploy MCP tools — field reference (phase 1)

Endpoint: `POST https://mcp.i3deploy.com/mcp/` (Streamable HTTP).
Auth: `Authorization: Bearer <org key>`. The organization is implied by the key —
you never pass an org/company argument.

**Every tool wraps its arguments under a `body` key.** Example:
`create_service_releases({"body": { ... }})`.

There are 11 tools: `{list,retrieve,create}` × `{projects, service_releases,
project_releases}` plus `{list,create}_services`. The four you need for releases
are documented below; the project/service create+list tools are summarized at the
end.

## Important: list tools are PAGINATED + org-wide (no server-side filter yet)

The `list_*` tools return a **paginated object**, not a bare array:
`{"count": N, "page_size": 25, "max_page_size": 100, "pages": P, "links": {...}, "results": [ ... ]}`.
**Read the rows from `.results`** (in both `structuredContent` and the parsed
`content[0].text`). Use `?page` / `?page_size` (max 100) if you need more than the
first page — pass them in the `body`, e.g. `{"body": {"page_size": 100}}`.

There is no `service`/`project` body filter yet, so to find "the latest release of
service X", read `.results`, **filter client-side** by the `service`/`project`
slug, then pick the highest `version` / `version_numeric`. **If `.results` is empty
for that service/project → it's the first release** (propose `0.1.0`/`1.0.0`).
(The REST `?project=` query param exists for `project-releases` but isn't exposed
through MCP in phase 1.)

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
| `version_numeric` | string | yes | semver, e.g. `2.3.0` |
| `authored_by` | `"human"` \| `"ai"` | no | default `human` |
| `service_releases` | array of `{service, version}` | no | the ServiceReleases this bundles; each must already exist in the org |

Returns the created project release (with `version_uuid` and derived
`version_major/minor/patch`). The nested `service_releases` are resolved by
`(service slug, version)` within the org — referencing a release from another org
fails (by design).

## list_service_releases / list_project_releases

`list_service_releases({"body": {}})` → array of service releases in the org
(filter client-side by `service`).
`list_project_releases({"body": {}})` → array of project releases in the org
(filter client-side by `project`).

Each item carries `version` / `version_numeric`, `created_at`, and (for service
releases) `commit_sha` — which you use to anchor the next `commit_range`.

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
