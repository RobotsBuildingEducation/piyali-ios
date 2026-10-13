#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export TEST_RUNNER_PIYALI_OFFLINE_TESTS=1
export TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)"
scripts/test-ios.sh -only-testing:PiyaliTests/NostrRelayTests -only-testing:PiyaliTests/NostrAchievementTests -only-testing:PiyaliTests/NostrTeamsTests
