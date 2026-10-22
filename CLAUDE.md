# CLAUDE.md

Marketplace di plugin Claude Code di i3idea (`prowodo-tasks`, `i3deploy-release`).

## Copia Hoopygang — tenerla allineata

Esiste una copia di questo repo nell'org Hoopygang:
**`hoopygang/i3idea-claude-plugins`** (upstream: `i3idea/claude-plugins`, branch `master`).
Serve a pubblicare i plugin nel marketplace dell'org Hoopygang su claude.ai
(Admin → Plugins & skills → Marketplaces → *Sync from GitHub*), che elenca solo
repo **privati**. Per questo è una copia privata e non un fork GitHub: il fork di
un repo pubblico resta pubblico. Contesto: task ProWoDo #2769.

**Regola:** ogni modifica che finisce su `master` qui (merge di una PR, bump di
versione, nuovo plugin) va portata anche sulla copia Hoopygang, nella stessa
sessione di lavoro. Una modifica non è "chiusa" finché la copia non è allineata.

Come allinearla, da un clone di `hoopygang/i3idea-claude-plugins`:

```bash
git remote add upstream https://github.com/i3idea/claude-plugins.git  # una volta
git fetch upstream master
git checkout master
git merge upstream/master        # merge, mai rebase/force-push: la copia può avere modifiche Hoopygang
git push origin master
```

Se è un fork GitHub vero, va bene anche *Sync fork → Update branch* dalla UI.
Dopo il push, sull'Admin di claude.ai rilancia *Sync from GitHub* se non si
aggiorna da solo.

Note:
- Se la copia ha modifiche proprie che vanno in conflitto, risolvi tenendo quelle
  Hoopygang (nome marketplace, descrizioni, personalizzazioni) e chiedi in caso di dubbio.
- Se dalla sessione non hai accesso a `hoopygang/i3idea-claude-plugins` (app GitHub
  non installata sull'org, repo non allegato), non saltare il passo in silenzio:
  dillo esplicitamente all'utente a fine lavoro, con i comandi qui sopra.
- La copia non esiste ancora? Crea su GitHub un repo **privato** vuoto
  `hoopygang/i3idea-claude-plugins`, poi da un clone di questo repo:
  `git push https://github.com/hoopygang/i3idea-claude-plugins.git master`.

## Progetti collegati

I plugin descrivono i tool MCP di **ProWoDo** (`mcp.prowodo.com`) e **i3deploy**
(`mcp.i3deploy.com`). Quando una modifica in quei progetti cambia i tool MCP
(nomi, parametri, comportamento), aggiorna la skill qui (`*/skills/**`,
`references/*.md`), bumpa la versione in `plugin.json` **e** in
`.claude-plugin/marketplace.json`, poi allinea la copia Hoopygang come sopra.
