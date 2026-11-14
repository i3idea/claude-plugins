# Project defaults in memory

← [Skill index](../SKILL.md) · See also: [archived projects gotcha](gotchas.md) · [sprints](sprints.md)

How to save and use the default company/project/Scrum mode for the cwd.

To avoid asking every time for company/project/scrum-on-off, write a memory file in the memory dir of the current cwd (path: `~/.claude/projects/<dir-slug>/memory/prowodo_defaults.md`). Index it in `MEMORY.md` with a line:

```
- [Defaults ProWoDo](prowodo_defaults.md) — default company/project/scrum for this cwd
```

**When to create it:**
- After you have worked out which company + project + whether the user uses Scrum on this cwd, **propose** saving it as a default. Do not write it silently: ask for confirmation just once.
- Update it if the user changes their mind or works on a new project in the same cwd (multiple projects? add a section, do not overwrite).

**File format** (`prowodo_defaults.md`):

```markdown
---
name: Defaults ProWoDo
description: Default company / project / Scrum mode for this working directory
type: project
---

**Default company:** Acme (id: `42`)
**Default project:** Marketing site (id: `7`)
**Uses scrum:** true
**Story-points cap per task:** 8 (decompose if >8)
**Note:** preference emerged on 2026-04-26.
```

**How to use them:**
- At the start of every session about tasks/planning, **before** calling `list_companies` / `list_projects`, read the file (if it exists) and proceed directly with the defaults.
- **Verify that the default project is not archived** before writing to it: a `list_projects` (or `retrieve_projects` if available) and a check of `is_archivied`. If it is, warn the user and ask for an active alternative instead of operating silently.
- The defaults are **not binding**: if the user cites another project/company in the conversation, follow that without asking and without modifying the memory. Update the memory only if the user explicitly says "change the default project" / "now I'm working on X" ("cambia il progetto di default" / "ora lavoro su X").
- If `uses_scrum=false`, do not proactively suggest sprint/grooming/points flows. If `uses_scrum=true`, apply [ordering-and-estimation.md](ordering-and-estimation.md) (story points) and [sprints.md](sprints.md).
