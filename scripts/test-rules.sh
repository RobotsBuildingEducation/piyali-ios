#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
firebase --config Backend/firebase.rules-emulator.json --project demo-piyali-ios-auth \
  emulators:exec --only firestore 'PIYALI_RULES_EMULATOR=1 npm test --prefix Backend'
