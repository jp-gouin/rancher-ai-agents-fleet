# Rendered into secret.yaml by the "Render agent secrets" workflow from GitHub
# variables. ${NAME} is required, ${NAME:-default} is optional.
# The rendered secret.yaml contains credentials in plain text: keep your fork PRIVATE.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-rovo-auth
  namespace: cattle-ai-agent-system
type: kubernetes.io/basic-auth
stringData:
  username: ${ROVO_USERNAME}
  password: ${ROVO_API_TOKEN}
