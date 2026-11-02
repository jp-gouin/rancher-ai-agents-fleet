# Argo CD

Connects Rancher AI to an Argo CD MCP server, so the assistant can list Argo CD
Applications, report their sync and health status, detect drift from Git, walk
the resource tree and read the logs and events of managed workloads. The agent
is read-only: it diagnoses, it does not sync, create, change or delete
Applications.

MCP server: [argoproj-labs/mcp-for-argocd](https://github.com/argoproj-labs/mcp-for-argocd).
See its documentation to install and configure it.

## Configuration

### GitHub variables

| Name | Required | Description |
|------|----------|-------------|
| `ARGOCD_MCP_TOKEN` | yes | `MCP_AUTH_TOKEN` set on the MCP server. The template adds the `Bearer ` prefix |

### Settings in aiagentconfig.yaml

- `spec.mcpURL`: example value `https://argocd-mcp.example.com/mcp`, marked
  `# EDIT`. You must change it to the `/mcp` endpoint of your MCP server.
- `spec.enabled`: default `true`.
- `Argo CD web UI` line in the system prompt (Environment): default
  `not configured`. Set it to your Argo CD UI URL, for example
  `https://argocd.example.com`, to get deep links in answers.

## Rancher AI notes
- Run the MCP server with the HTTP transport and expose its `/mcp` endpoint so
  that it is reachable from the Rancher local cluster (where the Rancher AI agent
  runs), not only from the cluster that runs Argo CD.
- Authentication is `HEADER`: Rancher AI sends every key of the
  `ai-agent-argocd-auth` secret as an HTTP header. The only key is
  `Authorization: Bearer <ARGOCD_MCP_TOKEN>`. The Argo CD API token stays on the
  MCP server and never goes through Rancher AI.
- Run the MCP server in read-only mode (`MCP_READ_ONLY=true`), ideally with a
  read-only Argo CD account. The mutating tools are also listed in
  `humanValidationTools`, so the user must confirm them if read-only mode is off.
- The supervisor routes Rancher Fleet prompts to the built-in **Continuous
  Delivery** agent and general Kubernetes administration to the **Rancher**
  agent.
