#!/usr/bin/env python3
"""Opt-in native service check. Pass debug tokens only through the runner environment."""
import argparse, json, os, subprocess, uuid
from pathlib import Path
root = Path(__file__).resolve().parent.parent
methods = {'narration-warm-refill':'testSilentNarrationRefillPreservesAnActiveNativePlayback','narration-warm':'testSilentPreparedNarrationHandsOffOneConnectionAndChangesVoiceBeforeSpeech','narration-cache':'testCompletedNativeNarrationCapturesPCMAndReplaysFromMemoryAndDisk','standard-help':'testOriginalStandardAssistanceStreamsSubmittedAttemptsAndLanguages','oral':'testOriginalOralGenerationFlashcardJudgesAndAssistanceUseNativeProviders','word-bank':'testTranslationAndRepeatUseOriginalDirectionsAndNativeJudges','standard':'testStandardChoiceFillAndMatchingUseOriginalNativeJudges','writing':'testWritingExercisesUseOriginalSemanticJudges','exercise-interactions':'testFiveExerciseBodiesUseOriginalSemanticJudgesIncludingAlternativeReplies','question-help':'testOriginalQuestionAssistanceStreamsAndExplainsThroughLearnerFirebase','teams':'testDeployedPublicMirrorMembershipRenameAddsAndRevocation','help':'testNativeHelpChatStreamsSupportLanguageAndAnalyzesTargetMorphemes',
           'tutor-gemini':'testLearnerGeminiTutorUsesFirebaseIdentitySourcePromptAndNativePlayback',
           'tutor-focused':'testOriginalFocusedTutorGoalAndRepairJudgesUseNativeProviders',
           'tutor':'testOriginalTutorJudgeWelcomeAndNativeVoiceWithSourceTranscriptionContext',
           'story-speech':'testStoryCaptureTranscribesAPublicRecordingWithoutMicrophoneInput',
           'reading-story-audio':'testReadingAndCharacterStoryNarrationReceiveOriginalVoiceAudio',
           'lesson-audio':'testLessonNarrationUsesOriginalVoiceAndReceivesSpanishAndArabicAudio',
           'phonics':'testNativePhonicsJudgeGeneratedDeckAndReceiveOnlyNarration',
           'flashcards':'testOriginalFlashcardJudgeRevealAndDifficultyThroughNativeProviders',
           'focused-goal':'testOriginalFocusedGoalPlannerAndWrittenRubricUseNativeProvider',
           'companion-quest':'testNativeCompanionBlueprintAndRecallDeckUseOriginalPrompts',
           'headline':'testNativePlateHeadlineStreamsPublicLessonOutcomesAndResponsesRecovery',
           'lesson-content':'testActualCurriculumContextProducesFamilyVocabularyAndMatching',
           'realtime-connection':'testDefaultRealtimeModelReturnsDataEventsAndNativeWebRTCAudio',
           'realtime-legacy-gemini':'testOriginalRealtimeGoalAndJudgingWithLegacyGeminiAudio',
           'realtime':'testDefaultRealtimeModelReturnsDataEventsAndNativeWebRTCAudio',
           'landing':'testPublicLandingDemoReturnsLiveAudioWithoutAccount',
           'practice':'testOriginalPracticeRecipesGenerateAndJudgeNativeQuestionContracts',
           'practice-formats':'testEveryOriginalPracticeFormatProducesAUsableNativeQuestion',
           'quiz':'testNativeFinalQuizQuestionsUseAuthoredContentAndProviderFallback',
           'exploration':'testNativeExplorationQuestReauthoringAndNPCSpeechPreservePlayablePaths',
           'reading': 'testNativeReadingGenerationAndResponsesFallback',
           'stories': 'testNativeStorySourcePoliciesBatchWorthAndResponsesFallback',
           'services': 'testNativeAuthenticationGeminiResponsesAndVoice',
           'immersion': 'testNativeImmersionGenerationUsesResponsesAndPreservesExistingMissions',
           'conversation': 'testNativeConversationGoalsGradeCommunicationAndReanchorPremiseRejection',
           'rpg': 'testNativeRPGStoryAndRoleplayUseTheAuthoredChapter',
           'rpg-objects': 'testNativeRPGObjectsUseOriginalPromptAndReturnBilingualAmbientContent',
           'signer': 'testNativeRemoteSignerAuthenticatesWithActualUserAndWebRestoreDeniesUnlinkedAccount'}
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--only", choices=sorted(methods))
parser.add_argument("--result-bundle", type=Path)
arguments = parser.parse_args()
selection = arguments.only

with (root / '.secrets/app-check-debug.json').open() as f:
    token = json.load(f)['token']
env = os.environ.copy()
env.update(TEST_RUNNER_PIYALI_OFFLINE_TESTS='1', TEST_RUNNER_PIYALI_LIVE_API_TESTS='1',
           TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE=str(uuid.uuid4()), TEST_RUNNER_FIRAAppCheckDebugToken=token)
if selection == 'exploration':
    env['TEST_RUNNER_PIYALI_EXPLORATION_DIAGNOSTICS_DIR'] = str(root / '.secrets/exploration-diagnostics')
test = ('PiyaliTests/RealtimeConnectionTests' if selection in ('realtime','realtime-connection') else 'PiyaliTests/LiveAPIIntegrationTests') + ('/' + methods[selection] if selection else '')
if selection == 'teams':
    test = 'PiyaliTests/TeamsMirrorLiveTests/testDeployedPublicMirrorMembershipRenameAddsAndRevocation'
tests = [test]
if selection == 'phonics':
    tests.append('PiyaliTests/RealtimeConnectionTests/testDefaultRealtimeModelReturnsDataEventsAndNativeWebRTCAudio')
subprocess.run([str(root / 'scripts/test-ios.sh'), *['-only-testing:' + item for item in tests],
                *(['-resultBundlePath',str(arguments.result_bundle)] if arguments.result_bundle else [])],
               cwd=root, env=env, check=True)
