# Rendered into secret.yaml by the "Render agent secrets" workflow from GitHub
# variables. ${NAME} is required, ${NAME:-default} is optional.
# The rendered secret.yaml contains credentials in plain text: keep your fork PRIVATE.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-sbomscanner-auth
  namespace: cattle-ai-agent-system
type: kubernetes.io/basic-auth
stringData:
  username: ${SBOMSCANNER_MCP_USERNAME}
  password: ${SBOMSCANNER_MCP_PASSWORD}
---
# CA of the SBOMscanner MCP server certificate (spec.caBundleRef). Copy it from
# the ca.crt key of the MCP server's TLS secret (sbomscanner-mcp-tls by default).
apiVersion: v1
kind: Secret
metadata:
  name: sbomscanner-mcp-ca
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  ca.crt: ${SBOMSCANNER_MCP_CA}
