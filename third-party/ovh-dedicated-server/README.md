# OVHcloud Dedicated Server

Connects Rancher AI to the `v1_dedicated_server` section of the official OVHcloud
MCP server. The assistant can inventory OVHcloud bare-metal servers, match them
to Rancher cluster nodes, and check hardware, tasks and datacenter interventions.
After you confirm, it can also run server operations: reboot, rescue boot,
reinstall and hardware replacement requests.

MCP server: hosted by OVHcloud, one endpoint per region (EU, CA, US), so there is
nothing to install. See the [OVHcloud MCP server documentation](https://labs.ovhcloud.com/en/mcp-server/).

## Configuration

### GitHub variables

Rendered into `secret.yaml` from `secret.yaml.tpl`. Shared with `ovh-network`.

| Name | Required | Description |
|------|----------|-------------|
| `OVH_CLIENT_ID` | yes | OAuth2 client ID registered on the OVHcloud MCP OAuth proxy |
| `OVH_CLIENT_SECRET` | yes | OAuth2 client secret |
| `OVH_OAUTH_METADATA_ENDPOINT` | no | Default `https://mcp.eu.ovhcloud.com/.well-known/oauth-authorization-server/oauth-proxy` (use `mcp.ca.` / `mcp.us.` for other regions) |
| `OVH_OAUTH_SCOPE` | no | Default `all` |

### Settings in aiagentconfig.yaml

Edit these directly in your fork:

- `spec.mcpURL`: default `https://mcp.eu.ovhcloud.com/mcp/v1_dedicated_server`
  (use `mcp.ca.` / `mcp.us.` for other regions, matching
  `OVH_OAUTH_METADATA_ENDPOINT`)
- `spec.enabled`: default `true`

## Rancher AI notes
- **OAuth2 login per user.** The OAuth2 scope defaults to `all`
  (`OVH_OAUTH_SCOPE`). The first time you use the agent, Rancher AI opens an
  OVHcloud login popup. After that, the agent can do whatever your OVHcloud account (or IAM identity) can do.
- **Registering the client.** The OVHcloud OAuth proxy supports dynamic client
  registration, so you do not create anything in the OVHcloud Control Panel.
  The client must be registered with the Rancher AI callback URL of your
  Rancher server:
  `https://<rancher-host>/api/v1/namespaces/cattle-ai-agent-system/services/http:rancher-ai-agent:80/proxy/v1/api/oauth2/callback`.
  The simplest way to do this:
  1. In the Rancher UI, go to *Rancher AI > Settings > Agents > Add agent*,
     choose OAuth2 and enter the MCP URL.
  2. Use the actions that discover the metadata endpoint and the client
     registration details automatically.
  3. Copy the client ID and secret into the `OVH_CLIENT_ID` and
     `OVH_CLIENT_SECRET` GitHub variables, then discard the draft agent.
     Fleet manages the real one.
- **One client for both OVH agents.** `ovh-dedicated-server` and `ovh-network`
  use the same authorization server, so they share the `OVH_*` GitHub variables.
  Each agent still gets its own Kubernetes Secret and token. If the two agents
  must use different regions, register one client per region.
- **Approvals.** Every state-changing, billing or credential-exposing tool is
  listed in `humanValidationTools`. Review that list when OVHcloud adds tools to
  the section.
- **Hand-offs.** Before a reboot or reinstall, the agent asks the built-in
  **Rancher** agent for node IPs and recommends cordon/drain. Firewall, DDoS and
  IP questions go to the `ovh-network` agent.
