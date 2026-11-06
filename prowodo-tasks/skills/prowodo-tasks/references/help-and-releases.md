# Guida ai tool e novità del prodotto

← [Indice della skill](../SKILL.md) · [tool completi](tools.md)

Due tool di sola lettura, utili soprattutto a chi usa ProWoDo come connector senza questa skill.

| Tool | Scopo |
|------|-------|
| `help` | Senza `topic`: introduzione e elenco delle aree (con quanti tool ciascuna). Con `topic` (`tasks`, `notes`, `rhythm`, `sprints`, …): i tool di quell'area con titolo e una frase. L'elenco è generato dal registro MCP, quindi un tool nuovo compare da solo (in `other` finché non ha un'area). Un `topic` sconosciuto dà errore con le aree valide. |
| `list_release_notes` | Le ultime release di ProWoDo dal feed pubblico, la più recente per prima: `version`, `name`, `released_at`, `short_summary`, `changelog_markdown`. `limit` (1–20, default 5), `since_version` (es. `1.18.0`: solo release più nuove, confronto numerico). |

Quando usarli:
- **"Cosa c'è di nuovo in ProWoDo?"** → `list_release_notes`. Se l'utente dice l'ultima versione che conosce, passa `since_version`.
- **Non sai quale tool usare, o l'utente chiede cosa sai fare** → `help`, poi `help(topic=…)` solo per l'area che serve.
- **Un tool che ti aspettavi non c'è** → prima `list_release_notes` (potrebbe essere nuovo, o questa skill essere indietro), poi `help`.

Cose da sapere:
- Il feed è pubblico e in cache cinque minuti sul backend. Se non è raggiungibile `list_release_notes` risponde comunque con `results: []`, `feed_available: false` e una `note`: non è un errore dell'utente, riprova più tardi.
- Il feed ha solo le release pubblicate, senza note tecniche né SHA. Non sostituisce i tool di i3deploy (`list_project_releases`, …), che servono a chi pubblica le release.
