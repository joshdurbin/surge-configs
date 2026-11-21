#!/usr/bin/env bash
# Convert hagezi wildcard lists to Surge DOMAIN-SET format.
# Surge matches bare entries exactly; a leading dot also matches subdomains.
set -euo pipefail

base="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard"
out="$(cd "$(dirname "$0")/.." && pwd)/lists"
mkdir -p "$out"

for name in pro tif.mini doh; do
  curl -fsSL "$base/$name-onlydomains.txt" \
    | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' \
    | sed 's/^/./' > "$out/$name.domainset.tmp"
  mv "$out/$name.domainset.tmp" "$out/$name.domainset"
done
