---
name: prowodo-tasks
description: Use this skill whenever the user mentions tasks, planning, todo, things to do, work to track, backlog, sprint, story points, scrum, grooming, planning poker, checking what needs to be done, or asks to log/create/manage/plan/review tasks. ProWoDo is the single source of truth for all task management and planning. Trigger on any mention of "segna", "crea task", "aggiungi task", "traccia", "todo", "cose da fare", "planning", "pianifica", "backlog", "sprint", "story point", "punti", "stima", "scrum", "grooming", "cosa c'è da fare", "cosa devo fare", "cosa ho da fare", "dimmi i task", "mostrami i task", "check tasks", "what do I need to do", or equivalent in any language. Trigger also on reminder mentions: "reminder", "promemoria", "ricordami", "ricordarmi", "avvisami", "remind me", "set a reminder", "scadenza". Also trigger proactively at the end of a working session to suggest logging completed or upcoming work.
---

# ProWoDo — Task Management & Planning

ProWoDo è il sistema centrale per task, planning e backlog. Usalo **sempre** per:
- Creare task da fare
- Vedere cosa c'è in backlog
- Pianificare il lavoro (sprint, priorità, ordine)
- Segnare task completati o in corso
- Organizzare il lavoro per progetto
- Tracciare avanzamento (progress %)

## Flusso base

1. **Controlla la memoria di progetto** (`prowodo_defaults.md` nella memory dir corrente — vedi sezione "Defaults di progetto in memoria"). Se esiste, usa company/project/scrum come default.
2. Altrimenti **lista le company** con `mcp__prowodo__list_companys` e **i progetti** con `mcp__prowodo__list_projects` (passa `company_id`). **Controlla il campo `is_archivied`** (sic, typo backend) su ogni progetto: non proporre progetti archiviati come destinazione e non scriverci task. Se l'unico match è archiviato, segnalalo all'utente e chiedi un'alternativa.
3. Quando hai capito company + project + se l'utente usa scrum, **proponi di salvarlo in memoria** (vedi sezione apposita) per evitare di richiederlo ogni volta.
4. Agisci in base all'intenzione dell'utente (vedi sezioni sotto).

**Operazioni di sola lettura** (list, retrieve): eseguile direttamente senza chiedere conferma.
**Operazioni di scrittura singola** (crea/aggiorna/sposta 1 task): eseguile direttamente senza chiedere conferma.
**Operazioni massive** (modifica/crea/elimina 5+ task in una volta): chiedi conferma prima.

## Scenari d'uso

### "Cosa c'è da fare?" / Backlog / Planning
Usa `mcp__prowodo__list_tasks` per mostrare i task aperti del progetto. Presenta in modo leggibile: nome, priorità, progress %, assegnatario se presente.

### "Cerca task su X" / "Ci sono task che riguardano Y?"
`list_tasks` espone **tre filtri testuali distinti** — usano index diversi, non sono intercambiabili:

| Parametro | Tipo di match | Index |
|-----------|---------------|-------|
| `search` | **fuzzy trigram similarity** su titolo + descrizione, soglia 0.2, ordinato per similarity desc | GIN su trigrammi (`pg_trgm`) |
| `title__icontains` | substring case-insensitive solo nel titolo | b-tree / varchar_pattern_ops (o sequential scan) |
| `description__icontains` | substring case-insensitive solo nella descrizione | stesso tipo |

**Implicazioni pratiche:**
- `search` tollera **typo, parole abbreviate, ordine diverso** (es. "clodbuild" trova "cloudbuild"), ma **scarta** i match con similarity < 0.2 → keyword troppo corte o diverse dal testo vengono filtrate.
- `title__icontains` / `description__icontains` sono **letterali**: la stringa deve comparire tale e quale (case-insensitive). Non gestiscono typo ma non filtrano per threshold.

**Strategia consigliata** per una ricerca completa:
1. Parti da `search=<keyword>` → cattura la maggior parte (inclusi typo) con i più rilevanti in cima.
2. Se i risultati sembrano pochi, ripeti con `description__icontains=<keyword>` (e/o `title__icontains`) per pescare task dove la keyword compare letteralmente ma con similarity < 0.2 (es. frasi lunghe dove la keyword è una parola tra tante).
3. Combina sempre con `project_id`, `is_completed=false`, `parent_id` per restringere lo scope.

Non esiste un tool di ricerca separato — tutto passa da `list_tasks` con parametri diversi.

### "Aggiungi un task" / "Segna che devo fare X"
Usa `mcp__prowodo__create_tasks`. Chiedi il progetto se non specificato.

### "Assegna X a Y" / "Chi è assegnato a Z?"

**Disponibile dal backend `8489763` (2026-05-26) / `@prowodo/angular-client@1.2.0`.**

Per assegnare un task a un utente:

1. Risolvi il nome utente in `user_id` con `mcp__prowodo__list_users` (path param: `company_id`). Lo viewset supporta search via `search_fields` su email/username/first_name/last_name/display_name/identity_email — passa la stringa di ricerca come parametro `search` se l'utente cita un nome libero ("Ivan").
2. Chiama `mcp__prowodo__task_assign_user` con `pk=<task_id>` e `body={"user_id": <id>}`. È **idempotente** — chiamarlo due volte non crea duplicati né errore.
3. Per rimuovere: `mcp__prowodo__task_unassign_user` con stesso shape. Ritorna `{"unassigned": true|false}`. **Noop-safe** — chiamarlo su un'assegnazione che non esiste non solleva errore.

**Sicurezza:** il backend rifiuta con 400 se `user_id` punta a un utente NON membro della company del task (cross-tenant). Niente leak.

**Per vedere chi è assegnato a un task:** il `Task` serializer espone già la lista degli assegnatari nel campo `users`/`task_assignements` — basta `retrieve_tasks(pk=<id>)`. Non serve una chiamata separata.

Esempio flow tipico — "Assegna il task #1234 a Ivan":
```
1. list_users(company_id=1, search="Ivan")
   → [{id: 42, display_name: "Ivan Bettarini", ...}]
2. task_assign_user(pk=1234, body={user_id: 42})
   → 201 {id: ..., task_id: 1234, user_id: 42}
```

Se la search ritorna più match, mostrali all'utente e chiedi disambiguazione prima di assegnare.

### "Ricordami X" / "Metti un reminder" / Reminder sui task

**Live in prod dal 2026-07-01.** Ogni task può avere **N reminder** temporizzati, consegnati su più canali (notifica push, email, Telegram). Uno scheduler backend pesca i reminder dovuti ogni minuto, li invia ai destinatari e marca `is_sent`.

- **Creare**: `mcp__prowodo__create_reminders` con `task_id` (path) + body:
  - `remind_at` — datetime ISO, **obbligatorio** (quando scatta)
  - `text` — messaggio del reminder
  - `recipient_id` — opzionale; se omesso i destinatari sono gli **assegnatari correnti del task**. Deve essere un membro della company del task.
  - `send_push` / `send_email` / `send_telegram` — canali; **almeno uno true** (default: solo push)
  - `notify_if_completed` — default false; se true parte anche quando il task è già DONE
- **Listare**: `mcp__prowodo__list_reminders` con `task_id` (ogni reminder espone `is_sent`).
- **Aggiornare / eliminare**: `mcp__prowodo__partial_update_reminders` / `mcp__prowodo__destroy_reminders`.

Esempio — "ricordami di rivedere questo task domani alle 9":
```
create_reminders(task_id=1234, body={
  "remind_at": "2026-07-02T09:00:00Z",
  "text": "Rivedi il task",
  "send_push": true
})
```

Consiglia di impostare i reminder quando l'utente dice "ricordami", "avvisami", "metti un promemoria" o cita una scadenza su un task specifico.

### "Ho finito X" / "Segna come completato"
Usa `mcp__prowodo__partial_update_tasks` con questi campi insieme: `is_completed: true, progress: 100, status: "DONE"`. Il backend tratta i tre "segnali done" come invariante (vedi `Task.save()` in `core.models`) — settandone uno solo, gli altri vengono comunque sincronizzati, ma esplicitare tutti e tre rende l'intent chiaro e indipendente da future modifiche al backend.

**Aggiornare anche la description con un riassunto di cosa è stato fatto** è una buona pratica quando il task è non-banale: aiuta a riprendere il contesto in futuro. Limite hard: la description ha **max 4096 caratteri** (HTTP 400 oltre, con field-level error message). Se serve narrare molto, splitta in un commento sul task o linka allo spec/plan in `docs/superpowers/`.

### Aggiornare l'avanzamento / "Sono al 50% su X"
Usa `mcp__prowodo__partial_update_tasks` con il campo `progress` (0–100).
Mostra sempre il progress % nei riepiloghi quando è > 0.

### "Sposta X prima di Y" / Riordinare
Per spostamenti singoli usa `mcp__prowodo__move_up_tasks` / `mcp__prowodo__move_down_tasks`. Per spostare un task in posizione precisa o riordinare in massa usa `partial_update_tasks` con il campo `order`.

**Comportamento critico del backend (verificato 2026-05-22):** dopo ogni `partial_update_tasks` il backend chiama `Task.reorder()` che **renormalizza tutti gli order del livello** sequenzialmente (0, 1, 2, ...) ordinando per `(order ASC, id ASC)`. Implicazioni:

- Setting `order=200` su un task NON lo mette a posizione 200: lo mette in fondo (o vicino), perché la renormalizzazione lo abbassa al "first free position" dopo i task con order più basso.
- Setting `order=0` su un task lo porta in cima — gli altri vengono bumpati di 1.
- Gap grandi (10, 20, 30) NON sono preservati: dopo il primo `partial_update` di un altro task, vengono compattati.

**Pattern raccomandato per riordino massivo** (es. ribilanciare 50+ task per priorità):
1. Costruisci la lista nell'ordine finale desiderato in memoria.
2. Itera dall'inizio alla fine: per ogni task in posizione `i`, chiama `partial_update_tasks(order=i)` (interi consecutivi 0,1,2,...).
3. Eseguili in serie (un batch parallelo va comunque bene, l'ultimo renormalize vince), e accetta che valori esatti possano essere coerciti — quel che conta è l'ordine relativo.
4. Se due task collidono su uno stesso order, il tiebreak è `id ASC` — se non va bene, fai una seconda passata bumpando il task che vuoi più in alto a `order=i-1` (lo sposta sopra).

Per il task `reorder_root_tasks`: chiama solo `Task.reorder(project_id, parent_id=None)` con solo `project_id` nel body — è un cleanup che compatta gli order, non accetta liste di IDs.

### "Pianifichiamo il prossimo sprint" / Prioritizzazione
Lista i task aperti, poi aiuta l'utente a ordinarli per priorità o a spostarli con i tool di riordino.
Se per il progetto è attivo il workflow Scrum (vedi sezione "Sprint / Scrum"), proponi anche di assegnare i task a uno sprint con `move_to_sprint_tasks` e di stimarli con `story_points` (vedi sotto).

## Story points e decomposizione

Quando crei o aggiorni un task **consiglia** (senza imporlo) la stima in story_points. È utile per:
- avere un'idea della dimensione del lavoro prima di partire
- decidere se il task va spezzato in sotto-task più piccoli
- riempire uno sprint senza overcommit

**Scala consigliata** (Fibonacci-like): `1, 2, 3, 5, 8, 13, 21`. Significato indicativo:
- `1–3` → mezza giornata o meno, pronto da fare
- `5` → ~1 giorno, scope chiaro
- `8` → ~2 giorni, ancora gestibile come task singolo
- `13+` → **troppo grande**, da decomporre

**Cap di decomposizione** (default sensato, override-abile dall'utente):
- Se un task ha `story_points >= 8` → suggerisci di **spezzarlo in sotto-task** ognuno ≤ 5 punti, usando `create_tasks` con `parent_id` e/o `increase_depth_tasks`.
- Somma indicativa dei figli ≈ stima del padre (non vincolante, è una sanity check).
- Per task root rimasti senza stima dopo la conversazione, **non bloccare** l'utente: crea il task lo stesso e segnala "valuta se aggiungere story_points".

**Quando NON insistere sui punti:**
- Task amministrativi/operativi rapidi (inviare email, prenotare call): l'overhead di stimarli supera il valore
- L'utente ha già detto che non usa stime su quel progetto (rispetta il default in memoria, vedi sotto)

## Sprint / Scrum (opzionale, non obbligatorio)

Non tutti i progetti seguono Scrum. La modalità è una **preferenza per progetto**, registrata in memoria (`uses_scrum: true|false`). Quando è attiva, valgono questi flussi aggiuntivi:

- **Pianificazione sprint**: prima dell'inizio sprint, lista i task del backlog (`list_tasks` con `sprint__isnull=true`), aiuta a stimarli con `story_points`, poi spostali nello sprint con `move_to_sprint_tasks`.
- **Durante lo sprint**: `list_tasks` con `sprint=<id>` mostra il contenuto dello sprint attivo.
- **Chiusura**: a fine sprint i task non DONE possono essere portati nello sprint successivo o restituiti al backlog.

Quando l'utente NON usa Scrum (o non lo ha indicato in memoria) **non menzionare mai** sprint/grooming/velocity in modo proattivo: stai sul workflow base (backlog, priorità, ordine).

I tool MCP per gestire sprint dal lato agente (`list_sprints`, `start_sprints`, `close_sprints`, `move_to_sprint_tasks`, `move_sprint_lanes`, ...) saranno disponibili dopo il deploy della relativa feature backend. Se non li trovi nella lista tool, gestisci sprint chiedendo all'utente di farlo dall'UI e limita la skill al backlog/task.

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
| Lista company | `mcp__prowodo__list_companys` |
| Lista progetti | `mcp__prowodo__list_projects` |
| Lista task | `mcp__prowodo__list_tasks` |
| Dettaglio task | `mcp__prowodo__retrieve_tasks` |
| Crea task | `mcp__prowodo__create_tasks` |
| Aggiorna task | `mcp__prowodo__partial_update_tasks` |
| Sposta su/giù | `mcp__prowodo__move_up_tasks` / `mcp__prowodo__move_down_tasks` |
| Sposta in progetto | `mcp__prowodo__move_to_project_tasks` |
| Riordina root | `mcp__prowodo__reorder_root_tasks` |
| Aggiungi tag | `mcp__prowodo__add_tag_tasks` |
| Sotto-task (indent) | `mcp__prowodo__increase_depth_tasks` / `mcp__prowodo__decrease_depth_tasks` |
| Lista utenti company | `mcp__prowodo__list_users` (path: `company_id`, supporta `search`) |
| Dettaglio utente | `mcp__prowodo__retrieve_users` |
| Assegna utente a task | `mcp__prowodo__task_assign_user` (`pk` + `body.user_id`, idempotente) |
| Rimuovi utente da task | `mcp__prowodo__task_unassign_user` (`pk` + `body.user_id`, noop-safe) |
| Lista reminder di un task | `mcp__prowodo__list_reminders` (path: `task_id`) |
| Crea reminder | `mcp__prowodo__create_reminders` (path: `task_id` + body) |
| Aggiorna reminder | `mcp__prowodo__partial_update_reminders` |
| Elimina reminder | `mcp__prowodo__destroy_reminders` |

## Parametri minimi per creare un task

```
title: "titolo del task"   # obbligatorio
project_id: <id>           # obbligatorio (default dalla memoria di progetto se presente)
description: "..."         # opzionale
progress: 0–100            # opzionale, default 0
story_points: 1|2|3|5|8|13 # opzionale, consigliato (vedi sezione apposita)
parent_id: <id>            # opzionale, per sotto-task
```

## Defaults di progetto in memoria

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
- All'inizio di ogni sessione che riguarda task/planning, **prima** di chiamare `list_companys` / `list_projects`, leggi il file (se esiste) e procedi direttamente con i default.
- **Verifica che il progetto di default non sia archiviato** prima di scriverci: una `list_projects` (o `retrieve_projects` se disponibile) e controllo di `is_archivied`. Se lo è, avvisa l'utente e chiedi un'alternativa attiva invece di operare silenziosamente.
- I default **non sono vincolanti**: se l'utente cita un altro progetto/company nella conversazione, segui quello senza chiedere e senza modificare la memoria. Aggiorni la memoria solo se l'utente dice esplicitamente "cambia il progetto di default" / "ora lavoro su X".
- Se `uses_scrum=false`, non proporre flussi sprint/grooming/punti in modo proattivo. Se `uses_scrum=true`, applica le sezioni "Story points" e "Sprint / Scrum".

## Gotcha tecnici dell'API (verificati 2026-05-22)

Cose che NON sono ovvie dalla descrizione dei tool MCP e ti costano tempo se le scopri sul momento:

### `partial_update_tasks` richiede `title` nel body anche per update parziali

Lo schema MCP marca `title` come required nel body anche se stai cambiando solo `order`, `progress`, `is_completed`, o un tag. Se ometti `title`, ricevi un 400. Workaround: passa sempre il title originale (puoi leggerlo prima con `retrieve_tasks` se non lo hai in cache, oppure passalo come parametro se l'hai già).

### `description` ha cap a 4096 caratteri

L'API rifiuta description più lunghe con `400 {"description": ["Ensure this field has no more than 4096 characters."]}`. Se devi narrare di più, linka a spec/plan esterni o usa commenti sul task (separati). Splitta sezioni mantenendo gli ancoraggi essenziali.

### Tag orfani da altre company non sono rimovibili

A volte un task ha un tag con `company` diverso da quella corrente (residuo di refactor passati o errore di assegnazione). `remove_tag_tasks` rifiuta con `"tag not in this company"`. Workaround: lascialo, non bloccare il flusso, eventualmente aggiungi i tag corretti della company corrente sopra. Segnalalo all'utente come "tag orfano da pulire eventualmente lato admin".

### `list_tasks` con `depth=0` e `page_size=100` produce response da 80KB+

Su progetti con 50+ task root, la response supera il limit di token MCP e viene salvata in un file temporaneo. Per analizzarla efficacemente, usa `jq` via Bash:

```bash
jq -r '.results | sort_by(.order) | .[] | "\(.order)\t#\(.id)\tsp=\(.story_points // "-")\t\(.title[0:60])"' <file>
```

Per uso interattivo (mostrare task all'utente), filtra meglio: `is_completed=false`, `depth=0`, `sprint__isnull=true`, `page_size=25` invece di 100, e paginazione esplicita.

### Mass tagging / mass reorder: batch in parallelo OK ma con riserve

Le scritture (`add_tag_tasks`, `partial_update_tasks`) sono safe in parallelo dal tuo lato — la transazione del backend è atomica per chiamata. MA: ogni `partial_update_tasks` rinormalizza gli order del livello → race condition sull'order finale se mandi 50 update in parallelo. Se l'ordine relativo è importante (riordino), serializza. Se invece stai solo taggando (no order change), parallelizza pure.

### Closing pattern verificato

Per chiudere un task non-banale (feature implementata, decisione presa):

1. `partial_update_tasks`: `is_completed: true, progress: 100, status: "DONE", title: <original>`
2. Aggiorna description con un breve ✅ Done summary in cima (≤4096 char): cosa è stato fatto, commit SHA principali, link a spec/plan, eventuali follow-up non-MVP esplicitamente fuori scope.
3. Memoria utente: se il lavoro ha sbloccato pattern riusabili, scrivi memoria type=`reference` o `feedback` linkata al task ID.

---

### Progetti archiviati: campo `is_archivied` (sic) — verificato 2026-05-25

Il campo è `is_archivied` (typo del backend, non `is_archived`).

**`list_projects` filtra di default i progetti archiviati** — quindi se non compaiono nella lista *potrebbe* essere perché sono archiviati, non perché non esistono. Conferma sempre con `retrieve_projects(pk=<id>, company_id=<cid>)` quando un ID atteso non appare nella list.

**`retrieve_projects` invece restituisce anche gli archiviati** — utile per ispezione, pericoloso se non si controlla il campo `is_archivied` prima di scriverci task.

**`create_tasks` NON valida `is_archivied`**: puoi creare un task in un progetto archiviato senza nessun errore lato backend (verificato — task #1455 creato in Higher Level (5) archiviato senza warning).

**Regole operative:**
- Quando salvi un **default in memoria** o stai per scrivere su un progetto noto solo per ID (es. da `prowodo_defaults.md`), fai un `retrieve_projects` rapido e verifica `is_archivied: false`. I default in memoria invecchiano — un progetto attivo ieri può essere archiviato oggi.
- Se un default risulta archiviato, **avvisa l'utente** e chiedi un'alternativa attiva (di solito il team ha consolidato il lavoro altrove). Aggiorna la memoria.
- Se l'utente cita un progetto per nome che non appare in `list_projects`, fai un `retrieve_projects` per id (se lo conosci) o segnala "non trovato tra gli attivi, potrebbe essere archiviato".

### `move_to_project_tasks`: schema MCP incompleto, tool non invocabile (verificato 2026-05-25)

Il tool MCP `move_to_project_tasks` espone solo `pk` nello schema, ma il viewset richiede `project_id` nel body HTTP. Passare `project_id` (o `body`, `data`, `project`) dentro `kwargs` viene espanso come keyword argument al metodo del viewset e rifiutato con `got an unexpected keyword argument`. Al momento il tool non è invocabile dall'agente.

**Workaround:** ricrea il task in destinazione con `create_tasks(project_id=<target>)` (copia title/description/priority/story_points/status) e cancella l'originale con `destroy_tasks`. Perdi l'ID originale e l'order, ma è funzionalmente equivalente. Avvisa l'utente del nuovo ID.

## Regole

- **Lettura e scrittura singola**: esegui senza chiedere conferma
- **Operazioni massive (5+)**: chiedi conferma con riepilogo di cosa verrà fatto
- Se l'utente non specifica il progetto, mostra i progetti disponibili e chiedi
- Dopo ogni operazione mostra un riepilogo conciso (nome task, ID, stato, progress %)
- Preferisci aggiornare task esistenti piuttosto che crearne di nuovi duplicati
- Quando mostri task con progress > 0, visualizza sempre la percentuale
