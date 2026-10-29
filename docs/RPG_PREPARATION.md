# Authored game preparation and speech

Native authored chapters now use the original `legacyScenario.js` preparation prompt, loose JSON parser, validator, script guards, cache schema/key and beat application. `scripts/export-rpg-preparation.mjs` executes those source blocks read-only and bundles their pure policy for JavaScriptCore. Swift still owns navigation, SpriteKit, dialogue UI, networking, persistence and rewards.

The prompt retains the exact chapter title, bounded review terms, structured lessons/objectives, NPC roster, CEFR level, target/support language requirements and seven-beat story contract. Valid preparation has exactly two or three speech beats, the original three-choice checks and double-weighted finale. Authored episodes keep their prepared choices; the source explicitly skips dynamic choice generation for them. Provider errors, invalid story structure and wrong-script output keep the original local deck, including reviews with fewer than seven tasks. A valid seven-task story is distinct from inventing filler tasks for an offline fallback.

Speech requests use the original in-character micro-goal grading/reply prompt with the current assigned NPC, personality, spoken line, example, story premise and last ten committed dialogue entries. The original loose JSON parser accepts fenced/prefixed results and validates the full/partial/miss reply. Failed grading uses the original local matcher and continues nonempty roleplay. The existing Firebase/Nostr/App Check authenticated Cloudflare route, fixed native JSON output profiles and worker bounds remain in use. This correction needs no backend deployment.

## Cache, ownership and saved work

Prepared content is cached under the source `v5-lang-guard` unit/target/level/episode key, additionally scoped to the native account and support language. This prevents a different learner or Latin-script support language from borrowing the previous narration. Files live in the app cache and may be evicted by iOS; cache failures are nonblocking. Cache restoration revalidates content with the original rules before applying it to the authored scenario. Invalid output is not cached and can recover on the next preparation.

An unfinished saved run takes precedence over preparation, preserving its cast, position, score and task. Reopening a claimed run creates a fresh practice run using cached content where available. The old claimed recap is hidden during that transition. A recap already owned by the current presentation remains available across the trial boundary until its completion owner closes it. Content reuse does not create a second lesson reward; the existing canonical completion receipt remains authoritative.

Identical pending preparations share one request. A new account, target/support language, level, cancellation or withdrawn access rejects old results before caching or saving a run. A failed language-library load clears the old library rather than presenting its content under a new target language.

Closing dialogue cancels its pending speech turn, and a reply token separately prevents late narration. Reopening can grade once without the discarded reply changing points, dialogue or the new request's state. Run/account/access changes fence delayed grading as well.

## Scene captions

The original support-language story caption now appears above the NPC's spoken line with the source small italic/muted treatment and support-language direction. Choice reply captions follow the reply, survive saved-run restoration and clear on the next task. The optional saved field remains compatible with older runs. Spoken narration continues to use the direct dialogue rather than the caption. The dialogue uses the original 100-point portrait header, the matching original character portrait pool and source capsule choice buttons. Shadows apply to button shapes so labels do not acquire a second offset image. The offline provider fixture no longer bypasses the real native paywall.

## Verification boundaries

The complete Core suite passes 318 tests (244.047 seconds). The focused preparation selection passes all three checks after adding caption persistence assertions. The exporter executes 360 original request, response, cache and speech cases; all seven generated policy/fixture/manifest files reproduce byte for byte. These include bounded curriculum inputs, language/level variants, malformed/fenced responses, original JavaScript normalization and wrong-script rejection.

Native ownership/cache checks exercise real `RPGService` state and disk cache with controlled provider completions. Product tests use the actual landing, onboarding, course, native map/dialogue, saved profile and lesson receipt with explicit isolated provider fixtures. Source comparisons mount the original `GameRouter` and renderer; only public prepared responses and disabled external I/O are supplied. Source/native captions are compared in English/light and Arabic/dark, including the first prompt and its reply. Cast names and portraits may differ naturally.

The first prepared product run reached its recap and 30-XP reward but checked replay status while the old recap was still visible. Inspection found the seven-task content intact on disk and restored in learner state. The transition now hides claimed recaps, and the test explicitly waits for the fresh run's status. `PiyaliRPGPreparationFinal.xcresult` then passes both complete journeys: the three-task fallback in 205.349 seconds and seven-task preparation in 319.002 seconds. The final layout/real-paywall run, `PiyaliRPGPreparationPaint.xcresult`, passes all 15 selected checks, including nine ownership/cache checks, three access checks, four source/native prepared states, the earned-recap presentation test and the complete seven-task journey again (324.811 seconds). An isolated live Firebase/App Check/Cloudflare check passes actual chapter preparation plus full and wrong-language roleplay grading in 29.580 seconds; its Auth identity is removed afterward, with no learner-progress writes or relay publication. Final run evidence is recorded in [VALIDATION.md](VALIDATION.md).

The [course preparation map](GAME_PREPARATION.md), [introduction/Tutor handoffs](GAME_HANDOFFS.md), and [progressive dialogue/aligned translations](RPG_DIALOGUE.md) have separate verification.

Remaining work includes the legacy exploration/generation/search flow, broader transient dialogue/history recovery, game sound effects, wider device/locale layouts and physical microphone/playback checks. This is one correction within the active [product parity audit](PARITY_AUDIT.md).

Source/native examples: [prompt in English](native/rpg-prepared-prompt-en.png), [reply in English](native/rpg-prepared-reply-en.png), [prompt with Arabic support](native/rpg-prepared-prompt-ar.png), [reply with Arabic support](native/rpg-prepared-reply-ar.png). Product evidence: [speech cancellation](native/rpg-prepared-cancellation-product.png), [restored task](native/rpg-prepared-restored-product.png), [recap](native/rpg-prepared-recap-product.png) and [cached replay](native/rpg-prepared-cached-replay-product.png).

Completion-time next-review warming and shared foreground requests now have a separate [checkpoint](UPCOMING_GAME_REVIEWS.md). Its source selection and cache/product evidence do not close the other boundaries above.
