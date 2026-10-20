# Cercare task e assegnarli

← [Indice della skill](../SKILL.md) · Vedi anche: [note](notes.md) · [ordinamento e stime](ordering-and-estimation.md)

Ricerca testuale sui task (`search` vs `*__icontains`) e assegnazione a utenti.

## "Cerca task su X" / "Ci sono task che riguardano Y?"
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

Per cercare **per contenuto** anche in commenti e note, o quando la domanda è "dove ne abbiamo parlato?", usa `search_knowledge` (vedi [notes.md](notes.md)). `list_tasks` cerca solo nei task.

## "Assegna X a Y" / "Chi è assegnato a Z?"

**Disponibile dal backend `8489763` (2026-05-26) / `@prowodo/angular-client@1.2.0`.**

**Mostra sempre gli assegnatari nei riepiloghi**, leggendo il campo `assignees` del task (`retrieve_tasks(pk=<id>)` o già incluso in `list_tasks`) — una lista di dict con `id`, `display_name`, `username`, `email`, `identity_picture_url`. Non serve una chiamata separata per saperlo.

**"Assegna a me" / "cosa devo fare io":** risolvi "io" con il tool utente corrente `retrieve_current_user` (nessun parametro — ritorna id, username, display name, email dell'utente autenticato). **Non indovinare** il proprio nome con una `list_users` a tentativi: prima che esistesse questo tool era l'unico modo, ora è quello sbagliato.

Per assegnare un task a un **altro** utente (non "me"):

1. Risolvi il nome utente in `user_id` con `list_users` (path param: `company_id`). Lo viewset supporta search via `search_fields` su email/username/first_name/last_name/display_name/identity_email — passa la stringa di ricerca come parametro `search` se l'utente cita un nome libero ("Ivan").
2. Chiama `assign_user_tasks` con `pk=<task_id>` e `body={"user_id": <id>}`. È **idempotente** — chiamarlo due volte non crea duplicati né errore.
3. Per rimuovere: `unassign_user_tasks` con stesso shape. Ritorna `{"unassigned": true|false}`. **Noop-safe** — chiamarlo su un'assegnazione che non esiste non solleva errore.

**Sicurezza:** il backend rifiuta con 400 se `user_id` punta a un utente NON membro della company del task (cross-tenant). Niente leak.

**Quando un task passa a `IN_PROGRESS` e non ha assegnatari, proponi di assegnarlo** — default: l'utente collegato (via `retrieve_current_user`), salvo diversa indicazione. Uno stato "in corso" senza nessun responsabile è il caso più comune di task che si perde.

Esempio flow tipico — "Assegna il task #1234 a Ivan":
```
1. list_users(company_id=1, search="Ivan")
   → [{id: 42, display_name: "Ivan Bettarini", ...}]
2. assign_user_tasks(pk=1234, body={user_id: 42})
   → 201 {id: ..., task_id: 1234, user_id: 42}
```

Se la search ritorna più match, mostrali all'utente e chiedi disambiguazione prima di assegnare.
