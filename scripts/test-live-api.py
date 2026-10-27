#!/usr/bin/env python3
"""Opt-in native service check. Pass debug tokens only through the runner environment."""
import argparse, json, os, subprocess, uuid
from pathlib import Path
root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--only', choices=['standard-help', 'oral', 'word-bank', 'standard', 'writing', 'teams', 'tutor-gemini', 'tutor-focused', 'tutor', 'phonics', 'flashcards', 'focused-goal', 'companion-quest', 'headline', 'lesson-content', 'realtime', 'realtime-connection', 'realtime-legacy-gemini', 'landing', 'practice', 'question-help', 'exercise-interactions', 'practice-formats', 'services', 'immersion', 'conversation', 'rpg', 'rpg-objects', 'help', 'signer', 'stories', 'reading', 'exploration', 'quiz'])
selection = parser.parse_args().only
methods = {'standard-help':'testOriginalStandardAssistanceStreamsSubmittedAttemptsAndLanguages','oral':'testOriginalOralGenerationFlashcardJudgesAndAssistanceUseNativeProviders','word-bank':'testTranslationAndRepeatUseOriginalDirectionsAndNativeJudges','standard':'testStandardChoiceFillAndMatchingUseOriginalNativeJudges','writing':'testWritingExercisesUseOriginalSemanticJudges','exercise-interactions':'testFiveExerciseBodiesUseOriginalSemanticJudgesIncludingAlternativeReplies','question-help':'testOriginalQuestionAssistanceStreamsAndExplainsThroughLearnerFirebase','teams':'testDeployedPublicMirrorMembershipRenameAddsAndRevocation','help':'testNativeHelpChatStreamsSupportLanguageAndAnalyzesTargetMorphemes',
           'tutor-gemini':'testLearnerGeminiTutorUsesFirebaseIdentitySourcePromptAndNativePlayback',
           'tutor-focused':'testOriginalFocusedTutorGoalAndRepairJudgesUseNativeProviders',
           'tutor':'testOriginalTutorJudgeWelcomeAndNativeVoiceWithSourceTranscriptionContext',
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
subprocess.run([str(root / 'scripts/test-ios.sh'), *['-only-testing:' + item for item in tests]],
               cwd=root, env=env, check=True)
