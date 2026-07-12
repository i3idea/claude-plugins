---
name: relations-mcp
description: Use this skill whenever the user asks about Relation (Hoopygang) influencers, campaigns, deals, organizations, or audience analytics — e.g. "che campagne ha l'organizzazione X", "info sull'influencer @handle su Instagram", "audience di questo creator", "lookup profilo", "elenco deal", "dati demografici follower", "list campaigns", "influencer audience breakdown", "organization campaigns", or equivalent in any language. Relation's MCP server exposes read-only data about influencers, campaigns and their audiences for a given organization. Trigger also when the user wants analytics on a creator's followers/audience composition.
---

# Relation MCP — Influencer & Campaign Analytics

Relation (Hoopygang) espone un server MCP di **sola lettura** su dati di influencer, campagne e organizzazioni. Questa skill guida l'uso dei tool: quando usarli, quali input passare, cosa aspettarsi in risposta, e i vincoli di accesso.

## Quando usarla

Usa questa skill per rispondere a domande su:
- Campagne di un'organizzazione (elenco, dettaglio)
- Influencer noti alla piattaforma (elenco, dettaglio)
- Organizzazioni (elenco, dettaglio)
- Lookup di un profilo influencer per piattaforma/handle
- Analisi audience/demografia dei follower di un influencer

Non usarla per creare, modificare o cancellare dati — non esiste alcuna operazione di scrittura in questo set di tool (vedi "Vincoli" sotto).

## Tool disponibili

Tutti i tool sono **read-only** e restituiscono dati già presenti nel database di Relation (nessuna chiamata live a provider esterni).

| Tool | Cosa fa | Input chiave | Output |
|------|---------|---------------|--------|
| `list_campaigns` | Elenca le campagne | `organization` (scoping tenant), filtri di lista standard (paginazione, status, ecc.) | Lista paginata di campagne (id, nome, brand, status, date) |
| `retrieve_campaigns` | Dettaglio di una campagna | `pk` (id campagna) | Oggetto campagna completo (pipeline, deal associati, economics se esposte) |
| `list_influencers` | Elenca gli influencer noti | `organization`, filtri di lista | Lista paginata di influencer (id, nome, handle principali) |
| `retrieve_influencers` | Dettaglio di un influencer | `pk` (id influencer) | Oggetto influencer completo (handle su varie piattaforme, metadati profilo) |
| `list_organizations` | Elenca le organizzazioni (tenant) visibili all'utente | filtri di lista | Lista organizzazioni (id, nome) |
| `retrieve_organizations` | Dettaglio di un'organizzazione | `pk` (id organizzazione) | Oggetto organizzazione completo |
| `lookup_influencer` | Cerca un profilo influencer per piattaforma+handle | `organization`, `platform` (es. `instagram`, `tiktok`, `youtube`), `handle` | Profilo influencer corrispondente, se noto/già indicizzato |
| `get_influencer_audience` | Dati di audience/demografia di un influencer | `organization`, `platform`, `handle`, `category` (es. `gender`, `age`, `country`), `aggregated` (bool — se `true` ritorna un breakdown aggregato invece del dettaglio grezzo) | Breakdown audience per la categoria richiesta, calcolato sui dati già memorizzati |

Se un tool elencato qui **non compare** nella lista tool disponibili durante la sessione, significa che il servizio corrispondente non è abilitato per l'utente corrente (vedi "Accesso" sotto) — non è un errore da investigare lato codice.

## Vincoli importanti

- **Tutto è read-only.** Non esiste alcun tool di creazione/modifica/cancellazione in questo set — è pensato solo per interrogare dati esistenti.
- **Nessuna chiamata a pagamento.** `lookup_influencer` e `get_influencer_audience` leggono **solo dati già memorizzati** lato Relation: non triggerano refresh a provider a pagamento come HypeAuditor o Apify. Se un profilo/audience non è ancora presente nel database, il tool ritorna semplicemente "non trovato" — non va interpretato come malfunzionamento, e non c'è modo (da qui) di forzare un aggiornamento a pagamento.
- **Scoping per organizzazione.** Quasi tutti i tool richiedono/accettano `organization` per delimitare i dati al tenant corretto (un'organizzazione = un cliente/advertiser). Se l'utente non specifica l'organizzazione e ce n'è più di una visibile, usa prima `list_organizations` per disambiguare invece di assumere.

## Accesso

Questi tool sono disponibili solo se:
1. L'utente è marcato **`is_dev`**, e
2. Ha il **flag per-servizio** abilitato per Relation.

La connessione avviene tramite il **connettore MCP OAuth** configurato su claude.ai, puntato a `https://mcp.hoopygang.com/mcp/` con login Firebase. Non è previsto un transport MCP incluso in questo plugin — il plugin fornisce solo la skill di guida; la connessione va configurata separatamente (vedi README del plugin per i passi).

Se durante una sessione i tool sopra elencati non risultano disponibili, il problema più comune è che il servizio non è abilitato per l'utente collegato — non tentare workaround, segnala all'utente di verificare l'abilitazione lato admin.

## Esempio di flusso

"Mostrami le campagne attive dell'organizzazione Acme e l'audience Instagram di @creatorname"

1. Se l'organizzazione non è già nota per id, `list_organizations` (o chiedi all'utente) per risolvere `organization`.
2. `list_campaigns(organization=<id>, status=...)` per l'elenco campagne.
3. `lookup_influencer(organization=<id>, platform="instagram", handle="creatorname")` per risolvere il profilo.
4. `get_influencer_audience(organization=<id>, platform="instagram", handle="creatorname", category="age", aggregated=true)` (ripeti per le categorie richieste, es. `gender`, `country`).

## Rimandi ad altre skill

- Per task/planning legati a questo lavoro (es. "segna un task per verificare l'audience di X"), usa la skill `prowodo-tasks`, non questa.
- Per rilasci/versioning del servizio MCP stesso, usa `i3deploy-release`.
