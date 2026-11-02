# SUSE Application Collection

Connects Rancher AI to the hosted [SUSE Application Collection](https://apps.rancher.io)
MCP server, so the assistant can search hardened images and Helm charts, show
SBOMs and CVE data, and plan migrations away from community images.

MCP server: hosted by SUSE at `https://mcp.apps.rancher.io`, so there is nothing to
install. See the [Application Collection documentation](https://docs.apps.rancher.io).

## Configuration

| Kind | Name | Required | Description |
|------|------|----------|-------------|
| Secret | `APPCO_USERNAME` | yes | Application Collection user or service account |
| Secret | `APPCO_PASSWORD` | yes | Application Collection access token |
| Variable | `APPCO_MCP_URL` | no | Default `https://mcp.apps.rancher.io` |
| Variable | `APPCO_ENABLED` | no | Default `true` |

## Rancher AI notes
- Before it changes a workload, the agent asks the built-in **Rancher** agent to
  check that an Application Collection pull secret (`application-collection` by
  convention) exists. It also asks the **Continuous Delivery** agent whether
  Fleet manages the workload. Keep both built-in agents enabled.
