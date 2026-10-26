---
name: oggi
description: Plan the user's day or week across all their ProWoDo companies, in one ordered list. Use when they ask "cosa faccio oggi", "cosa conviene fare oggi", "cosa devo fare oggi", "la mia giornata", "what should I do today", "plan my day", "plan my week", when they want to move or reprioritise a task ("sposta questo a domani", "alza la precedenza di questo", "move this to tomorrow"), capture something new ("segna: …", "devo anche …"), or describe their weekly rhythm ("lunedì hoopy e tesi", "questa settimana devo finire il sito", "entro il 3 novembre devo aver finito X", "il mio ritmo"). Reads the ProWoDo rhythm and tasks, plus Google Calendar and Gmail when connected.
---

# Oggi — giornata e ritmo settimanale

L'utente ha cose da fare in più company e progetti (lavoro, side project, università, personale) e
si perde. Questa skill gli dà **un solo ordine** per tutto, e gli lascia correggerlo parlando.
Il calcolo dell'ordine lo fa il **backend** (`today_rhythm`, deterministico): tu non riordini,
interpreti il testo del ritmo, aggiungi calendario e mail, e applichi le modifiche richieste.

Nomi dei tool: nudi come nella skill `prowodo-tasks` (il prefisso dipende da come è connesso il
server). Dettaglio dei tool del ritmo: [../prowodo-tasks/references/rhythm.md](../prowodo-tasks/references/rhythm.md).

## "Cosa faccio oggi?"

1. `retrieve_current_rhythm` → testo, voci, `pending_interpretation`.
2. Se `pending_interpretation` è true: **interpreta il testo** (sezione sotto), poi continua.
3. `today_rhythm` (senza `date` = oggi, ora di Roma). Restituisce `focus`, `off_focus_deadlines`,
   `rest`, `anomalies`, `interpretation`. **Non cambiare l'ordine dei task.**
4. Aggiungi, se i connettori ci sono: eventi di **Google Calendar** di oggi e **mail** che aspettano
   risposta (ricerca mirata, poche; mai leggere o citare il contenuto privato oltre a mittente/oggetto).
   Se un connettore non c'è, dillo in una riga e vai avanti.
5. Rispondi nel formato qui sotto.

### Formato

```
☀️ lunedì 26 ottobre — la tua giornata
Oggi interpreto il focus così: hoopy, tesi, [Sito] Copy…   ← sempre, dalla `interpretation`

🔴 Da fare oggi            ← `focus`
• [company] titolo (scade 28 ott) — link `app_url`
⚠️ Fuori focus, non può aspettare   ← `off_focus_deadlines`, mai omessi
📅 Calendario   ✉️ Mail in attesa
🟡 Se resta tempo          ← `rest`
🧹 Da sistemare            ← `anomalies`, una domanda per riga ("la alzo?", "lo chiudo?")
```

- Mostra **sempre** la riga "Oggi interpreto il focus così": è come l'utente si accorge che hai
  capito male. Voci con `missing: true` → segnalale ("un riferimento non esiste più").
- Giornata vuota (nessun focus): dillo e mostra comunque scadenze e "se resta tempo".
- Ogni task con il suo `app_url`; non costruire URL a mano.
- Le **anomalie** si propongono, non si applicano senza risposta.

## Interpretare il testo del ritmo

Quando `pending_interpretation` è true (o l'utente scrive/dice il ritmo a voce):

1. Se parla a voce, salva prima il testo con `set_text_rhythm` (testo completo aggiornato, non un frammento).
2. Spezza il testo in **frasi**. Per ognuna decidi lo scope:
   - giorno della settimana ("lunedì hoopy e tesi") → `DAY` + `weekday` (0 = lunedì … 6 = domenica);
   - "questa settimana devo …" → `WEEK` + `ends_on` = domenica della settimana corrente;
   - "entro il … devo aver finito …" → `DEADLINE` + `ends_on`, **e** `partial_update_tasks` con
     `expected_stop_datetime` sul task (ora di Roma → UTC). Se il task non esiste, crealo
     (company/progetto con la regola di cattura sotto) e dillo.
3. Risolvi i riferimenti con i tool di lettura (`list_companies`, `list_projects`, `list_tasks` con
   `search`, tag): company, progetto, task (anche grosso o piccolo) o tag. Un testo che non punta a
   nulla di concreto ("voglio staccare presto") va come `note`.
4. Una frase ambigua (due task che combaciano, nome mai visto) **non si indovina**: lasciala fuori e
   chiedi, in una domanda sola per tutte le ambigue.
5. Crea le voci con `create_rhythm_items`, sempre con `source_phrase` = la frase originale e
   senza `is_manual`. Vincoli dal backend: un solo riferimento per voce; un id di una company che
   l'utente non vede dà errore (non riprovare con altri id).
6. **Non toccare** le voci con `is_manual: true` (le ha messe l'utente a mano) e non cancellare voci
   per rifare da capo. Una voce che l'utente ha tolto a mano e che riproponi con la stessa frase non
   viene ricreata (il backend risponde con la voce scartata): è voluto, non insistere.
7. Per spostare una voce usa `partial_update_rhythm_items`; per toglierla `destroy_rhythm_items`.
8. Chiudi con `mark_interpreted_rhythm`.

## Modifiche a voce

- **"Sposta X a domani"**: se X ha una scadenza (`expected_stop_datetime`), spostala a domani alla
  stessa ora con `partial_update_tasks` (se la scadenza era una data fissa dell'utente, chiedi prima).
  Se non ha scadenza, il suo posto nella giornata dipende dal ritmo: proponi di aggiungerlo al focus
  di domani con `create_rhythm_items` (`DAY`, `weekday` di domani, `task_id`), senza `source_phrase`
  e con `is_manual: true`, e di' che è quello che farai.
- **"Alza la precedenza di X"**: `partial_update_tasks` con `priority` +1 (massimo 4); riporta
  prima → dopo. Per "mettilo al massimo" usa 4.
- **"Chiudi X"**: `is_completed: true, progress: 100, status: "DONE"` (vedi `prowodo-tasks`).
- **"Cosa conviene fare oggi?"**: parti da `today_rhythm` e dai un consiglio **motivato su quei dati**
  (scadenze vicine, priorità, focus del giorno, tempo libero nel calendario). Non inventare scadenze
  né priorità che non sono nei dati.

## "Segna: …" (cattura)

L'utente scrive a Claude invece di segnarsi le cose a mente o su WhatsApp. Per ogni frase:
1. Scegli company e progetto dal contesto (memoria di progetto, `list_companies`/`list_projects`);
   **se è incerto, chiedi** invece di indovinare.
2. `create_tasks` con titolo breve, e proponi (non imporre) `priority`, `importance` e scadenza se
   la frase ne dà indizi ("urgente", "entro venerdì").
3. Riporta titolo, company/progetto, scadenza e `app_url`.

## Regole

- Lettura e scritture singole: esegui senza chiedere conferma. Modifiche su 5+ task: riepilogo e conferma.
- Mai mostrare più della giornata: il resto del backlog solo se richiesto.
- Il messaggio Telegram delle 8 ha solo la parte ProWoDo; calendario e mail compaiono qui, a richiesta.
