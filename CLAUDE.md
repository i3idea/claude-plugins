# CLAUDE.md

Marketplace di plugin Claude Code di i3idea (`prowodo-tasks`, `i3deploy-release`).

## Fork Hoopygang — tenerlo allineato

Esiste un fork di questo repo nell'org Hoopygang:
**`hoopygang/i3idea-claude-plugins`** (upstream: `i3idea/claude-plugins`, branch `master`).

**Regola:** ogni modifica che finisce su `master` qui (merge di una PR, bump di
versione, nuovo plugin) va portata anche sul fork, nella stessa sessione di lavoro.
Una modifica non è "chiusa" finché il fork non è allineato.

Come allinearlo, in ordine di preferenza:

1. **GitHub UI** — sul fork: *Sync fork → Update branch*.
2. **CLI**, da un clone del fork:
   ```bash
   git remote add upstream https://github.com/i3idea/claude-plugins.git  # una volta
   git fetch upstream master
   git checkout master
   git merge upstream/master        # merge, mai rebase/force-push: il fork può avere modifiche Hoopygang
   git push origin master
   ```

Note:
- Se il fork ha modifiche proprie che vanno in conflitto, risolvi tenendo quelle
  Hoopygang (nome marketplace, descrizioni, personalizzazioni) e chiedi in caso di dubbio.
- Se dalla sessione non hai accesso a `hoopygang/i3idea-claude-plugins` (app GitHub
  non installata sull'org, repo non allegato), non saltare il passo in silenzio:
  dillo esplicitamente all'utente a fine lavoro, con il comando o il link *Sync fork*.
- Il fork non esiste ancora? Va creato da
  https://github.com/i3idea/claude-plugins/fork (owner `hoopygang`, nome
  `i3idea-claude-plugins`).

## Progetti collegati

I plugin descrivono i tool MCP di **ProWoDo** (`mcp.prowodo.com`) e **i3deploy**
(`mcp.i3deploy.com`). Quando una modifica in quei progetti cambia i tool MCP
(nomi, parametri, comportamento), aggiorna la skill qui (`*/skills/**`,
`references/*.md`), bumpa la versione in `plugin.json` **e** in
`.claude-plugin/marketplace.json`, poi allinea il fork Hoopygang come sopra.
