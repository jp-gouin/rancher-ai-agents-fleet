# SUSE agents

Rancher AI agents for SUSE products. This folder is a single Fleet bundle
deployed to `cattle-ai-agent-system` on the Rancher local cluster.

| Agent | What it does | MCP server | GitHub variables |
|-------|--------------|------------|------------------|
| `appco` | Hardened images and charts, SBOMs, CVEs, migrations | [hosted by SUSE](https://docs.apps.rancher.io) | `APPCO_USERNAME`, `APPCO_PASSWORD` |
| `sbomscanner` | Image and workload vulnerability reports, scan jobs, VEX | [SBOMscanner MCP](https://documentation.suse.com/cloudnative/vulnerability-scanner/latest/en/user-guide/mcp-server.html) | `SBOMSCANNER_MCP_USERNAME`, `SBOMSCANNER_MCP_PASSWORD`, `SBOMSCANNER_MCP_CA` |

## Files
- `<agent>.yaml`: the `AIAgentConfig`. The comment header gives the MCP server
  link, notes specific to Rancher AI, and which fields to **Edit** (for example
  `spec.mcpURL`).
- `<agent>.secret.yaml.tpl`: its credentials Secret. Each `${VARIABLE}` is
  described in a comment above it. The **Render agent secrets** workflow turns
  it into `<agent>.secret.yaml`.

## Use
1. Edit the fields listed in each header. Delete the files of agents you don't use.
2. Set the GitHub variables above, then run **Render agent secrets**.
3. Fleet deploys everything in this folder (GitRepo path `suse`).

## Add an agent
See [Add an agent](../README.md#add-an-agent). Then add one row to the table above.
