# Rendered into secret.yaml by the "Render agent secrets" workflow from GitHub
# variables. ${NAME} is required, ${NAME:-default} is optional.
# The rendered secret.yaml contains credentials in plain text: keep your fork PRIVATE.
# OAUTH2: both OVHcloud agents can share the same OAuth client.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-ovh-dedicated-server-auth
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  clientID: ${OVH_CLIENT_ID}
  clientSecret: ${OVH_CLIENT_SECRET}
  metadataEndpoint: ${OVH_OAUTH_METADATA_ENDPOINT:-https://mcp.eu.ovhcloud.com/.well-known/oauth-authorization-server/oauth-proxy}
  scope: ${OVH_OAUTH_SCOPE:-all}
