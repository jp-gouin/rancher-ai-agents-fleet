#!/usr/bin/env bash
# Static checks for the agent bundles (run by the Lint workflow, safe to run locally).
# PUBLIC_REPO=true additionally rejects committed *.secret.yaml files.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
errors=0
err() { echo "::error file=$1::$2"; errors=$((errors + 1)); }

names=""
for cat in suse third-party; do
  for f in fleet.yaml .fleetignore README.md; do [[ -f "$cat/$f" ]] || err "$cat/$f" "missing $f"; done
  [[ "$(yq -r .defaultNamespace "$cat/fleet.yaml" 2>/dev/null)" == "cattle-ai-agent-system" ]] ||
    err "$cat/fleet.yaml" "defaultNamespace must be cattle-ai-agent-system"
  grep -qx '\*\.tpl' "$cat/.fleetignore" 2>/dev/null || err "$cat/.fleetignore" "must ignore *.tpl"

  for m in "$cat"/*.yaml; do
    case "$m" in */fleet.yaml|*.secret.yaml) continue ;; esac
    agent="$(basename "$m" .yaml)"; tpl="$cat/$agent.secret.yaml.tpl"
    if ! yq -e '.kind == "AIAgentConfig" and .apiVersion == "ai.cattle.io/v1alpha1"' "$m" >/dev/null 2>&1; then
      err "$m" "not a valid AIAgentConfig"; continue
    fi
    [[ "$(yq -r .metadata.name "$m")" == "$agent" ]] || err "$m" "metadata.name must equal the file name ($agent)"
    [[ "$(yq -r .metadata.namespace "$m")" == "cattle-ai-agent-system" ]] || err "$m" "metadata.namespace must be cattle-ai-agent-system"
    [[ " $names " == *" $agent "* ]] && err "$m" "duplicate agent name '$agent'"
    names+=" $agent"
    for field in displayName mcpURL authenticationType description systemPrompt; do
      [[ -n "$(yq -r ".spec.$field // \"\"" "$m")" ]] || err "$m" "spec.$field is empty"
    done
    head -1 "$m" | grep -q '^#' || err "$m" "start with a short comment header (what it does, MCP server link, notes)"
    grep -q '\${' "$m" && err "$m" "placeholders are only supported in $agent.secret.yaml.tpl"
    grep -q "\`$agent\`" "$cat/README.md" || err "$cat/README.md" "add a table row for \`$agent\`"

    refs="$(yq -r '[.spec.authenticationSecret, .spec.caBundleRef.name] | map(select(. != null)) | .[]' "$m")"
    if [[ -n "$refs" ]]; then
      if [[ ! -f "$tpl" ]]; then err "$cat" "$agent.secret.yaml.tpl is required (spec references a Secret)"; continue; fi
      for r in $refs; do
        yq -e "select(.kind == \"Secret\" and .metadata.name == \"$r\")" "$tpl" >/dev/null 2>&1 ||
          err "$tpl" "no Secret named '$r' (referenced by $m)"
      done
      [[ -z "$(yq -r 'select(.kind == "Secret") | .metadata.namespace | select(. != "cattle-ai-agent-system")' "$tpl")" ]] ||
        err "$tpl" "Secrets must be in cattle-ai-agent-system"
      for v in $(grep -vE '^\s*#' "$tpl" | grep -ohE '\$\{[A-Z0-9_]+' | cut -c3- | sort -u); do
        [[ "$v" == GITHUB_* ]] && err "$tpl" "variable names cannot start with GITHUB_ ($v)"
        grep -qE "^\s*# $v:" "$tpl" || err "$tpl" "document $v with a '# $v: <description>' comment above it"
      done
    fi
  done
  if [[ "${PUBLIC_REPO:-false}" == "true" ]] && ls "$cat"/*.secret.yaml >/dev/null 2>&1; then
    err "$cat" "rendered *.secret.yaml must never be committed to a public repository"
  fi
done
((errors)) && { echo "$errors problem(s) found"; exit 1; }
echo "All agents OK"
