# Learner Tutor: Gemini connection checkpoint

The web Tutor defaults to Gemini. Native Tutor now does too. Conversations, Reading, ordinary narration and the public landing demo retain their separate source providers and identities. `TutorRealtimeProvider=openai` in local app configuration preserves the source OpenAI profile when explicitly selected.

The target-owned exporter extracts the original `buildLanguageInstructions`, response suffix, welcome/kickoff/follow-up and reconnect builders. Gemini sends its system context once and its original per-turn prompt; OpenAI retains its composed response instructions. The source Tutor disables tool grading, so native progress continues through the original phrase/semantic grading pipeline. Unsolicited provider tool calls cannot grant XP.

The native bridge implements the source response queue, 20-second first-response timeout, local speech activity, continuous enabled 16 kHz PCM input (including silence), explicit mute/thinking gate, suppression of unsolicited automatic replies, preferred output transcription, thought-free fallback text, 24 kHz PCM playout and completion only after the final scheduled buffer has played. It reconnects after four completed responses and retains queued work and the latest input gate. Native response/input IDs remain unique across reconnect and pause/resume.

The actual reference bridge executes under inert session, clock and audio adapters to produce nine traces / 70 steps. Swift matches the events, sends, PCM history and state after every step. One source race is intentionally fixed: closing during a pending reconnect cannot accept a late socket, reopen the microphone or dispatch queued prompts. Native tests exercise that boundary at both initial connection and the fourth-turn reset.

Firebase Google AI uses `gemini-3.1-flash-live-preview`; the configured Vertex profile uses `gemini-live-2.5-flash-native-audio` in the configured region. The learner connection requires the dedicated `piyali-ios` Firebase app, custom Nostr sign-in with matching UID/public-key claim, and App Check. It never reuses the limited public-demo identity. A thin URLSession websocket boundary follows the pinned FirebaseAI 12.19.2 route, resource names and authentication headers. This retains the source `inputAudioTranscription.languageCodes`, which the pinned Swift SDK's empty public transcription config cannot encode. The service host is fixed; local configuration cannot redirect Firebase credentials to another websocket host.

Settings exposes the four source Gemini voices and 0–4 volume control. Effective playback gain follows the original bridge's unity clamp. The original voice preview runs on receive-only native PCM, with no microphone capture or transcription request. Tutor and previews share an audio-session lease so closing a preview cannot deactivate a still-running Tutor. Stored settings outbox entries include their provider; legacy entries keep the previous OpenAI normalization behavior. The source Settings fixture now renders the active Gemini profile using explicit public volume and provider snapshots.

## Verification

- The complete 290-test Core suite passes, including 598 source-executed Tutor prompt/policy cases, 274 Settings cases and the 70-step bridge comparison. The new settings encoding test checks Gemini outbox retry and legacy decoding.
- All 20 existing Tutor controller checks and five initial transport checks pass in the focused run. These include ordinary, completed-practice, Goal/repair, quiz, pause/resume, failed-save/retry, trial boundary, monotonic access and completion-reward behavior.
- A live isolated learner account received the original welcome through Firebase/App Check: 341,762 PCM bytes, 29 native played buffers and a nonempty transcript. No learner-progress writes or paid-access grants were made.
- The final six transport/audio checks, both Settings UI journeys, real Charon preview, Firestore races/retries and twelve source/native comparison pairs pass; details are recorded in [VALIDATION.md](VALIDATION.md).

## Remaining scope

This is a provider/lifecycle correction within the ongoing parity work. Physical iPhone microphone/acoustic behavior, Bluetooth/background route recovery, split/late ASR burst recovery, stored recorded-clip replay, streamed translated tokens, wider completion/review designs, all locales and the remaining product surfaces still require their own checks. The native connection currently fails visibly if its transcription/voice setup is rejected; the source's fallback configurations that omit transcription or selected voice are not used to silently claim a successful learner session.
