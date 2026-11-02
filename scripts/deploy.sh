#!/usr/bin/env bash
# Deploy Rancher AI agents from this repository.
#
#   deploy.sh secrets        create/update the Kubernetes Secrets declared in <agent>/agent.yaml
#   deploy.sh render <dir>   render <agent>/aiagentconfig.yaml (+ fleet.yaml) into <dir>
#   deploy.sh gitrepo        create/update the Fleet GitRepo watching the rendered branch
#
# Inputs (environment):
#   AGENTS           comma/space separated agents ("appco", "suse/appco") or "all"   (required)
#   REPO_URL         Git URL Fleet watches                       (default: origin remote)
#   FLEET_BRANCH     Branch holding the rendered manifests        (default: fleet)
#   GITREPO_NAME     Fleet GitRepo name                           (default: rancher-ai-agents)
#   FLEET_GIT_TOKEN  Token Fleet uses to clone a private fork     (optional)
#   VARS_JSON        JSON object of variables (GitHub: toJSON(vars)); falls back to the environment
#   DRY_RUN          "true": print manifests (secrets redacted) instead of applying them
#
# Placeholders in aiagentconfig.yaml:
#   ${NAME}            required, rendering fails when the variable is unset
#   ${NAME:-default}   optional, the default is used when the variable is unset
# Values are inserted verbatim and must fit on one line.
#
# Rancher AI always reads AIAgentConfigs from cattle-ai-agent-system on the
# Rancher local cluster, so the namespace and the fleet-local workspace are fixed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NS=cattle-ai-agent-system
FLEET_NS=fleet-local
GITREPO_NAME="${GITREPO_NAME:-rancher-ai-agents}"
FLEET_BRANCH="${FLEET_BRANCH:-fleet}"
VARS_JSON="${VARS_JSON:-}"
[[ -z "$VARS_JSON" ]] && VARS_JSON='{}'
export VARS_JSON
DRY_RUN="${DRY_RUN:-false}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR\033[0m %s\n' "$*" >&2; exit 1; }

# var <NAME>: GitHub variable from VARS_JSON, else environment variable.
var() {
  local v
  v="$(jq -r --arg k "$1" '.[$k] // empty' <<<"$VARS_JSON")"
  [[ -z "$v" ]] && v="${!1:-}"
  printf '%s' "$v"
}

apply() {
  if [[ "$DRY_RUN" == "true" ]]; then
    yq 'with(select(.kind == "Secret" and has("data")); .data[] = "<redacted>")' -
    echo "---"
  else
    kubectl apply -f -
  fi
}

# Resolve AGENTS into "category/name" folders.
resolve_agents() {
  local list a c matches
  list="$(tr ',' ' ' <<<"${AGENTS:-}" | xargs)"
  [[ -z "$list" ]] && die "AGENTS is empty. Set the AGENTS repository variable, e.g. 'appco,github' or 'all'."
  if [[ "$list" == "all" ]]; then
    (cd "$ROOT" && for f in suse/*/aiagentconfig.yaml third-party/*/aiagentconfig.yaml; do
      [[ -f "$f" ]] && dirname "$f"
    done)
    return
  fi
  for a in $list; do
    a="${a%/}"
    if [[ "$a" == */* ]]; then
      [[ -f "$ROOT/$a/aiagentconfig.yaml" ]] || die "unknown agent '$a'"
      echo "$a"
    else
      matches=""
      for c in suse third-party; do
        [[ -f "$ROOT/$c/$a/aiagentconfig.yaml" ]] && matches+="$c/$a"$'\n'
      done
      [[ -n "$matches" ]] || die "unknown agent '$a' (looked in suse/ and third-party/)"
      printf '%s' "$matches"
    fi
  done
}

# ------------------------------------------------------------------ secrets
build_secret() {
  local file="$1" path="$2" agent name type dir key ref val missing=()
  agent="$(yq -r .name "$file")"
  name="$(yq -r "$path.name" "$file")"
  type="$(yq -r "$path.type // \"Opaque\"" "$file")"
  dir="$WORK/secret-$name"; rm -rf "$dir"; mkdir -p "$dir"

  while IFS=$'\t' read -r key val; do
    [[ -n "$key" ]] && printf '%s' "$val" >"$dir/$key"
  done < <(yq -r "($path.defaults // {}) | to_entries[] | [.key, .value] | @tsv" "$file")

  while IFS=$'\t' read -r key ref; do
    [[ -z "$key" ]] && continue
    val="${!ref:-}"   # GitHub secrets are passed as environment variables
    if [[ -n "$val" ]]; then
      printf '%s' "$val" >"$dir/$key"
    elif [[ ! -f "$dir/$key" ]]; then
      missing+=("$ref")
    fi
  done < <(yq -r "($path.data // {}) | to_entries[] | [.key, .value] | @tsv" "$file")

  if ((${#missing[@]})); then
    if [[ "$(yq -r "$path.optional // false" "$file")" == "true" ]]; then
      warn "$agent: optional secret $name skipped (not set: ${missing[*]})"; return 0
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
      warn "$agent: missing GitHub secret(s): ${missing[*]} (the real run will fail)"
      for key in "${missing[@]}"; do : >"$dir/missing-$key"; done
    else
      die "$agent: missing GitHub secret(s): ${missing[*]}"
    fi
  fi

  kubectl create secret generic "$name" -n "$NS" --type="$type" --from-file="$dir" \
    --dry-run=client -o yaml |
    yq '.metadata.labels."app.kubernetes.io/part-of" = "rancher-ai-agents-fleet"' | apply
  log "  secret $NS/$name"
}

copy_secrets() {
  local file="$1" agent n i fns fname fkey tname tkey ref val
  agent="$(yq -r .name "$file")"
  n="$(yq -r '(.copySecrets // []) | length' "$file")"
  for ((i = 0; i < n; i++)); do
    fns="$(yq -r ".copySecrets[$i].from.namespace" "$file")"
    fname="$(yq -r ".copySecrets[$i].from.name" "$file")"
    fkey="$(yq -r ".copySecrets[$i].from.key" "$file")"
    tname="$(yq -r ".copySecrets[$i].to.name" "$file")"
    tkey="$(yq -r ".copySecrets[$i].to.key // \"$fkey\"" "$file")"
    ref="$(yq -r ".copySecrets[$i].from.namespaceVar // \"\"" "$file")"
    [[ -n "$ref" && -n "$(var "$ref")" ]] && fns="$(var "$ref")"
    ref="$(yq -r ".copySecrets[$i].from.nameVar // \"\"" "$file")"
    [[ -n "$ref" && -n "$(var "$ref")" ]] && fname="$(var "$ref")"
    if [[ "$DRY_RUN" == "true" ]]; then
      val="$(printf 'dry-run' | base64)"
    elif ! val="$(kubectl get secret -n "$fns" "$fname" -o json 2>/dev/null | jq -er --arg k "$fkey" '.data[$k]')"; then
      if [[ "$(yq -r ".copySecrets[$i].optional // false" "$file")" == "true" ]]; then
        warn "$agent: optional secret $fns/$fname ($fkey) not found, skipping"; continue
      fi
      die "$agent: cannot read key '$fkey' of secret $fns/$fname"
    fi
    jq -n --arg n "$tname" --arg ns "$NS" --arg k "$tkey" --arg v "$val" '{
      apiVersion: "v1", kind: "Secret", type: "Opaque",
      metadata: {name: $n, namespace: $ns, labels: {"app.kubernetes.io/part-of": "rancher-ai-agents-fleet"}},
      data: {($k): $v}}' | yq -P | apply
    log "  secret $NS/$tname (copied from $fns/$fname)"
  done
}

cmd_secrets() {
  local dir file n i
  if [[ "$DRY_RUN" != "true" ]]; then
    kubectl get crd aiagentconfigs.ai.cattle.io >/dev/null 2>&1 ||
      die "AIAgentConfig CRD not found: install Rancher AI on the Rancher local cluster first"
  fi
  for dir in $(resolve_agents); do
    file="$ROOT/$dir/agent.yaml"
    log "agent $dir"
    [[ -f "$file" ]] || continue
    if [[ "$(yq -r '.secret | type' "$file")" == "!!map" ]]; then build_secret "$file" .secret; fi
    n="$(yq -r '(.extraSecrets // []) | length' "$file")"
    for ((i = 0; i < n; i++)); do build_secret "$file" ".extraSecrets[$i]"; done
    copy_secrets "$file"
  done
}

# ------------------------------------------------------------------- render
cmd_render() {
  local out="${1:?usage: deploy.sh render <dir>}" dir
  mkdir -p "$out"
  for dir in $(resolve_agents); do
    mkdir -p "$out/$dir"
    perl -MJSON::PP -e '
      my $vars = decode_json($ENV{VARS_JSON} || "{}");
      my $file = shift; my @missing;
      sub lookup {
        my ($n, $d) = @_;
        my $v = (defined $vars->{$n} && $vars->{$n} ne "") ? $vars->{$n}
              : (defined $ENV{$n} && $ENV{$n} ne "") ? $ENV{$n} : undef;
        if (!defined $v) { if (defined $d) { $v = $d } else { push @missing, $n; $v = "" } }
        die "ERROR $n contains a newline\n" if $v =~ /\n/;
        return $v;
      }
      local $/; open my $fh, "<", $file or die "$file: $!"; my $t = <$fh>;
      $t =~ s/\$\{([A-Z0-9_]+)(?::-([^\}]*))?\}/lookup($1, $2)/ge;
      if (@missing) { print STDERR "ERROR $file: missing GitHub variable(s): @missing\n"; exit 1 }
      print $t;
    ' "$ROOT/$dir/aiagentconfig.yaml" >"$out/$dir/aiagentconfig.yaml" || die "render failed for $dir"
    yq -e '.kind == "AIAgentConfig"' "$out/$dir/aiagentconfig.yaml" >/dev/null ||
      die "$dir: rendered manifest is not a valid AIAgentConfig"
    # takeOwnership lets Fleet adopt agents previously created in the Rancher UI
    printf 'defaultNamespace: %s\nnamespace: %s\nhelm:\n  takeOwnership: true\n' "$NS" "$NS" >"$out/$dir/fleet.yaml"
    log "  rendered $dir"
  done
}

# ------------------------------------------------------------------ gitrepo
cmd_gitrepo() {
  local repo paths
  repo="${REPO_URL:-$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)}"
  [[ -z "$repo" ]] && die "REPO_URL is empty"
  if [[ "$repo" =~ ^git@([^:]+):(.+)$ ]]; then repo="https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"; fi
  paths="$(resolve_agents | jq -R . | jq -sc .)"

  local auth=""
  if [[ -n "${FLEET_GIT_TOKEN:-}" ]]; then
    kubectl create secret generic "$GITREPO_NAME-git-auth" -n "$FLEET_NS" \
      --type=kubernetes.io/basic-auth --from-literal=username=git \
      --from-literal=password="$FLEET_GIT_TOKEN" --dry-run=client -o yaml | apply
    auth="$GITREPO_NAME-git-auth"
  fi

  log "Fleet GitRepo $FLEET_NS/$GITREPO_NAME -> $repo@$FLEET_BRANCH"
  PATHS="$paths" REPO="$repo" AUTH="$auth" yq -n '
    .apiVersion = "fleet.cattle.io/v1alpha1" |
    .kind = "GitRepo" |
    .metadata.name = strenv(GITREPO_NAME) |
    .metadata.namespace = "fleet-local" |
    .metadata.labels."app.kubernetes.io/part-of" = "rancher-ai-agents-fleet" |
    .spec.repo = strenv(REPO) |
    .spec.branch = strenv(FLEET_BRANCH) |
    .spec.paths = env(PATHS) | .spec.paths style="" |
    (select(strenv(AUTH) != "") | .spec.clientSecretName = strenv(AUTH)) // .
  ' | apply
}

export GITREPO_NAME FLEET_BRANCH
for bin in kubectl yq jq perl; do command -v "$bin" >/dev/null || die "$bin is required"; done
case "${1:-}" in
  secrets) cmd_secrets ;;
  render)  shift; cmd_render "$@" ;;
  gitrepo) cmd_gitrepo ;;
  *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
