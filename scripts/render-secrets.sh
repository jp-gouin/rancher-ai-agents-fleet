#!/usr/bin/env bash
# Render every <agent>/secret.yaml.tpl into <agent>/secret.yaml from GitHub
# variables (VARS_JSON, as passed by the workflow) or environment variables.
#
#   ${NAME}            required
#   ${NAME:-default}   optional, default used when NAME is unset or empty
#
# A placeholder can appear anywhere in a value ("Bearer ${TOKEN}"); the whole
# value is then written as a quoted YAML string, so multi-line values (PEM
# certificates) and special characters are safe. Comment lines are left as-is.
#
# An agent is rendered only when all its required variables are set; others are
# skipped and their existing secret.yaml is left untouched.
#
# Usage: render-secrets.sh [--check]   (--check: report only, write nothing)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="${1:-}"
export VARS_JSON="${VARS_JSON:-{\}}"

rendered=0
for tpl in "$ROOT"/suse/*/secret.yaml.tpl "$ROOT"/third-party/*/secret.yaml.tpl; do
  [[ -f "$tpl" ]] || continue
  dir="$(dirname "$tpl")"; agent="${dir#"$ROOT"/}"
  if out="$(perl -MJSON::PP -e '
      my $vars = decode_json($ENV{VARS_JSON});
      my (@missing, $all, $set);
      sub val {
        my ($n, $d) = @_; $all++;
        my $v = (defined $vars->{$n} && $vars->{$n} ne "") ? $vars->{$n}
              : (defined $ENV{$n} && $ENV{$n} ne "") ? $ENV{$n} : undef;
        if (defined $v) { $set++ } elsif (defined $d) { $v = $d } else { push @missing, $n; $v = "" }
        return $v;
      }
      my $json = JSON::PP->new->ascii->allow_nonref;
      print "# Generated from secret.yaml.tpl by scripts/render-secrets.sh. Do not edit.\n";
      while (my $line = <>) {
        next if $line =~ /^\s*#/;
        if ($line =~ /^(\s*[^\s:#][^:]*:\s+)(.*\$\{.*?)\s*$/) {
          my ($key, $expr) = ($1, $2);
          $expr =~ s/\$\{([A-Z0-9_]+)(?::-([^\}]*))?\}/val($1, $2)/ge;
          $line = $key . $json->encode($expr) . "\n";
        }
        print $line;
      }
      if (@missing) { print STDERR join(" ", @missing); exit($set ? 2 : 3) }
    ' "$tpl" 2>"$dir/.missing")"; then
    if [[ "$CHECK" == "--check" ]]; then
      echo "ready    $agent"
    else
      printf '%s\n' "$out" >"$dir/secret.yaml"
      echo "rendered $agent/secret.yaml"
    fi
    rendered=$((rendered + 1))
  else
    code=$?
    missing="$(cat "$dir/.missing")"
    case $code in
      2) echo "::warning::$agent: incomplete, missing variable(s): $missing" ;;
      3) echo "skipped  $agent (not configured: $missing)" ;;
      *) echo "::error::$agent: failed to render $tpl"; rm -f "$dir/.missing"; exit 1 ;;
    esac
  fi
  rm -f "$dir/.missing"
done
echo "$rendered agent secret(s) ready"
