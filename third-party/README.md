# Third-party agents

Rancher AI agents for third-party MCP servers. This folder is a single Fleet
bundle deployed to `cattle-ai-agent-system` on the Rancher local cluster.

| Agent | What it does | MCP server | GitHub variables |
|-------|--------------|------------|------------------|
| `argocd` | Read-only Argo CD inventory, sync/health, drift | [mcp-for-argocd](https://github.com/argoproj-labs/mcp-for-argocd) | `ARGOCD_MCP_TOKEN` |
| `github` | Repos, PRs, issues, Actions; GitOps changes as PRs | [GitHub remote MCP](https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md) | `GH_MCP_TOKEN`, `GH_MCP_TOOLSETS`* |
| `kubernetes-mcp` | Read-only introspection of the Rancher local cluster | [kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server) | none |
| `ovh-dedicated-server` | Bare-metal inventory, tasks, reboots (approved) | [OVHcloud MCP](https://labs.ovhcloud.com/en/mcp-server/) | `OVH_CLIENT_ID`, `OVH_CLIENT_SECRET`, `OVH_OAUTH_*`* |
| `ovh-network` | IPs, Edge Network Firewall, DDoS; files firewall tickets | [OVHcloud MCP](https://labs.ovhcloud.com/en/mcp-server/) | same as `ovh-dedicated-server` |
| `rovo` | Jira and Confluence; opens network request tickets | [Atlassian Rovo MCP](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/) | `ROVO_USERNAME`, `ROVO_API_TOKEN` |

\* optional

The agents work together. `ovh-network` diagnoses a blocked flow and hands the
firewall request to `rovo`. `github` and `kubernetes-mcp` hand writes and Fleet
questions to the built-in Rancher and Continuous Delivery agents.

## Files
- `<agent>.yaml`: the `AIAgentConfig`. The comment header gives the MCP server
  link, notes specific to Rancher AI, and which fields to **Edit** (for example
  `spec.mcpURL` or the Jira project key in the Guidelines).
- `<agent>.secret.yaml.tpl`: its credentials Secret. Each `${VARIABLE}` is
  described in a comment above it. The **Render agent secrets** workflow turns
  it into `<agent>.secret.yaml`.

## Use
1. Edit the fields listed in each header. Delete the files of agents you don't use.
2. Set the GitHub variables above, then run **Render agent secrets**.
3. Fleet deploys everything in this folder (GitRepo path `third-party`).

## Add an agent
Add `<name>.yaml` (and `<name>.secret.yaml.tpl` if it needs credentials),
starting with the same comment header, then add one row to the table above.
`./scripts/lint.sh` checks the rest. See [docs/adding-an-agent.md](../docs/adding-an-agent.md).
