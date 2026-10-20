# Gotcha tecnici dell'API

← [Indice della skill](../SKILL.md) · Vedi anche: [riordino](ordering-and-estimation.md) · [defaults di progetto](project-defaults.md) · [tool completi](tools.md)

Cose non ovvie dalla descrizione dei tool MCP, verificate sul backend.

Cose che NON sono ovvie dalla descrizione dei tool MCP e ti costano tempo se le scopri sul momento:

## `partial_update_tasks` richiede `title` nel body anche per update parziali

Lo schema MCP marca `title` come required nel body anche se stai cambiando solo `order`, `progress`, `is_completed`, o un tag. Se ometti `title`, ricevi un 400. Workaround: passa sempre il title originale (puoi leggerlo prima con `retrieve_tasks` se non lo hai in cache, oppure passalo come parametro se l'hai già).

## `description` ha cap a 4096 caratteri

L'API rifiuta description più lunghe con `400 {"description": ["Ensure this field has no more than 4096 characters."]}`. Se devi narrare di più, linka a spec/plan esterni o usa commenti sul task (separati). Splitta sezioni mantenendo gli ancoraggi essenziali.

## Tag orfani da altre company non sono rimovibili

A volte un task ha un tag con `company` diverso da quella corrente (residuo di refactor passati o errore di assegnazione). `remove_tag_tasks` rifiuta con `"tag not in this company"`. Workaround: lascialo, non bloccare il flusso, eventualmente aggiungi i tag corretti della company corrente sopra. Segnalalo all'utente come "tag orfano da pulire eventualmente lato admin".

## `list_tasks` con `depth=0` e `page_size=100` produce response da 80KB+

Su progetti con 50+ task root, la response supera il limit di token MCP e viene salvata in un file temporaneo. Per analizzarla efficacemente, usa `jq` via Bash:

```bash
jq -r '.results | sort_by(.order) | .[] | "\(.order)\t#\(.id)\tsp=\(.story_points // "-")\t\(.title[0:60])"' <file>
```

Per uso interattivo (mostrare task all'utente), filtra meglio: `is_completed=false`, `depth=0`, `sprint__isnull=true`, `page_size=25` invece di 100, e paginazione esplicita.

## Mass tagging / mass reorder: batch in parallelo OK ma con riserve

Le scritture (`add_tag_tasks`, `partial_update_tasks`) sono safe in parallelo dal tuo lato — la transazione del backend è atomica per chiamata. MA: ogni `partial_update_tasks` rinormalizza gli order del livello → race condition sull'order finale se mandi 50 update in parallelo. Se l'ordine relativo è importante (riordino), serializza. Se invece stai solo taggando (no order change), parallelizza pure.

## Closing pattern verificato

Per chiudere un task non-banale (feature implementata, decisione presa):

1. `partial_update_tasks`: `is_completed: true, progress: 100, status: "DONE", title: <original>`
2. Aggiorna description con un breve ✅ Done summary in cima (≤4096 char): cosa è stato fatto, commit SHA principali, link a spec/plan, eventuali follow-up non-MVP esplicitamente fuori scope.
3. Memoria utente: se il lavoro ha sbloccato pattern riusabili, scrivi memoria type=`reference` o `feedback` linkata al task ID.

---

## Progetti archiviati: campo `is_archivied` (sic) — verificato 2026-05-25

Il campo è `is_archivied` (typo del backend, non `is_archived`).

**`list_projects` filtra di default i progetti archiviati** — quindi se non compaiono nella lista *potrebbe* essere perché sono archiviati, non perché non esistono. Conferma sempre con `retrieve_projects(pk=<id>, company_id=<cid>)` quando un ID atteso non appare nella list.

**`retrieve_projects` invece restituisce anche gli archiviati** — utile per ispezione, pericoloso se non si controlla il campo `is_archivied` prima di scriverci task.

**`create_tasks` NON valida `is_archivied`**: puoi creare un task in un progetto archiviato senza nessun errore lato backend (verificato — task #1455 creato in Higher Level (5) archiviato senza warning).

**Regole operative:**
- Quando salvi un **default in memoria** o stai per scrivere su un progetto noto solo per ID (es. da `prowodo_defaults.md`), fai un `retrieve_projects` rapido e verifica `is_archivied: false`. I default in memoria invecchiano — un progetto attivo ieri può essere archiviato oggi.
- Se un default risulta archiviato, **avvisa l'utente** e chiedi un'alternativa attiva (di solito il team ha consolidato il lavoro altrove). Aggiorna la memoria.
- Se l'utente cita un progetto per nome che non appare in `list_projects`, fai un `retrieve_projects` per id (se lo conosci) o segnala "non trovato tra gli attivi, potrebbe essere archiviato".

## `move_to_project_tasks`: come si usa

Per spostare un task in un altro progetto (anche di un'altra company) chiama `move_to_project_tasks` con `pk=<task_id>` e `body={"project_id": <target_project_id>, "company_id": <target_company_id>}`. Lo schema MCP accetta entrambi i campi nel body — il task mantiene ID e passa al nuovo progetto/company. Non serve ricrearlo né cancellare l'originale.
