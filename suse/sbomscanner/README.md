# SBOMscanner

Connects Rancher AI to the [SBOMscanner](https://github.com/kubewarden/sbomscanner)
MCP server running in the local cluster, so the assistant can report the
vulnerabilities of scanned images, workloads and nodes, give a security-posture
overview, and manage Registries, ScanJobs, NodeScanJobs and VEXHubs. Write tools
(`create_*`, `update_*`, `delete_*`) require approval in the chat.

MCP server: part of SBOMscanner (experimental), enabled with the `mcp.*` Helm
values. See the [SBOMscanner MCP server documentation](https://documentation.suse.com/cloudnative/vulnerability-scanner/latest/en/user-guide/mcp-server.html).

## Configuration

### GitHub variables

| Name | Required | Description |
|------|----------|-------------|
| `SBOMSCANNER_MCP_USERNAME` | yes | `username` of the server's `mcp.auth` secret |
| `SBOMSCANNER_MCP_PASSWORD` | yes | `password` of the server's `mcp.auth` secret |
| `SBOMSCANNER_MCP_CA` | yes | PEM CA certificate of the MCP server: the `ca.crt` key of its TLS secret (`sbomscanner-mcp-tls` by default) |

### Settings in aiagentconfig.yaml

- `spec.mcpURL`: default `https://sbomscanner-mcp.sbomscanner.svc.cluster.local:8222`.
- `spec.enabled`: default `true`.
- `Ignored namespaces` line in the system prompt (Excluded resources): namespaces
  the agent leaves out of its answers. Default `cattle-ai-agent-system`.
- `Ignored images` line in the system prompt: comma-separated image references
  to leave out, `*` wildcard allowed. Default `none`.

## Rancher AI notes
- Rancher AI authenticates with BASIC auth: the username and password variables
  must match the secret referenced by the server's `mcp.auth.secretName`.
- The MCP server uses a self-signed cert-manager certificate. Read its CA with:
  `kubectl -n sbomscanner get secret sbomscanner-mcp-tls -o jsonpath='{.data.ca\.crt}' | base64 -d`.
  The CA changes when cert-manager renews the certificate: update
  `SBOMSCANNER_MCP_CA` then.
- Rancher Apps installs use release `rancher-sbomscanner` in
  `cattle-sbomscanner-system`: set `spec.mcpURL` to
  `https://rancher-sbomscanner-mcp.cattle-sbomscanner-system.svc.cluster.local:8222`
  and read the CA from secret `rancher-sbomscanner-mcp-tls` in
  `cattle-sbomscanner-system`.
- For hardened replacements of the vulnerable images it reports, keep the
  **SUSE Application Collection** agent (`appco`) enabled.
