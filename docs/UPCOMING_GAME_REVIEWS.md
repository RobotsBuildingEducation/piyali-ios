# Completion-time Game Review warming

The web app calls `warmUpcomingGameReview` after an accepted ordinary lesson completion. It resolves that lesson's source level, finds its containing unit and prepares a story only when the immediately following lesson is a Game Review. Native previously waited until the review preview was started. It now starts that optional content work after the corresponding accepted local completion, while the ordinary lesson acknowledgment/path remains visible. It does not select a game, move a learner, advance a task or award review XP.

## Source rule and native ownership

`scripts/export-upcoming-game-review.mjs` extracts the actual `App.jsx` completion predicate and lookup through `unit.lessons[lessonIndex + 1]`, with the original CEFR inference helper. Async curriculum loading is the only lookup replaced by supplied units. The Swift bridge supplies the identities, type flags and authored game level read by that selector. Native normalized catalog type flags are restored from the existing mode/tutorial representation. Full review context still comes from the already exported original RPG review library and preparation policy.

The exporter executes all 8,750 original lessons across fourteen content languages. Exactly 1,204 are eligible: 126 Pre-A1, 196 A1, 252 A2, 210 B1, 168 B2, 140 C1 and 112 C2. All source cases are checked against native curriculum data, including the fourteen introductions in the separate `IntroLibrary`. The introduction, Game Review, goal and repair completion paths do not start this ordinary-lesson warmer. It does not scan later lessons/units or warm on restoring an already completed lesson.

`AppModel.complete` starts the silent controller only after the existing completion accepts a new receipt. The controller uses `RPGService` with `stageOnly: true`; its temporary run is discarded. The shared `RPGPreparationPool` stores validated original story content under the existing account/source-key/support cache identity. A foreground preview can join the same pending request, or reuse the completed story after process restart. Each consumer owns a separate lease. Cancelling one consumer keeps work needed by another; cancelling all removes that request's authority. A late abandoned response cannot write progress or overwrite a same-key retry.

Account, target/support language, course level, access and application activity scope the warm. Sign-out/account activation and backgrounding cancel it. Entitlement withdrawal is checked after the provider returns as well as before handoff. Cache failure, provider failure and malformed/wrong-script content retain the original complete authored local deck. Saved unfinished games remain authoritative. The source 5–8 second playable exploration window and explicit handoff still run even when story content is already cached.

This is client-side content warming. Firebase/Cloudflare APIs and the existing `rpg_story` output profile are unchanged; no backend deployment, identity migration or new cache service was added. The reference repository remains read-only.

## Verification and retained failed attempts

The final core selection passes all 8,750 original cases, including the 1,204 eligible transitions, in **32.125 seconds**. The initial core attempt failed to find an introduction in the ordinary catalog; the test now reads its existing separate export. A second attempt ended with process status 1 without a completed test result while it repeatedly serialized full curriculum payloads. It is not passing evidence. The bridge now projects only fields actually used by the source selector, and each fixture iteration releases temporary bridged objects before the next case. The passing result is the third run.

`PiyaliUpcoming1.xcresult` failed compilation because a default argument tried to create a MainActor policy outside the actor; initialization was moved inside the controller. `PiyaliUpcoming2.xcresult` compiled production but failed a test assertion that compared non-Equatable practice receipts directly; that assertion now compares their full encoded JSON. Neither run is runtime verification.

`PiyaliUpcoming3.xcresult` passes all **23 selected app tests in 118.551s**, with no failures or skips:

- Six warming/pool checks (**51.117s**): actual quiz completion and a joined foreground request; finished-cache reuse after recreation and preserving an unfinished run; cancellation of either consumer and rejecting abandoned work; concurrent account/support isolation; same-key retry ownership; and target/support/level/sign-out/access/background invalidation.
- Eight existing preparation/handoff checks (**35.598s**) covering staging, cancellation, introductory prewarming/reveal/Skip, Tutor track ownership and saved/newer progress.
- Nine existing preparation/cache/speech checks (**31.836s**) covering malformed content, retries, language/account changes, quota withdrawal, saved replay and cancelled speech.

Its normal product journey also passes (**193.075s**): new account, onboarding, self-reported A1, beginner quiz, eight real typed answers, the +80 quiz acknowledgment, an unstarted review on the path, relaunch with the prepared-story provider disabled, a seven-beat cached review, Back and saved-run relaunch. No learner progress is prefilled. The cached-only fixture would return the three-task local deck if the completion-time warm had not persisted its valid story. All controller checks additionally keep canonical game/lesson/task/receipt/XP state unchanged by warming.

Visual review caught the last run-3 saved-game capture during presentation, with the underlying app header still visible. That image is not accepted as settled full-screen evidence. The journey now explicitly waits for the map's accessibility frame to span the complete phone display at both game entries; its follow-up result and replacement captures are recorded below.

## Limits

This adds no new visible controls or styles. The existing source/native loading-map and game-panel comparisons retain their original scope. The public provider fixtures establish request/cache ownership and a real product handoff; they do not establish live provider latency, physical-device background/network behavior or complete app parity. Wider interruptions, edge caching/prepared audio tickets, full prepared-game completion/celebration replay, ordinary Tutor viewport hosting, legacy generation/fallback routing, visual/motion calibration and physical audio/signing remain separate open work in `PARITY_AUDIT.md`.

The final `PiyaliUpcoming4.xcresult` repeats the full native journey with explicit whole-display checks at cached launch and saved resume, passing without failures or skips in **199.951s**. Visual inspection confirms that the game fills the display after the presentation transition; no production layout change was necessary. The six current product captures in `docs/reference/upcoming-review-product-captures.json` come only from this final run and have verified hashes. The executable app/service code is unchanged from the passing 23-check run 3; run 4 strengthens the UI test and replaces its timing-sensitive capture.
