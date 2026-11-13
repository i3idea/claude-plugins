# Task comments

← [Skill index](../SKILL.md) · See also: [attachments](attachments.md) · [dependencies](dependencies.md) · [tickets](collaboration.md)

Conversation thread on a task.

**When needed:** the user wants to leave an update for stakeholders on a
task, read the discussion that already took place, or reply to a comment — different from the
`description` (the "what" of the task): comments are the conversation thread.

- `list_taskcomments` / `retrieve_taskcomments` (path: `task_id`) — thread, newest
  first (unlike ticket comments, which are oldest first).
- `create_taskcomments` — **`task_id` goes in the body, not in the path** (an exception
  compared to the other tools in this family — if you pass it only as a path param the comment
  ends up detached). The author is always the authenticated user. `comment_id` optional
  to reply to an existing comment.
- `destroy_taskcomments` (path: `task_id`) — soft-delete: the comment disappears from the
  thread but is not physically deleted.

```
create_taskcomments(body={
  "task_id": 1234,
  "text": "Blocked waiting for confirmation from the customer on the copy."
})
```

The comment's `app_url` points to the parent task's drawer (comments have no page of their
own — see "Platform links" in [SKILL.md](../SKILL.md#platform-links)).
