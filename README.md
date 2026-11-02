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
(`description`, used for routing) and Guidelines (`systemPrompt`). Mutating
tools are listed in `humanValidationTools`, so they need approval in the chat.
MCP servers are not installed by this repository; each agent links to its
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

## Updates and contributions
- To get upstream changes: `git remote add upstream https://github.com/jp-gouin/rancher-ai-agents-fleet.git && git pull upstream main --allow-unrelated-histories`.
- To add an agent, see [docs/adding-an-agent.md](docs/adding-an-agent.md).
  It takes one or two files and one table row. `./scripts/lint.sh` runs the CI
  checks. Never commit a rendered `*.secret.yaml` here.

## License
[Apache 2.0](LICENSE)
