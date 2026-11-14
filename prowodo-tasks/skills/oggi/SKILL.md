---
name: oggi
description: Plan the user's day or week across all their ProWoDo companies, in one ordered list. Use when they ask "cosa faccio oggi", "cosa conviene fare oggi", "cosa devo fare oggi", "la mia giornata", "what should I do today", "plan my day", "plan my week", when they want to move or reprioritise a task ("sposta questo a domani", "alza la precedenza di questo", "move this to tomorrow"), capture something new ("segna: …", "devo anche …"), or describe their weekly rhythm ("lunedì hoopy e tesi", "questa settimana devo finire il sito", "entro il 3 novembre devo aver finito X", "il mio ritmo"). Reads the ProWoDo rhythm and tasks, plus Google Calendar and Gmail when connected.
---

# Oggi — day and weekly rhythm

The user has things to do across multiple companies and projects (work, side projects, university, personal) and
gets lost. This skill gives them **a single order** for everything, and lets them correct it by talking.
The computation of the order is done by the **backend** (`today_rhythm`, deterministic): you do not reorder,
you interpret the rhythm text, add calendar and mail, and apply the requested changes.

Tool names: bare as in the `prowodo-tasks` skill (the prefix depends on how the
server is connected). Detail of the rhythm tools: [../prowodo-tasks/references/rhythm.md](../prowodo-tasks/references/rhythm.md).

## "What do I do today?" ("Cosa faccio oggi?")

1. `retrieve_current_rhythm` → text, entries, `pending_interpretation`.
2. If `pending_interpretation` is true: **interpret the text** (section below), then continue.
3. `today_rhythm` (without `date` = today, Rome time). It returns `focus`, `off_focus_deadlines`,
   `rest`, `anomalies`, `interpretation`. **Do not change the order of the tasks.**
4. Add, if the connectors are there: today's **Google Calendar** events and **mails** awaiting
   a reply (targeted search, few; never read or quote private content beyond sender/subject).
   If a connector is not there, say so in one line and move on.
5. Reply in the format below (in the user's language).

### Format

```
☀️ Monday 26 October — your day
Today I read the focus as: hoopy, thesis, [Site] Copy…   ← always, from `interpretation`

🔴 To do today            ← `focus`
• [company] title (due 28 Oct) — link `app_url`
⚠️ Off focus, cannot wait   ← `off_focus_deadlines`, never omitted
📅 Calendar   ✉️ Mails waiting
🟡 If time remains          ← `rest`
🧹 To fix up            ← `anomalies`, one question per line ("raise it?", "close it?")
```

- **Always** show the line "Today I read the focus as": it is how the user notices that you
  misunderstood. Entries with `missing: true` → flag them ("a reference no longer exists").
- Empty day (no focus): say so and still show deadlines and "if time remains".
- Every task with its `app_url`; do not build URLs by hand.
- **Anomalies** are proposed, not applied without an answer.

## Interpreting the rhythm text

When `pending_interpretation` is true (or the user writes/says the rhythm out loud):

1. If they speak it, first save the text with `set_text_rhythm` (full updated text, not a fragment).
2. Split the text into **sentences**. For each one decide the scope:
   - day of the week ("lunedì hoopy e tesi" — "Monday hoopy and thesis") → `DAY` + `weekday` (0 = Monday … 6 = Sunday);
   - "this week I have to …" ("questa settimana devo …") → `WEEK` + `ends_on` = Sunday of the current week;
   - "by … I must have finished …" ("entro il … devo aver finito …") → `DEADLINE` + `ends_on`, **and** `partial_update_tasks` with
     `expected_stop_datetime` on the task (Rome time → UTC). If the task does not exist, create it
     (company/project with the capture rule below) and say so.
3. Resolve the references with the read tools (`list_companies`, `list_projects`, `list_tasks` with
   `search`, tags): company, project, task (big or small) or tag. A text that points to
   nothing concrete ("I want to knock off early") goes as a `note`.
4. An ambiguous sentence (two matching tasks, a name never seen) **is not guessed**: leave it out and
   ask, in a single question for all the ambiguous ones.
5. Create the entries with `create_rhythm_items`, always with `source_phrase` = the original sentence and
   without `is_manual`. Constraints from the backend: only one reference per entry; an id of a company the
   user cannot see gives an error (do not retry with other ids).
6. **Do not touch** entries with `is_manual: true` (the user put them in by hand) and do not delete entries
   to start over. An entry that the user removed by hand and that you re-propose with the same sentence is not
   recreated (the backend responds with the discarded entry): it is intended, do not insist.
7. To move an entry use `partial_update_rhythm_items`; to remove it `destroy_rhythm_items`.
8. Finish with `mark_interpreted_rhythm`.

## Spoken changes

- **"Move X to tomorrow" ("Sposta X a domani")**: if X has a deadline (`expected_stop_datetime`), move it to tomorrow at the
  same time with `partial_update_tasks` (if the deadline was a fixed date set by the user, ask first).
  If it has no deadline, its place in the day depends on the rhythm: propose adding it to tomorrow's
  focus with `create_rhythm_items` (`DAY`, tomorrow's `weekday`, `task_id`), without `source_phrase`
  and with `is_manual: true`, and say that this is what you will do.
- **"Raise the priority of X" ("Alza la precedenza di X")**: `partial_update_tasks` with `priority` +1 (maximum 4); report
  before → after. For "set it to the maximum" use 4.
- **"Close X" ("Chiudi X")**: `is_completed: true, progress: 100, status: "DONE"` (see `prowodo-tasks`).
- **"What is best to do today?" ("Cosa conviene fare oggi?")**: start from `today_rhythm` and give advice **grounded in that data**
  (close deadlines, priorities, the day's focus, free time in the calendar). Do not invent deadlines
  or priorities that are not in the data.

## "Note: …" (capture) ("Segna: …")

The user writes to Claude instead of keeping things in mind or on WhatsApp. For each sentence:
1. Choose company and project from the context (project memory, `list_companies`/`list_projects`);
   **if it is uncertain, ask** instead of guessing.
2. `create_tasks` with a short title, and propose (do not impose) `priority`, `importance` and deadline if
   the sentence gives hints of them ("urgent", "by Friday" — "urgente", "entro venerdì").
3. Report title, company/project, deadline and `app_url`.

## Rules

- Reads and single writes: run without asking for confirmation. Changes on 5+ tasks: summary and confirmation.
- Never show more than the day: the rest of the backlog only if requested.
- The 8 o'clock Telegram message has only the ProWoDo part; calendar and mail appear here, on request.
