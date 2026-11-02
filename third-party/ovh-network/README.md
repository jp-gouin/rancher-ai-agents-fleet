# OVHcloud Network

Connects Rancher AI to the `v1_ip` section of the official OVHcloud MCP server.
The assistant uses it to troubleshoot network access to clusters and servers
hosted at OVHcloud. It can check IP blocks, Edge Network Firewall rules, DDoS
mitigation, anti-hack and spam blocks, and reverse DNS. It never changes firewall
rules.

MCP server: hosted by OVHcloud, one endpoint per region (EU, CA, US), so there is
nothing to install. See the [OVHcloud MCP server documentation](https://labs.ovhcloud.com/en/mcp-server/).

## Configuration

### GitHub variables

Rendered into `secret.yaml` from `secret.yaml.tpl`. Shared with `ovh-dedicated-server`.

| Name | Required | Description |
|------|----------|-------------|
| `OVH_CLIENT_ID` | yes | OAuth2 client ID registered on the OVHcloud MCP OAuth proxy |
| `OVH_CLIENT_SECRET` | yes | OAuth2 client secret |
| `OVH_OAUTH_METADATA_ENDPOINT` | no | Default `https://mcp.eu.ovhcloud.com/.well-known/oauth-authorization-server/oauth-proxy` (use `mcp.ca.` / `mcp.us.` for other regions) |
| `OVH_OAUTH_SCOPE` | no | Default `all` |

### Settings in aiagentconfig.yaml

Edit these directly in your fork:

- `spec.mcpURL`: default `https://mcp.eu.ovhcloud.com/mcp/v1_ip`
  (use `mcp.ca.` / `mcp.us.` for other regions, matching
  `OVH_OAUTH_METADATA_ENDPOINT`)
- `spec.enabled`: default `true`

## Rancher AI notes
- **OAuth2 setup.** Login and client registration work the same way as for
  [`ovh-dedicated-server`](../ovh-dedicated-server/README.md#rancher-ai-notes),
  and both agents share the same `OVH_*` GitHub variables.
- **Is the cluster hosted at OVHcloud?** To decide, the agent asks the built-in
  **Rancher** agent for the cluster labels and node IPs, then matches the IPs
  against your OVHcloud IP blocks. It asks you only as a last resort.
- **No firewall changes. Use a ticket instead.** When a rule needs to change,
  the agent writes a change request: IP, source CIDR, protocol, ports, the
  conflicting rule and the evidence. It then asks the supervisor to hand the
  request to the [`rovo`](../rovo/README.md) (Atlassian Rovo) agent, which opens
  a Jira ticket. If `rovo` is not enabled, the agent returns a ticket body you
  can paste.
- **Approvals.** The only write tool in the section today is
  `update-ip-reverse`, and it requires approval. If OVHcloud adds firewall write
  tools, the Guidelines still forbid using them. Add those tools to
  `humanValidationTools` as well.
