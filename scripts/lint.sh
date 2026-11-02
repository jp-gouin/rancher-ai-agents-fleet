#!/usr/bin/env bash
# Static checks for every agent folder (run by the Lint workflow, safe to run locally).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
errors=0
err() { echo "::error file=$1::$2"; errors=$((errors + 1)); }

names=()
for dir in suse/*/ third-party/*/; do
  dir="${dir%/}"; agent="$(basename "$dir")"; m="$dir/aiagentconfig.yaml"
  for f in aiagentconfig.yaml agent.yaml README.md; do
    [[ -f "$dir/$f" ]] || err "$dir/$f" "missing $f"
  done
  [[ -f "$m" && -f "$dir/agent.yaml" ]] || continue

  [[ "$(yq -r .name "$dir/agent.yaml")" == "$agent" ]] || err "$dir/agent.yaml" "name must be '$agent'"

  # valid YAML once every placeholder is substituted
  rendered="$(perl -pe 's/\$\{[A-Z0-9_]+:-([^}]*)\}/$1/g; s/\$\{[A-Z0-9_]+\}/https:\/\/example.com/g' "$m")"
  if ! yq -e '.kind == "AIAgentConfig"' <<<"$rendered" >/dev/null 2>&1; then
    err "$m" "not a valid AIAgentConfig once placeholders are substituted"; continue
  fi
  [[ "$(yq -r .metadata.namespace <<<"$rendered")" == "cattle-ai-agent-system" ]] ||
    err "$m" "metadata.namespace must be cattle-ai-agent-system"
  name="$(yq -r .metadata.name <<<"$rendered")"
  [[ " ${names[*]:-} " == *" $name "* ]] && err "$m" "duplicate metadata.name '$name'"
  names+=("$name")
  for field in description systemPrompt displayName mcpURL authenticationType; do
    [[ -n "$(yq -r ".spec.$field // \"\"" <<<"$rendered")" ]] || err "$m" "spec.$field is empty"
  done
  if grep -nE '\$\{' "$m" | grep -vqE '\$\{[A-Z0-9_]+(:-[^}]*)?\}'; then
    err "$m" "malformed placeholder (use \${NAME} or \${NAME:-default})"
  fi

  # auth secret consistency
  auth="$(yq -r .spec.authenticationType <<<"$rendered")"
  sname="$(yq -r '.spec.authenticationSecret // ""' <<<"$rendered")"
  if [[ "$auth" =~ ^(BASIC|HEADER|OAUTH2)$ ]]; then
    [[ "$(yq -r '.secret.name // ""' "$dir/agent.yaml")" == "$sname" ]] ||
      err "$dir/agent.yaml" "secret.name must equal spec.authenticationSecret ($sname)"
  fi

  # every variable and secret is documented, every secret is wired into the deploy workflow
  for v in $(grep -ohE '\$\{[A-Z0-9_]+' "$m" | cut -c3- | sort -u) \
           $(yq -r '(.copySecrets // [])[] | .from | (.namespaceVar, .nameVar) | select(. != null)' "$dir/agent.yaml"); do
    grep -q "\`$v\`" "$dir/README.md" || err "$dir/README.md" "variable $v is not documented"
  done
  for s in $(yq -r '[.secret.data, (.extraSecrets // [])[].data] | map(select(. != null) | to_entries[] | .value) | .[]' "$dir/agent.yaml"); do
    [[ "$s" == GITHUB_* ]] && err "$dir/agent.yaml" "GitHub secret names cannot start with GITHUB_ ($s)"
    grep -q "\`$s\`" "$dir/README.md" || err "$dir/README.md" "secret $s is not documented"
    grep -q "secrets\.$s }}" .github/workflows/deploy.yaml ||
      err .github/workflows/deploy.yaml "add '$s' (from secrets.$s) to the env of the 'Create agent secrets' step"
  done
done
((errors)) && { echo "$errors problem(s) found"; exit 1; }
echo "All agents OK"
