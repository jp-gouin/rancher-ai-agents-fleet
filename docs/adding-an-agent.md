# Adding an agent

## 1. Create the folder
Put SUSE products under `suse/<name>/` and everything else under `third-party/<name>/`.
The folder needs three files:

```
third-party/my-tool/
├── aiagentconfig.yaml   # the AIAgentConfig, with ${VARIABLE} placeholders
├── agent.yaml           # which GitHub secrets become which Kubernetes Secret keys
└── README.md            # what it does, upstream MCP link, configuration table, Rancher AI notes
```

Copy [`suse/appco`](../suse/appco) as a starting point.

## 2. `aiagentconfig.yaml`

```yaml
apiVersion: ai.cattle.io/v1alpha1
kind: AIAgentConfig
metadata:
  name: my-tool
  namespace: cattle-ai-agent-system        # always: Rancher AI only reads this namespace
spec:
  displayName: My Tool
  enabled: ${MY_TOOL_ENABLED:-true}
  builtIn: false
  mcpURL: ${MY_TOOL_MCP_URL}                # required variable: rendering fails if unset
  authenticationType: HEADER                # NONE | BASIC | HEADER | OAUTH2
  authenticationSecret: ai-agent-my-tool-auth
  # caBundleRef: { name: my-tool-mcp-ca, key: ca.crt }
  humanValidationTools: [create_thing, delete_thing]
  description: |
    ...Agent Profile...
  systemPrompt: |
    ...Guidelines...
```

Placeholders:

| Syntax | Behaviour |
|--------|-----------|
| `${NAME}` | Required: the deploy fails if the GitHub variable `NAME` is unset |
| `${NAME:-default}` | Optional: `default` is used when `NAME` is unset |

Values are inserted as plain text and must fit on one line. There are no
conditionals, so write prompts that still read naturally with the default, for
example `Jira project: ${MY_TOOL_PROJECT:-not configured (ask the user)}`. Use
the agent name as the variable prefix.

## 3. `agent.yaml`

```yaml
name: my-tool                              # = folder name
secret:                                    # omit for authenticationType NONE
  name: ai-agent-my-tool-auth              # = spec.authenticationSecret
  type: Opaque                             # kubernetes.io/basic-auth for BASIC
  data:                                    # <secret key>: <GitHub secret name>
    Authorization: MY_TOOL_MCP_AUTH_HEADER
  defaults:                                # <secret key>: <value> used when the GitHub secret is unset
    X-Extra-Header: value
  optional: false                          # true = skip instead of failing when unset
extraSecrets: []                           # more Secrets, same shape as `secret`
copySecrets:                               # copy a key from a Secret already on the cluster (e.g. a CA)
  - from: { namespace: my-tool, name: my-tool-tls, key: ca.crt,
            namespaceVar: MY_TOOL_NAMESPACE, nameVar: MY_TOOL_TLS_SECRET }   # optional variable overrides
    to:   { name: my-tool-mcp-ca, key: ca.crt }
    optional: false
```

Secret formats Rancher AI expects:

| Auth type | Secret |
|-----------|--------|
| `BASIC` | `kubernetes.io/basic-auth` with `username` and `password` |
| `HEADER` | `Opaque`. **Every key is sent as an HTTP header**, so store only headers (e.g. `Authorization: Bearer ...`) |
| `OAUTH2` | `Opaque` with `clientID`, `clientSecret`, `metadataEndpoint`, `scope` |

GitHub secret names cannot start with `GITHUB_`.

## 4. Wire the secrets and check

```bash
./scripts/wire-secrets.sh    # adds the new secrets to .github/workflows/deploy.yaml
./scripts/lint.sh            # same checks as CI
```

GitHub holds any run that reads all secrets at once (`toJSON(secrets)`) for
manual approval, so the workflow lists each secret explicitly.

## Writing the Agent Profile and Guidelines

| UI label | Field | Read by | Purpose |
|----------|-------|---------|---------|
| **Agent Profile** | `spec.description` | the supervisor | Decide *whether* to route a prompt to this agent |
| **Guidelines** | `spec.systemPrompt` | the agent | Decide *how* the agent behaves |

**Agent Profile**
- Open with one bold sentence naming the domain.
- List 3 to 6 topics with real example prompts.
- End with boundaries: "Do NOT route X here; those belong to the Y agent".
  Agents that overlap (Argo CD and Fleet, Kubernetes MCP and Rancher) need these most.
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
- Keep environment details in placeholders, not hard-coded.
