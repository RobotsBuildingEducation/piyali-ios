# Conversations correction

The generic conversation form has been replaced by the source voice-first screen: a compact settings/goal/chat-log card, foundation help, a small orb area, the latest assistant reply, and the shared fixed action bar. The screen begins with Start, then shows separate mute, pause/resume and end controls. There is no typed-reply form and no automatically generated opening message. Starting listens for the learner, as the reference does.

Settings use the actual source proficiency descriptions, pronunciation switch and custom-topic copy. Closing after a level/topic edit regenerates the topic; shuffling preserves the private conversation, progression and rewards. The source uses observed rating for generated challenge even when the saved proficiency preference changes; native topic selection, instructions and difficulty quotes now follow that policy. Curriculum context samples up to 15 unit/lesson titles from all levels through the observed level, excluding tutorials and quizzes.

The actual `Conversations.jsx` initial-topic, contextual-goal, judge and voice instruction expressions run in the existing pure policy interpreter. The original starter prompt/parser supplies a target phrase, at most one personal blank and its support-language translation. Network, audio, private state and UI remain native. Initial topics use the configured Firebase text path; contextual goals/judges use Responses; separate source difficulty assessment produces the saved quote. Source hashes are in the policy and UI manifests.

## Speech and learning behavior

Learner transcription now has its own callback, so saving/grading starts before the assistant finishes speaking. Completed assistant replies are saved separately. Provider IDs deduplicate messages and let a delayed learner transcript be inserted before its already-saved reply. Older private drafts decode without those optional IDs. Scope checks still reject callbacks after account/language/view replacement.

New connections do not treat the old chat log as fresh speech. Pause/resume retains mute and supplies a frozen private history snapshot; later instruction updates do not repeatedly append the current connection's messages. Starter playback ducks the microphone, server VAD and remote track without changing the user's mute setting or re-enabling input during assistant speech. Native narration keeps the existing voice-chat audio session while connected.

A successful goal remains visible briefly before the next goal, matching the source's 1.5-second transition. The purple completion summary shows this connection's XP, goals and speaking turns, plus per-language XP progress. Its totals survive pause/resume and do not award again when reviewed. The chat log preserves separate learner/tutor bubbles, translation and saving to private notes.

## Language changes and overlapping requests

Changing support language now regenerates the goal and starter while preserving the private session, message log, turn receipts, XP and rating. Goals record their requested support language; translations record theirs and are only displayed for that language. Unknown older translations remain stored but can be translated again. Older goals are adopted only when a single matching language key proves their language; the source sometimes aliases a localized goal under `en`, so multiple untagged keys trigger regeneration. Optional fields keep older drafts decodable.

Account, practice-language and support-language changes close the old connection and clear temporary voice text. Every pending goal, starter, translation and grade fences both its result and error against that context. An old request cannot overwrite the current goal or clear another request's busy state. Speech still gets assessed while a translation is pending; only another pending grade causes neutral practice. Continued speech during the source's delayed successor-goal transition shares one goal request. Returning to an already completed saved goal advances without another completion reward.

## Native orb and centered completion dialog

Conversations now uses a native SceneKit/Metal sphere rather than the static app artwork. Its 72×48 deformed body, curved face, eight exported eye outlines, critically damped morph, blinking, default tutor moods, mint/blue palettes, pigment flow, thinking dots and five reactions follow the original orb. Correct goals produce the source joyful moods and reactions; misses produce curious/tender moods; an inactive call rests with sleepy eyes. Explicit reactions expire even when Reduce Motion stops the frame loop. Scene resources stop animating offscreen or behind the conversation sheets/dialog.

The original default pigment and Three ACES tone-mapping expressions are converted to Metal shader modifiers. The original RoomEnvironment is captured as linear RGBE for native image-based lighting; Three's MIT notice is bundled. Native transparent-ink blending has a gamma adapter. This preserves the source artwork and movement, while the SceneKit lighting model, reflections, shadow filtering and final compositing still require further visual calibration. Other screens' display orbs and pet/drag interactions have not yet been migrated.

WebRTC input/receiver statistics supply normalized audio amplitude at 100-ms intervals. The native visual envelope follows the executed source noise-floor, onset/hold and attack/release policy. Muting input, starter playback ducking, disconnect and stale connection samples cannot keep the orb reacting to old audio. Statistics do not alter microphone recording, server VAD or reward decisions. The real receive-only WebRTC check also passes (6.4s), including positive receiver amplitude from incoming RTP. Microphone amplitude, audible response and physical-device behavior remain unverified.

The completion summary is now a centered, rounded purple dialog with the original character-34 portrait mapping, mobile inset/spacing, XP badge, green progress colors and Done button. The page behind it is dimmed and cannot be operated. Done, outside-tap and accessibility escape close the dialog without modifying rewards. The card can scroll on smaller displays. Fine geometry, wave decoration, all locales, dynamic text sizes and transitions remain visual-comparison work.

## Verified

- **25 affected Core checks pass** (0.54s), including 120 reaction poses and 16 eye-morph trajectories executed by the original source, the original voice-envelope trajectory, conversation/language compatibility and realtime policies. The previous complete Core baseline is 221 passing tests (164.8s); the three visual-policy tests were added after that baseline.
- **17 native checks pass**: seven language/service races; eight voice-controller checks, including audio envelope mute/duck/stale-sample handling; and two actual renderer checks covering both palettes, transparent corners, non-white pigment and reaction expiry with Reduce Motion. Renderer snapshots exercise Metal shaders, not replacement artwork. Their scope does not prove complete pixel parity.
- The three conversation simulator journeys pass together: settings/theme persistence, English → French → Spanish support refresh/relaunch, and the complete voice/reward/history journey. They retain the original five XP, one goal/two-turn summary, private history/note and unchanged account XP after relaunch. The final full voice journey also verifies outside-tap dismissal, a second zero-turn/+0-XP call and Done dismissal (78.6s). The latest complete run and durations are in [VALIDATION.md](VALIDATION.md).
- The earlier real provider check passes (30.0s): initial/contextual goals, communication-success/wrong-language/premise-rejection judging, starter, translation and legacy text/reply/Gemini audio paths. It deletes its disposable authentication. This visual correction does not change those prompts or endpoints. OpenAI WebRTC's separately verified network scope is in [VOICE_TRANSPORT.md](VOICE_TRANSPORT.md).

The simulator voice journeys send scripted protocol events through the production controller and learning service. They do not capture microphone audio or add extra learner controls. A failed container-type assertion was replaced with checks of the visible dialog position and blocked underlying controls. Screenshot review also corrected the portrait-map offset before the final captures.

## Source/native captures

The reference renderer uses the unmodified goal/orb, summary and call-control JSX, original styles/copy and original 3D renderer with fixed QA state. It inherits the actual Chakra/theme/index fonts; the earlier comparison fixture's forced DM Sans override was removed. It omits account/model/microphone effects. Its footer host reserves the global menu slot; it is not the full web app header/portal. Reference frames are 402×874; native captures include the iOS status bar and current product shell at simulator resolution. They support comparison of this component, not a claim of complete screen pixel parity.

| State | Source | Native |
|---|---|---|
| Initial light | [Original goal/orb/control panel](reference/conversation-light.png) | [Native initial screen](native/conversation-light.png) |
| Dark | [Original connected controls](reference/conversation-dark-controls.png) | [Native initial dark](native/conversation-dark.png), [settings](native/conversation-settings-dark.png) |
| Completion | [Original centered dialog](reference/conversation-summary.png) | [Native centered dialog](native/conversation-summary.png) |
| Other native states | Source behavior inspected in `Conversations.jsx` | [Paused controls](native/conversation-paused.png), [reply](native/conversation-reply.png), [summary](native/conversation-summary.png), [private history](native/conversation-history.png) |

Fixed sleepy-pose comparisons: [source mint](reference/orb-mint-sleepy.png), [native mint](native/orb-mint-sleepy.png), [source blue](reference/orb-blue-sleepy.png), [native blue](native/orb-blue-sleepy.png). Source orbs are 256×256 on the page background; native renderer snapshots retain transparency and display scale. Source hashes and the HDR asset are recorded in [orb manifest](reference/orb-visuals-manifest.json).

The dark images show different call states; they are labeled accordingly. `scripts/render-conversation-reference.mjs --serve` recreates the isolated source fixture, and `scripts/export-conversation-ui.mjs` refreshes the source UI copy/manifests. The reference repo remains read-only.

Language-state captures from that successful run: [French support](native/conversation-support-fr.png) and [Spanish support restored](native/conversation-support-es-restored.png).

## Remaining differences

This is a scoped correction, not completed Conversations parity. Orb lighting/reflections/compositing need further comparison, and other screens still retain static display artwork. Live text lacks source morpheme alignment/selection, archival animation and some translation/streaming behavior. Exact recorded-audio replay/cache, source Realtime narration, unfinished-speech continuation on resume, advanced global voice/personality/pause preferences and cross-device web draft compatibility remain open. The centered summary still needs all locale/dynamic-text and fine geometry/wave-animation comparisons.

Physical microphone capture, audible playback, starter ducking, interruptions/routes and device background behavior still require iPhone audio interaction. Passing scripted events, model calls and received RTP packets does not establish those behaviors or full functional/design parity across the app.
