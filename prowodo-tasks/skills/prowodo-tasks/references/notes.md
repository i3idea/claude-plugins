# Note e second brain — salvare e ritrovare conoscenza

← [Indice della skill](../SKILL.md) · Vedi anche: [ricerca sui task](search-and-assign.md) · [allegati](attachments.md)

Knowledge base della company: salvare, cercare, collegare, revisionare le note.

Le note sono la knowledge base della company: markdown libero, opzionalmente legato a un progetto. Servono per decisioni, contesto, appunti che non sono azioni da fare (quelli sono task).

**Quale tool per quale domanda:**

| Domanda dell'utente | Tool |
|---|---|
| "Dove ne abbiamo parlato?" / "Cosa sappiamo su X?" / "Ho già scritto qualcosa su Y?" | `search_knowledge` — **default per ogni ricerca di conoscenza**: cerca in una chiamata sola su task (titolo+descrizione), commenti dei task e note, ordinato per rilevanza |
| Cerco solo tra le note, per contenuto | `search_notes` |
| Elenco le note di un progetto / per titolo | `list_notes` (`project_id`, `title__icontains`) |
| Salva questa decisione / appunto | `create_notes` |
| Correggi / aggiungi a una nota | `partial_update_notes` |

**`search_knowledge`:** `company_id` e `query` obbligatori, `project_id` opzionale per restringere. Ogni risultato ha `kind` (`task` | `task_comment` | `note`), `id`, `snippet` (ritagliato, non il testo intero) e — per `task_comment` — il `task_id` del task padre. Per il testo completo chiama poi `retrieve_notes` / `retrieve_tasks` / `list_taskcomments`. Restituisce `{"results": [...]}`, max una pagina di risultati: se serve, affina la query o passa `project_id`. **Ticket e commenti ticket non sono inclusi.** La ricerca è full-text (parole intere), non semantica: "riunione" non trova "meeting". Il significato lo metti tu — vedi "Ricerca che non trova" qui sotto.

**Promuovere un task a nota:** non c'è un tool dedicato. Leggi il task (`retrieve_tasks`, più `list_taskcomments` se la discussione conta), poi `create_notes` con `source_task` = id del task: la nota resta collegata alla sua origine (`SET_NULL` se il task viene eliminato). `source_task` è scrivibile anche su `update_notes` / `partial_update_notes` e deve appartenere alla stessa company della nota. Non chiudere né modificare il task d'origine, a meno che l'utente lo chieda.

**Scrivere una nota:**
- `title` breve e cercabile (l'utente lo cercherà per parole chiave); `content` in markdown.
- Metti `project_id` se il contenuto riguarda un progetto, omettilo per note di company.
- Prima di creare, se il tema può esistere già, fai una `search_notes` e proponi di aggiornare la nota esistente invece di duplicarla.
- **Visibilità.** Ogni nota è `company` (default, la vedono tutti i membri della company) oppure `private` (la vede solo chi l'ha scritta, nessuna eccezione nemmeno per gli admin). Crea con `visibility: "private"` **solo** se l'utente lo chiede ("nota mia", "privata", "solo per me", "appunto personale"); in tutti gli altri casi lascia il default. `visibility` lo cambia solo l'autore: non rendere privata una nota di altri né pubblica una privata senza richiesta esplicita.
- **Ricerca che non trova.** `search_notes` e `search_knowledge` cercano parole intere, non significati. Se i risultati sono pochi o zero, **non concludere che la nota non esiste**: riprova almeno due volte con varianti — sinonimi, termini correlati, singolare/plurale, una parola più corta, e la **traduzione** (italiano ↔ inglese: "riunione" / "meeting", "scadenza" / "deadline"). Lancia le varianti in sequenza e unisci i risultati; solo dopo dì all'utente che non hai trovato nulla, elencando i termini provati.
- Le ricerche (`search_notes`, `search_knowledge`, `list_notes`) restituiscono solo le note che l'utente può vedere: una nota privata altrui non compare mai, quindi "non l'ho trovata" non prova che non esista. `list_notes` accetta `visibility=private` per ritrovare solo i propri appunti privati.
- **Cestino.** `destroy_notes` **non cancella per sempre**: sposta la nota nel cestino (si vede e si recupera con `trashed_notes` / `restore_notes`). La cancellazione definitiva non esiste via MCP: la fa l'utente dall'app (tab Trash). Conferma comunque prima di cestinare più di una nota, e di' all'utente dove ritrovarla.
- **Cronologia.** `history_notes` elenca le ultime 50 versioni (con `history_id`, data, titolo e contenuto); `revert_notes` ripristina titolo e contenuto di una versione (tag, progetto e visibilità non cambiano) e salva il revert come nuova versione, quindi si può annullare. Usali per "torna alla versione di ieri" o dopo una modifica sbagliata, invece di riscrivere la nota a mano.
- **Collegamenti.** Nel `content` si può scrivere `[[Titolo nota]]` oppure `[[id|etichetta]]`: crea un link verso un'altra nota della stessa company. Un titolo con zero o più corrispondenze resta "non risolto": usa la forma con l'id. Una nota condivisa non può linkare una privata. `links_notes` restituisce i link in uscita (`resolved` vero/falso) e i **backlink** (chi punta a questa nota): seguili per ricostruire il contesto prima di rispondere a "cosa sappiamo su X?". I `[[...]]` dentro blocchi di codice sono ignorati.
- **Revisione delle note** ("rivedi le mie note", o l'utente risponde al promemoria mensile "Review my ProWoDo notes"). Procedi per passi e **chiedi conferma prima di scrivere o cancellare**: cestino e cronologia rendono tutto reversibile, ma decide l'utente.
  1. **Inbox**: `list_notes` con `tags__text=inbox` (per company). Per ogni nota proponi progetto, tag e titolo migliori, oppure unione o cestino; dopo lo smistamento togli il tag `inbox`.
  2. **Note vecchie**: `list_notes` con `updated_at__lte=<data di 6 mesi fa>` e `ordering=updated_at` (le più vecchie per prime). Proponi di aggiornare, mandare nel cestino (`destroy_notes`) o lasciare.
  3. **Doppioni**: confronta i titoli e, per i candidati, usa `search_notes` sul titolo; proponi di unire.
  4. **Wikilink orfani**: `links_notes` sulle note più importanti; per ogni link con `resolved: false` proponi di creare la nota mancante o di correggere il titolo.
  5. Riepiloga cosa hai cambiato e cosa hai lasciato, con i link (`app_url`). Le note private altrui non compaiono mai: "non ho trovato doppioni" vale solo per ciò che l'utente può vedere.
