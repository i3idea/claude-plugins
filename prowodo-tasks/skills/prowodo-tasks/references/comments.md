# Commenti sui task

← [Indice della skill](../SKILL.md) · Vedi anche: [allegati](attachments.md) · [dipendenze](dependencies.md) · [ticket](collaboration.md)

Thread di conversazione su un task.

**Quando serve:** l'utente vuole lasciare un aggiornamento per gli stakeholder su un
task, leggere la discussione già avvenuta, o rispondere a un commento — diverso dalla
`description` (il "cosa" del task): i commenti sono il thread di conversazione.

- `list_taskcomments` / `retrieve_taskcomments` (path: `task_id`) — thread, dal più
  recente (a differenza dei commenti ticket, che sono dal più vecchio).
- `create_taskcomments` — **`task_id` va nel body, non nel path** (eccezione rispetto
  agli altri tool di questa famiglia — se lo passi solo come path param il commento
  finisce scollegato). L'autore è sempre l'utente autenticato. `comment_id` opzionale
  per rispondere a un commento esistente.
- `destroy_taskcomments` (path: `task_id`) — soft-delete: il commento sparisce dal
  thread ma non è cancellato fisicamente.

```
create_taskcomments(body={
  "task_id": 1234,
  "text": "Bloccato in attesa di conferma dal cliente sul copy."
})
```

`app_url` del commento punta al drawer del task padre (i commenti non hanno una pagina
propria — vedi "Link alla piattaforma" in [SKILL.md](../SKILL.md#link-alla-piattaforma)).
