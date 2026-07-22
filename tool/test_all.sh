#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

dart pub get

for pkg in packages/*/; do
  (
    cd "$pkg"
    dart pub get
    dart format --output=none --set-exit-if-changed .
    dart analyze --fatal-infos
    if [ -d test ]; then
      dart test --coverage=coverage
      dart run coverage:format_coverage --lcov --check-ignore \
        --in=coverage --out=coverage/lcov.info --report-on=lib
    fi
  )
done

(
  cd app
  flutter pub get
  dart format --output=none --set-exit-if-changed lib test
  flutter analyze --fatal-infos
  # Goldens are Linux-CI-only; ci.yaml runs `flutter test --tags golden`.
  flutter test --coverage --exclude-tags golden
)

"$root/tool/check_loc.sh"
# shellcheck disable=SC2046
"$root/tool/check_coverage.sh" $(find app/coverage packages/*/coverage -name lcov.info)
