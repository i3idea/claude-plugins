# Allegati — company/progetto e task

← [Indice della skill](../SKILL.md) · Vedi anche: [commenti](comments.md) · [note](notes.md)

File, testo e link attaccati a company, progetti e task.

**Quando serve:** mostrare cosa è attaccato a un progetto o a una company, o crearne di
nuovi (testo, file piccoli, link a Drive/Figma/pagine web).

Due famiglie distinte, non intercambiabili:

- **Allegati di company/progetto** — `list_attachments` / `retrieve_attachments` /
  `create_attachments` / `destroy_attachments` (path: `company_id`). `list_attachments`
  con `project_id` filtra su un progetto, con `project_id__isnull=true` mostra i soli
  allegati della company. **Un allegato senza progetto (`project_id` omesso) ha
  `app_url = null`: non esiste una pagina "allegati di company"**, solo quella per
  progetto — non aspettarti un link cliccabile in quel caso, e dillo se l'utente lo
  chiede. Non esistono `update`/`partial_update_attachments`: un allegato si sostituisce
  (cancella + ricrea), non si modifica.
- **Allegati sul task** — `list_taskattachments` / `retrieve_taskattachments` (path:
  `task_id`), più `request_taskattachment_upload` per crearne uno via il flusso a
  due passi descritto più sotto (nessun campo `comment_id` da passare: viene creato un
  `TaskComment` contenitore automaticamente, come fa già l'upload dall'app).

**Creare un allegato di company/progetto** — `create_attachments` accetta esattamente
UNO tra:
- `text` — salvato come file di testo/markdown (richiede `file_name`)
- `content_base64` — binario base64 (richiede `file_name` e `content_type`)
- `link` — un URL http(s), es. Google Drive/Figma/una pagina web (nessun file_name)

Contenuto inline (`text`/`content_base64`) è **capped a 4 MB** — oltre, carica su Drive
e passa l'URL come `link`. Tipi di file ammessi: immagini, PDF, testo semplice, CSV,
documenti Office e zip.

```
# nota testuale su un progetto
create_attachments(company_id=1, body={
  "project_id": 7,
  "text": "## Decisione\nUsiamo Resend per le mail transazionali.",
  "file_name": "decisione-mail-provider.md"
})

# link a un file Drive
create_attachments(company_id=1, body={
  "project_id": 7,
  "link": "https://drive.google.com/file/d/..."
})
```

**File più grandi o pesanti (oltre quanto conviene passare come `text`/`content_base64`)** —
usa il flusso a due passi invece di `create_attachments`:

1. `request_attachment_upload(company_id, project_id?, title?)` — nessun contenuto
   file in questa chiamata. Risponde con `upload_url`, `method`, `file_field`,
   `expires_at`, `max_bytes`, `allowed_content_types`.
2. Fai una POST multipart a `upload_url` con il file nel campo indicato da
   `file_field` — con qualunque client HTTP tu abbia a disposizione nel tuo
   ambiente (non è prescritto un comando specifico: la risposta del punto 1
   ti dice cosa mandare, non come). Il token in `upload_url` scade dopo
   pochi minuti ed è monouso; se il file viene rifiutato (tipo/dimensione)
   resta valido — riprova con un file diverso senza rifare il passo 1.
3. La risposta di quella POST è l'allegato creato, con `app_url` incluso.

Stesso flusso, stesso shape di risposta, per gli allegati sui **commenti dei
task** (non sui commenti dei ticket, che restano fuori scope — vedi [collaboration.md](collaboration.md)):
`request_taskattachment_upload(task_id)` → POST multipart → `TaskAttachment`
creato, con un `TaskComment` contenitore auto-generato come fa già l'upload
dall'app.
