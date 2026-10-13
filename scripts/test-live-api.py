#!/usr/bin/env python3
"""Opt-in native service check. Pass debug tokens only through the runner environment."""
import argparse, json, os, subprocess, uuid
from pathlib import Path
root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--only', choices=['services', 'immersion', 'conversation', 'rpg', 'signer'])
selection = parser.parse_args().only
methods = {'services': 'testNativeAuthenticationGeminiResponsesAndVoice',
           'immersion': 'testNativeImmersionGenerationUsesResponsesAndPreservesExistingMissions',
           'conversation': 'testNativeConversationGoalsGradeCommunicationAndReanchorPremiseRejection',
           'rpg': 'testNativeRPGStoryAndRoleplayUseTheAuthoredChapter',
           'signer': 'testNativeRemoteSignerAuthenticatesWithActualUserAndWebRestoreDeniesUnlinkedAccount'}
with (root / '.secrets/app-check-debug.json').open() as f:
    token = json.load(f)['token']
env = os.environ.copy()
env.update(TEST_RUNNER_PIYALI_OFFLINE_TESTS='1', TEST_RUNNER_PIYALI_LIVE_API_TESTS='1',
           TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE=str(uuid.uuid4()), TEST_RUNNER_FIRAAppCheckDebugToken=token)
test = 'PiyaliTests/LiveAPIIntegrationTests' + ('/' + methods[selection] if selection else '')
subprocess.run([str(root / 'scripts/test-ios.sh'), '-only-testing:' + test],
               cwd=root, env=env, check=True)
