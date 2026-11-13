# Complete list of ProWoDo MCP tools

← [Skill index](../SKILL.md) · See also: [low-frequency families](collaboration.md)

Table generated from the backend (`grep -oP '^\s{4}"\K[a-z_]+(?=":)' pwd-backend/src/prowodo/core/api/mcp_descriptions.py | sort`) plus `assign_user_tasks` / `unassign_user_tasks`, which carry the description inline via `@mcp_tool(description=...)` instead of in `mcp_descriptions.py` and therefore do not appear in that grep — **92 tools** in total. See `SKILL.md` for bare names vs the real tool prefix (`mcp__plugin_prowodo-tasks_prowodo__...` or equivalent) and for the base flow.

"Path param" lists only the parameters **in addition to** the resource's own id (which for retrieve/update/partial_update/destroy must be passed anyway, typically as `pk`). "—" = no path param besides possibly `pk`.

## Company (workspace)

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_companies` | — | Lists the companies (workspaces) the user is a member of. |
| `retrieve_companies` | — | Detail of a company by id. |
| `create_companies` | — | Creates a new company; the user who creates it becomes its owner. |

## Company members

| Tool | Path param | Purpose |
|------|-----------|---------|
| `retrieve_current_user` | — | Profile of the authenticated user (id, username, display name, email) — resolves "me". |
| `list_users` | `company_id` | Lists the members of a company; supports `search` on email/username/name/display name. |
| `retrieve_users` | `company_id` | Detail of a company member by id. |

## Projects

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_projects` | `company_id` | Lists the projects of a company. Excludes archived ones unless `include_archived=true`. Also filters by `id`, `title__icontains`, `description__icontains`, plus `search`. |
| `retrieve_projects` | `company_id` | Detail of a project by id (including archived ones). |
| `create_projects` | `company_id` | Creates a project in a company. |
| `update_projects` | `company_id` | Full replacement (PUT) of a project — all writable fields required. |
| `partial_update_projects` | `company_id` | Partial update (PATCH) of a project. |
| `destroy_projects` | `company_id` | Archives (soft) the project: `is_archivied=true`, not a physical deletion. |

## Tasks — CRUD

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_tasks` | — | Lists the tasks accessible to the user, with rich filters (`project_id`, `sprint`, `search`, dates, `has_ticket`, `assignee_id`, ...). |
| `retrieve_tasks` | — | Detail of a task by id. |
| `create_tasks` | — | Creates a task; requires `project_id`. |
| `update_tasks` | — | Full replacement (PUT) of a task — also requires `title`. |
| `partial_update_tasks` | — | Partial update (PATCH) of a task (progress, status, story_points, order, ...). |
| `destroy_tasks` | — | Soft-delete of the task; descendants are not automatically re-promoted. |

## Tasks — ordering and hierarchy

| Tool | Path param | Purpose |
|------|-----------|---------|
| `move_up_tasks` | — | Moves the task one position up among its siblings. |
| `move_down_tasks` | — | Moves the task one position down among its siblings. |
| `move_relative_to_tasks` | — | Positions the task right `before`/`after` a sibling (`related_task_id`). |
| `increase_depth_tasks` | — | Indents the task as a child of another (`new_parent_id`). |
| `decrease_depth_tasks` | — | Outdents the task to the parent's level, optionally after `after_task_id`. |
| `reorder_root_tasks` | — | Compacts the `order` of a project's root tasks (`project_id` in the body); maintenance, does not accept lists. |
| `reorder_children_tasks` | — | Compacts the `order` of a task's direct children (parent's id as `pk`). |
| `move_to_project_tasks` | — | Moves the task to another project/company (`project_id` + `company_id` in the body). |
| `move_to_sprint_tasks` | — | Moves one or more tasks (and descendants) to a sprint or to the backlog (`task_ids` + `sprint_id`, null = backlog). |

## User assignment on a task

| Tool | Path param | Purpose |
|------|-----------|---------|
| `assign_user_tasks` | — | Adds a user as an assignee of a task (`pk` + `body.user_id`); idempotent, rejects with 400 if the user is not a member of the task's company. |
| `unassign_user_tasks` | — | Removes a user from a task's assignees (`pk` + `body.user_id`); noop-safe, raises no error if they were not assigned. |

## Tags

| Tool | Path param | Purpose |
|------|-----------|---------|
| `add_tag_tasks` | — | Applies a tag to a task, by `text` (creates the tag if it does not exist) or by `id`. |
| `remove_tag_tasks` | — | Detaches a tag from a task by `id`; no-op if it was not attached. |
| `list_tasktags` | `company_id` | Lists the tags defined in a company. |
| `retrieve_tasktags` | `company_id` | Detail of a tag by id. |
| `create_tasktags` | `company_id` | Creates a tag in the company (`text` field). |
| `update_tasktags` | `company_id` | Full replacement (PUT) of a tag. |
| `partial_update_tasktags` | `company_id` | Renames or partially updates a tag. |
| `destroy_tasktags` | `company_id` | Deletes a tag from the company; tasks that used it lose the association. |

## Task comments

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_taskcomments` | `task_id` | Comment thread of a task. |
| `retrieve_taskcomments` | `task_id` | Detail of a comment by id. |
| `create_taskcomments` | — (**`task_id` goes in the body**, not in the path — an exception compared to the other tools in this family) | Adds a comment; author = authenticated user. `comment_id` optional to reply to an existing comment. |
| `destroy_taskcomments` | `task_id` | Soft-delete (hides) a comment; it is not a physical deletion. |

## Attachments (company/project)

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_attachments` | `company_id` | Lists what is attached to a company or one of its projects (`project_id` to filter, `project_id__isnull=true` for company-only attachments). |
| `retrieve_attachments` | `company_id` | Detail of an attachment: title, `kind` (file/link), author, `url` (signed, expires in 15 minutes for files). |
| `create_attachments` | `company_id` | Creates an attachment: exactly one of `text`, `content_base64` (+`content_type`) or `link`; `project_id` optional (omitted = company attachment); inline content max 4MB. |
| `request_attachment_upload` | body: `company_id`, `project_id?`, `title?` | First step of a two-phase upload for an Attachment: no file in the call, responds with an `upload_url` to be used in a separate multipart POST. |
| `destroy_attachments` | `company_id` | Soft-delete of a company attachment. |

`update_attachments`/`partial_update_attachments` do not exist: an attachment is replaced (delete + recreate), not edited.

## Task attachments

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_taskattachments` | `task_id` | Lists the files attached to a task (name, size, url). |
| `retrieve_taskattachments` | `task_id` | Metadata and download url of a single task attachment. |
| `request_taskattachment_upload` | body: `task_id` | First step of a two-phase upload for a TaskAttachment: no file in the call, responds with an `upload_url` to be used in a separate multipart POST. |

## Reminders

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_reminders` | `task_id` | Lists a task's reminders, ordered by time. |
| `retrieve_reminders` | `task_id` | Detail of a reminder by id. |
| `create_reminders` | `task_id` | Creates a reminder (`remind_at` required, `text`, channels `send_push`/`send_email`/`send_telegram`, `recipient_id` optional = assignees). |
| `update_reminders` | `task_id` | Full replacement (PUT) of a reminder. |
| `partial_update_reminders` | `task_id` | Partial update (PATCH) of a reminder. |
| `destroy_reminders` | `task_id` | Deletes a reminder from the task. |
| `list_all_reminders` | — | Reminders of **all** the user's tasks (e.g. "what fires today"), not scoped to a task. Filters by `remind_at` and `is_sent`. |

## Task dependencies

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_taskdependencies` | `company_id`, `project_id` | Lists the scheduling dependencies of a project. Pass `task` to get only those touching a task, in both directions (what blocks it and what depends on it); without it, the whole graph is returned. |
| `retrieve_taskdependencies` | `company_id`, `project_id` | Detail of a dependency by id. |
| `create_taskdependencies` | `company_id`, `project_id` | Links two tasks of the same project (`dependency_type` FS/SS/FF/SF, `lag_days`); rejected (400) on self-link, cross-project, ancestor/descendant, cycle. |
| `update_taskdependencies` | `company_id`, `project_id` | Full replacement (PUT) of a dependency — requires predecessor, successor, dependency_type, lag_days. |
| `partial_update_taskdependencies` | `company_id`, `project_id` | Changes `dependency_type` or `lag_days`; re-propagates the successor's scheduling. |
| `destroy_taskdependencies` | `company_id`, `project_id` | Removes a dependency; does not move back the dates already shifted forward. |

## Sprints

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_sprints` | — | Lists the sprints of the projects of the user's companies; filters by `state` (PLANNED\|ACTIVE\|CLOSED) and by `project_id` (to narrow to a single project). |
| `retrieve_sprints` | — | Detail of a sprint by id. |
| `create_sprints` | — | Creates a sprint (`project_id` in the body); born in PLANNED state. |
| `update_sprints` | — | Full replacement (PUT) of a sprint. |
| `partial_update_sprints` | — | Partial update (PATCH) of a sprint (name, planned dates, notes); **not** for state transitions. |
| `destroy_sprints` | — | Deletes a sprint; only if PLANNED, otherwise 409 (it must be closed). |
| `start_sprints` | — | PLANNED → ACTIVE transition; fails if another sprint of the project is already ACTIVE. |
| `close_sprints` | — | ACTIVE → CLOSED transition; non-DONE tasks go to `carry_over_to` or return to the backlog if omitted. |

## Sprint board lanes

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_sprint_lanes` | — | Lists the lanes (task → board column) of a sprint. **Always pass `sprint_id`**: without it, it returns the lanes of all sprints of all companies, and the backfill of missing lanes does not run. Also accepts `task_id`. See `references/collaboration.md`. |
| `retrieve_sprint_lanes` | — | Detail of a lane by id. |
| `move_sprint_lanes` | — | Moves a lane to another column (`project_task_status_id`, null = "Incoming" column); cannot be moved on closed sprints. |

## Tickets

| Tool | Path param | Purpose |
|------|-----------|---------|
| `retrieve_ticketsubmissions` | — | Intake metadata of a ticket (submitter, widget, date). The ticket itself is a Task: for detail/triage use the task tools. |
| `list_ticketcomments` | `submission_id` | Comment thread of a ticket, oldest first. |
| `retrieve_ticketcomments` | `submission_id` | Detail of a ticket comment by id. |
| `create_ticketcomments` | `submission_id` | Adds a comment; default `is_internal=true` (team only) — pass `is_internal=false` to make it visible to the customer. |
| `destroy_ticketcomments` | `submission_id` | Soft-delete (hides) a ticket comment. |

## Resume entries (daily plan/done)

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_resumeentries` | `company_id` | Lists the resume entries of a company; filters by `kind` (plan\|done), date range, `user_id`. |
| `retrieve_resumeentries` | `company_id` | Detail of a resume entry by id. |
| `create_resumeentries` | `company_id` | Creates an entry (`kind`, `date_from`/`date_to`, `note`, optional linked `tasks`). |
| `update_resumeentries` | `company_id` | Full replacement (PUT) of an entry. |
| `partial_update_resumeentries` | `company_id` | Partial update (PATCH) of an entry. |
| `destroy_resumeentries` | `company_id` | Soft-delete of an entry. |

## Notes (second brain / knowledge base)

| Tool | Path param | Purpose |
|------|-----------|---------|
| `list_notes` | `company_id` | Lists the notes of a company; filters by `project_id` (and `project_id__isnull=true` for company notes not tied to a project) or `title__icontains`, or `visibility` (`company`/`private`). Review filters: `updated_at__lt|lte|gt|gte`, `created_at__lt|lte|gt|gte` (ISO datetime), `tags__text` (e.g. `inbox`, case-insensitive), `ordering` (`updated_at`, `created_at`, `title`, `-` prefix for reverse; default most recent first). Returns only the notes visible to the user. It does not search the body — use `search_notes` for that. |
| `retrieve_notes` | `company_id` | Detail of a note by id. |
| `create_notes` | `company_id` | Creates a note (`title`, markdown `content`, optional `project_id`, optional `tags` by id, optional `source_task`: id of the task the note was promoted from, same company, optional `visibility`: `company` (default) or `private`, visible only to the author). |
| `update_notes` | `company_id` | Full replacement (PUT) of a note. |
| `partial_update_notes` | `company_id` | Partial update (PATCH) of a note; `visibility` can be changed only by the author. |
| `destroy_notes` | `company_id` | Moves a note to the trash (soft-delete, recoverable with `restore_notes`). There is no permanent deletion via MCP. |
| `trashed_notes` | — (`company_id` in the body) | Notes in the trash that the user can see (their private ones + the shared ones), most recent first, max 100; optional `project_id`. |
| `restore_notes` | `company_id` | Brings a note back from the trash to the active notes (private ones only their author). |
| `history_notes` | `company_id` | Last 50 versions of a note (`history_id`, date, title, content), most recent first. |
| `revert_notes` | `company_id` | Restores the title and content of a version (`history_id` in the body); the revert is a new version. |
| `links_notes` | `company_id` | Outgoing links (`[[wikilink]]`, with `resolved`) and backlinks of a note; only notes visible to the user. |
| `search_notes` | — (`company_id` in the body) | Full-text search on `title`+`content` in a company; optional `project_id` to narrow to a project. Use it instead of `list_notes` when searching by content, not by title/project. It does not return other people's private notes. It searches whole words, not meanings: with few results retry with synonyms and translations. |
| `search_knowledge` | — (`company_id` in the body) | Unified full-text search across tasks (`title`+`description`), task comments and notes; optional `project_id`. Mixed results ordered by relevance: `kind` (`task`\|`task_comment`\|`note`), `id`, `snippet`, `project_id`/`task_id`. Tickets excluded. Default for "where did we talk about it?" ("dove ne abbiamo parlato?"). Whole words, not semantic: with few results retry with synonyms and translations. |

---

For the high-frequency flows (comments, attachments, dependencies, sprints, `list_all_reminders`) with call examples, see the index in [SKILL.md](../SKILL.md). For tickets/resume entries/tag-CRUD/project-CRUD/lanes with examples, see `references/collaboration.md`.

## Rhythm (day and weekly focus)

Eight tools, see [rhythm.md](rhythm.md): `retrieve_current_rhythm`, `today_rhythm`, `set_text_rhythm`, `mark_interpreted_rhythm`, `list_rhythm_items`, `create_rhythm_items`, `partial_update_rhythm_items`, `destroy_rhythm_items`. They are not included in the count in the heading above.

## Guide and news

Two tools, see [help-and-releases.md](help-and-releases.md): `help`, `list_release_notes`. They are not included in the count in the heading above.
