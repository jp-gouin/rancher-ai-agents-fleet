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

| Kind | Name | Required | Description |
|------|------|----------|-------------|
| Secret | `ROVO_USERNAME` | yes | Email address of the Atlassian account that owns the API token |
| Secret | `ROVO_API_TOKEN` | yes | [Atlassian API token](https://id.atlassian.com/manage-profile/security/api-tokens) scoped for the Rovo MCP app |
| Variable | `ROVO_SITE` | no | Default site, e.g. `example.atlassian.net`. If unset and several sites are reachable, the agent asks |
| Variable | `ROVO_JIRA_PROJECT_KEY` | no | Jira project that receives network requests, e.g. `NET`. If unset, the agent asks |
| Variable | `ROVO_JIRA_ISSUE_TYPE` | no | Issue type for network requests. Default `Task` |
| Variable | `ROVO_JIRA_LABELS` | no | Labels for network requests. Default `network-request,rancher-ai` |
| Variable | `ROVO_MCP_URL` | no | Default `https://mcp.atlassian.com/v2/mcp` |
| Variable | `ROVO_ENABLED` | no | Default `true` |

## Rancher AI notes
- **Authentication.** The agent uses BASIC authentication. The
  `ai-agent-rovo-auth` Secret holds the account email as `username` and the API
  token as `password`. The agent sees and changes exactly what that account
  can, so use a dedicated account. Rotate `ROVO_API_TOKEN` before it expires.
- **Approvals.** Every Jira or Confluence write requires approval in the chat
  through `humanValidationTools`. This includes the deferred
  `executeWrite` and `executeDestructive` tools. Do not add `?tools=all` to the
  MCP URL: it exposes write tools under names that this list does not cover.
- **Hand-offs.** The agent asks the built-in **Rancher** agent for cluster,
  node, pod and service CIDRs to fill in network request tickets. It also
  receives firewall change requests from the
  [`ovh-network`](../ovh-network/README.md) agent.
