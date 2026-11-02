# Rendered to argocd.secret.yaml from GitHub variables by the Render agent secrets workflow.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-argocd-auth
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  # ARGOCD_MCP_TOKEN: MCP_AUTH_TOKEN of the Argo CD MCP server
  Authorization: Bearer ${ARGOCD_MCP_TOKEN}
