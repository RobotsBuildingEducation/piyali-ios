# Today's Focus: source comparison in progress

This checkpoint replaces the generic native home cards with the reference product's task rows, floating companion panel and combined Score/immersion card. It does not establish whole-product parity.

The read-only sources are `DailyPlateHome.jsx`, `PlatePetPanel.jsx`, `CompanionQuestBubble.jsx`, `WaveBar.jsx`, `PlateScoreJourney.jsx`, `ImmersionTasksContent.jsx`, `companionDrawing.js` and `companionCustomizeCopy.js`. [Source hashes](reference/focus-source-manifest.json) identify the inputs. `scripts/export-focus-ui.mjs` extracts the original ten-language copy, stage appearances, six companions × six health states × twelve frames and original icon paths. Existing celebration artwork stays separate from the home health animation.

## Behavior and presentation

| Source behavior | Native checkpoint |
|---|---|
| Ordered, display-only 64-point rows, 10-point gaps; neutral, purple or teal borders; next badge, count and wave progress | Original course icons, source spacing/copy, completion colors and clipped gradient/wave bars |
| Tasks locked until the per-day companion acknowledgement; the balloon overlaps the tasks above the pet | Preserves the scoped acknowledgement and setup → placement handoff; measured balloon height positions the single seeded outline above the pet |
| Health affects the drawing, badge and panel background, with a separate daily XP bar and total-language XP/level bar | Exact source pixel rectangles for each health stage; source labels and gradients; true daily percentage may exceed 100 while the bar remains capped |
| Pencil opens a companion editor, with draft changes and six choices at levels 1/2/5/10/20/40 | Dedicated editor replaces the jump to generic Settings; Cancel/outside dismissal discard, Save/Return trim and persist the name and available type; locked options remain visible |
| 56-point Score, localized practice-language name, CEFR label and horizontally scrollable 96-point milestone columns | Original milestone icon paths and captions, reached/current styling and automatic centering |
| Immersion lives below a divider in Score; rounded task checkboxes, optional fourth goal and +15 XP completion card | Same containment, labels, goal marker and completion card; rewarded completed tasks disable further toggles, including after relaunch |
| Source changes the motivational phrase between days | Chooses from the original twenty localized encouragements; VoiceOver includes the encouragement and reward |

The editor uses a persistent scroll container during keyboard presentation. An initial `ViewThatFits` implementation switched view identity when the keyboard appeared and lost focus; the actual keyboard journey caught this and the final implementation removes that switch. No production account/key was used by those tests.

The source Arabic balloon extends beyond the right edge of the phone. Native deliberately mirrors its outline/tail and anchors it left of the right-hand pet, keeping the whole message and Continue control usable. Source physical left anchoring of the progress fill is retained in either document direction. Source screenshots are evidence of the original behavior, not a requirement to reproduce its clipping bug.

## Evidence boundaries

`scripts/reference-onboarding.jsx?screen=focus` renders the unmodified source components at 402 × 874 with the source DM Sans CSS and original theme/language stores. The target-owned wrapper hides desktop scrollbars to match iPhone overlay scrollbars; all Vite caches remain in this iOS repository. Fixtures explicitly supply the source fallback subtitle as a cached headline so QA does not call Gemini or write a real learner document. The source user has no account id. The progress fixture supplies one completed task, two reviewed cards, 49 health and 250% daily XP. Immersion task text is an explicit service fixture, not an AI-quality comparison. The full web App's header and animated background are outside this component harness.

[Welcome measurements](reference/focus-welcome-layout.json) record the actual source line boxes, task control, canvas and balloon geometry. [Editor measurements](reference/focus-customize-layout.json) record the actual 370 × 628 source dialog, 116-point choice tiles and 40-point footer buttons. Native keeps iOS status/navigation/home chrome; compare component-relative positions rather than subtracting an assumed browser toolbar height.

## Verified checkpoint

The final `Focus-PickerFinal.xcresult` run passes all three selected tests with no failures/skips: built-app resources (1.157s), Arabic/dark home/editor/reward journey (35.842s), and English/light acknowledgement/editor/keyboard/Cancel/Save/immersion/relaunch journey (57.470s). These use disposable offline identities and explicit immersion-service fixtures. They do not test live generation or paid membership.

The UI checks assert 64-point task rows and 10-point spacing, balloon placement above the pet, full RTL button bounds, six visible companion options with level gates, text-entry focus, discarded drafts, trimmed saved names, reward locks and persistence after relaunch. The main onboarding → Today’s Focus → menu → libraries → setup/placement → next Tutor-mode regression also passes (29.141s in `Focus-Final.xcresult`). The source checklist fixture independently reaches three checked/disabled rows and its original +15 XP/encouragement card.

| State | Source component at iPhone width | Final native capture |
|---|---|---|
| First acknowledgement | [English/light](reference/focus-welcome-light-402.png) | [English/light](native/focus-welcome-light.png) |
| RTL message | [Source clipping](reference/focus-welcome-ar-dark-402.png) | [Native bounds correction](native/focus-welcome-ar-dark.png) |
| Companion editor | [Source](reference/focus-customize-light-402.png) | [Light](native/focus-customize-light.png), [Arabic/dark](native/focus-customize-ar-dark.png) |
| Score and immersion | [Source awaiting placement](reference/focus-score-immersion-light-402.png), [ready tasks](reference/focus-immersion-tasks-light-402.png) | [Light](native/focus-score-immersion-light.png), [Arabic/dark](native/focus-score-immersion-ar-dark.png) |
| Completion | [Source](reference/focus-immersion-reward-light-402.png) | [Light](native/focus-immersion-reward-light.png), [Arabic/dark](native/focus-immersion-reward-ar-dark.png) |

The existing regular simulator receives the same built application without erasing its learner data. The QA screenshots above are from isolated first-session test identities.

## Still open

- Primary-provider headline streaming, original task/prompt policy, canonical caching, offline retry, scope fencing and relaunch are now implemented and checked; see [HEADLINES.md](HEADLINES.md). The Responses recovery route still delivers one final update, so equivalent fallback-provider streaming remains open.
- Returning-day companion messages still require the web's ready blueprint preference, cleared repair recap and full repair/goal-memory comparisons. The first deterministic welcome is the journey covered here.
- Native activity history is interactive but its full heatmap, year legend/loading/error and transitions still require a source comparison. The companion/activity and achievements buttons now use source copy.
- The native queued/offline immersion receipt model remains in place. Source reward-claim failure/retry presentation, the complete reward particle/sound choreography and live generated-task quality need separate verification.
- Header/orb/daily-goal controls, source post-intro goal/timer sequencing, complete guided-session journeys, remaining modes/panels and physical-device audio/auth remain broader goal work.
- Rounded control/typography calibration across more device widths, Dynamic Type, all locales and long companion names remains. This pass verifies representative English/light and Arabic/dark journeys, not every rendering combination.
