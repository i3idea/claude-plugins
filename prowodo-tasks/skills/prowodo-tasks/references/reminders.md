# Reminder

← [Indice della skill](../SKILL.md) · Vedi anche: [assegnatari](search-and-assign.md) · [tool completi](tools.md)

Promemoria temporizzati sui task (push, email, Telegram) e vista trasversale.

## "Ricordami X" / "Metti un reminder" / Reminder sui task

**Live in prod dal 2026-07-01.** Ogni task può avere **N reminder** temporizzati, consegnati su più canali (notifica push, email, Telegram). Uno scheduler backend pesca i reminder dovuti ogni minuto, li invia ai destinatari e marca `is_sent`.

- **Creare**: `create_reminders` con `task_id` (path) + body:
  - `remind_at` — datetime ISO, **obbligatorio** (quando scatta)
  - `text` — messaggio del reminder
  - `recipient_id` — opzionale; se omesso i destinatari sono gli **assegnatari correnti del task**. Deve essere un membro della company del task.
  - `send_push` / `send_email` / `send_telegram` — canali; **almeno uno true** (default: solo push)
  - `notify_if_completed` — default false; se true parte anche quando il task è già DONE
- **Listare**: `list_reminders` con `task_id` (ogni reminder espone `is_sent`).
- **Aggiornare / eliminare**: `partial_update_reminders` / `destroy_reminders`.

Esempio — "ricordami di rivedere questo task domani alle 9":
```
create_reminders(task_id=1234, body={
  "remind_at": "2026-07-02T09:00:00Z",
  "text": "Rivedi il task",
  "send_push": true
})
```

Consiglia di impostare i reminder quando l'utente dice "ricordami", "avvisami", "metti un promemoria" o cita una scadenza su un task specifico.

## "Che reminder ho oggi?" / "Cosa scatta questa settimana?"

`list_reminders` è scoped a **un** task (richiede `task_id`). Per una vista trasversale
— "i miei reminder di oggi", indipendentemente dal task su cui sono stati messi — usa
`list_all_reminders`: nessun path param, filtra su tutti i task dell'utente con
`remind_at__date` / `remind_at__gte` / `remind_at__lte` e `is_sent`.

```
list_all_reminders(remind_at__date="2026-08-05", is_sent=false)
```

Usalo per riepiloghi tipo "cosa devo ricordare oggi" invece di iterare `list_tasks` +
`list_reminders` task per task.
