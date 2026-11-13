# Reordering, estimating, prioritizing

← [Skill index](../SKILL.md) · See also: [sprints](sprints.md) · [API gotchas](gotchas.md) · [project defaults](project-defaults.md)

Task reordering, story points with decomposition, ICE/RICE prioritization.

## "Move X before Y" / Reordering ("Sposta X prima di Y")
For single moves use `move_up_tasks` / `move_down_tasks`. To move a task to an exact position or to reorder in bulk use `partial_update_tasks` with the `order` field.

**Critical backend behavior (verified 2026-05-22):** after every `partial_update_tasks` the backend calls `Task.reorder()` which **renormalizes all the orders of the level** sequentially (0, 1, 2, ...) sorting by `(order ASC, id ASC)`. Implications:

- Setting `order=200` on a task does NOT put it at position 200: it puts it at the bottom (or close), because the renormalization lowers it to the "first free position" after the tasks with a lower order.
- Setting `order=0` on a task brings it to the top — the others are bumped by 1.
- Large gaps (10, 20, 30) are NOT preserved: after the first `partial_update` of another task, they get compacted.

**Recommended pattern for bulk reordering** (e.g. rebalancing 50+ tasks by priority):
1. Build the list in the desired final order in memory.
2. Iterate from start to end: for each task at position `i`, call `partial_update_tasks(order=i)` (consecutive integers 0,1,2,...).
3. Run them serially (a parallel batch is still fine, the last renormalize wins), and accept that exact values may be coerced — what matters is the relative order.
4. If two tasks collide on the same order, the tiebreak is `id ASC` — if that does not work, do a second pass bumping the task you want higher to `order=i-1` (it moves it above).

For the `reorder_root_tasks` task: it only calls `Task.reorder(project_id, parent_id=None)` with just `project_id` in the body — it is a cleanup that compacts the orders, it does not accept lists of IDs.

## Story points and decomposition

When you create or update a task **recommend** (without imposing it) the estimate in story_points. It is useful to:
- get an idea of the size of the work before starting
- decide whether the task should be split into smaller sub-tasks
- fill a sprint without overcommitting

**Recommended scale** (Fibonacci-like): `1, 2, 3, 5, 8, 13, 21`. Indicative meaning:
- `1–3` → half a day or less, ready to do
- `5` → ~1 day, clear scope
- `8` → ~2 days, still manageable as a single task
- `13+` → **too big**, to be decomposed

**Decomposition cap** (sensible default, user-overridable):
- If a task has `story_points >= 8` → suggest **splitting it into sub-tasks** each ≤ 5 points, using `create_tasks` with `parent_id` and/or `increase_depth_tasks`.
- Indicative sum of the children ≈ the parent's estimate (not binding, it is a sanity check).
- For root tasks left without an estimate after the conversation, **do not block** the user: create the task anyway and flag "consider adding story_points".

**When NOT to insist on points:**
- Quick administrative/operational tasks (sending an email, booking a call): the overhead of estimating them exceeds the value
- The user has already said they do not use estimates on that project (respect the default in memory, see [project-defaults.md](project-defaults.md))

## ICE / RICE prioritization

Besides story points (size), ProWoDo exposes the fields to prioritize the backlog with **ICE** and **RICE**. They are the right fields when the user asks "use ICE for priority", "reorder by priority", "what do I do first" ("usa ICE per priorità", "riordina per priorità", "cosa faccio prima"), or wants an objective order instead of the `priority` field (often left at the default MEDIUM and therefore not very discriminating).

**Fields (settable in `create_tasks` / `partial_update_tasks`):**

| Field | Range | Meaning |
|-------|-------|---------|
| `impact` | 1–5 | How much it moves the needle (value per user/business) |
| `confidence` | 0–100 | How sure you are of the impact / how well the work is understood (%) |
| `effort` | 1–5 | Effort/cost. **Higher = lower score** |
| `reach` | 0–N | RICE only: how many people/events it touches in a period |

**Scores computed by the backend (read-only in the response):**
- `ice_score = impact × (confidence / 100) ÷ effort` — verified (e.g. `i2 c85 e1` → `1.7`).
- `rice_score = reach × impact × (confidence / 100) ÷ effort` — standard RICE formula; populated only if `reach` is set.

**How to use them:**
1. When you create/update product tasks **recommend** filling in `impact` / `confidence` / `effort` (and `reach` if the user reasons by volume → RICE). For quick operational tasks do not insist, as with story points.
2. To prioritize: read the tasks with `list_tasks`, sort by `ice_score` (or `rice_score`) descending and propose that order. To **persist** the order on the board use `partial_update_tasks(order=i)` **serially top-down** (0,1,2,...) — see "Reordering" above and [gotchas.md](gotchas.md).
3. `story_points` (size) and ICE/RICE (priority) are orthogonal: a task can be small but low priority and vice versa. Do not confuse them.

**⚠️ Known ICE limitation — always flag it before reordering the board literally:** ICE rewards *cheap* tasks (low effort) and penalizes high-effort *strategic bets*. A 5-minute tech-debt item can outscore the payment gate / the launch. When the user wants to reorder by ICE, **propose to manually "pin" the 2-3 strategic bets at the top** (monetization, launch, critical blocker) and sort everything else by ICE, instead of applying pure ICE. RICE partly mitigates the problem by introducing `reach`, but does not eliminate it.
