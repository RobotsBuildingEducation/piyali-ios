#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1
export TEST_RUNNER_PIYALI_OFFLINE_TESTS=1
export TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)"
if [[ "${1:-}" == "--ui" ]]; then
  firebase --config BackendReference/firebase.emulator.json --project demo-piyali-ios \
    emulators:exec --only firestore 'scripts/test-ios.sh -only-testing:PiyaliUITests/PrivateTeamsPlayTests'
else
  firebase --config BackendReference/firebase.emulator.json --project demo-piyali-ios \
    emulators:exec --only firestore 'scripts/test-ios.sh -only-testing:PiyaliTests/PrivateTeamsContractTests'
fi
