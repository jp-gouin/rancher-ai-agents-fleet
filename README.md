# Rancher AI agents with Fleet

A [Fleet](https://fleet.rancher.io) repository of custom **Rancher AI agents**
(`AIAgentConfig`). Fork it, adjust the agents, create their Secrets on the
cluster, and point Fleet at your fork. Fleet deploys the agents to
`cattle-ai-agent-system` on the Rancher local cluster.

| Folder | Agents |
|--------|--------|
| [`suse/`](suse) | SUSE Application Collection, SBOMscanner |
| [`third-party/`](third-party) | Argo CD, GitHub, Kubernetes MCP, OVHcloud (dedicated server, network), Atlassian Rovo |

Each folder is one Fleet bundle. Its README lists the agents, their MCP server,
and the Secret each one needs. Every agent has a detailed Agent Profile
(`description`, used for routing) and Guidelines (`systemPrompt`). Tools that
should need approval in the chat are suggested in a commented-out
`humanValidationTools` list: check the tool names your MCP server exposes, then
uncomment it. This repository does not install MCP servers; each agent links to
its upstream docs.

## Quick start
1. **Fork** this repository.
2. In each folder, edit the fields listed in each agent's comment header, and
   delete the agents you don't use.
3. **Create the Secrets** listed in the folder READMEs (see [Secrets](#secrets)).
4. In Rancher, open **Continuous Delivery → Git Repos** in workspace
   `fleet-local` and add your fork: branch `main`, paths `suse` and/or
   `third-party`. Or apply [`examples/gitrepo.yaml`](examples/gitrepo.yaml).
5. Check with `kubectl get aiagentconfig -n cattle-ai-agent-system`.

Fleet takes over (`helm.takeOwnership`) any agent with the same name that you
created in the Rancher UI. Back those up first.

## Secrets
Following [Fleet best practices](https://fleet.rancher.io/tutorials/best-practices#_use_valuesfrom_do_not_store_plain_text_secrets_in_git),
credentials are never stored in git. Each agent references a Secret by name in
`spec.authenticationSecret` (and `spec.caBundleRef`). You create that Secret in
`cattle-ai-agent-system`, filling in the values as the upstream docs linked in
the folder READMEs describe. For example:

```bash
kubectl -n cattle-ai-agent-system create secret generic ai-agent-rovo-auth \
  --type=kubernetes.io/basic-auth --from-literal=username=<email> --from-literal=password=<api-token>
```

You can also use the Rancher UI (**Storage → Secrets**) or a secret manager
such as [External Secrets](https://external-secrets.io) or
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets).

| Auth type | Secret Rancher AI expects |
|-----------|---------------------------|
| `BASIC` | `kubernetes.io/basic-auth` with `username` and `password` |
| `HEADER` | `Opaque`. **Every key is sent as an HTTP header** (e.g. `Authorization`) |
| `OAUTH2` | `Opaque` with `clientID`, `clientSecret`, `metadataEndpoint`, `scope` |
| `caBundleRef` | `Opaque` with the PEM CA under the referenced key (default `ca.crt`) |

## Add an agent
Put SUSE products in `suse/` and everything else in `third-party/`:

1. Add **`<name>.yaml`**: an `AIAgentConfig` with `metadata.name: <name>` and
   `namespace: cattle-ai-agent-system`. Start it with a short comment: what it
   does, the upstream MCP link, the Secret it needs, notes specific to Rancher
   AI, and the fields to edit. Copy an existing agent as a starting point.
   - **Agent Profile** (`description`): what the agent covers, example prompts,
     and "Do NOT route X here" boundaries. The supervisor uses it to route.
   - **Guidelines** (`systemPrompt`): role, rules, hand-offs to other agents,
     workflows, and response format. Don't describe the tools: Rancher AI adds
     them to the system prompt automatically.
   - Suggest the mutating tools as a commented-out `humanValidationTools` list.
2. In the folder README, add one table row and one **Secrets** bullet (name,
   type, keys, and an upstream link explaining how to get the values).
3. Never commit a Secret.

## License
[Apache 2.0](LICENSE)
