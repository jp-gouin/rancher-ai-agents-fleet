# Rendered to appco.secret.yaml from GitHub variables by the Render agent secrets workflow.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-appco-auth
  namespace: cattle-ai-agent-system
type: kubernetes.io/basic-auth
stringData:
  # APPCO_USERNAME: Application Collection user or service account
  username: ${APPCO_USERNAME}
  # APPCO_PASSWORD: Application Collection access token
  password: ${APPCO_PASSWORD}
