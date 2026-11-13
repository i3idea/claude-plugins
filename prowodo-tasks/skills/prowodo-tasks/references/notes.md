# Notes and second brain — saving and retrieving knowledge

← [Skill index](../SKILL.md) · See also: [task search](search-and-assign.md) · [attachments](attachments.md)

The company's knowledge base: saving, searching, linking, reviewing notes.

Notes are the company's knowledge base: free markdown, optionally tied to a project. They are for decisions, context, notes that are not actions to do (those are tasks).

**Which tool for which question:**

| User's question | Tool |
|---|---|
| "Where did we talk about it?" / "What do we know about X?" / "Have I already written something about Y?" ("Dove ne abbiamo parlato?" / "Cosa sappiamo su X?" / "Ho già scritto qualcosa su Y?") | `search_knowledge` — **default for any knowledge search**: it searches in a single call across tasks (title+description), task comments and notes, ordered by relevance |
| I only search among notes, by content | `search_notes` |
| I list a project's notes / by title | `list_notes` (`project_id`, `title__icontains`) |
| Save this decision / note ("Salva questa decisione / appunto") | `create_notes` |
| Fix / add to a note ("Correggi / aggiungi a una nota") | `partial_update_notes` |

**`search_knowledge`:** `company_id` and `query` required, `project_id` optional to narrow down. Each result has `kind` (`task` | `task_comment` | `note`), `id`, `snippet` (excerpted, not the full text) and — for `task_comment` — the `task_id` of the parent task. For the full text then call `retrieve_notes` / `retrieve_tasks` / `list_taskcomments`. It returns `{"results": [...]}`, at most one page of results: if needed, refine the query or pass `project_id`. **Tickets and ticket comments are not included.** The search is full-text (whole words), not semantic: "riunione" does not find "meeting". You supply the meaning — see "Searches that find nothing" below.

**Promoting a task to a note:** there is no dedicated tool. Read the task (`retrieve_tasks`, plus `list_taskcomments` if the discussion matters), then `create_notes` with `source_task` = the task's id: the note stays linked to its origin (`SET_NULL` if the task is deleted). `source_task` is also writable on `update_notes` / `partial_update_notes` and must belong to the same company as the note. Do not close or modify the originating task, unless the user asks.

**Writing a note:**
- Short, searchable `title` (the user will search for it by keywords); `content` in markdown.
- Set `project_id` if the content concerns a project, omit it for company notes.
- Before creating, if the topic may already exist, do a `search_notes` and propose updating the existing note instead of duplicating it.
- **Visibility.** Every note is `company` (default, visible to all members of the company) or `private` (visible only to whoever wrote it, no exception even for admins). Create with `visibility: "private"` **only** if the user asks for it ("nota mia", "privata", "solo per me", "appunto personale" — i.e. "my note", "private", "just for me", "personal note"); in all other cases leave the default. Only the author changes `visibility`: do not make someone else's note private nor a private one public without an explicit request.
- **Searches that find nothing.** `search_notes` and `search_knowledge` search for whole words, not meanings. If the results are few or zero, **do not conclude that the note does not exist**: retry at least twice with variants — synonyms, related terms, singular/plural, a shorter word, and the **translation** (Italian ↔ English: "riunione" / "meeting", "scadenza" / "deadline"). Run the variants in sequence and merge the results; only afterwards tell the user you found nothing, listing the terms tried.
- Searches (`search_notes`, `search_knowledge`, `list_notes`) return only the notes the user can see: someone else's private note never shows up, so "I did not find it" does not prove it does not exist. `list_notes` accepts `visibility=private` to find only one's own private notes.
- **Trash.** `destroy_notes` **does not delete forever**: it moves the note to the trash (it can be seen and recovered with `trashed_notes` / `restore_notes`). Permanent deletion does not exist via MCP: the user does it from the app (Trash tab). Still confirm before trashing more than one note, and tell the user where to find it again.
- **History.** `history_notes` lists the last 50 versions (with `history_id`, date, title and content); `revert_notes` restores the title and content of a version (tags, project and visibility do not change) and saves the revert as a new version, so it can be undone. Use them for "go back to yesterday's version" or after a wrong edit, instead of rewriting the note by hand.
- **Links.** In the `content` you can write `[[Note title]]` or `[[id|label]]`: it creates a link to another note of the same company. A title with zero or multiple matches stays "unresolved": use the form with the id. A shared note cannot link to a private one. `links_notes` returns the outgoing links (`resolved` true/false) and the **backlinks** (who points to this note): follow them to rebuild context before answering "what do we know about X?". `[[...]]` inside code blocks are ignored.
- **Notes review** ("rivedi le mie note" — "review my notes", or the user replies to the monthly reminder "Review my ProWoDo notes"). Proceed step by step and **ask for confirmation before writing or deleting**: trash and history make everything reversible, but the user decides.
  1. **Inbox**: `list_notes` with `tags__text=inbox` (per company). For each note propose a better project, tag and title, or merging or trashing; after sorting, remove the `inbox` tag.
  2. **Old notes**: `list_notes` with `updated_at__lte=<date 6 months ago>` and `ordering=updated_at` (oldest first). Propose to update, send to the trash (`destroy_notes`) or leave.
  3. **Duplicates**: compare the titles and, for the candidates, use `search_notes` on the title; propose merging.
  4. **Orphan wikilinks**: `links_notes` on the most important notes; for each link with `resolved: false` propose creating the missing note or fixing the title.
  5. Summarize what you changed and what you left, with the links (`app_url`). Other people's private notes never show up: "I found no duplicates" holds only for what the user can see.

## Cultivating the second brain: proactive capture and periodic cleanup

← [Skill index](../SKILL.md) · See also: [reminders](reminders.md)

**Proactive capture.** If during the work something lasting and reusable emerges — a decision **with its why**, a gotcha learned the hard way, a verified procedure, a non-obvious fact about a project — **propose in one line to save it as a note** («Do you want me to save it as a note?» / «Vuoi che lo salvi come nota?»). Then:
- **Never save without an explicit yes.** The proposal is an offer, not an action.
- **Search first** (`search_knowledge`, with the variants from "Searches that find nothing"): if a note on the topic exists, propose updating that one instead of creating a new one.
- **One note, one concept**: short, searchable title, `[[Title]]` to the related notes, `project_id` if it concerns a project. If it comes from a task, `source_task`.
- **Do not propose** what is already in the code or in the git history, state that changes quickly, obvious things, or things already proposed and declined in the same session.
- `private` visibility only if the user asks (see above).

The plugin brings this reminder into context at every session start with a `SessionStart` hook (`hooks/session-start.sh`). A `PreCompact` hook (`hooks/pre-compact.sh`) asks the compaction summary to keep an «Unsaved note candidates» section: it cannot get anything saved before the compaction (its output goes only to the summary), so it is `SessionStart` with matcher `compact` that gets those notes proposed as soon as the session resumes. If you find that section in the summary, propose saving as above. The hook works only in Claude Code: on claude.ai this skill rule applies, without the automatic reminder.

**Periodic cleanup.** A server-side reminder already exists: on the **1st of every month at 09:00** ProWoDo sends a fixed message («Ask your AI assistant: "Review my ProWoDo notes."», with the number of notes in `inbox`). The channels (push, email, Telegram) are **opt-in and off by default**: if the user says they do not receive it, the first place to look is the profile's notification settings. On the reply, follow the "Notes review" procedure above.

**A skill cannot schedule on its own.** It can only suggest it, and it does so only if the user shows interest in a review more frequent than monthly («review them every week» / «rivedile ogni settimana»). In that case:
- propose a **cloud routine** (skill `schedule`) or, for a check within the session, `/loop`;
- the routine must **only prepare proposals** — for example list inbox, notes untouched for 6 months, duplicates and orphan wikilinks — **never** trash or rewrite: the user decides;
- create the schedule **only after confirmation**: it is an action that persists outside the session;
- remember that the routine needs access to the ProWoDo MCP; if the environment loses it, it fails silently.
