# Sprint / Scrum

← [Skill index](../SKILL.md) · See also: [estimates](ordering-and-estimation.md) · [board lanes](collaboration.md) · [project defaults](project-defaults.md)

Optional Scrum flow: sprint CRUD, lifecycle, moving tasks.

Not all projects follow Scrum. The mode is a **per-project preference**, recorded in memory (`uses_scrum: true|false`). When it is active, these additional flows apply:

- **Sprint planning**: before the sprint starts, list the backlog tasks (`list_tasks` with `sprint__isnull=true`), help estimate them with `story_points`, then move them into the sprint with `move_to_sprint_tasks`.
- **During the sprint**: `list_tasks` with `sprint=<id>` shows the content of the active sprint.
- **Closing**: at the end of the sprint the non-DONE tasks can be carried over to the next sprint or returned to the backlog.

When the user does NOT use Scrum (or has not indicated it in memory) **never mention** sprint/grooming/velocity proactively: stay on the base workflow (backlog, priority, order).

**Sprint CRUD** — no path param (the sprint is scoped to the user's companies via
query, not via URL):

- `list_sprints` / `retrieve_sprints` — filter by `state` (`PLANNED`|`ACTIVE`|`CLOSED`) and by `project_id`; use `list_sprints(state="ACTIVE", project_id=<id>)` to find the active sprint *of a specific project* — without `project_id` the search covers the sprints of all the projects of the user's companies.
- `create_sprints` — `project_id` in the body (not in the path), `name`, `start_date`/`end_date`. It is always born as `PLANNED`.
- `update_sprints` / `partial_update_sprints` — name, dates, notes; **not** to change state (see "Lifecycle" below).
- `destroy_sprints` — only if `PLANNED`; on an ACTIVE/CLOSED sprint it returns 409, it must be closed instead of deleted.

**Lifecycle — dedicated tools, not `partial_update_sprints`:**

- `start_sprints` (pk = sprint) — `PLANNED → ACTIVE`. Fails if another sprint of the
  same project is already ACTIVE: **only one active sprint per project**.
- `close_sprints` (pk = sprint) — `ACTIVE → CLOSED`. The non-DONE tasks go to
  `carry_over_to` (id of the next sprint) if passed, otherwise they return to the
  product backlog (`sprint=null`).

```
create_sprints(body={"project_id": 7, "name": "Sprint 12", "start_date": "2026-08-10", "end_date": "2026-08-21"})
start_sprints(pk=44)
...
close_sprints(pk=44, body={"carry_over_to": 45})
```

**Moving tasks in/out of a sprint** — `move_to_sprint_tasks` (no path param):
`task_ids` (non-empty list, all in the same project) + `sprint_id` (`null` =
backlog). It also moves the descendants of the tasks passed. Rejected on closed sprints.

```
move_to_sprint_tasks(body={"task_ids": [1234, 1235], "sprint_id": 44})
```

For the **sprint kanban board** (columns, not just "which tasks are there") — the
lanes — see [collaboration.md](collaboration.md): it is a low-frequency family, it is not
here.
