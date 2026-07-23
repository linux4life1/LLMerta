#!/usr/bin/env bash
set -euo pipefail
threshold=${COVERAGE_MIN:-90}
total_lf=0
total_lh=0
for f in "$@"; do
  while IFS= read -r line; do
    case $line in
      LF:*) total_lf=$((total_lf + ${line#LF:}));;
      LH:*) total_lh=$((total_lh + ${line#LH:}));;
    esac
  # Excluded like generated code: pure native/plugin wrappers whose happy
  # paths cannot run under `flutter test` (no FFI/plugin host). They are
  # covered by the M0 spike integration tests on-device; their guard and
  # fallback logic stays in counted files. update_install.dart is the
  # updater's Process/exit sidecar layer — unrunnable in tests by nature;
  # its decision logic lives in counted update_logic/update_service.
  # onnx_embedder.dart moved its native session/inference into a worker
  # isolate (v0.1.2 jank fix) where per-isolate coverage cannot see it;
  # the fallback seam stays covered via services_embedding tests.
  done < <(awk '/^SF:/ { skip = ($0 ~ /\.g\.dart$|\.freezed\.dart$|lib\/services\/sherpa_tts\.dart$|lib\/services\/audio\.dart$|lib\/services\/update_install\.dart$|lib\/services\/onnx_embedder\.dart$/) } !skip && /^L[FH]:/' "$f")
done
if (( total_lf == 0 )); then
  echo "no coverage data found" >&2
  exit 1
fi
pct=$((100 * total_lh / total_lf))
echo "coverage: $total_lh/$total_lf lines ($pct%, threshold $threshold%)"
(( pct >= threshold ))
