#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
limit=600
fail=0
while IFS= read -r f; do
  lines=$(wc -l < "$f")
  if (( lines > limit )); then
    echo "LOC over $limit: $f ($lines)"
    fail=1
  fi
done < <(find app/lib app/test packages/*/lib packages/*/test \
  -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' 2>/dev/null)
if (( fail == 0 )); then echo "LOC check passed (limit $limit)"; fi
exit $fail
