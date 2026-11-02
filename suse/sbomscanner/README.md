# SBOMscanner

Connects Rancher AI to the [SBOMscanner](https://github.com/kubewarden/sbomscanner)
MCP server running in the local cluster, so the assistant can report the
vulnerabilities of scanned images, workloads and nodes, give a security-posture
overview, and manage Registries, ScanJobs, NodeScanJobs and VEXHubs. Write tools
(`create_*`, `update_*`, `delete_*`) require approval in the chat.

MCP server: part of SBOMscanner (experimental), enabled with the `mcp.*` Helm
values. See the [SBOMscanner MCP server documentation](https://documentation.suse.com/cloudnative/vulnerability-scanner/latest/en/user-guide/mcp-server.html).

## Configuration

| Kind | Name | Required | Description |
|------|------|----------|-------------|
| Secret | `SBOMSCANNER_MCP_USERNAME` | yes | `username` of the server's `mcp.auth` secret |
| Secret | `SBOMSCANNER_MCP_PASSWORD` | yes | `password` of the server's `mcp.auth` secret |
| Variable | `SBOMSCANNER_MCP_URL` | no | Default `https://sbomscanner-mcp.sbomscanner.svc.cluster.local:8222` |
| Variable | `SBOMSCANNER_NAMESPACE` | no | Namespace of SBOMscanner, to copy the MCP CA. Default `sbomscanner` |
| Variable | `SBOMSCANNER_MCP_TLS_SECRET` | no | TLS secret of the MCP server. Default `sbomscanner-mcp-tls` |
| Variable | `SBOMSCANNER_IGNORE_NAMESPACES` | no | Comma-separated namespaces the agent leaves out of its answers. Default `cattle-ai-agent-system` (setting it replaces the default) |
| Variable | `SBOMSCANNER_IGNORE_IMAGES` | no | Comma-separated image references to leave out, `*` wildcard allowed. Default `none` |
| Variable | `SBOMSCANNER_ENABLED` | no | Default `true` |

## Rancher AI notes
- Rancher AI authenticates with BASIC auth: the two GitHub secrets must hold the
  same `username` and `password` as the secret referenced by the server's
  `mcp.auth.secretName`.
- The MCP server uses a self-signed cert-manager certificate. The deploy copies
  its CA (`<SBOMSCANNER_NAMESPACE>/<SBOMSCANNER_MCP_TLS_SECRET>`, key `ca.crt`)
  to `cattle-ai-agent-system/sbomscanner-mcp-ca`, which the agent uses as
  `caBundleRef`. Re-run the deploy after cert-manager renews the certificate.
- Rancher Apps installs use release `rancher-sbomscanner` in
  `cattle-sbomscanner-system`: set `SBOMSCANNER_MCP_URL` to
  `https://rancher-sbomscanner-mcp.cattle-sbomscanner-system.svc.cluster.local:8222`,
  `SBOMSCANNER_NAMESPACE` to `cattle-sbomscanner-system` and
  `SBOMSCANNER_MCP_TLS_SECRET` to `rancher-sbomscanner-mcp-tls`.
- For hardened replacements of the vulnerable images it reports, keep the
  **SUSE Application Collection** agent (`appco`) enabled.
