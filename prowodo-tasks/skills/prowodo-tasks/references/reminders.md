# Reminders

← [Skill index](../SKILL.md) · See also: [assignees](search-and-assign.md) · [full tools](tools.md)

Timed reminders on tasks (push, email, Telegram) and a cross-task view.

## "Remind me X" / "Set a reminder" / Reminders on tasks ("Ricordami X" / "Metti un reminder")

**Live in prod since 2026-07-01.** Every task can have **N reminders** scheduled in time, delivered on multiple channels (push notification, email, Telegram). A backend scheduler picks up the due reminders every minute, sends them to the recipients and marks `is_sent`.

- **Create**: `create_reminders` with `task_id` (path) + body:
  - `remind_at` — ISO datetime, **required** (when it fires)
  - `text` — the reminder's message
  - `recipient_id` — optional; if omitted the recipients are the task's **current assignees**. Must be a member of the task's company.
  - `send_push` / `send_email` / `send_telegram` — channels; **at least one true** (default: push only)
  - `notify_if_completed` — default false; if true it also fires when the task is already DONE
- **List**: `list_reminders` with `task_id` (each reminder exposes `is_sent`).
- **Update / delete**: `partial_update_reminders` / `destroy_reminders`.

Example — "remind me to review this task tomorrow at 9" ("ricordami di rivedere questo task domani alle 9"):
```
create_reminders(task_id=1234, body={
  "remind_at": "2026-07-02T09:00:00Z",
  "text": "Review the task",
  "send_push": true
})
```

Recommend setting reminders when the user says "ricordami", "avvisami", "metti un promemoria" (remind me, notify me, set a reminder) or mentions a deadline on a specific task.

## "What reminders do I have today?" / "What fires this week?" ("Che reminder ho oggi?" / "Cosa scatta questa settimana?")

`list_reminders` is scoped to **one** task (requires `task_id`). For a cross-task view
— "my reminders for today", regardless of the task they were put on — use
`list_all_reminders`: no path param, it filters across all the user's tasks with
`remind_at__date` / `remind_at__gte` / `remind_at__lte` and `is_sent`.

```
list_all_reminders(remind_at__date="2026-08-05", is_sent=false)
```

Use it for summaries like "what do I have to remember today" instead of iterating `list_tasks` +
`list_reminders` task by task.
