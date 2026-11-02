# Rendered to rovo.secret.yaml from GitHub variables by the Render agent secrets workflow.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-rovo-auth
  namespace: cattle-ai-agent-system
type: kubernetes.io/basic-auth
stringData:
  # ROVO_USERNAME: Atlassian account email
  username: ${ROVO_USERNAME}
  # ROVO_API_TOKEN: Atlassian API token
  password: ${ROVO_API_TOKEN}
