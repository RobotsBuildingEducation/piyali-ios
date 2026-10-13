#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# The installed iOS 26.4 runtime cannot initialize StoreKit Test via xcodebuild.
# Use an isolated iOS 17 test device when that runtime is available; callers can select another UDID.
if [[ -z "${PIYALI_TEST_DEVICE:-}" ]]; then
  PIYALI_TEST_DEVICE=$(python3 - <<'PYDEVICE'
import json, subprocess
runtimes=json.loads(subprocess.check_output(['xcrun','simctl','list','runtimes','--json']))['runtimes']
if any(r['identifier']=='com.apple.CoreSimulator.SimRuntime.iOS-17-0' and r['isAvailable'] for r in runtimes):
    devices=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))['devices'].get('com.apple.CoreSimulator.SimRuntime.iOS-17-0',[])
    found=next((d for d in devices if d['name']=='Piyali StoreKit Tests'),None)
    print(found['udid'] if found else subprocess.check_output(['xcrun','simctl','create','Piyali StoreKit Tests','com.apple.CoreSimulator.SimDeviceType.iPhone-15','com.apple.CoreSimulator.SimRuntime.iOS-17-0'],text=True).strip())
PYDEVICE
  )
  if [[ -n "$PIYALI_TEST_DEVICE" ]]; then export PIYALI_TEST_DEVICE; else unset PIYALI_TEST_DEVICE; fi
fi
export PIYALI_TEST_SCHEME=PiyaliStoreKit
export TEST_RUNNER_PIYALI_STOREKIT_TESTS=1
export TEST_RUNNER_PIYALI_OFFLINE_TESTS=1
export TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)"
scripts/test-ios.sh -only-testing:PiyaliTests/StoreKitSubscriptionTests
