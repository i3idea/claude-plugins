# Elenco completo dei tool MCP ProWoDo

Tabella generata dal backend (`grep -oP '^\s{4}"\K[a-z_]+(?=":)' pwd-backend/src/prowodo/core/api/mcp_descriptions.py | sort`) più `assign_user_tasks` / `unassign_user_tasks`, che portano la descrizione inline via `@mcp_tool(description=...)` invece che in `mcp_descriptions.py` e quindi non compaiono in quel grep — **82 tool** in totale. Vedi `SKILL.md` per i nomi nudi vs il prefisso reale del tool (`mcp__plugin_prowodo-tasks_prowodo__...` o equivalente) e per il flusso base.

"Path param" elenca solo i parametri **oltre** all'id della risorsa stessa (che per retrieve/update/partial_update/destroy va comunque passato, tipicamente come `pk`). "—" = nessun path param oltre eventualmente `pk`.

## Company (workspace)

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_companies` | — | Lista le company (workspace) di cui l'utente è membro. |
| `retrieve_companies` | — | Dettaglio di una company per id. |
| `create_companies` | — | Crea una nuova company; l'utente che la crea ne diventa owner. |

## Membri della company

| Tool | Path param | Scopo |
|------|-----------|-------|
| `retrieve_current_user` | — | Profilo dell'utente autenticato (id, username, display name, email) — risolve "io". |
| `list_users` | `company_id` | Lista i membri di una company; supporta `search` su email/username/nome/display name. |
| `retrieve_users` | `company_id` | Dettaglio di un membro della company per id. |

## Progetti

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_projects` | `company_id` | Lista i progetti di una company. Esclude gli archiviati salvo `include_archived=true`. Filtra anche per `id`, `title__icontains`, `description__icontains`, più `search`. |
| `retrieve_projects` | `company_id` | Dettaglio di un progetto per id (inclusi gli archiviati). |
| `create_projects` | `company_id` | Crea un progetto in una company. |
| `update_projects` | `company_id` | Sostituzione completa (PUT) di un progetto — tutti i campi scrivibili richiesti. |
| `partial_update_projects` | `company_id` | Aggiornamento parziale (PATCH) di un progetto. |
| `destroy_projects` | `company_id` | Archivia (soft) il progetto: `is_archivied=true`, non cancellazione fisica. |

## Task — CRUD

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_tasks` | — | Lista i task accessibili all'utente, con filtri ricchi (`project_id`, `sprint`, `search`, date, `has_ticket`, `assignee_id`, ...). |
| `retrieve_tasks` | — | Dettaglio di un task per id. |
| `create_tasks` | — | Crea un task; richiede `project_id`. |
| `update_tasks` | — | Sostituzione completa (PUT) di un task — richiede anche `title`. |
| `partial_update_tasks` | — | Aggiornamento parziale (PATCH) di un task (progress, status, story_points, order, ...). |
| `destroy_tasks` | — | Soft-delete del task; i discendenti non vengono ripromossi automaticamente. |

## Task — ordinamento e gerarchia

| Tool | Path param | Scopo |
|------|-----------|-------|
| `move_up_tasks` | — | Sposta il task di una posizione su tra i fratelli. |
| `move_down_tasks` | — | Sposta il task di una posizione giù tra i fratelli. |
| `move_relative_to_tasks` | — | Posiziona il task subito `before`/`after` un fratello (`related_task_id`). |
| `increase_depth_tasks` | — | Indenta il task come figlio di un altro (`new_parent_id`). |
| `decrease_depth_tasks` | — | Deindenta il task al livello del genitore, opzionalmente dopo `after_task_id`. |
| `reorder_root_tasks` | — | Compatta gli `order` dei task root di un progetto (`project_id` nel body); manutenzione, non accetta liste. |
| `reorder_children_tasks` | — | Compatta gli `order` dei figli diretti di un task (id del genitore come `pk`). |
| `move_to_project_tasks` | — | Sposta il task in un altro progetto/company (`project_id` + `company_id` nel body). |
| `move_to_sprint_tasks` | — | Sposta uno o più task (e discendenti) in uno sprint o nel backlog (`task_ids` + `sprint_id`, null = backlog). |

## Assegnazione utenti sul task

| Tool | Path param | Scopo |
|------|-----------|-------|
| `assign_user_tasks` | — | Aggiunge un utente come assegnatario di un task (`pk` + `body.user_id`); idempotente, rifiuta con 400 se l'utente non è membro della company del task. |
| `unassign_user_tasks` | — | Rimuove un utente dagli assegnatari di un task (`pk` + `body.user_id`); noop-safe, non solleva errore se non era assegnato. |

## Tag

| Tool | Path param | Scopo |
|------|-----------|-------|
| `add_tag_tasks` | — | Applica un tag a un task, per `text` (crea il tag se non esiste) o per `id`. |
| `remove_tag_tasks` | — | Stacca un tag da un task per `id`; no-op se non era attaccato. |
| `list_tasktags` | `company_id` | Lista i tag definiti in una company. |
| `retrieve_tasktags` | `company_id` | Dettaglio di un tag per id. |
| `create_tasktags` | `company_id` | Crea un tag nella company (campo `text`). |
| `update_tasktags` | `company_id` | Sostituzione completa (PUT) di un tag. |
| `partial_update_tasktags` | `company_id` | Rinomina o aggiorna parzialmente un tag. |
| `destroy_tasktags` | `company_id` | Elimina un tag dalla company; i task che lo usavano perdono l'associazione. |

## Commenti sui task

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_taskcomments` | `task_id` | Thread dei commenti di un task. |
| `retrieve_taskcomments` | `task_id` | Dettaglio di un commento per id. |
| `create_taskcomments` | — (**`task_id` va nel body**, non nel path — eccezione rispetto agli altri tool di questa famiglia) | Aggiunge un commento; autore = utente autenticato. `comment_id` opzionale per rispondere a un commento esistente. |
| `destroy_taskcomments` | `task_id` | Soft-delete (nasconde) un commento; non è una cancellazione fisica. |

## Allegati (company/progetto)

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_attachments` | `company_id` | Lista cosa è attaccato a una company o a un suo progetto (`project_id` per filtrare, `project_id__isnull=true` per i soli allegati di company). |
| `retrieve_attachments` | `company_id` | Dettaglio di un allegato: titolo, `kind` (file/link), autore, `url` (signed, scade in 15 minuti per i file). |
| `create_attachments` | `company_id` | Crea un allegato: esattamente uno tra `text`, `content_base64` (+`content_type`) o `link`; `project_id` opzionale (omesso = allegato di company); contenuto inline max 4MB. |
| `destroy_attachments` | `company_id` | Soft-delete di un allegato della company. |

Non esistono `update_attachments`/`partial_update_attachments`: un allegato si sostituisce (cancella + ricrea), non si modifica.

## Allegati sul task (sola lettura via MCP)

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_taskattachments` | `task_id` | Lista i file allegati a un task (nome, size, url). Upload solo dall'app. |
| `retrieve_taskattachments` | `task_id` | Metadati e url di download di un singolo allegato task. |

## Reminder

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_reminders` | `task_id` | Lista i reminder di un task, ordinati per orario. |
| `retrieve_reminders` | `task_id` | Dettaglio di un reminder per id. |
| `create_reminders` | `task_id` | Crea un reminder (`remind_at` obbligatorio, `text`, canali `send_push`/`send_email`/`send_telegram`, `recipient_id` opzionale = assegnatari). |
| `update_reminders` | `task_id` | Sostituzione completa (PUT) di un reminder. |
| `partial_update_reminders` | `task_id` | Aggiornamento parziale (PATCH) di un reminder. |
| `destroy_reminders` | `task_id` | Elimina un reminder dal task. |
| `list_all_reminders` | — | Reminder di **tutti** i task dell'utente (es. "cosa scatta oggi"), non scoped a un task. Filtra per `remind_at` e `is_sent`. |

## Dipendenze tra task

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_taskdependencies` | `company_id`, `project_id` | Lista le dipendenze di schedulazione di un progetto. Passa `task` per avere solo quelle che toccano un task, da entrambi i versi (chi lo blocca e chi ne dipende); senza, torna il grafo intero. |
| `retrieve_taskdependencies` | `company_id`, `project_id` | Dettaglio di una dipendenza per id. |
| `create_taskdependencies` | `company_id`, `project_id` | Collega due task dello stesso progetto (`dependency_type` FS/SS/FF/SF, `lag_days`); rifiutata (400) su self-link, cross-project, antenato/discendente, ciclo. |
| `update_taskdependencies` | `company_id`, `project_id` | Sostituzione completa (PUT) di una dipendenza — richiede predecessor, successor, dependency_type, lag_days. |
| `partial_update_taskdependencies` | `company_id`, `project_id` | Cambia `dependency_type` o `lag_days`; ripropaga lo scheduling del successor. |
| `destroy_taskdependencies` | `company_id`, `project_id` | Rimuove una dipendenza; non riporta indietro le date già spostate in avanti. |

## Sprint

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_sprints` | — | Lista gli sprint dei progetti delle company dell'utente; filtra per `state` (PLANNED\|ACTIVE\|CLOSED) e per `project_id` (per restringere a un singolo progetto). |
| `retrieve_sprints` | — | Dettaglio di uno sprint per id. |
| `create_sprints` | — | Crea uno sprint (`project_id` nel body); nasce in stato PLANNED. |
| `update_sprints` | — | Sostituzione completa (PUT) di uno sprint. |
| `partial_update_sprints` | — | Aggiornamento parziale (PATCH) di uno sprint (nome, date pianificate, note); **non** per le transizioni di stato. |
| `destroy_sprints` | — | Elimina uno sprint; solo se PLANNED, altrimenti 409 (va chiuso). |
| `start_sprints` | — | Transizione PLANNED → ACTIVE; fallisce se un altro sprint del progetto è già ACTIVE. |
| `close_sprints` | — | Transizione ACTIVE → CLOSED; i task non-DONE vanno a `carry_over_to` o tornano nel backlog se omesso. |

## Lanes della board sprint

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_sprint_lanes` | — | Lista le lane (task → colonna board) di uno sprint. **Passa sempre `sprint_id`**: senza, torna le lane di tutti gli sprint di tutte le company, e non scatta il backfill delle lane mancanti. Accetta anche `task_id`. Vedi `references/collaboration.md`. |
| `retrieve_sprint_lanes` | — | Dettaglio di una lane per id. |
| `move_sprint_lanes` | — | Sposta una lane in un'altra colonna (`project_task_status_id`, null = colonna "Incoming"); non muovibile su sprint chiusi. |

## Ticket

| Tool | Path param | Scopo |
|------|-----------|-------|
| `retrieve_ticketsubmissions` | — | Metadati di intake di un ticket (submitter, widget, data). Il ticket stesso è un Task: per il dettaglio/triage usa i tool task. |
| `list_ticketcomments` | `submission_id` | Thread dei commenti di un ticket, dal più vecchio. |
| `retrieve_ticketcomments` | `submission_id` | Dettaglio di un commento ticket per id. |
| `create_ticketcomments` | `submission_id` | Aggiunge un commento; default `is_internal=true` (solo team) — passa `is_internal=false` per renderlo visibile al cliente. |
| `destroy_ticketcomments` | `submission_id` | Soft-delete (nasconde) un commento ticket. |

## Resume entry (piano/fatto giornaliero)

| Tool | Path param | Scopo |
|------|-----------|-------|
| `list_resumeentries` | `company_id` | Lista le resume entry di una company; filtra per `kind` (plan\|done), range date, `user_id`. |
| `retrieve_resumeentries` | `company_id` | Dettaglio di una resume entry per id. |
| `create_resumeentries` | `company_id` | Crea una entry (`kind`, `date_from`/`date_to`, `note`, `tasks` collegati opzionali). |
| `update_resumeentries` | `company_id` | Sostituzione completa (PUT) di una entry. |
| `partial_update_resumeentries` | `company_id` | Aggiornamento parziale (PATCH) di una entry. |
| `destroy_resumeentries` | `company_id` | Soft-delete di una entry. |

---

Per i flussi ad alta frequenza (commenti, allegati, dipendenze, sprint, `list_all_reminders`) con esempi di chiamata, vedi `SKILL.md`. Per ticket/resume entry/tag-CRUD/progetti-CRUD/lanes con esempi, vedi `references/collaboration.md`.
