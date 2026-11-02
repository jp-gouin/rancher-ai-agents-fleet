# Rendered into secret.yaml by the "Render agent secrets" workflow from GitHub
# variables. ${NAME} is required, ${NAME:-default} is optional.
# The rendered secret.yaml contains credentials in plain text: keep your fork PRIVATE.
# HEADER auth: Rancher AI sends every key of this Secret as an HTTP header.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-argocd-auth
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  Authorization: Bearer ${ARGOCD_MCP_TOKEN}
