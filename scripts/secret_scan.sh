#!/usr/bin/env bash
# Lightweight secret scan for tracked files. Does not print secret values.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
# Scan tracked files for high-confidence credential shapes without printing matches.
if git grep -I -E -n 'AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH) PRIVATE KEY|sk-[a-zA-Z0-9]{20,}' -- . >/tmp/careerly_secret_hits.txt 2>/dev/null; then
  while read -r line; do
    file="${line%%:*}"
    echo "POTENTIAL SECRET PATTERN in: $file (content redacted)"
    fail=1
  done < /tmp/careerly_secret_hits.txt
fi
rm -f /tmp/careerly_secret_hits.txt
if [[ "$fail" -ne 0 ]]; then
  echo "ROTATION REQUIRED if any match is a live credential. Do not commit secrets."
  exit 1
fi
echo "Secret scan: no high-confidence patterns in tracked files."
