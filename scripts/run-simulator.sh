#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Build and launch Debug with the registered, ignored App Check token. Never echo the token.
if [[ -z "${PIYALI_TEST_DEVICE:-}" ]]; then
  PIYALI_TEST_DEVICE=$(xcrun simctl list devices available --json | python3 -c 'import json,sys; ds=[d for group in json.load(sys.stdin)["devices"].values() for d in group if "iPhone" in d["name"]]; ds.sort(key=lambda d:d["state"]!="Booted"); print(ds[0]["udid"])')
fi
xcodebuild -project Piyali.xcodeproj -scheme Piyali -destination "platform=iOS Simulator,id=$PIYALI_TEST_DEVICE" -derivedDataPath DerivedData CODE_SIGN_IDENTITY=- build
xcrun simctl install "$PIYALI_TEST_DEVICE" DerivedData/Build/Products/Debug-iphonesimulator/Piyali.app
python3 - "$PIYALI_TEST_DEVICE" <<'PY'
import json, os, subprocess, sys
with open('.secrets/app-check-debug.json') as f: token = json.load(f)['token']
env = os.environ.copy(); env['SIMCTL_CHILD_FIRAAppCheckDebugToken'] = token
subprocess.run(['xcrun', 'simctl', 'launch', '--terminate-running-process', sys.argv[1], 'app.piyali.ios'], env=env, check=True)
PY
