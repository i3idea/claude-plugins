---
name: prowodo-tasks
description: Use whenever the user mentions tasks, planning, todo, backlog, sprint, story points, scrum, grooming, planning poker, or asks to log/create/manage/plan/review tasks. ProWoDo is the single source of truth for task management and planning. Trigger on "segna", "crea task", "aggiungi task", "traccia", "todo", "cose da fare", "pianifica", "backlog", "sprint", "story point", "stima", "scrum", "cosa c'è da fare", "cosa devo fare", "dimmi i task", "mostrami i task", "check tasks", "what do I need to do", or equivalents in any language. Also on reminders ("reminder", "promemoria", "ricordami", "avvisami", "remind me", "scadenza") and on notes / second brain / knowledge base ("nota", "appunti", "second brain", "knowledge base", "salva questa decisione", "segnati che", "dove ne abbiamo parlato", "cosa sappiamo su", "what do we know about", "save this as a note"). Also proactively at the end of a working session, to suggest logging completed or upcoming work.
---

# ProWoDo — Task Management & Planning

ProWoDo is the central system for tasks, planning and backlog. **Always** use it to:
- Create tasks to do
- See what is in the backlog
- Plan the work (sprints, priorities, order)
- Mark tasks as completed or in progress
- Organize work by project
- Track progress (progress %)

## The MCP tools: names and prefix

This skill refers to tools by their **bare name** (`list_tasks`, `create_tasks`, ...). The
real prefix **depends on how the ProWoDo server is connected** and is not under the
skill's control:

| How it is connected | Real tool name |
|---------------------|----------------|
| MCP bundled in the plugin (default) | `mcp__plugin_prowodo-tasks_prowodo__list_tasks` |
| `claude mcp add ... prowodo` (manual) | `mcp__prowodo__list_tasks` |
| claude.ai connector | `mcp__claude_ai_Prowodo__list_tasks` |

**Do not assume a prefix: look at the tools actually available in the session and use
the one that ends with the right name.** If the same installation has more than one of
these connections active, you will see **two equivalent sets** of tools — use only one
and stay consistent for the whole session.

If you find **no** ProWoDo tool at all, the server is not authenticated: tell the user to
run `/mcp` and complete the OAuth login in the browser. Do not fall back to `curl`.

## Base flow

1. **Check the project memory** (`prowodo_defaults.md` in the current memory dir — see [references/project-defaults.md](references/project-defaults.md)). If it exists, use company/project/scrum as defaults.
2. Otherwise **list the companies** with `list_companies` and **the projects** with `list_projects` (pass `company_id`). **Check the `is_archivied` field** (sic, backend typo) on every project: do not suggest archived projects as a destination and do not write tasks into them. If the only match is archived, tell the user and ask for an alternative.
3. Once you have worked out company + project + whether the user uses scrum, **offer to save it in memory** (see [references/project-defaults.md](references/project-defaults.md)) to avoid asking every time.
4. Act according to the user's intent (see the "Scenario index" below).

**Read-only operations** (list, retrieve): run them directly without asking for confirmation.
**Single write operations** (create/update/move 1 task): run them directly without asking for confirmation.
**Bulk operations** (edit/create/delete 5+ tasks at once): ask for confirmation first.

## Platform links

When you report a task, a project, a sprint, a comment, a reminder, an attachment or a dependency, **always include `app_url`** as a clickable link — it is a read-only field exposed by the serializer for exactly this purpose.

**Never build the URL of a task (or project/sprint/...) by hand.** The field exists precisely because the payload alone is not enough to compose it correctly: always use `app_url` as it is.

Things to know about links:
- A task opens the task drawer. Comments, reminders, task attachments and dependencies **have no page of their own** — their `app_url` points to the parent task's drawer (for a dependency, to the **successor**, i.e. the blocked task). The frontend opens the drawer only via `?taskId=`: **there are no addressable tabs**, so you cannot link directly to the comments tab.
- A project has an `app_url` pointing to `/{company}/{project}/dashboard`. The other views share the same base `/{company}/{project}/`: `tasks/list`, `board`, `backlog`, `matrix`, `tasks/timeline`, `sprints`, `attachments`, `scoring`. When to use them: prioritization → `matrix`, time planning → `tasks/timeline`, current sprint → `board`, search/tree → `tasks/list`. Tasks and sprints also carry `company_id`, so you can compose these view URLs yourself when needed.
- **The timeline is plan-gated** (`featureGuard('gantt')`): for users without Gantt in their plan that link opens the billing page with an upgrade toast. Do not suggest it as a default — only if the user explicitly asks for the timeline/Gantt view.
- A ticket submission carries **two** distinct links: `app_url` (INTERNAL, for the team) and `public_url` (`/t/{uuid}`, PUBLIC — the page seen by whoever opened the ticket). **Do not confuse them**: giving the internal `app_url` to a customer is exactly the mistake this distinction exists to avoid. `public_url` is to be shared with whoever opened the ticket, `app_url` stays internal to the team.

## Scenario index

The base flow and the rules are below. The detail of each scenario lives in a dedicated
file: open it **only** when the user touches that topic.

| If the user wants to… | Open |
|-----------------------|------|
| Search tasks by text ("are there tasks about Y?" / "ci sono task su Y?") · assign to someone · "what do I have to do" / "cosa devo fare io" | [references/search-and-assign.md](references/search-and-assign.md) |
| A reminder / "ricordami" (remind me) · "what reminders do I have today?" / "che reminder ho oggi?" | [references/reminders.md](references/reminders.md) |
| Save or retrieve knowledge (notes, "where did we talk about it?" / "dove ne abbiamo parlato?", notes review) | [references/notes.md](references/notes.md) |
| Today's day in a single order · the weekly rhythm (focus per day, goals, deadlines) · "move to tomorrow" / "sposta a domani" · "segna: …" (note: …) | skill **oggi** · tools in [references/rhythm.md](references/rhythm.md) |
| "What's new in ProWoDo?" / "cosa c'è di nuovo in ProWoDo?" · "what can you do?" / "cosa sai fare?" · you don't know which tool to use | [references/help-and-releases.md](references/help-and-releases.md) |
| Comment on a task or read its thread | [references/comments.md](references/comments.md) |
| Attach files/text/links to a project, company or task | [references/attachments.md](references/attachments.md) |
| Constraints "X does not start until Y is finished" | [references/dependencies.md](references/dependencies.md) |
| Reorder · estimate (story points) · prioritize (ICE/RICE) | [references/ordering-and-estimation.md](references/ordering-and-estimation.md) |
| Sprints, Scrum, closing a sprint | [references/sprints.md](references/sprints.md) |
| Company/project defaults for the cwd | [references/project-defaults.md](references/project-defaults.md) |
| Odd API errors, archived projects, moving a task to another project | [references/gotchas.md](references/gotchas.md) |
| Tickets, resume entries, tags, project CRUD, lanes | [references/collaboration.md](references/collaboration.md) |
| Exact name of a tool (full list of the 108) | [references/tools.md](references/tools.md) |

## Quick scenarios

### "What is there to do?" / Backlog / Planning ("Cosa c'è da fare?")
Use `list_tasks` to show the project's open tasks. Present them readably: name, priority, progress %, assignee if present.

### "Add a task" / "Note that I have to do X" ("Aggiungi un task" / "Segna che devo fare X")
Use `create_tasks`. Ask for the project if not specified.

### Task states (`status`)

The `status` field has **four values**: `BACKLOG`, `TODO`, `IN_PROGRESS`, `DONE`. Use it to reflect where the task is in the workflow, not just to mark it finished — e.g. when the user says "I'm working on it" or "I'm starting X" ("ci sto lavorando" / "inizio X"), move the task to `IN_PROGRESS` with `partial_update_tasks(status: "IN_PROGRESS")` (see also the note on IN_PROGRESS and assignees in [references/search-and-assign.md](references/search-and-assign.md)).

### "I finished X" / "Mark as completed" ("Ho finito X" / "Segna come completato")
Use `partial_update_tasks` with these fields together: `is_completed: true, progress: 100, status: "DONE"`. The backend treats the three "done signals" as an invariant (see `Task.save()` in `core.models`) — if you set just one, the others get synced anyway, but spelling out all three makes the intent clear and independent of future backend changes.

**Also updating the description with a summary of what was done** is good practice when the task is non-trivial: it helps recover the context in the future. Hard limit: the description has a **max of 4096 characters** (HTTP 400 beyond that, with a field-level error message). If you need to narrate a lot, split it into a comment on the task or link to the spec/plan in `docs/superpowers/`.

### Updating progress / "I'm at 50% on X" ("Sono al 50% su X")
Use `partial_update_tasks` with the `progress` field (0–100).
Always show the progress % in summaries when it is > 0.

### "Let's plan the next sprint" / Prioritization ("Pianifichiamo il prossimo sprint")
List the open tasks, then help the user order them by priority or move them with the reordering tools.
If the Scrum workflow is active for the project (see [references/sprints.md](references/sprints.md)), also suggest assigning the tasks to a sprint with `move_to_sprint_tasks` and estimating them with `story_points` (see [references/ordering-and-estimation.md](references/ordering-and-estimation.md)).

### End of a work session
If you have completed significant work, suggest recording the completed tasks or creating follow-up tasks in ProWoDo.

## Internal tasks created by superpowers (TaskCreate)

Claude Code uses the `TaskCreate` / `TaskUpdate` tool to track its own internal work while running skills (e.g. superpowers, feature-dev). These internal tasks **do not go on ProWoDo** — they exist only in the current session.

**Use ProWoDo** for the user's project tasks (features, bugs, backlog).
**Use TaskCreate** for internal steps of a work session (e.g. a skill's checklist).

When the user asks "what did you do?" or "update the tasks" ("cosa hai fatto?" / "aggiorna i task"), update the relevant ProWoDo tasks with progress and status, not the internal tasks.

## Available tools

| Action | Tool |
|--------|------|
| List companies | `list_companies` |
| List projects | `list_projects` |
| List tasks | `list_tasks` |
| Task detail | `retrieve_tasks` |
| Create task | `create_tasks` |
| Update task | `partial_update_tasks` |
| Move up/down | `move_up_tasks` / `move_down_tasks` |
| Move to project | `move_to_project_tasks` |
| Reorder root | `reorder_root_tasks` |
| Add tag | `add_tag_tasks` |
| Sub-task (indent) | `increase_depth_tasks` / `decrease_depth_tasks` |
| Search knowledge (tasks+comments+notes) | `search_knowledge` |
| Notes (CRUD + search) | `list_notes` / `retrieve_notes` / `create_notes` / `partial_update_notes` / `destroy_notes` (trash) / `search_notes` |
| Notes trash, versions, links | `trashed_notes` / `restore_notes` / `history_notes` / `revert_notes` / `links_notes` |
| List company users | `list_users` (path: `company_id`, supports `search`) |
| User detail | `retrieve_users` |
| Current user ("me") | `retrieve_current_user` (no parameters) |
| Assign user to task | `assign_user_tasks` (`pk` + `body.user_id`, idempotent) |
| Remove user from task | `unassign_user_tasks` (`pk` + `body.user_id`, noop-safe) |
| List a task's reminders | `list_reminders` (path: `task_id`) |
| Create reminder | `create_reminders` (path: `task_id` + body) |
| Update reminder | `partial_update_reminders` |
| Delete reminder | `destroy_reminders` |
| Rhythm and day | `retrieve_current_rhythm` / `today_rhythm` / `set_text_rhythm` / `mark_interpreted_rhythm` / `list_rhythm_items` / `create_rhythm_items` / `partial_update_rhythm_items` / `destroy_rhythm_items` (see [references/rhythm.md](references/rhythm.md)) |
| Tool guide · product news | `help` / `list_release_notes` (see [references/help-and-releases.md](references/help-and-releases.md)) |

## Minimum parameters to create a task

```
title: "task title"   # required
project_id: <id>           # required (default from project memory if present)
description: "..."         # optional
progress: 0–100            # optional, default 0
story_points: 1|2|3|5|8|13 # optional, recommended (see references/ordering-and-estimation.md)
parent_id: <id>            # optional, for sub-tasks
```

## Reference documentation

This file covers the base flow; the details are split by topic (see the
"Scenario index" above) so they are not loaded in every session. The backend exposes
**108 MCP tools** in total:

- **[references/tools.md](references/tools.md)** — complete table of all 108 tools,
  grouped by family, with required path params and a one-sentence purpose for each.
  Open it when you need the exact name of a tool you do not remember.
- **[references/collaboration.md](references/collaboration.md)** — the low-frequency
  families with "when needed" and an example: tickets (`retrieve_ticketsubmissions`,
  `*_ticketcomments`, `is_internal` flag), resume entries (daily plan/done), tag CRUD
  beyond `add_tag_tasks`/`remove_tag_tasks`, project CRUD, sprint board lanes.
  Open it only when the user explicitly asks for one of these things.

## Rules

- **Single read and write**: run without asking for confirmation
- **Bulk operations (5+)**: ask for confirmation with a summary of what will be done
- If the user does not specify the project, show the available projects and ask
- After every operation show a concise summary (task name, ID, status, progress %)
- Prefer updating existing tasks over creating new duplicates
- When showing tasks with progress > 0, always display the percentage
