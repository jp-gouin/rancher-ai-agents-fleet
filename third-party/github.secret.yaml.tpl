# Rendered to github.secret.yaml from GitHub variables by the Render agent secrets workflow.
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-github-auth
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  # GH_MCP_TOKEN: GitHub personal access token
  Authorization: Bearer ${GH_MCP_TOKEN}
  # GH_MCP_TOOLSETS: optional, comma-separated toolsets
  X-MCP-Toolsets: ${GH_MCP_TOOLSETS:-context,repos,issues,pull_requests,users,actions}
