#!/usr/bin/env bash
# Regenerate the secret env list of the "Create agent secrets" step in
# .github/workflows/deploy.yaml from every agent.yaml. Run after adding an agent.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wf="$ROOT/.github/workflows/deploy.yaml"
names="$(yq -r '[.secret.data, (.extraSecrets // [])[].data] | map(select(. != null) | to_entries[] | .value) | .[]' \
  "$ROOT"/suse/*/agent.yaml "$ROOT"/third-party/*/agent.yaml | sort -u)"
NAMES="$names" perl -0pi -e '
  my $block = join "", map { "          $_: \${{ secrets.$_ }}\n" } split /\s+/, $ENV{NAMES};
  s/(          # --- agent secrets \(keep sorted\) ---\n)(?:          [A-Z0-9_]+: \$\{\{ secrets\.[A-Z0-9_]+ \}\}\n)*/$1$block/;
' "$wf"
echo "Wired $(wc -w <<<"$names" | tr -d ' ') secret(s) into $wf"
