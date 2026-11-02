# Atlassian Rovo

Connects Rancher AI to the Atlassian Rovo MCP server, so the assistant can
search, read, create and update Jira work items and Confluence content. When it
takes part in network troubleshooting, it always opens a Jira request for the
network team. The request includes source and destination CIDRs, ports and
evidence.

MCP server: hosted by Atlassian at `https://mcp.atlassian.com/v2/mcp`, so there is
nothing to install. See the [Atlassian Rovo MCP server documentation](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/)
and [Configure authentication via API token](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/).
**Prerequisite:** an organization admin must allow API token authentication for
the Rovo MCP server. See
[Control Atlassian MCP server settings](https://support.atlassian.com/security-and-access-policies/docs/control-atlassian-mcp-server-settings/).

## Configuration

### GitHub variables

Rendered into `secret.yaml` from `secret.yaml.tpl`.

| Name | Required | Description |
|------|----------|-------------|
| `ROVO_USERNAME` | yes | Email address of the Atlassian account that owns the API token |
| `ROVO_API_TOKEN` | yes | [Atlassian API token](https://id.atlassian.com/manage-profile/security/api-tokens) scoped for the Rovo MCP app |

### Settings in aiagentconfig.yaml

Edit these directly in your fork:

- `spec.mcpURL`: default `https://mcp.atlassian.com/v2/mcp`
- `spec.enabled`: default `true`
- In the Guidelines (`spec.systemPrompt`):
  - **Jira project** (*Network request settings*): default `not configured
    (ask the user for the project key; do not guess one)`. **Replace it with
    your network team's project key** (for example `NET`), otherwise the agent
    asks for it every time it opens a network request.
  - **Issue type**: default `Task`.
  - **Labels**: default `network-request,rancher-ai`.
  - **Default Atlassian site** (*Site first* directive): default `not
    configured`. Set it (for example `example.atlassian.net`) if several sites
    are reachable; otherwise the agent asks which one to use.

## Rancher AI notes
- **Authentication.** The agent uses BASIC authentication. The
  `ai-agent-rovo-auth` Secret holds the account email as `username` and the API
  token as `password`, rendered from the GitHub variables above. The agent
  sees and changes exactly what that account can, so use a dedicated account.
  Rotate the token before it expires: update `ROVO_API_TOKEN` and run the
  *Render agent secrets* workflow again.
- **Approvals.** Every Jira or Confluence write requires approval in the chat
  through `humanValidationTools`. This includes the deferred
  `executeWrite` and `executeDestructive` tools. Do not add `?tools=all` to the
  MCP URL: it exposes write tools under names that this list does not cover.
- **Hand-offs.** The agent asks the built-in **Rancher** agent for cluster,
  node, pod and service CIDRs to fill in network request tickets. It also
  receives firewall change requests from the
  [`ovh-network`](../ovh-network/README.md) agent.
