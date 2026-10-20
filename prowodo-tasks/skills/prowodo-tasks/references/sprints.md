# Sprint / Scrum

← [Indice della skill](../SKILL.md) · Vedi anche: [stime](ordering-and-estimation.md) · [lanes della board](collaboration.md) · [defaults di progetto](project-defaults.md)

Flusso Scrum opzionale: CRUD sprint, ciclo di vita, spostamento task.

Non tutti i progetti seguono Scrum. La modalità è una **preferenza per progetto**, registrata in memoria (`uses_scrum: true|false`). Quando è attiva, valgono questi flussi aggiuntivi:

- **Pianificazione sprint**: prima dell'inizio sprint, lista i task del backlog (`list_tasks` con `sprint__isnull=true`), aiuta a stimarli con `story_points`, poi spostali nello sprint con `move_to_sprint_tasks`.
- **Durante lo sprint**: `list_tasks` con `sprint=<id>` mostra il contenuto dello sprint attivo.
- **Chiusura**: a fine sprint i task non DONE possono essere portati nello sprint successivo o restituiti al backlog.

Quando l'utente NON usa Scrum (o non lo ha indicato in memoria) **non menzionare mai** sprint/grooming/velocity in modo proattivo: stai sul workflow base (backlog, priorità, ordine).

**CRUD sprint** — nessun path param (lo sprint è scoped alle company dell'utente via
query, non via URL):

- `list_sprints` / `retrieve_sprints` — filtra per `state` (`PLANNED`|`ACTIVE`|`CLOSED`) e per `project_id`; usa `list_sprints(state="ACTIVE", project_id=<id>)` per trovare lo sprint attivo *di un progetto specifico* — senza `project_id` la ricerca copre gli sprint di tutti i progetti delle company dell'utente.
- `create_sprints` — `project_id` nel body (non nel path), `name`, `start_date`/`end_date`. Nasce sempre in `PLANNED`.
- `update_sprints` / `partial_update_sprints` — nome, date, note; **non** per cambiare stato (vedi "Ciclo di vita" qui sotto).
- `destroy_sprints` — solo se `PLANNED`; su uno sprint ACTIVE/CLOSED torna 409, va chiuso invece di cancellato.

**Ciclo di vita — tool dedicati, non `partial_update_sprints`:**

- `start_sprints` (pk = sprint) — `PLANNED → ACTIVE`. Fallisce se un altro sprint dello
  stesso progetto è già ACTIVE: **un solo sprint attivo per progetto**.
- `close_sprints` (pk = sprint) — `ACTIVE → CLOSED`. I task non-DONE vanno a
  `carry_over_to` (id dello sprint successivo) se passato, altrimenti tornano nel
  product backlog (`sprint=null`).

```
create_sprints(body={"project_id": 7, "name": "Sprint 12", "start_date": "2026-08-10", "end_date": "2026-08-21"})
start_sprints(pk=44)
...
close_sprints(pk=44, body={"carry_over_to": 45})
```

**Spostare i task dentro/fuori sprint** — `move_to_sprint_tasks` (nessun path param):
`task_ids` (lista non vuota, tutti nello stesso progetto) + `sprint_id` (`null` =
backlog). Sposta anche i discendenti dei task passati. Rifiutato su sprint chiusi.

```
move_to_sprint_tasks(body={"task_ids": [1234, 1235], "sprint_id": 44})
```

Per la **board kanban dello sprint** (colonne, non solo "quali task ci sono") — le
lanes — vedi [collaboration.md](collaboration.md): è una famiglia a bassa frequenza, non è
qui.
