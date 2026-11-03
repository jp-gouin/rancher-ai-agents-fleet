# Rancher AI agents with Fleet

A template [Fleet](https://fleet.rancher.io) repository of custom **Rancher AI
agents** (`AIAgentConfig`). Fleet deploys them to `cattle-ai-agent-system` on
the Rancher local cluster. GitHub Actions only renders credentials into your
repository and never touches the cluster.

| Folder | Agents |
|--------|--------|
| [`suse/`](suse) | SUSE Application Collection, SBOMscanner |
| [`third-party/`](third-party) | Argo CD, GitHub, Kubernetes MCP, OVHcloud (dedicated server, network), Atlassian Rovo |

Each folder is one Fleet bundle, and its README lists the agents with their
MCP server and GitHub variables. Every agent has a detailed Agent Profile
(`description`, used for routing) and Guidelines (`systemPrompt`). Tools that
should need approval in the chat are suggested in a commented-out
`humanValidationTools` list. Check the tool names your MCP server exposes, then
uncomment it. MCP servers are not installed by this repository; each agent links to its
upstream docs.

## Quick start
1. **Use this template → Create a new repository → Private.** Don't fork: a
   fork of a public repository is always public, and your copy will hold
   credentials.
2. In each folder, edit the fields listed in each agent's comment header and
   delete the agents you don't use.
3. Add the GitHub variables listed in the folder READMEs (**Settings → Secrets
   and variables → Actions → Variables**), then run **Actions → Render agent
   secrets**. This commits `<agent>.secret.yaml` next to each agent.
4. In Rancher, open **Continuous Delivery → Git Repos** in workspace
   `fleet-local` and add your repository: branch `main`, paths `suse` and/or
   `third-party`, and a read-only token. Or apply
   [`examples/gitrepo.yaml`](examples/gitrepo.yaml).
5. Check with `kubectl get aiagentconfig -n cattle-ai-agent-system`.

Fleet takes over (`helm.takeOwnership`) any agent with the same name that you
created in the Rancher UI. Back those up first.

> [!WARNING]
> Rendered secrets and GitHub variables are plain text for anyone with read
> access to your repository. Keep it private and restrict access. The render
> workflow refuses to run in a public repository.

## Add an agent
Put SUSE products in `suse/` and everything else in `third-party/`:

1. **`<name>.yaml`**: an `AIAgentConfig` with `metadata.name: <name>` and
   `namespace: cattle-ai-agent-system`. Start it with a short comment: what it
   does, the upstream MCP link, notes specific to Rancher AI, and which fields
   to edit. Copy an existing agent as a starting point.
   - **Agent Profile** (`description`): what the agent covers, example prompts,
     and "Do NOT route X here" boundaries. The supervisor uses it to route.
   - **Guidelines** (`systemPrompt`): role, rules, hand-offs to other agents,
     workflows, and response format. Don't describe the tools: Rancher AI adds
     them to the system prompt automatically.
   - Suggest the mutating tools as a commented-out `humanValidationTools` list.
2. **`<name>.secret.yaml.tpl`** (only if it needs credentials): the Secret named
   in `spec.authenticationSecret` (and `caBundleRef`). Put `${VARIABLE}` or
   `${VARIABLE:-default}` in values, and describe each variable in a comment above it.

   | Auth type | Secret |
   |-----------|--------|
   | `BASIC` | `kubernetes.io/basic-auth` with `username` and `password` |
   | `HEADER` | `Opaque`. Every key is sent as an HTTP header |
   | `OAUTH2` | `Opaque` with `clientID`, `clientSecret`, `metadataEndpoint`, `scope` |
3. Add one row to the folder's README table.

Never commit a rendered `*.secret.yaml` to this repository. To pull upstream
changes into your copy:
`git pull https://github.com/jp-gouin/rancher-ai-agents-fleet.git main --allow-unrelated-histories`.

## License
[Apache 2.0](LICENSE)
