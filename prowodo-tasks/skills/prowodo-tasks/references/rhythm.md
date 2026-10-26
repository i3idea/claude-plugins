# Ritmo (giornata e focus settimanale)

← [Indice della skill](../SKILL.md) · La procedura completa è nella skill [oggi](../../oggi/SKILL.md)

Per-utente (non per company): dice **su cosa spingere quale giorno**. Ha un testo libero, voci
risolte (company, progetto, task, tag o nota) per giorno della settimana, obiettivi di periodo e
scadenze. La pagina "Rhythm" in ProWoDo (menu principale) mostra e permette di modificare le stesse voci.

| Tool | Scopo |
|------|-------|
| `retrieve_current_rhythm` | Testo, voci, `pending_interpretation` (il testo è cambiato dopo l'ultima interpretazione). Sola lettura. |
| `today_rhythm` | La giornata calcolata dal backend (`date` opzionale, ora di Roma): `focus`, `off_focus_deadlines`, `rest`, `anomalies`, `interpretation`. Sola lettura. |
| `set_text_rhythm` | Sostituisce il testo libero (`body.text`, max 8192) e lo marca da interpretare. |
| `mark_interpreted_rhythm` | Azzera `pending_interpretation` dopo aver creato le voci. |
| `list_rhythm_items` | Voci dell'utente; filtri `scope`, `weekday`. Le voci scartate non compaiono. |
| `create_rhythm_items` | Crea una voce: `scope` `DAY` (serve `weekday`), `WEEK` o `DEADLINE` (con `ends_on`); **un solo** tra `company_id`, `project_id`, `task_id`, `tag_id`, `note`; `source_phrase` = la frase di origine. |
| `partial_update_rhythm_items` | Cambia giorno, data, riferimento o nota di una voce. |
| `destroy_rhythm_items` | Una voce nata dal testo viene *scartata* (non si ricrea con la stessa frase); una messa a mano viene cancellata. |

Cose da sapere:
- `weekday`: 0 = lunedì … 6 = domenica. Il "giorno" è sempre a Roma (`Europe/Rome`).
- `today_rhythm`: **focus** = task aperti assegnati all'utente sotto le voci di oggi (un task include i suoi sottotask); **fuori focus** = scadute o entro 3 giorni; **resto** = in corso o priorità ≥ 3, max 5. Ordine: priorità, importanza, scadenza, punteggio ICE.
- Una voce con `missing: true` puntava a qualcosa che non esiste più: segnalalo, non ignorarlo.
- L'impostazione del messaggio Telegram delle 8 (on/off, lingua) è solo nella pagina web, non via MCP.
- Il testo libero lo interpreta Claude, non il backend: finché non lo fai, la pagina mostra "in attesa di interpretazione".
