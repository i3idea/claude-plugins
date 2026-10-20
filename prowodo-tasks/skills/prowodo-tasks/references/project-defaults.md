# Defaults di progetto in memoria

← [Indice della skill](../SKILL.md) · Vedi anche: [gotcha progetti archiviati](gotchas.md) · [sprint](sprints.md)

Come salvare e usare company/progetto/modalità Scrum di default per la cwd.

Per evitare di chiedere ogni volta company/progetto/scrum-on-off, scrivi un file di memoria nella memory dir della cwd corrente (path: `~/.claude/projects/<dir-slug>/memory/prowodo_defaults.md`). Indicizzalo in `MEMORY.md` con una riga:

```
- [Defaults ProWoDo](prowodo_defaults.md) — company/progetto/scrum di default per questa cwd
```

**Quando crearlo:**
- Dopo che hai capito quale company + project + se l'utente usa Scrum su questa cwd, **proponi** di salvarlo come default. Non scriverlo silenziosamente: chiedi conferma una sola volta.
- Aggiornalo se l'utente cambia idea o lavora su un nuovo progetto della stessa cwd (più progetti? aggiungi una sezione, non sovrascrivere).

**Formato file** (`prowodo_defaults.md`):

```markdown
---
name: Defaults ProWoDo
description: Company / progetto / modalità Scrum di default per questa working directory
type: project
---

**Default company:** Acme (id: `42`)
**Default project:** Sito marketing (id: `7`)
**Uses scrum:** true
**Story-points cap per task:** 8 (decomporre se >8)
**Note:** preferenza emersa il 2026-04-26.
```

**Come usarli:**
- All'inizio di ogni sessione che riguarda task/planning, **prima** di chiamare `list_companies` / `list_projects`, leggi il file (se esiste) e procedi direttamente con i default.
- **Verifica che il progetto di default non sia archiviato** prima di scriverci: una `list_projects` (o `retrieve_projects` se disponibile) e controllo di `is_archivied`. Se lo è, avvisa l'utente e chiedi un'alternativa attiva invece di operare silenziosamente.
- I default **non sono vincolanti**: se l'utente cita un altro progetto/company nella conversazione, segui quello senza chiedere e senza modificare la memoria. Aggiorni la memoria solo se l'utente dice esplicitamente "cambia il progetto di default" / "ora lavoro su X".
- Se `uses_scrum=false`, non proporre flussi sprint/grooming/punti in modo proattivo. Se `uses_scrum=true`, applica [ordering-and-estimation.md](ordering-and-estimation.md) (story points) e [sprints.md](sprints.md).
