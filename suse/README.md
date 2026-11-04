# SUSE agents

Rancher AI agents for SUSE products. This folder is a single Fleet bundle
deployed to `cattle-ai-agent-system` on the Rancher local cluster.

| Agent | What it does | MCP server |
|-------|--------------|------------|
| `appco` | Hardened images and charts, SBOMs, CVEs, migrations | [hosted by SUSE](https://docs.apps.rancher.io) |
| `sbomscanner` | Image and workload vulnerability reports, scan jobs, VEX | [SBOMscanner MCP](https://documentation.suse.com/cloudnative/vulnerability-scanner/latest/en/user-guide/mcp-server.html) |

Each `<agent>.yaml` starts with a comment giving its Secret, notes specific to
Rancher AI, and the fields to **Edit** (for example `spec.mcpURL`).

## Secrets
Credentials are not stored in git. Create them in `cattle-ai-agent-system`
before or after deploying (see the [main README](../README.md#secrets)):

- `appco`: `ai-agent-appco-auth` (`kubernetes.io/basic-auth`). Use your
  Application Collection user and an access token as the password; see
  [Authentication](https://docs.apps.rancher.io/get-started/authentication/).
- `sbomscanner`:
  - `ai-agent-sbomscanner-auth` (`kubernetes.io/basic-auth`): the username and
    password from the secret referenced by the server's `mcp.auth.secretName`.
    See [MCP server](https://documentation.suse.com/cloudnative/vulnerability-scanner/latest/en/user-guide/mcp-server.html).
  - `sbomscanner-mcp-ca` (`Opaque`): the `ca.crt` key copied from the server's
    TLS secret (`sbomscanner-mcp-tls`). Refresh it when the certificate is renewed.

## Add an agent
See [Add an agent](../README.md#add-an-agent), then add one row to the table
and one bullet under Secrets.
