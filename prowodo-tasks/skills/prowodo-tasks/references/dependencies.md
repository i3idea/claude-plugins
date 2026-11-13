# Task dependencies

← [Skill index](../SKILL.md) · See also: [ordering and estimation](ordering-and-estimation.md) · [sprints](sprints.md)

FS/SS/FF/SF constraints between tasks with auto-schedule.

**When needed:** model "X cannot start until Y finishes" (or variants) for
planning/Gantt, or understand what blocks what before telling someone "you can start".

`list/retrieve/create/update/partial_update/destroy_taskdependencies` (path:
`company_id` + `project_id`). Each dependency has a `predecessor`, a `successor`, a
`dependency_type` — **FS** (finish-to-start, default: the successor starts after the
predecessor finishes), **SS** (start-to-start), **FF** (finish-to-finish), **SF**
(start-to-finish) — and `lag_days` (can be negative, shifts the constraint).

Creating/updating a dependency **automatically re-propagates** the successor's planned
dates (auto-schedule) if the new constraint requires it. Rejected with 400 on
self-link, cross-project dependency, ancestor/descendant relationship, or if it creates a
cycle. Deleting a dependency does not move back the dates that were already shifted.

```
create_taskdependencies(company_id=1, project_id=7, body={
  "predecessor": 1200,
  "successor": 1234,
  "dependency_type": "FS",
  "lag_days": 2
})
```

For the dependencies of a **single** task pass `task`: it matches in both directions —
both the dependencies that block it and those that depend on it. Without it, you get the
whole project graph.

```
list_taskdependencies(company_id=1, project_id=7, task=1234)
```
