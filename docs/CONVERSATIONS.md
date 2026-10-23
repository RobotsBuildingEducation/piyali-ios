# Conversations correction

The generic conversation form has been replaced by the source voice-first screen: a compact settings/goal/chat-log card, foundation help, a small orb area, the latest assistant reply, and the shared fixed action bar. The screen begins with Start, then shows separate mute, pause/resume and end controls. There is no typed-reply form and no automatically generated opening message. Starting listens for the learner, as the reference does.

Settings use the actual source proficiency descriptions, pronunciation switch and custom-topic copy. Closing after a level/topic edit regenerates the topic; shuffling preserves the private conversation, progression and rewards. The source uses observed rating for generated challenge even when the saved proficiency preference changes; native topic selection, instructions and difficulty quotes now follow that policy. Curriculum context samples up to 15 unit/lesson titles from all levels through the observed level, excluding tutorials and quizzes.

The actual `Conversations.jsx` initial-topic, contextual-goal, judge and voice instruction expressions run in the existing pure policy interpreter. The original starter prompt/parser supplies a target phrase, at most one personal blank and its support-language translation. Network, audio, private state and UI remain native. Initial topics use the configured Firebase text path; contextual goals/judges use Responses; separate source difficulty assessment produces the saved quote. Source hashes are in the policy and UI manifests.

## Speech and learning behavior

Learner transcription now has its own callback, so saving/grading starts before the assistant finishes speaking. Completed assistant replies are saved separately. Provider IDs deduplicate messages and let a delayed learner transcript be inserted before its already-saved reply. Older private drafts decode without those optional IDs. Scope checks still reject callbacks after account/language/view replacement.

New connections do not treat the old chat log as fresh speech. Pause/resume retains mute and supplies a frozen private history snapshot; later instruction updates do not repeatedly append the current connection's messages. Starter playback ducks the microphone, server VAD and remote track without changing the user's mute setting or re-enabling input during assistant speech. Native narration keeps the existing voice-chat audio session while connected.

A successful goal remains visible briefly before the next goal, matching the source's 1.5-second transition. The purple completion summary shows this connection's XP, goals and speaking turns, plus per-language XP progress. Its totals survive pause/resume and do not award again when reviewed. The chat log preserves separate learner/tutor bubbles, translation and saving to private notes.

## Verified

- Full Core suite: **217 tests, zero failures** (185.3s). New cases cover source goal/judge/starter prompts, contextual alignment, support translation, late transcript ordering, provider replay and older draft decoding.
- Six native voice-controller checks pass input-before-reply grading, muted resume, frozen history, source personality/VAD, playback locks, starter ducking, failure cleanup and duplicate/stale callbacks.
- The real provider check passes (30.0s): initial and contextual goals, communication-success/wrong-language/premise-rejection judging, starter, translation and the legacy text/reply/Gemini audio paths. It uses disposable Piyali authentication, which is removed. The default OpenAI WebRTC connection's separate verified scope is documented in [VOICE_TRANSPORT.md](VOICE_TRANSPORT.md).
- The simulator settings journey passes (43.7s): original labels, proficiency/pronunciation/topics, dismissal without recording, persistence and dark relaunch.
- The complete voice-first journey passes (70.3s): no typed form/opening reply, help, a missed turn, mute, pause, muted resume, a successful turn, one +5-XP summary, one goal/two turns, history, private note saving, relaunch and unchanged account XP. Strictly scoped Debug fixtures send scripted protocol events through the production voice controller and learning service. They do not capture actual microphone audio or insert extra learner controls.

## Source/native captures

The reference renderer uses the unmodified goal/orb and call-control JSX, original styles/copy and original 3D renderer with fixed QA state. It omits account/model/microphone effects. Its footer host reserves the global menu slot; it is not the full web app header/portal. Reference frames are 402×874; native captures include the iOS status bar and current product shell at simulator resolution. They support comparison of this component, not a claim of complete screen pixel parity.

| State | Source | Native |
|---|---|---|
| Initial light | [Original goal/orb/control panel](reference/conversation-light.png) | [Native initial screen](native/conversation-light.png) |
| Dark | [Original connected controls](reference/conversation-dark-controls.png) | [Native initial dark](native/conversation-dark.png), [settings](native/conversation-settings-dark.png) |
| Other native states | Source behavior inspected in `Conversations.jsx` | [Paused controls](native/conversation-paused.png), [reply](native/conversation-reply.png), [summary](native/conversation-summary.png), [private history](native/conversation-history.png) |

The dark images show different call states; they are labeled accordingly. `scripts/render-conversation-reference.mjs --serve` recreates the isolated source fixture, and `scripts/export-conversation-ui.mjs` refreshes the source UI copy/manifests. The reference repo remains read-only.

## Remaining differences

This is a scoped correction, not completed Conversations parity. The orb still uses the bundled static artwork; it lacks the source's 3D expression, dark palette, reactions and audio response. Live text lacks source morpheme alignment/selection, archival animation and some translation/streaming behavior. Exact recorded-audio replay/cache, source Realtime narration, unfinished-speech continuation on resume, advanced global voice/personality/pause preferences and cross-device web draft compatibility remain open. The native summary is currently an iOS sheet rather than the centered web dialog; detailed geometry, icon/palette and locale comparisons remain. Support-language changes also still need explicit invalidation of saved goal/translation language metadata, rather than retaining a previous language's draft.

Physical microphone capture, audible playback, starter ducking, interruptions/routes and device background behavior still require iPhone audio interaction. Passing scripted events, model calls and received RTP packets does not establish those behaviors or full functional/design parity across the app.
