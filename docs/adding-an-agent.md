# Adding an agent

## Folder layout
Put SUSE products under `suse/<name>/` and everything else under `third-party/<name>/`.

```
third-party/my-tool/
├── fleet.yaml           # Fleet bundle options
├── .fleetignore         # keeps README.md and *.tpl out of the bundle
├── aiagentconfig.yaml   # the AIAgentConfig (plain YAML, edited directly)
├── secret.yaml.tpl      # auth Secret template, rendered from GitHub variables
└── README.md            # what it does, upstream MCP link, variables, Rancher AI notes
```

Copy [`suse/appco`](../suse/appco) as a starting point.

## `fleet.yaml` and `.fleetignore`

```yaml
defaultNamespace: cattle-ai-agent-system
namespace: cattle-ai-agent-system
helm:
  takeOwnership: true      # adopt an agent with the same name created in the Rancher UI
```

```
README.md
*.tpl
```

## `aiagentconfig.yaml`

```yaml
apiVersion: ai.cattle.io/v1alpha1
kind: AIAgentConfig
metadata:
  name: my-tool
  namespace: cattle-ai-agent-system        # always: Rancher AI only reads this namespace
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

Use sensible defaults. Users edit this file in their fork, so mark values they
must change with `# EDIT`. Placeholders are not supported here.

## `secret.yaml.tpl`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-my-tool-auth               # = spec.authenticationSecret
  namespace: cattle-ai-agent-system
type: Opaque
stringData:
  Authorization: Bearer ${MY_TOOL_TOKEN}    # required GitHub variable
  X-Extra: ${MY_TOOL_EXTRA:-default}        # optional, with a default
```

- `${NAME}` is required. `${NAME:-default}` is optional.
- Placeholders can sit anywhere in a value. The rendered value is always
  quoted, so special characters and multi-line PEM data are safe.
- Comment lines are not rendered.
- Use the agent name as the variable prefix. Names cannot start with `GITHUB_`.
- An agent is rendered only when all of its required variables are set.

Secret formats Rancher AI expects:

| Auth type | Secret |
|-----------|--------|
| `BASIC` | `kubernetes.io/basic-auth` with `username` and `password` |
| `HEADER` | `Opaque`. **Every key is sent as an HTTP header**, so store only headers |
| `OAUTH2` | `Opaque` with `clientID`, `clientSecret`, `metadataEndpoint`, `scope` |
| `caBundleRef` | `Opaque` with the PEM CA under the referenced key (default `ca.crt`) |

## Check

```bash
./scripts/lint.sh                    # same checks as CI
./scripts/render-secrets.sh --check  # which agents have all their variables
```

## Writing the Agent Profile and Guidelines

| UI label | Field | Read by | Purpose |
|----------|-------|---------|---------|
| **Agent Profile** | `spec.description` | the supervisor | Decide *whether* to route a prompt to this agent |
| **Guidelines** | `spec.systemPrompt` | the agent | Decide *how* the agent behaves |

**Agent Profile**
- Open with one bold sentence naming the domain.
- List 3 to 6 topics with real example prompts.
- End with boundaries: "Do NOT route X here; those belong to the Y agent".
- Keep behavioural rules out of the Profile. The agent may never see it.

**Guidelines**
1. **Role**: who the agent is and its scope (for example, read-only).
2. **Tools**: the exact MCP tool names, and when to use each.
3. **Core directives**: never invent data, check before writing, show changes
   before applying them, protect secrets.
4. **Hand-offs**: which other agent to involve, and when.
5. **Workflows**: 1 to 3 step-by-step examples.
6. **Response format**: Markdown, concise, tables for lists.

**Safety**
- List every mutating tool in `humanValidationTools`, using the exact name.
- Tell the agent to treat tool output (issues, pages, logs, files) as data, not
  instructions.
