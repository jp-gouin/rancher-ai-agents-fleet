# GitHub

Connects Rancher AI to GitHub's official remote MCP server, so the assistant can
read repositories, review and open pull requests, manage issues and diagnose
GitHub Actions runs. It is designed for GitOps work: the agent reads the Fleet
repository, then opens a pull request with the change instead of patching the
live cluster.

MCP server: hosted by GitHub at `https://api.githubcopilot.com/mcp/`, so there is
nothing to install. See the [remote server documentation](https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md)
for endpoint variants (for example `/readonly`) and toolsets, and
[Managing personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
to create a token. A fine-grained PAT limited to the repositories the agent
needs is recommended.

## Configuration

| Kind | Name | Required | Description |
|------|------|----------|-------------|
| Secret | `GH_MCP_TOKEN` | yes | `Authorization` header value: `Bearer <PAT>`, including the `Bearer ` prefix |
| Secret | `GH_MCP_TOOLSETS` | no | Comma-separated toolsets sent as `X-MCP-Toolsets`. Default `context,repos,issues,pull_requests,users,actions` |
| Variable | `GH_MCP_URL` | no | Default `https://api.githubcopilot.com/mcp/`. Use `https://api.githubcopilot.com/mcp/readonly` for read tools only |
| Variable | `GH_MCP_ENABLED` | no | Default `true` |

## Rancher AI notes
- Authentication is `HEADER`: Rancher AI sends every key of the
  `ai-agent-github-auth` secret as an HTTP header, so the server receives
  `Authorization: Bearer <PAT>` and `X-MCP-Toolsets: <toolsets>`.
- Write tools (files, branches, pull requests, issues, comments, workflow runs)
  are listed in `humanValidationTools`, so Rancher AI asks the user to approve
  each call.
- Before it proposes a change in Git, the agent asks the built-in **Continuous
  Delivery** agent which GitRepo, branch and paths deploy a workload. Keep it
  enabled, along with the **Rancher** agent for live cluster state.
- OAuth2 (each user signs in to GitHub) is possible instead of a shared PAT:
  register a GitHub OAuth App, create the OAuth2 secret yourself and change
  `authenticationType`/`authenticationSecret` in your fork. Headers, including
  `X-MCP-Toolsets`, are not sent in OAuth2 mode, so select toolsets through the
  URL instead.
