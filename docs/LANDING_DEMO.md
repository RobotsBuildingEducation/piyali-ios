# Public landing voice demo: native correction

The source for this checkpoint is the unmodified `LandingTutorDemo.jsx`, `landingTutorDemo.js`, `geminiLiveBridge.js`, `VoiceOrbNext.jsx`, `VoiceWaveIcon.jsx` and landing CSS in the reference checkout. The public demo uses Gemini in the original web app too. It remains an unsaved lesson with a separate Start control from account creation.

## Behavior carried over

The source has five numbered teaching turns and a sixth final-feedback response. The learner speaks after turns 1, 3, 4 and 5. Turn 2 gives feedback on the first attempt and immediately requests turn 3. The last review attempt must be accepted before the goodbye response. The native controller now follows that sequence, using the original exported system and per-turn prompts for all twelve practice languages.

The microphone remains gated until each requested response finishes playback. Server turn completion alone does not reopen input. The Gemini adapter assigns audio-buffer tickets and only emits the source `response.done` event after its own buffers drain. Old/duplicate completion callbacks cannot complete the next response. Unrequested automatic Gemini replies are suppressed; the learner transcription requests the next authored turn instead. The native adapter also preserves an input transcription that arrives late within a suppressed automatic turn.

Stop before the first completed response restores the sample. Stop after a completed response retains the transcript and offers another lesson. Changing capability tabs preserves the selected language and completed transcript while closing the active session, matching the source's retained panels. Language selection resets the sample; selection is disabled during startup and practice. Permission denial, failed connection and a missing response start offer retry. The source has a twenty-second connection and response-start limit, with no countdown that cuts off an otherwise connected speaking/listening lesson.

An iOS microphone permission sheet changes the scene to inactive. That transition now preserves startup; backgrounding, leaving the view and scrolling the component entirely offscreen close it. Each attempt scopes callbacks and timeout/meter work to that attempt. Public auth and audio cleanup happen before an old asynchronous SDK close can finish, so it cannot sign out or deactivate a newer attempt.

## Presentation

The compact language selector, original locale-sorted labels and beta tags, mint/peach transcript bubbles, DM Sans sizing, nine-bar voice indicator, 116-point orb and compact status/start/stop controls follow the original mobile component. Transcript bubbles scroll internally after 100 points. The inactive orb uses the original random display personalities and reactions, loving tap reaction and drag turn; an active demo switches to the raw tutor state. Conversations deliberately swaps listening/speaking visual patterns in its source helper; that mapping is now applied only to Conversations.

The reference captures ([light](reference/landing-demo-es-en-402.png), [dark](reference/landing-demo-es-en-dark-402.png)) mount the original demo JSX and CSS at 402 CSS pixels. Their host omits the rest of the page and starts no microphone, account or model session. `scripts/render-landing-demo-reference.mjs` records source hashes and documents that scope. Native captures cover the component in the actual landing scroll view. Browser/native 3D rendering, native menu presentation and random animation frame differ; these comparisons do not establish whole-page pixel parity.

Native simulator captures: [idle Spanish sample](native/landing-demo-light.png), [loving tap reaction](native/landing-demo-boop.png), [sixth feedback and unsaved completion](native/landing-demo-ended.png). The completion transcript in that last image comes from the documented scripted UI transport, not a recording of model output.

## Evidence and remaining checks

`scripts/export-landing-demo-policy.mjs` executes the real JavaScript controller to capture six journeys, including the complete lesson and original request prompts, early/empty/duplicate input, duplicate completions, cancellation, provider errors and transcript bounds. Native Core checks compare those traces and exercise playback tickets, automatic-reply suppression, delayed transcription and text-only fallback. Injectable native service checks cover permission-sheet inactivity, backgrounding, old connection callbacks, retries and response-start timeout without interrupting tutor playback.

UI tests use a strictly scoped DEBUG transport with no network, microphone or learner identity. They exercise the actual native service/controller and views, with six scripted replies and four learner attempts. The separate opt-in network test supplies four text attempts directly to the real Gemini session; it requires PCM and a transcript for all six original response prompts. The live six-response check passed in 61.4 seconds, and the three simulator journeys passed together alongside the capability-page regression. The complete Conversations reward/history/relaunch regression also passed after the shared renderer extension. Neither layer proves physical microphone recognition, audible playback, Bluetooth/audio-route recovery or real human turn-taking. Those remain device checks.

The public session still uses its separate named Firebase app and fixed public-only service identity. It cannot read learner Firestore documents or use learner Responses authorization. It creates no Nostr identity, progress, reward, saved transcript or automatic signup transition. The main learner session remains signed out.
