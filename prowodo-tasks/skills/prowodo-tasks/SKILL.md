---
name: prowodo-tasks
description: Use whenever the user mentions tasks, planning, todo, backlog, sprint, story points, scrum, grooming, planning poker, or asks to log/create/manage/plan/review tasks. ProWoDo is the single source of truth for task management and planning. Trigger on "segna", "crea task", "aggiungi task", "traccia", "todo", "cose da fare", "pianifica", "backlog", "sprint", "story point", "stima", "scrum", "cosa c'è da fare", "cosa devo fare", "dimmi i task", "mostrami i task", "check tasks", "what do I need to do", or equivalents in any language. Also on reminders ("reminder", "promemoria", "ricordami", "avvisami", "remind me", "scadenza") and on notes / second brain / knowledge base ("nota", "appunti", "second brain", "knowledge base", "salva questa decisione", "segnati che", "dove ne abbiamo parlato", "cosa sappiamo su", "what do we know about", "save this as a note"). Also proactively at the end of a working session, to suggest logging completed or upcoming work.
---

# ProWoDo — Task Management & Planning

ProWoDo è il sistema centrale per task, planning e backlog. Usalo **sempre** per:
- Creare task da fare
- Vedere cosa c'è in backlog
- Pianificare il lavoro (sprint, priorità, ordine)
- Segnare task completati o in corso
- Organizzare il lavoro per progetto
- Tracciare avanzamento (progress %)

## I tool MCP: nomi e prefisso

Questa skill cita i tool con il **nome nudo** (`list_tasks`, `create_tasks`, ...). Il
prefisso reale **dipende da come il server ProWoDo è connesso** e non è sotto il
controllo della skill:

| Come è connesso | Nome reale del tool |
|-----------------|---------------------|
| MCP incluso nel plugin (default) | `mcp__plugin_prowodo-tasks_prowodo__list_tasks` |
| `claude mcp add ... prowodo` (manuale) | `mcp__prowodo__list_tasks` |
| Connector claude.ai | `mcp__claude_ai_Prowodo__list_tasks` |

**Non assumere un prefisso: guarda i tool effettivamente disponibili in sessione e
usa quello che finisce col nome giusto.** Se una stessa installazione ha più di una
di queste connessioni attive, vedrai **due set equivalenti** di tool — usane uno solo
e resta coerente per tutta la sessione.

Se non trovi **nessun** tool ProWoDo, il server non è autenticato: di' all'utente di
lanciare `/mcp` e completare il login OAuth nel browser. Non ripiegare su `curl`.

## Flusso base

1. **Controlla la memoria di progetto** (`prowodo_defaults.md` nella memory dir corrente — vedi [references/project-defaults.md](references/project-defaults.md)). Se esiste, usa company/project/scrum come default.
2. Altrimenti **lista le company** con `list_companies` e **i progetti** con `list_projects` (passa `company_id`). **Controlla il campo `is_archivied`** (sic, typo backend) su ogni progetto: non proporre progetti archiviati come destinazione e non scriverci task. Se l'unico match è archiviato, segnalalo all'utente e chiedi un'alternativa.
3. Quando hai capito company + project + se l'utente usa scrum, **proponi di salvarlo in memoria** (vedi [references/project-defaults.md](references/project-defaults.md)) per evitare di richiederlo ogni volta.
4. Agisci in base all'intenzione dell'utente (vedi l'"Indice degli scenari" sotto).

**Operazioni di sola lettura** (list, retrieve): eseguile direttamente senza chiedere conferma.
**Operazioni di scrittura singola** (crea/aggiorna/sposta 1 task): eseguile direttamente senza chiedere conferma.
**Operazioni massive** (modifica/crea/elimina 5+ task in una volta): chiedi conferma prima.

## Link alla piattaforma

Quando riporti un task, un progetto, uno sprint, un commento, un reminder, un allegato o una dipendenza, **includi sempre `app_url`** come link cliccabile — è un campo read-only esposto dal serializer proprio per questo.

**Non costruire mai a mano la URL di un task (o di un progetto/sprint/...).** Il campo esiste apposta perché il payload da solo non basta a comporla correttamente: usa sempre `app_url` così com'è.

Cose da sapere sui link:
- Un task apre il drawer del task. Commenti, reminder, allegati task e dipendenze **non hanno una pagina propria** — il loro `app_url` punta al drawer del task padre (per una dipendenza, al **successore**, cioè il task bloccato). Il frontend apre il drawer solo via `?taskId=`: **non esistono tab indirizzabili**, quindi non puoi linkare direttamente al tab dei commenti.
- Un progetto ha `app_url` che punta a `/{company}/{project}/dashboard`. Le altre viste condividono la stessa base `/{company}/{project}/`: `tasks/list`, `board`, `backlog`, `matrix`, `tasks/timeline`, `sprints`, `attachments`, `scoring`. Quando usarle: prioritizzazione → `matrix`, pianificazione temporale → `tasks/timeline`, sprint in corso → `board`, ricerca/albero → `tasks/list`. Task e sprint portano anche `company_id`, quindi puoi comporre tu stesso queste URL di vista quando serve.
- **La timeline è gated sul piano** (`featureGuard('gantt')`): a chi non ha Gantt nel piano quel link apre la pagina di billing con un toast di upgrade. Non proporla come default — solo se l'utente chiede esplicitamente la vista timeline/Gantt.
- Una ticket submission porta **due** link distinti: `app_url` (INTERNO, per il team) e `public_url` (`/t/{uuid}`, PUBBLICO — la pagina che vede chi ha aperto il ticket). **Non confonderli**: dare l'`app_url` interno a un cliente è esattamente l'errore che questa distinzione serve a evitare. `public_url` va condiviso con chi ha aperto il ticket, `app_url` resta interno al team.

## Indice degli scenari

Il flusso base e le regole sono qui sotto. Il dettaglio di ogni scenario sta in un file
dedicato: aprilo **solo** quando l'utente tocca quell'argomento.

| Se l'utente vuole… | Apri |
|--------------------|------|
| Cercare task per testo ("ci sono task su Y?") · assegnare a qualcuno · "cosa devo fare io" | [references/search-and-assign.md](references/search-and-assign.md) |
| Un promemoria / "ricordami" · "che reminder ho oggi?" | [references/reminders.md](references/reminders.md) |
| Salvare o ritrovare conoscenza (note, "dove ne abbiamo parlato?", revisione note) | [references/notes.md](references/notes.md) |
| Commentare un task o leggerne il thread | [references/comments.md](references/comments.md) |
| Allegare file/testo/link a progetto, company o task | [references/attachments.md](references/attachments.md) |
| Vincoli "X non parte finché Y non finisce" | [references/dependencies.md](references/dependencies.md) |
| Riordinare · stimare (story points) · prioritizzare (ICE/RICE) | [references/ordering-and-estimation.md](references/ordering-and-estimation.md) |
| Sprint, Scrum, chiusura sprint | [references/sprints.md](references/sprints.md) |
| Default di company/progetto per la cwd | [references/project-defaults.md](references/project-defaults.md) |
| Errori strani dell'API, progetti archiviati, spostare un task di progetto | [references/gotchas.md](references/gotchas.md) |
| Ticket, resume entry, tag, CRUD progetti, lanes | [references/collaboration.md](references/collaboration.md) |
| Nome esatto di un tool (elenco completo dei 97) | [references/tools.md](references/tools.md) |

## Scenari rapidi

### "Cosa c'è da fare?" / Backlog / Planning
Usa `list_tasks` per mostrare i task aperti del progetto. Presenta in modo leggibile: nome, priorità, progress %, assegnatario se presente.

### "Aggiungi un task" / "Segna che devo fare X"
Usa `create_tasks`. Chiedi il progetto se non specificato.

### Stati del task (`status`)

Il campo `status` ha **quattro valori**: `BACKLOG`, `TODO`, `IN_PROGRESS`, `DONE`. Usalo per riflettere dove si trova il task nel flusso di lavoro, non solo per marcarlo finito — es. quando l'utente dice "ci sto lavorando" o "inizio X", porta il task a `IN_PROGRESS` con `partial_update_tasks(status: "IN_PROGRESS")` (vedi anche la nota su IN_PROGRESS e assegnatari in [references/search-and-assign.md](references/search-and-assign.md)).

### "Ho finito X" / "Segna come completato"
Usa `partial_update_tasks` con questi campi insieme: `is_completed: true, progress: 100, status: "DONE"`. Il backend tratta i tre "segnali done" come invariante (vedi `Task.save()` in `core.models`) — settandone uno solo, gli altri vengono comunque sincronizzati, ma esplicitare tutti e tre rende l'intent chiaro e indipendente da future modifiche al backend.

**Aggiornare anche la description con un riassunto di cosa è stato fatto** è una buona pratica quando il task è non-banale: aiuta a riprendere il contesto in futuro. Limite hard: la description ha **max 4096 caratteri** (HTTP 400 oltre, con field-level error message). Se serve narrare molto, splitta in un commento sul task o linka allo spec/plan in `docs/superpowers/`.

### Aggiornare l'avanzamento / "Sono al 50% su X"
Usa `partial_update_tasks` con il campo `progress` (0–100).
Mostra sempre il progress % nei riepiloghi quando è > 0.

### "Pianifichiamo il prossimo sprint" / Prioritizzazione
Lista i task aperti, poi aiuta l'utente a ordinarli per priorità o a spostarli con i tool di riordino.
Se per il progetto è attivo il workflow Scrum (vedi [references/sprints.md](references/sprints.md)), proponi anche di assegnare i task a uno sprint con `move_to_sprint_tasks` e di stimarli con `story_points` (vedi [references/ordering-and-estimation.md](references/ordering-and-estimation.md)).

### Fine sessione di lavoro
Se hai completato del lavoro significativo, proponi di registrare i task completati o creare task per il follow-up in ProWoDo.

## Task interni creati da superpowers (TaskCreate)

Claude Code usa il tool `TaskCreate` / `TaskUpdate` per tracciare il proprio lavoro interno durante l'esecuzione di skill (es. superpowers, feature-dev). Questi task interni **non vanno su ProWoDo** — esistono solo nella sessione corrente.

**Usa ProWoDo** per task del progetto utente (feature, bug, backlog).
**Usa TaskCreate** per step interni di una sessione di lavoro (es. checklist di una skill).

Quando l'utente chiede "cosa hai fatto?" o "aggiorna i task", aggiorna i task ProWoDo rilevanti con progress e stato, non i task interni.

## Tool disponibili

| Azione | Tool |
|--------|------|
| Lista company | `list_companies` |
| Lista progetti | `list_projects` |
| Lista task | `list_tasks` |
| Dettaglio task | `retrieve_tasks` |
| Crea task | `create_tasks` |
| Aggiorna task | `partial_update_tasks` |
| Sposta su/giù | `move_up_tasks` / `move_down_tasks` |
| Sposta in progetto | `move_to_project_tasks` |
| Riordina root | `reorder_root_tasks` |
| Aggiungi tag | `add_tag_tasks` |
| Sotto-task (indent) | `increase_depth_tasks` / `decrease_depth_tasks` |
| Cerca conoscenza (task+commenti+note) | `search_knowledge` |
| Note (CRUD + ricerca) | `list_notes` / `retrieve_notes` / `create_notes` / `partial_update_notes` / `destroy_notes` (cestino) / `search_notes` |
| Cestino, versioni, link delle note | `trashed_notes` / `restore_notes` / `history_notes` / `revert_notes` / `links_notes` |
| Lista utenti company | `list_users` (path: `company_id`, supporta `search`) |
| Dettaglio utente | `retrieve_users` |
| Utente corrente ("io") | `retrieve_current_user` (nessun parametro) |
| Assegna utente a task | `assign_user_tasks` (`pk` + `body.user_id`, idempotente) |
| Rimuovi utente da task | `unassign_user_tasks` (`pk` + `body.user_id`, noop-safe) |
| Lista reminder di un task | `list_reminders` (path: `task_id`) |
| Crea reminder | `create_reminders` (path: `task_id` + body) |
| Aggiorna reminder | `partial_update_reminders` |
| Elimina reminder | `destroy_reminders` |

## Parametri minimi per creare un task

```
title: "titolo del task"   # obbligatorio
project_id: <id>           # obbligatorio (default dalla memoria di progetto se presente)
description: "..."         # opzionale
progress: 0–100            # opzionale, default 0
story_points: 1|2|3|5|8|13 # opzionale, consigliato (vedi references/ordering-and-estimation.md)
parent_id: <id>            # opzionale, per sotto-task
```

## Documentazione di riferimento

Questo file copre il flusso base; i dettagli sono divisi per argomento (vedi
"Indice degli scenari" sopra) per non caricarli in ogni sessione. Il backend espone
**97 tool MCP** in totale:

- **[references/tools.md](references/tools.md)** — tabella completa di tutti i 97 tool,
  raggruppati per famiglia, con path param richiesti e una frase di scopo per ciascuno.
  Aprilo quando ti serve il nome esatto di un tool che non ricordi.
- **[references/collaboration.md](references/collaboration.md)** — le famiglie a bassa
  frequenza con "quando serve" ed esempio: ticket (`retrieve_ticketsubmissions`,
  `*_ticketcomments`, flag `is_internal`), resume entry (piano/fatto giornaliero), CRUD
  tag oltre `add_tag_tasks`/`remove_tag_tasks`, CRUD progetti, lanes della board sprint.
  Aprilo solo quando l'utente chiede esplicitamente una di queste cose.

## Regole

- **Lettura e scrittura singola**: esegui senza chiedere conferma
- **Operazioni massive (5+)**: chiedi conferma con riepilogo di cosa verrà fatto
- Se l'utente non specifica il progetto, mostra i progetti disponibili e chiedi
- Dopo ogni operazione mostra un riepilogo conciso (nome task, ID, stato, progress %)
- Preferisci aggiornare task esistenti piuttosto che crearne di nuovi duplicati
- Quando mostri task con progress > 0, visualizza sempre la percentuale
