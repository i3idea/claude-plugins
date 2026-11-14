# Low-frequency families

← [Skill index](../SKILL.md) · See also: [full tools](tools.md) · [sprints](sprints.md) · [comments](comments.md)

These tool families are used less often than the base task/sprint flow — that is why
they are here and not in `SKILL.md`: there is no need to load them in every session. For
the complete list of all tools with path params and purpose, see [tools.md](tools.md). For
bare names vs the real prefix of the MCP tool, see [SKILL.md](../SKILL.md).

## Tickets

**When needed:** the user asks to read/manage customer tickets (support widget
on the website), or to reply to whoever opened a ticket. A ticket **is a Task** with a linked
`TicketSubmission` — for triage, status, assignment use the normal task tools
(`list_tasks` with `has_ticket=true`, `partial_update_tasks`, `assign_user_tasks`); this
family covers only intake and the ticket-specific comments.

- `retrieve_ticketsubmissions` — opening metadata: who opened the ticket
  (submitter), from which widget, when. It does **not** contain the ticket's status/assignee/text:
  those are on the linked Task (`retrieve_tasks`).
- `list_ticketcomments` / `retrieve_ticketcomments` — thread of comments on the ticket
  (path: `submission_id`), oldest first.
- `create_ticketcomments` — adds a comment (path: `submission_id`). **The `is_internal`
  flag decides who sees it:** default `true` (internal note, team only, the
  customer never sees it); `is_internal=false` makes it visible on the ticket's public
  page. **Write as internal by default and make public only on purpose** —
  it is the opposite direction of error that matters: an internal note that leaks out
  as public exposes details not meant for the customer.
- `destroy_ticketcomments` — soft-delete (hides) a comment, not a physical deletion.

**The two links, not to be confused** (see also "Platform links" in [SKILL.md](../SKILL.md#platform-links)):
`app_url` on ticket submissions/comments is INTERNAL (the task drawer within the team); `public_url`
on `retrieve_ticketsubmissions` is PUBLIC, the page seen by whoever opened the ticket.
Never give `app_url` to the customer.

Example — replying publicly to a ticket:
```
retrieve_ticketsubmissions(pk=88)
  → {..., "public_url": "https://app.prowodo.com/t/9c2e..."}
create_ticketcomments(submission_id=88, body={
  "text": "Resolved: we have published the fix to production.",
  "is_internal": false
})
```
Afterwards, if needed, share `public_url` with the customer — never `app_url`.

## Resume entries (daily plan/done)

**When needed:** asynchronous stand-ups, "what did/are my colleagues planning
today", or to record yourself what you planned/did on a day or over a
range — separate from the actual tasks, it is a summary note optionally
linked to one or more tasks.

- `list_resumeentries` (path: `company_id`) — filter by `kind` (`plan`|`done`), range
  `date_from`/`date_to`, `user_id`.
- `retrieve_resumeentries` — detail by id.
- `create_resumeentries` — `kind`, `date_from`/`date_to`, `note` (free text), `tasks`
  optional (list of linked ids). Multiple entries on the same day are allowed.
- `update_resumeentries` / `partial_update_resumeentries` — full or
  partial replacement.
- `destroy_resumeentries` — soft-delete.

Example — recording what was done today:
```
create_resumeentries(company_id=1, body={
  "kind": "done",
  "date_from": "2026-08-05",
  "date_to": "2026-08-05",
  "note": "Closed the attachments fix, started the spike on Telegram reminders.",
  "tasks": [1234, 1240]
})
```

## Tag CRUD beyond add_tag / remove_tag

`add_tag_tasks` / `remove_tag_tasks` (in `SKILL.md`) attach/detach an **existing**
tag to/from a task. This family manages the tags themselves as entities of the
company — needed when the user wants to **create, rename or delete** a tag (not
just apply it), typically when setting up a project or cleaning up the backlog.

- `list_tasktags` / `retrieve_tasktags` (path: `company_id`) — list/detail of the tags
  defined in the company.
- `create_tasktags` — creates a tag (`text`); from then on it is available for
  `add_tag_tasks`. Note: `add_tag_tasks` can create it on the fly by passing `text` instead of
  `id` — use an explicit `create_tasktags` only if you want the tag ready before tagging, or
  if you are creating it without attaching it to anything yet.
- `update_tasktags` / `partial_update_tasktags` — renames or updates an existing tag;
  the change is reflected on all the tasks that use it (it is the same record).
- `destroy_tasktags` — deletes the tag from the company; tasks that had it lose
  the association (they are not otherwise touched).

Example — renaming a tag:
```
list_tasktags(company_id=1)
  → [{id: 12, text: "gtm"}, ...]
partial_update_tasktags(company_id=1, pk=12, body={"text": "go-to-market"})
```

## Project CRUD

`create_projects` / `update_projects` / `partial_update_projects` / `destroy_projects`
(path: `company_id`) — full CRUD on the projects themselves, not on the tasks inside
them. Use them when the user wants to **create a new project**, rename it, or
archive it — a rare flow compared to the daily work on tasks, but direct: no
half-way soft-delete, `destroy_projects` archives (`is_archivied=true`), it does not delete.

See also the section on the `is_archivied` field (sic) in [gotchas.md](gotchas.md) — it also applies to
projects created/modified with these tools: always check `is_archivied: false` before
suggesting them as a destination.

Example — creating a project:
```
create_projects(company_id=1, body={
  "title": "Marketing site redesign",
  "description": "Landing + blog rebuild"
})
```

## Sprint board lanes

**When needed:** the user asks about the **kanban board of the active sprint** (columns
like "To do / In progress / Done") and not just "what tasks are in the sprint" — the
task list (`list_tasks(sprint=<id>)`) does not say which column a task is in, the lanes
do.

- `list_sprint_lanes` — **always pass `sprint_id`.** Without it, the call returns the
  lanes of *all* sprints of *all* the user's companies, and you end up
  looking at different boards mixed together believing you are seeing one. With `sprint_id` the
  backfill of the missing lanes also kicks in for tasks already in the sprint (legacy data
  that entered before lanes existed), so the result is complete — without the filter that
  backfill does not run and rows are missing. It also accepts `task_id` to isolate a single
  lane.
- `retrieve_sprint_lanes` — detail of a lane by id: which task, which column.
- `move_sprint_lanes` — moves a lane to another column
  (`project_task_status_id`, the id of the target column — it must belong to the project
  of the lane's sprint); `null` parks it in the synthetic "Incoming" column.
  It does not work on closed sprints.

Example — moving a task to "In progress" on the board (sprint 44):
```
list_sprint_lanes(sprint_id=44)
  → [{id: 501, sprint_id: 44, task_id: 1234, project_task_status_id: null}, ...]
move_sprint_lanes(pk=501, body={"project_task_status_id": 7})
```
