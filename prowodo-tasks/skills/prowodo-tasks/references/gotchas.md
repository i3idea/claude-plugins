# Technical API gotchas

← [Skill index](../SKILL.md) · See also: [reordering](ordering-and-estimation.md) · [project defaults](project-defaults.md) · [full tools](tools.md)

Things not obvious from the MCP tool descriptions, verified on the backend.

Things that are NOT obvious from the MCP tool descriptions and cost you time if you discover them on the spot:

## `partial_update_tasks` requires `title` in the body even for partial updates

The MCP schema marks `title` as required in the body even if you are only changing `order`, `progress`, `is_completed`, or a tag. If you omit `title`, you get a 400. Workaround: always pass the original title (you can read it beforehand with `retrieve_tasks` if you do not have it cached, or pass it as a parameter if you already have it).

## `description` is capped at 4096 characters

The API rejects longer descriptions with `400 {"description": ["Ensure this field has no more than 4096 characters."]}`. If you need to narrate more, link to external specs/plans or use comments on the task (separate). Split sections while keeping the essential anchors.

## Orphan tags from other companies cannot be removed

Sometimes a task has a tag with a `company` different from the current one (leftover from past refactors or an assignment error). `remove_tag_tasks` rejects with `"tag not in this company"`. Workaround: leave it, do not block the flow, optionally add the correct tags of the current company on top. Report it to the user as "orphan tag to clean up eventually on the admin side".

## `list_tasks` with `depth=0` and `page_size=100` produces an 80KB+ response

On projects with 50+ root tasks, the response exceeds the MCP token limit and is saved to a temporary file. To analyze it effectively, use `jq` via Bash:

```bash
jq -r '.results | sort_by(.order) | .[] | "\(.order)\t#\(.id)\tsp=\(.story_points // "-")\t\(.title[0:60])"' <file>
```

For interactive use (showing tasks to the user), filter better: `is_completed=false`, `depth=0`, `sprint__isnull=true`, `page_size=25` instead of 100, and explicit pagination.

## Mass tagging / mass reorder: parallel batches OK but with caveats

Writes (`add_tag_tasks`, `partial_update_tasks`) are safe in parallel on your side — the backend transaction is atomic per call. BUT: every `partial_update_tasks` renormalizes the orders of the level → race condition on the final order if you send 50 updates in parallel. If the relative order matters (reordering), serialize. If instead you are only tagging (no order change), go ahead and parallelize.

## Verified closing pattern

To close a non-trivial task (feature implemented, decision made):

1. `partial_update_tasks`: `is_completed: true, progress: 100, status: "DONE", title: <original>`
2. Update the description with a short ✅ Done summary at the top (≤4096 chars): what was done, main commit SHAs, links to spec/plan, any non-MVP follow-ups explicitly out of scope.
3. User memory: if the work unlocked reusable patterns, write a memory of type=`reference` or `feedback` linked to the task ID.

---

## Archived projects: the `is_archivied` field (sic) — verified 2026-05-25

The field is `is_archivied` (backend typo, not `is_archived`).

**`list_projects` filters out archived projects by default** — so if they do not show up in the list it *might* be because they are archived, not because they do not exist. Always confirm with `retrieve_projects(pk=<id>, company_id=<cid>)` when an expected ID does not appear in the list.

**`retrieve_projects` instead also returns archived ones** — useful for inspection, dangerous if you do not check the `is_archivied` field before writing tasks into it.

**`create_tasks` does NOT validate `is_archivied`**: you can create a task in an archived project with no backend error (verified — task #1455 created in the archived Higher Level (5) without a warning).

**Operating rules:**
- When you save a **default in memory** or are about to write to a project known only by ID (e.g. from `prowodo_defaults.md`), do a quick `retrieve_projects` and verify `is_archivied: false`. Defaults in memory age — a project that was active yesterday may be archived today.
- If a default turns out to be archived, **warn the user** and ask for an active alternative (usually the team has consolidated the work elsewhere). Update the memory.
- If the user cites a project by name that does not appear in `list_projects`, do a `retrieve_projects` by id (if you know it) or report "not found among the active ones, it might be archived".

## `move_to_project_tasks`: how to use it

To move a task to another project (even of another company) call `move_to_project_tasks` with `pk=<task_id>` and `body={"project_id": <target_project_id>, "company_id": <target_company_id>}`. The MCP schema accepts both fields in the body — the task keeps its ID and moves to the new project/company. There is no need to recreate it or delete the original.
