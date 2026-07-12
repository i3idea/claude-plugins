# relations-mcp

Guidance skill for the **Relation** (Hoopygang) MCP tools — influencer, campaign
and audience analytics — directly from Claude Code or claude.ai. Modeled on
`prowodo-tasks`: this plugin ships only a skill, no MCP transport.

> **Preview status.** The skill content is accurate and ready to use, but the
> live MCP connector (`mcp.hoopygang.com`) only works once the OAuth connector
> (sotto-progetto A) and the per-service access flag (sotto-progetto B) are
> deployed to production. Until then, installing the plugin gives you the
> guidance skill with nothing to connect to yet.

## What it does

- Detects when you're asking about Relation influencers, campaigns, deals,
  organizations, or audience/demographic analytics (IT / EN / mixed)
- Loads a workflow guide that tells Claude how to use the Relation MCP tools
  idiomatically: `list_campaigns` / `retrieve_campaigns`,
  `list_influencers` / `retrieve_influencers`,
  `list_organizations` / `retrieve_organizations`, `lookup_influencer`,
  `get_influencer_audience`
- Documents the constraints that matter: everything is **read-only**, there
  are **no paid-provider calls** (no HypeAuditor/Apify refresh — reads stored
  data only), and results are scoped by `organization`

## Install

```
/plugin marketplace add i3idea/claude-plugins
/plugin install relations-mcp@i3idea
```

## Connect the Relation MCP server (claude.ai)

The Relation MCP server is a **claude.ai connector**, not a local transport —
this plugin does not bundle a `.mcp.json`. On claude.ai:

1. Go to **Settings → Connectors → Add custom connector**.
2. Point it at `https://mcp.hoopygang.com/mcp/`.
3. Authenticate via the OAuth flow (Firebase login) when prompted.

Once connected, the tools listed above become available to Claude whenever
this skill triggers.

## Access prerequisites

You need:
1. An account marked **`is_dev`**, and
2. The **per-service access flag** for Relation enabled for your account.

If the tools don't show up after connecting, the most common cause is that
the per-service flag isn't enabled yet for your account — check with an admin
rather than retrying the connection.

## Usage

Just talk to Claude naturally about Relation data:

- "Che campagne ha l'organizzazione Acme?" → lists campaigns for that org
- "Dammi l'audience Instagram di @creatorname" → age/gender/country breakdown
  from stored data
- "Cerca l'influencer @handle su TikTok" → resolves the profile via
  `lookup_influencer`
- "Elenco organizzazioni" → lists tenants visible to you

## License

MIT — see [../LICENSE](../LICENSE).
