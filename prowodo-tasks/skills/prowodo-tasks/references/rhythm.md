# Rhythm (day and weekly focus)

← [Skill index](../SKILL.md) · The full procedure is in the skill [oggi](../../oggi/SKILL.md)

Per-user (not per company): it says **what to push on which day**. It has a free text, resolved
entries (company, project, task, tag or note) per day of the week, period goals and
deadlines. The "Rhythm" page in ProWoDo (main menu) shows and lets you edit the same entries.

| Tool | Purpose |
|------|---------|
| `retrieve_current_rhythm` | Text, entries, `pending_interpretation` (the text changed after the last interpretation). Read-only. |
| `today_rhythm` | The day computed by the backend (`date` optional, Rome time): `focus`, `off_focus_deadlines`, `rest`, `anomalies`, `interpretation`. Read-only. |
| `set_text_rhythm` | Replaces the free text (`body.text`, max 8192) and marks it to be interpreted. |
| `mark_interpreted_rhythm` | Resets `pending_interpretation` after creating the entries. |
| `list_rhythm_items` | The user's entries; filters `scope`, `weekday`. Discarded entries do not appear. |
| `create_rhythm_items` | Creates an entry: `scope` `DAY` (needs `weekday`), `WEEK` or `DEADLINE` (with `ends_on`); **only one** of `company_id`, `project_id`, `task_id`, `tag_id`, `note`; `source_phrase` = the original phrase. |
| `partial_update_rhythm_items` | Changes day, date, reference or note of an entry. |
| `destroy_rhythm_items` | An entry born from the text is *discarded* (it is not recreated with the same phrase); a manually added one is deleted. |

Things to know:
- `weekday`: 0 = Monday … 6 = Sunday. The "day" is always in Rome (`Europe/Rome`).
- `today_rhythm`: **focus** = open tasks assigned to the user under today's entries (a task includes its sub-tasks); **off focus** = overdue or due within 3 days; **rest** = in progress or priority ≥ 3, max 5. Order: priority, importance, due date, ICE score.
- An entry with `missing: true` pointed to something that no longer exists: flag it, do not ignore it.
- The setting of the 8 o'clock Telegram message (on/off, language) is only on the web page, not via MCP.
- The free text is interpreted by Claude, not by the backend: until you do it, the page shows "awaiting interpretation".
