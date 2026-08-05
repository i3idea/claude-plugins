# Famiglie a bassa frequenza

Queste famiglie di tool si usano meno spesso del flusso base task/sprint — per questo
sono qui e non in `SKILL.md`: non serve caricarle in ogni sessione. Per l'elenco
completo di tutti i tool con path param e scopo, vedi `references/tools.md`. Per i
nomi nudi vs il prefisso reale del tool MCP, vedi `SKILL.md`.

## Ticket

**Quando serve:** l'utente chiede di leggere/gestire ticket clienti (widget di supporto
sul sito), o di rispondere a chi ha aperto un ticket. Un ticket **è un Task** con una
`TicketSubmission` collegata — per triage, stato, assegnazione usa i tool task normali
(`list_tasks` con `has_ticket=true`, `partial_update_tasks`, `task_assign_user`); questa
famiglia copre solo l'intake e i commenti specifici del ticket.

- `retrieve_ticketsubmissions` — metadati di apertura: chi ha aperto il ticket
  (submitter), da quale widget, quando. **Non** contiene stato/assegnatario/testo del
  ticket: quelli sono sul Task collegato (`retrieve_tasks`).
- `list_ticketcomments` / `retrieve_ticketcomments` — thread dei commenti sul ticket
  (path: `submission_id`), dal più vecchio.
- `create_ticketcomments` — aggiunge un commento (path: `submission_id`). **Il flag
  `is_internal` decide chi lo vede:** default `true` (nota interna, solo team, il
  cliente non la vede mai); `is_internal=false` lo rende visibile sulla pagina pubblica
  del ticket. **Scrivi come interno per default e rendi pubblico solo di proposito** —
  è il verso opposto di sbagliare che conta: una nota interna che scappa fuori come
  pubblica espone dettagli non destinati al cliente.
- `destroy_ticketcomments` — soft-delete (nasconde) un commento, non cancellazione fisica.

**I due link, da non confondere** (vedi anche "Link alla piattaforma" in `SKILL.md`):
`app_url` su ticket submission/commenti è INTERNO (drawer del task nel team); `public_url`
su `retrieve_ticketsubmissions` è PUBBLICO, la pagina che vede chi ha aperto il ticket.
Non dare mai `app_url` al cliente.

Esempio — rispondere pubblicamente a un ticket:
```
retrieve_ticketsubmissions(pk=88)
  → {..., "public_url": "https://app.prowodo.com/t/9c2e..."}
create_ticketcomments(submission_id=88, body={
  "text": "Risolto: abbiamo pubblicato il fix in produzione.",
  "is_internal": false
})
```
Dopo, se serve, condividi `public_url` col cliente — mai `app_url`.

## Resume entry (piano/fatto giornaliero)

**Quando serve:** stand-up asincroni, "cosa hanno fatto/pianificato oggi i miei
colleghi", o per registrare tu stesso cosa hai pianificato/fatto in un giorno o in un
range — separato dai task veri e propri, è una nota di riepilogo eventualmente
collegata a uno o più task.

- `list_resumeentrys` (path: `company_id`) — filtra per `kind` (`plan`|`done`), range
  `date_from`/`date_to`, `user_id`.
- `retrieve_resumeentrys` — dettaglio per id.
- `create_resumeentrys` — `kind`, `date_from`/`date_to`, `note` (testo libero), `tasks`
  opzionale (lista di id collegati). Più entry nello stesso giorno sono ammesse.
- `update_resumeentrys` / `partial_update_resumeentrys` — sostituzione completa o
  parziale.
- `destroy_resumeentrys` — soft-delete.

Esempio — registrare cosa è stato fatto oggi:
```
create_resumeentrys(company_id=1, body={
  "kind": "done",
  "date_from": "2026-08-05",
  "date_to": "2026-08-05",
  "note": "Chiuso il fix sugli allegati, avviato lo spike sui reminder Telegram.",
  "tasks": [1234, 1240]
})
```

## CRUD tag oltre add_tag / remove_tag

`add_tag_tasks` / `remove_tag_tasks` (in `SKILL.md`) attaccano/staccano un tag
**esistente** a un task. Questa famiglia gestisce i tag stessi come entità della
company — serve quando l'utente vuole **creare, rinominare o eliminare** un tag (non
solo applicarlo), tipicamente in fase di setup di un progetto o di pulizia del backlog.

- `list_tasktags` / `retrieve_tasktags` (path: `company_id`) — elenco/dettaglio dei tag
  definiti nella company.
- `create_tasktags` — crea un tag (`text`); da qui in poi è disponibile per
  `add_tag_tasks`. Nota: `add_tag_tasks` può crearlo al volo passando `text` invece di
  `id` — usa `create_tasktags` esplicito solo se vuoi il tag pronto prima di taggare, o
  se lo stai creando senza ancora attaccarlo a nulla.
- `update_tasktags` / `partial_update_tasktags` — rinomina o aggiorna un tag esistente;
  il cambio si riflette su tutti i task che lo usano (è lo stesso record).
- `destroy_tasktags` — elimina il tag dalla company; i task che lo avevano perdono
  l'associazione (non vengono toccati altrimenti).

Esempio — rinominare un tag:
```
list_tasktags(company_id=1)
  → [{id: 12, text: "gtm"}, ...]
partial_update_tasktags(company_id=1, pk=12, body={"text": "go-to-market"})
```

## CRUD progetti

`create_projects` / `update_projects` / `partial_update_projects` / `destroy_projects`
(path: `company_id`) — CRUD completo sui progetti stessi, non sui task al loro
interno. Usali quando l'utente vuole **creare un nuovo progetto**, rinominarlo, o
archiviarlo — flusso raro rispetto al lavoro quotidiano sui task, ma diretto: niente
soft-delete a metà, `destroy_projects` archivia (`is_archivied=true`), non cancella.

Vedi anche in `SKILL.md` la sezione sul campo `is_archivied` (sic) — vale anche per i
progetti creati/modificati con questi tool: verifica sempre `is_archivied: false` prima
di proporli come destinazione.

Esempio — creare un progetto:
```
create_projects(company_id=1, body={
  "title": "Redesign sito marketing",
  "description": "Rifacimento landing + blog"
})
```

## Lanes della board sprint

**Quando serve:** l'utente chiede della **board kanban dello sprint attivo** (colonne
tipo "Da fare / In corso / Fatto") e non solo di "che task ci sono nello sprint" — la
lista task (`list_tasks(sprint=<id>)`) non dice in quale colonna sta un task, le lanes
sì.

- `list_sprint_lanes` — le lane di uno sprint (filtro `?sprint_id=`); le lane mancanti
  per task già nello sprint vengono create al volo, quindi non serve inizializzarle a
  mano.
- `retrieve_sprint_lanes` — dettaglio di una lane per id: quale task, quale colonna.
- `move_sprint_lanes` — sposta una lane in un'altra colonna
  (`project_task_status_id`, l'id della colonna target — deve appartenere al progetto
  dello sprint della lane); `null` la parcheggia nella colonna sintetica "Incoming".
  Non funziona su sprint chiusi.

Esempio — spostare un task in "In corso" sulla board:
```
list_sprint_lanes(sprint_id=44)
  → [{id: 501, task_id: 1234, project_task_status_id: null}, ...]
move_sprint_lanes(pk=501, body={"project_task_status_id": 7})
```
