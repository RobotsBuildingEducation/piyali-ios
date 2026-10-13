#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${PIYALI_TEST_DEVICE:-}" ]]; then
  PIYALI_TEST_DEVICE=$(xcrun simctl list devices available --json | python3 -c 'import json,sys; ds=[d for group in json.load(sys.stdin)["devices"].values() for d in group if "iPhone" in d["name"]]; ds.sort(key=lambda d:d["state"]!="Booted"); print(ds[0]["udid"])')
fi
args=(-project Piyali.xcodeproj -scheme Piyali -destination "platform=iOS Simulator,id=$PIYALI_TEST_DEVICE" -derivedDataPath DerivedData CODE_SIGN_IDENTITY=-)
if [[ -n "${PIYALI_SOURCE_PACKAGES:-}" ]]; then
  args+=(-clonedSourcePackagesDirPath "$PIYALI_SOURCE_PACKAGES")
fi
xcodebuild "${args[@]}" "$@" test
