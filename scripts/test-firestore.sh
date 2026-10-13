#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# A demo project ID guarantees these tests cannot target production Firebase services.
export TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1
firebase --config BackendReference/firebase.emulator.json --project demo-piyali-ios \
  emulators:exec --only firestore 'scripts/test-ios.sh -only-testing:PiyaliTests'
