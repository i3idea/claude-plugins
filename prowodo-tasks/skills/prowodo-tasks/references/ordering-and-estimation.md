# Riordinare, stimare, prioritizzare

← [Indice della skill](../SKILL.md) · Vedi anche: [sprint](sprints.md) · [gotcha API](gotchas.md) · [defaults di progetto](project-defaults.md)

Riordino dei task, story points con decomposizione, prioritizzazione ICE/RICE.

## "Sposta X prima di Y" / Riordinare
Per spostamenti singoli usa `move_up_tasks` / `move_down_tasks`. Per spostare un task in posizione precisa o riordinare in massa usa `partial_update_tasks` con il campo `order`.

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
- L'utente ha già detto che non usa stime su quel progetto (rispetta il default in memoria, vedi [project-defaults.md](project-defaults.md))

## Prioritizzazione ICE / RICE

Oltre agli story point (dimensione), ProWoDo espone i campi per prioritizzare il backlog con **ICE** e **RICE**. Sono i campi giusti quando l'utente chiede "usa ICE per priorità", "riordina per priorità", "cosa faccio prima", o vuole un ordine oggettivo invece del campo `priority` (spesso lasciato al default MEDIUM e quindi poco discriminante).

**Campi (settabili in `create_tasks` / `partial_update_tasks`):**

| Campo | Range | Significato |
|-------|-------|-------------|
| `impact` | 1–5 | Quanto muove l'ago (valore per utente/business) |
| `confidence` | 0–100 | Quanto sei sicuro dell'impatto / quanto è compreso il lavoro (%) |
| `effort` | 1–5 | Sforzo/costo. **Più alto = punteggio più basso** |
| `reach` | 0–N | Solo RICE: quante persone/eventi tocca in un periodo |

**Punteggi calcolati dal backend (read-only nella response):**
- `ice_score = impact × (confidence / 100) ÷ effort` — verificato (es. `i2 c85 e1` → `1.7`).
- `rice_score = reach × impact × (confidence / 100) ÷ effort` — formula RICE standard; valorizzato solo se `reach` è settato.

**Come usarli:**
1. Quando crei/aggiorni task di prodotto **consiglia** di valorizzare `impact` / `confidence` / `effort` (e `reach` se l'utente ragiona per volume → RICE). Per task operativi rapidi non insistere, come per gli story point.
2. Per prioritizzare: leggi i task con `list_tasks`, ordina per `ice_score` (o `rice_score`) decrescente e proponi quell'ordine. Per **persistere** l'ordine nella board usa `partial_update_tasks(order=i)` **in serie top-down** (0,1,2,...) — vedi "Riordinare" sopra e [gotchas.md](gotchas.md).
3. `story_points` (dimensione) ed ICE/RICE (priorità) sono ortogonali: un task può essere piccolo ma a bassa priorità e viceversa. Non confonderli.

**⚠️ Limite noto dell'ICE — segnalalo sempre prima di riordinare la board alla lettera:** l'ICE premia i task *cheap* (effort basso) e penalizza i *bet strategici* ad alto effort. Un tech-debt da 5 minuti può superare in punteggio il gate di pagamento / il lancio. Quando l'utente vuole riordinare per ICE, **proponi di "pinnare" manualmente in cima i 2-3 bet strategici** (monetizzazione, lancio, blocco critico) e ordinare per ICE tutto il resto, invece di applicare l'ICE puro. RICE mitiga in parte il problema introducendo `reach`, ma non lo elimina.
