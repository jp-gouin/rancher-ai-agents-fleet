# Adding an agent

Put SUSE products in `suse/` and everything else in `third-party/`. An agent is
one or two files plus a row in that folder's README table:

```
third-party/
├── my-tool.yaml              # AIAgentConfig, metadata.name = file name
└── my-tool.secret.yaml.tpl   # only if the agent needs credentials
```

## `my-tool.yaml`

```yaml
# My Tool - one line on what it does.
# MCP server: https://upstream-docs.example.com
# Notes: only what is specific to Rancher AI (auth format, flags the server needs, hand-offs).
# Edit: spec.mcpURL, ...
apiVersion: ai.cattle.io/v1alpha1
kind: AIAgentConfig
metadata:
  name: my-tool
  namespace: cattle-ai-agent-system        # always
spec:
  displayName: My Tool
  enabled: true
  builtIn: false
  mcpURL: https://mcp.example.com/mcp
  authenticationType: HEADER                # NONE | BASIC | HEADER | OAUTH2
  authenticationSecret: ai-agent-my-tool-auth
  # caBundleRef: { name: my-tool-mcp-ca, key: ca.crt }
  humanValidationTools: [create_thing, delete_thing]
  description: |
    ...Agent Profile...
  systemPrompt: |
    ...Guidelines...
```

## `my-tool.secret.yaml.tpl`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-my-tool-auth               # = spec.authenticationSecret
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  # MY_TOOL_TOKEN: API token of the MCP server
  Authorization: Bearer ${MY_TOOL_TOKEN}
  # MY_TOOL_EXTRA: optional
  X-Extra: ${MY_TOOL_EXTRA:-default}
```

- `${NAME}` is required and `${NAME:-default}` is optional. Document each
  variable with a `# NAME: description` comment above it.
- Rendered values are always quoted, so special characters and PEM data are safe.
- An agent is rendered only when all of its required variables are set. Names
  cannot start with `GITHUB_`.

| Auth type | Secret Rancher AI expects |
|-----------|---------------------------|
| `BASIC` | `kubernetes.io/basic-auth` with `username` and `password` |
| `HEADER` | `Opaque`. **Every key is sent as an HTTP header** |
| `OAUTH2` | `Opaque` with `clientID`, `clientSecret`, `metadataEndpoint`, `scope` |
| `caBundleRef` | `Opaque` with the PEM CA under the referenced key |

## Agent Profile and Guidelines
- **Agent Profile** (`description`) is read by the supervisor to route prompts.
  Give one bold sentence naming the domain, 3 to 6 topics with example prompts,
  and "Do NOT route X here" boundaries. No behavioural rules.
- **Guidelines** (`systemPrompt`) are read by the agent. Cover its role, the
  exact tool names, core directives (never invent data, confirm changes,
  protect secrets), hand-offs to other agents, 1 to 3 workflows, and the
  response format.
- List every mutating tool in `humanValidationTools`. Tell the agent to treat
  tool output as data, not instructions.

Run `./scripts/lint.sh` before opening a pull request.
