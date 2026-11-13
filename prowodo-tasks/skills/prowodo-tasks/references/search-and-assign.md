# Searching tasks and assigning them

← [Skill index](../SKILL.md) · See also: [notes](notes.md) · [ordering and estimation](ordering-and-estimation.md)

Text search on tasks (`search` vs `*__icontains`) and assignment to users.

## "Search tasks about X" / "Are there tasks about Y?" ("Cerca task su X" / "Ci sono task che riguardano Y?")
`list_tasks` exposes **three distinct text filters** — they use different indexes, they are not interchangeable:

| Parameter | Match type | Index |
|-----------|------------|-------|
| `search` | **fuzzy trigram similarity** on title + description, threshold 0.2, sorted by similarity desc | GIN on trigrams (`pg_trgm`) |
| `title__icontains` | case-insensitive substring in the title only | b-tree / varchar_pattern_ops (or sequential scan) |
| `description__icontains` | case-insensitive substring in the description only | same type |

**Practical implications:**
- `search` tolerates **typos, abbreviated words, different order** (e.g. "clodbuild" finds "cloudbuild"), but **discards** matches with similarity < 0.2 → keywords that are too short or different from the text get filtered out.
- `title__icontains` / `description__icontains` are **literal**: the string must appear exactly as is (case-insensitive). They do not handle typos but do not filter by threshold.

**Recommended strategy** for a complete search:
1. Start from `search=<keyword>` → it catches most of them (including typos) with the most relevant on top.
2. If the results seem few, repeat with `description__icontains=<keyword>` (and/or `title__icontains`) to catch tasks where the keyword appears literally but with similarity < 0.2 (e.g. long sentences where the keyword is one word among many).
3. Always combine with `project_id`, `is_completed=false`, `parent_id` to narrow the scope.

To search **by content** also in comments and notes, or when the question is "where did we talk about it?" ("dove ne abbiamo parlato?"), use `search_knowledge` (see [notes.md](notes.md)). `list_tasks` only searches in tasks.

## "Assign X to Y" / "Who is assigned to Z?" ("Assegna X a Y" / "Chi è assegnato a Z?")

**Available since backend `8489763` (2026-05-26) / `@prowodo/angular-client@1.2.0`.**

**Always show the assignees in summaries**, reading the task's `assignees` field (`retrieve_tasks(pk=<id>)` or already included in `list_tasks`) — a list of dicts with `id`, `display_name`, `username`, `email`, `identity_picture_url`. No separate call is needed to know it.

**"Assign to me" / "what do I have to do" ("Assegna a me" / "cosa devo fare io"):** resolve "me" with the current-user tool `retrieve_current_user` (no parameters — it returns id, username, display name, email of the authenticated user). **Do not guess** one's own name with trial-and-error `list_users`: before this tool existed it was the only way, now it is the wrong one.

To assign a task to **another** user (not "me"):

1. Resolve the user name into `user_id` with `list_users` (path param: `company_id`). The viewset supports search via `search_fields` on email/username/first_name/last_name/display_name/identity_email — pass the search string as the `search` parameter if the user cites a free-form name ("Ivan").
2. Call `assign_user_tasks` with `pk=<task_id>` and `body={"user_id": <id>}`. It is **idempotent** — calling it twice creates neither duplicates nor an error.
3. To remove: `unassign_user_tasks` with the same shape. It returns `{"unassigned": true|false}`. **Noop-safe** — calling it on an assignment that does not exist raises no error.

**Security:** the backend rejects with 400 if `user_id` points to a user who is NOT a member of the task's company (cross-tenant). No leak.

**When a task moves to `IN_PROGRESS` and has no assignees, propose assigning it** — default: the logged-in user (via `retrieve_current_user`), unless otherwise indicated. An "in progress" state with no owner is the most common case of a task getting lost.

Typical flow example — "Assign task #1234 to Ivan":
```
1. list_users(company_id=1, search="Ivan")
   → [{id: 42, display_name: "Ivan Bettarini", ...}]
2. assign_user_tasks(pk=1234, body={user_id: 42})
   → 201 {id: ..., task_id: 1234, user_id: 42}
```

If the search returns multiple matches, show them to the user and ask for disambiguation before assigning.
