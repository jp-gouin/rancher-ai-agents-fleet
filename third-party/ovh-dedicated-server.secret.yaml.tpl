# Rendered to ovh-dedicated-server.secret.yaml from GitHub variables by the Render agent secrets workflow.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-ovh-dedicated-server-auth
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  # OVH_CLIENT_ID: OAuth2 client ID (shared by both OVHcloud agents)
  clientID: ${OVH_CLIENT_ID}
  # OVH_CLIENT_SECRET: OAuth2 client secret
  clientSecret: ${OVH_CLIENT_SECRET}
  # OVH_OAUTH_METADATA_ENDPOINT: optional, change for the ca/us regions
  metadataEndpoint: ${OVH_OAUTH_METADATA_ENDPOINT:-https://mcp.eu.ovhcloud.com/.well-known/oauth-authorization-server/oauth-proxy}
  # OVH_OAUTH_SCOPE: optional
  scope: ${OVH_OAUTH_SCOPE:-all}
