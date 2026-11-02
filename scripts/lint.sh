#!/usr/bin/env bash
# Static checks for every agent folder (run by the Lint workflow, safe to run locally).
# PUBLIC_REPO=true additionally rejects committed secret.yaml files.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
errors=0
err() { echo "::error file=$1::$2"; errors=$((errors + 1)); }

names=""
for dir in suse/*/ third-party/*/; do
  dir="${dir%/}"; m="$dir/aiagentconfig.yaml"; tpl="$dir/secret.yaml.tpl"
  for f in aiagentconfig.yaml fleet.yaml .fleetignore README.md; do
    [[ -f "$dir/$f" ]] || err "$dir/$f" "missing $f"
  done
  [[ -f "$m" ]] || continue

  if ! yq -e '.kind == "AIAgentConfig" and .apiVersion == "ai.cattle.io/v1alpha1"' "$m" >/dev/null 2>&1; then
    err "$m" "not a valid AIAgentConfig"; continue
  fi
  [[ "$(yq -r .metadata.namespace "$m")" == "cattle-ai-agent-system" ]] || err "$m" "metadata.namespace must be cattle-ai-agent-system"
  name="$(yq -r .metadata.name "$m")"
  [[ " $names " == *" $name "* ]] && err "$m" "duplicate metadata.name '$name'"
  names+=" $name"
  for field in displayName mcpURL authenticationType description systemPrompt; do
    [[ -n "$(yq -r ".spec.$field // \"\"" "$m")" ]] || err "$m" "spec.$field is empty"
  done
  grep -q '\${' "$m" && err "$m" "placeholders are not supported in aiagentconfig.yaml (only in secret.yaml.tpl)"

  [[ "$(yq -r '.defaultNamespace' "$dir/fleet.yaml" 2>/dev/null)" == "cattle-ai-agent-system" ]] ||
    err "$dir/fleet.yaml" "defaultNamespace must be cattle-ai-agent-system"
  grep -qx '\*\.tpl' "$dir/.fleetignore" 2>/dev/null || err "$dir/.fleetignore" "must ignore *.tpl"

  # every secret referenced by the AIAgentConfig is produced by the template
  auth="$(yq -r .spec.authenticationType "$m")"
  refs="$(yq -r '[.spec.authenticationSecret, .spec.caBundleRef.name] | map(select(. != null)) | .[]' "$m")"
  if [[ "$auth" =~ ^(BASIC|HEADER|OAUTH2)$ || -n "$refs" ]]; then
    if [[ ! -f "$tpl" ]]; then
      err "$dir" "secret.yaml.tpl is required (spec references a Secret)"
    else
      for r in $refs; do
        yq -e "select(.kind == \"Secret\" and .metadata.name == \"$r\")" "$tpl" >/dev/null 2>&1 ||
          err "$tpl" "no Secret named '$r' (referenced by $m)"
      done
      [[ -z "$(yq -r 'select(.kind == "Secret") | .metadata.namespace | select(. != "cattle-ai-agent-system")' "$tpl")" ]] ||
        err "$tpl" "Secrets must be in cattle-ai-agent-system"
      for v in $(grep -vE '^\s*#' "$tpl" | grep -ohE '\$\{[A-Z0-9_]+' | cut -c3- | sort -u); do
        [[ "$v" == GITHUB_* ]] && err "$tpl" "variable names cannot start with GITHUB_ ($v)"
        grep -q "\`$v\`" "$dir/README.md" || err "$dir/README.md" "variable $v is not documented"
      done
    fi
  fi

  if [[ "${PUBLIC_REPO:-false}" == "true" && -f "$dir/secret.yaml" ]]; then
    err "$dir/secret.yaml" "rendered secrets must never be committed to a public repository"
  fi
done
((errors)) && { echo "$errors problem(s) found"; exit 1; }
echo "All agents OK"
