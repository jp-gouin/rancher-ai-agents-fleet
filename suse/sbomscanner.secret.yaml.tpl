# Rendered to sbomscanner.secret.yaml from GitHub variables by the Render agent secrets workflow.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-sbomscanner-auth
  namespace: cattle-ai-agent-system
type: kubernetes.io/basic-auth
stringData:
  # SBOMSCANNER_MCP_USERNAME: MCP username (from the server's mcp.auth secret)
  username: ${SBOMSCANNER_MCP_USERNAME}
  # SBOMSCANNER_MCP_PASSWORD: MCP password (from the server's mcp.auth secret)
  password: ${SBOMSCANNER_MCP_PASSWORD}
---
apiVersion: v1
kind: Secret
metadata:
  name: sbomscanner-mcp-ca
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  # SBOMSCANNER_MCP_CA: PEM CA of the MCP server certificate
  ca.crt: ${SBOMSCANNER_MCP_CA}
