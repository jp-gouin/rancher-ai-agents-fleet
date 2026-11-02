# Kubernetes MCP

Connects Rancher AI to an in-cluster
[containers/kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server),
so the assistant can inspect and troubleshoot the Rancher local (management)
cluster: list and get any resource, read pod logs (including the previous
crashed container), list events, and show Metrics Server usage. Writes and
downstream clusters stay with the built-in Rancher agent.

MCP server: install it yourself in the local cluster. See the upstream
[Kubernetes guide](https://github.com/containers/kubernetes-mcp-server/blob/main/docs/getting-started-kubernetes.md),
[Helm chart](https://github.com/containers/kubernetes-mcp-server/tree/main/charts/kubernetes-mcp-server)
and [configuration reference](https://github.com/containers/kubernetes-mcp-server/blob/main/docs/configuration.md).

## Configuration

### GitHub variables

None. The agent uses `authenticationType: NONE`, so there is no
`secret.yaml.tpl` and no Secret to render.

### Settings in aiagentconfig.yaml

Edit these directly in your fork:

- `spec.mcpURL`: default `http://kubernetes-mcp-server.kubernetes-mcp.svc.cluster.local:8080/mcp`
- `spec.enabled`: default `true`

## Rancher AI notes
- The Guidelines assume a read-only server. Run it with `read_only = true` and
  `disable_destructive = true`, deny the `Secret` kind (`[[denied_resources]]`),
  and bind its ServiceAccount to a read-only ClusterRole such as `view`. Never
  use `edit` or `cluster-admin`.
- Rancher AI reaches the server in-cluster without authentication, so anyone
  who can reach the Service gets its ServiceAccount's read access. Restrict
  ingress to the Rancher AI agent pods (`app=rancher-ai-agent` in
  `cattle-ai-agent-system`) with a NetworkPolicy, and do not expose it through
  an Ingress.
- Writes, downstream clusters and multi-cluster questions are handed off to
  the built-in **Rancher** agent, and Fleet questions to the **Continuous
  Delivery** agent. Keep both enabled.
