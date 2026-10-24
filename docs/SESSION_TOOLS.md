# Daily goal and session timer

The main product now has the original daily-goal/calendar action, daily-XP label and wave, timer action, countdown border and pause/resume action. The generic flame/XP toolbar and static orb have been removed from this signed-in surface. The public landing page retains its own source orb header.

`scripts/export-session-tools.mjs` records the current reference hashes, copies the nine original React icon SVGs, exports the original header labels and executes 23 numeric boundary cases from the source save/start handlers. It also copies the exact time-up portrait: source character ID 32 maps to `src/assets/33.webp`, not the existing story image numbered 33. Source files and caches are never written.

## Goal Manager

The original modal replaces the 10–300 XP stepper: companion/health preview, +15%/−10% explanation, 100/150/200/300 presets, a numeric draft, original translated copy, activity calendar, Close and Save. Input saves within 1–1,000 XP. Close discards the draft. Saving changes the daily target without erasing earned XP or the existing daily window. The companion editor reuses the existing native draft/locked-choice/Cancel/Save flow.

New profiles now use the source 100-XP goal and an empty custom companion name, allowing the localized “Your companion” fallback. Saved user choices remain intact. Shared-account import accepts valid small targets (including 1 and 5), the root/progress/stats fallback order and numeric strings; an invalid effective target falls back to 100. Native pending preference edits still use the existing sync conflict policy.

The calendar follows the source’s current Gregorian year, Sunday padding, 11-point cells, 2-point gaps, month labels, three-state legend, today/future treatment and original goal-day records. Today's local XP augments cloud history. Historical success is retained when the target changes. Successful history reads are cached by account/year; late account results cannot replace the new account’s calendar. The separate activity panel’s full source heatmap remains broader work.

## Timer

The modal uses the source clock, two duration layers, five-minute circular dragging, 10/20/30/45/60/90/120/180/240 presets, numeric draft, 240-minute input limit, Close and Start/Restart. Blank/nonpositive start values use ten minutes, positive values round to at least one minute. Closing retains the draft without resetting an active timer. The initial empty-session draft is 20 minutes, matching App's actual hydration behavior rather than the child component's fallback.

An account-local deadline continues while the app is backgrounded. Pause snapshots remaining seconds; resume creates a new deadline. State restores across native relaunches, the counterpart of restoring the web tab's session. A sleeping task publishes only state transitions; only the small countdown badge updates each second, so a running timer does not publish a root learning-surface update every second. Account changes cancel old scheduled callbacks.

Expiration opens the source purple/cyan time-up presentation with the mapped portrait and localized duration, Close and Start another timer. A restored expired timer opens the same presentation. Completion produces a durable account-local achievement intent keyed by the timer UUID. The existing private `nosabos`/`session_timers` ledger receives one immutable event; retries preserve its first timestamp and award no practice XP. The queue remains pending through offline/auth failure and retries on restoration, foregrounding or successful account sync. The timer write creates no public Nostr event or paid entitlement. If the learner already enabled achievement sharing, the existing opt-in achievement sync continues to handle newly earned awards.

The current reference contains only manual header callbacks for opening these tools. A full-tree search finds no active automatic post-introduction daily-goal → timer launch; older chain comments do not establish such a behavior. Native follows the current manual flow rather than introducing another onboarding interruption. Timer completion can overlay an open goal/timer without discarding its draft; native navigation sheets and first-run/lesson dialogs finish before the root time-up presentation is shown.

## Source and native verification

The read-only preview renders the unmodified goal/timer components. The header preview uses the exact source header JSX/constants extracted from `TopBar`, with public fixture actions and no App authentication or daily-reset effects. Only the goal modal's history service is replaced with an explicit empty public fixture; its save callback records a result locally. It creates no browser learner or Firebase write. The original browser interaction confirms 45-minute preset selection and that entering 1,001 XP saves `{ "goal": 1000 }`.

`SourceSessionToolsTests` renders both original modals in English/light and Arabic/dark on iPhone WebKit at 402×874. The result bundle includes complete images and public DOM/font geometry. Native journeys cover goal save/discard/reopen, small and upper-limit targets, clock dragging, retaining a draft without starting, pause/background/relaunch/resume, a real one-minute expiration, expired restoration and restart. Source captures use the same iPhone rendering engine; desktop measurements are labeled separately.

The complete Core suite passed 251 tests after adding the timer and restoring the goal default. The final affected Core selection passes 18 tests, including the 23 executed source numeric cases, clock wrapping/snapping, deadline/pause/restore behavior, source goal imports and existing sync/entry regressions. These are scoped evidence, not full app parity. The final `Session-Tools-RenderFinal.xcresult` passes all six selected tests without failures/skips: private Firestore idempotency/window/XP/paid-field preservation (7.067s), two controller restoration/outbox/draft cases, iPhone WebKit source captures (9.631s), Arabic dark goal/timer controls (53.712s), and the full English real-countdown journey (164.089s). The home/menu/setup/placement/Tutor regression also passes in `Session-Tools-Navigation.xcresult` (28.790s). The final mapped-artwork/resource/native component check passes in `Session-Tools-Resources.xcresult` (1.220s).

Remaining work includes complete click/tick/completion audio choreography, physical-device background/audio checks, broader device/Dynamic Type/locale calibration, the separate activity heatmap and the returning-day companion blueprint/repair recap. Existing app-wide day/health/progression and paid verification boundaries remain documented in the broader audit.


## Rendered evidence

| Surface | Original iPhone WebKit | Native |
|---|---|---|
| Goal Manager | [English](reference/session-tools-goal-en.png), [Arabic/dark](reference/session-tools-goal-ar.png) | [English](native/session-goal-en.png), [Arabic/dark](native/session-goal-ar.png) |
| Session timer | [English](reference/session-tools-timer-en.png), [Arabic/dark 20 minutes](reference/session-tools-timer-ar.png) | [English](native/session-timer-en.png), [Arabic/dark 240-minute selection](native/session-timer-ar.png) |
| Lifecycle | — | [Paused restoration](native/session-paused-restored.png), [real expiration](native/session-time-up.png) |

Labeled comparisons: [English goal](native/session-goal-comparison-en.png), [Arabic goal](native/session-goal-comparison-ar.png), [English timer](native/session-timer-comparison-en.png). Native includes its status area and actual home underneath; source uses a public service fixture. Pixel animation phases can differ. Public geometry is saved beside each source capture. The [desktop style measurements](reference/session-goal-dark-styles.json), [desktop header](reference/session-header-desktop-en.png) and [actual source upper-bound save](reference/session-goal-clamp-desktop.png) are labeled separately from iPhone evidence.

Current time-up component snapshots in [English](native/session-time-up-component-en.png) and [Arabic](native/session-time-up-component-ar.png) include the final white close symbol. The real-countdown screenshot predates that leaf color correction; its pause, expiry, restore and restart behavior is unchanged. The component resource test checks the exact source portrait bytes and renders both text directions without an account or network.

These comparisons still show small control-corner and mixed Latin/Arabic token-order differences in the goal presets/health preview. Detailed time-up dialog and multi-locale calibration remain open. The calendar uses the source's Gregorian year/key calculation independently of the phone's preferred display calendar. This checkpoint establishes the listed functional journeys and a substantially closer source presentation; it does not establish pixel-perfect parity or complete the product goal.
