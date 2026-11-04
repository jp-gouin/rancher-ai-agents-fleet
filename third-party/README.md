# Third-party agents

Rancher AI agents for third-party MCP servers. This folder is a single Fleet
bundle deployed to `cattle-ai-agent-system` on the Rancher local cluster.

| Agent | What it does | MCP server |
|-------|--------------|------------|
| `argocd` | Read-only Argo CD inventory, sync/health, drift | [mcp-for-argocd](https://github.com/argoproj-labs/mcp-for-argocd) |
| `github` | Repos, PRs, issues, Actions; GitOps changes as PRs | [GitHub remote MCP](https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md) |
| `kubernetes-mcp` | Read-only introspection of the Rancher local cluster | [kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server) |
| `ovh-dedicated-server` | Bare-metal inventory, tasks, interventions, reboots | [OVHcloud MCP](https://labs.ovhcloud.com/en/mcp-server/) |
| `ovh-network` | IPs, Edge Network Firewall, DDoS; files firewall tickets | [OVHcloud MCP](https://labs.ovhcloud.com/en/mcp-server/) |
| `rovo` | Jira and Confluence; opens network request tickets | [Atlassian Rovo MCP](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/) |

The agents work together. `ovh-network` hands firewall requests to `rovo`, and
writes and Fleet questions go to the built-in Rancher and Continuous Delivery
agents. Each `<agent>.yaml` starts with a comment giving its Secret, notes
specific to Rancher AI, and the fields to **Edit**.

## Secrets
Credentials are not stored in git. Create them in `cattle-ai-agent-system`
(see the [main README](../README.md#secrets)):

- `argocd`: `ai-agent-argocd-auth` (`Opaque`), with
  `Authorization=Bearer <token>`. The token is the server's `MCP_AUTH_TOKEN`;
  see [mcp-for-argocd](https://github.com/argoproj-labs/mcp-for-argocd).
- `github`: `ai-agent-github-auth` (`Opaque`), with
  `Authorization=Bearer <PAT>` and an optional `X-MCP-Toolsets`. See
  [personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  and the [remote server docs](https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md).
- `kubernetes-mcp`: none.
- `ovh-dedicated-server` and `ovh-network`: `ai-agent-ovh-dedicated-server-auth`
  and `ai-agent-ovh-network-auth` (`Opaque`), with `clientID`, `clientSecret`, `metadataEndpoint`, and
  `scope=all`. Register the OAuth client dynamically, as described in the
  [OVHcloud MCP docs](https://labs.ovhcloud.com/en/mcp-server/). The Rancher AI
  UI can do it for you: *Add agent > OAuth2 > discover*.
- `rovo`: `ai-agent-rovo-auth` (`kubernetes.io/basic-auth`). The username is
  the account email and the password is an
  [API token](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/).
  An admin must [allow API-token auth](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/configuring-authentication-via-api-token/).

## Add an agent
See [Add an agent](../README.md#add-an-agent), then add one row to the table
and one bullet under Secrets.
