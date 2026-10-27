# Playable course-game preparation

Starting a course Game Review now turns its preview into the original playable companion map while the chapter prepares. The learner can tap or swipe to move, examine objects, enter either indoor room and return outside. Cancel closes the preparation and lesson preview. Content preparation is followed by the original random 5–8 second exploration window before the actual chapter opens.

This replaces the immediate native transition into an RPG spinner. Swift owns the preview, staged preparation, input, drawing, timers, audio, cancellation, saved runs and lesson navigation. No production WebView renders the mini-game.

## Original rules and content

The game-loader exporter extracts the actual LoadingMiniGame.jsx world generator, tile and six companion drawers, initial state, movement/touch/interaction/door callbacks and frame loop. A pure JavaScriptCore policy keeps those rules intact. A small canvas-command adapter feeds UIKit/Core Graphics, at the source canvas's logical pixel resolution, including its camera, animation clocks, transitions, object messages and room-name timers. The world is generated once per presentation from a timestamp seed. New maps are temporary and never become the learner's saved chapter.

The header uses the original loading-message catalog and 1.5-second rotation. The support language selects the original room/object text and fallbacks. The current companion is used and refreshes in place when its canonical type changes. The original sine-note timings, pitches, gain and envelopes for movement, dialogue-open and door selection are exported as portable PCM; synthesis approximates Tone's exponential envelopes at 120 BPM. Sound enablement and volume use the existing learner preferences without changing the audio-session category.

## Preparation and ownership

RPGService can now stage a run without writing it. An unfinished matching saved run still takes precedence. Valid generated content can enter the existing account/support-scoped cache, but the staged cast/run does not become learner progress until handoff. Preparation, exploration and Cancel grant no XP, task credit, completion receipt or lesson start.

The preparation controller rejects delayed results after cancellation, account/target/support/level changes or lost access. The same pending request is shared. The exploration timer begins after content is ready, including a cached response, as in the course preview's source callback. Closing the view stops animation/audio and cancels unfinished work. A late canonical refresh of the same saved run is retained; a different newer run prevents an older draft from overwriting it. Only a valid, still-owned handoff commits the run and starts the ordinary lesson flow. Reopening saved work preserves the current task, position and cast.

## Verification

- All 321 Core tests pass (282.080 seconds). The focused map check covers 569 executions of the original generator, controls, drawing, object messages, room entry/return, timers, companions, loading copy and delay bounds. World structure, control state and copy compare exactly; drawing numbers and numeric RGBA components allow a 1e-9 tolerance for JavaScript engines' final floating-point bits.
- All thirteen affected preparation/controller checks pass. Four new cases cover uncommitted drafts, cancellation during both phases, delayed callbacks, scope/access loss, newer runs and late saved progress.
- The renderer draws a nonempty source map and stops its display link on detach. It averaged 14.138 ms per frame over twenty simulator frames including policy execution, decoding and drawing. This is a simulator sample, not a physical-device performance guarantee.
- The actual landing/onboarding/course journey passes in 131.594 seconds: move, Cancel, retry, handoff to the prepared seven-task chapter, and relaunch/resume at 0/7 without a completion bonus. All five selected model/renderer tests also pass in that run.
- The final three-test simulator selection passes the eight English/light and Arabic/dark source/native states (18.717 seconds), renderer and complete course preparation journey again (129.668 seconds), without failures or skips. The full prepared chapter also passes through pending-speech cancellation, relaunch, its 30-XP reward and cached replay in 343.815 seconds; its containing earlier run fails only the preview-initialization comparison. The final companion-refresh wiring also passes both source/renderer checks again (eight states in 16.582 seconds). Final comparison and chapter details are in [VALIDATION.md](VALIDATION.md). Provider fixtures are restricted to explicit isolated offline test identities; production access checks remain active.

The comparison harness mounts the actual source mini-game and extracts the course preview's original loading header. Only seed, clock/frame control, providers/stores and sound I/O are adapted. Comparison canvases freeze their animation clock on both sides; production animation stays enabled. Courier metrics, ordinary left-to-right paragraph behavior for the source Arabic strings, room/message padding and the light-theme gray color remapping follow the executed reference. Native and source receive the same movement/interaction trace.

The introductory game's earlier-module warming and loader handoff, Tutor launch handoff, opportunistic next-review warming, broader cancellation/interruption permutations, exact transient text motion and physical audio/accessibility remain open. Legacy exploration/generation/search is separate. The reference checkout and deployed Firebase/Cloudflare services remain unchanged.

Source/native examples: [arrival](native/game-preparation-arrival-en.png), [Arabic message](native/game-preparation-message-ar.png), [indoor room](native/game-preparation-indoor-en.png). Actual product captures: [playable map](native/game-preparation-playable-product.png), [Cancel](native/game-preparation-cancelled-product.png), [handoff](native/game-preparation-handoff-product.png), [saved chapter](native/game-preparation-resumed-product.png).
