# Games: functional and design correction in progress

Course Game Reviews now use the source pixel-art world and native map/dialogue controls. The previous gray-grid form and its invented seven-task fallback did not reproduce the product. This checkpoint replaces that renderer and routes course games directly into a full-screen game. Tutor and introductory games retain their separate completion contexts.

## Source content and rendering

`scripts/export-rpg-art.mjs` executes the original procedural ground, tile, object and companion drawers offline, and extracts the original player/NPC sheet frames. It covers all 443 map geometries referenced by the bundled episodes and introductions, all six pets, 46 NPC appearances, source pixel icons, the environment grade and the original music. The source uses 2D planes in an orthographic Three camera; the native scene uses SpriteKit with that coordinate model, camera scale, texture proportions and depth ordering. Time-dependent art uses a fixed seed in both the exporter and the read-only screenshot fixture. Source icon framebuffer color conversion is preserved.

The source fixture mounts the actual `GameRouter` and RPG component. Firebase, providers, speech and relay I/O are inert; UI/controller logic is original. Captures compare English/light and Arabic/dark world, quest, inventory and companion states at 402 × 874. Names and character appearances may differ because each run assigns a random cast. Component comparisons use a viewport without device chrome; the full product puts controls below the iPhone camera cutout while the map fills the display.

The read-only content export includes 14 target languages, seven levels, twelve episodes and ten support languages: 11,760 free episode variants and 1,246 chapter reviews. Every localized chapter deck is compared directly with the unmodified source dealer: 12,460 decks. The 45 reviews whose card pools produce fewer than seven tasks remain shorter. No tasks or double-weighted finale are appended. The first Spanish chapter review therefore has three tasks. The source keeps its 800-point scoring denominator even for short decks; native scoring follows it.

## Interaction and saved state

A tap moves one tile toward the destination, checking the primary axis and then the secondary axis. Solid tiles and NPC positions block movement. Tapping the current NPC opens dialogue when adjacent; a distant tap takes one step toward that NPC. Lesson games spawn at the nearest free center tile. 1,176 executed source movement/spawn cases protect these rules.

Short dialogue bubbles fit their content and longer dialogue scrolls within the source mobile height limit. The dialogue uses the original choices, retry points, three-miss reveal, explicit Continue, speech invitation/example and translation contract. Native speech has an optional typed response accessible from the microphone context menu, with Send and keyboard dismissal. Character narration uses the source voice/personality mapping through the existing receive-only narration service. Saved casts, positions, task indices, retries, score and dialogue remain scoped to the learner/language. Returning to unfinished work retains its cast and next task. A claimed game starts a fresh practice run when reopened.

The game-only companion picker has the source descriptions, two-column pet choices and per-language XP unlocks. Its preference is separate from the app-wide companion. Music starts off, loops the original track at volume 0.02, stops on exit/background, and synchronizes the source `rpgMusicEnabled` / `rpgMusicPreferenceVersion = 2` fields through canonical settings changes.

## Ambient object examination

Tapping an authored prop's exact tile opens its observation immediately, even from a distance, without movement, task credit or XP. One request preloads all props for the current area. The native controller shares pending work, caches original normalized replies and fallbacks, protects account/language/run changes from late responses, and starts the source 3.6-second dismissal only when loading finishes. Repeated taps reset that window. Descriptions use the original CEFR/Elo, chapter, map and language prompt through Cloudflare Responses. Generated content uses the target and support languages; the original offline fallback intentionally keeps the English object name/sentence and adds the support translation.

`scripts/export-rpg-objects.mjs` extracts the source prompt, fallback tables and reply resolver without loading source providers. Its 590 source-executed fixtures cover fallback localization, prompt levels, malformed/aliased replies, object keys and tile hits. Original map identities and environment summaries are retained even when episodes share geometry. The bottom card follows the source light/dark typography and Arabic support alignment; physical iPhone safe-area insets keep it above the home indicator. English and Arabic comparisons are in [rpg-object-en.png](native/rpg-object-en.png) and [rpg-object-ar.png](native/rpg-object-ar.png); the real map-touch journey is captured in [rpg-object-product.png](native/rpg-object-product.png).

Help now opens the shared source-style drawer and returns to the same map. Its text, saved chats, morpheme tool and separate voice session are documented in [HELP_CHAT.md](HELP_CHAT.md). The course journey verifies this handoff before continuing its tasks.

## Completion

Choice points are 100/50/25 on successive attempts, or zero after three misses. Speech gives 100/50/25 for full/partial/miss and advances after a nonempty reply. The finale, when present in the source deck, doubles its points. Scores select the original one/two/three-star reward scaling. Free episodes grant no course reward; introductory and Tutor games use their own completion owner.

Ordinary Game Review Continue claims the existing once-only lesson receipt, closes the game and displays the scaled lesson reward. Reopening completed work cannot award another lesson bonus. Firebase transactions retain the first completion result across concurrent claims and preserve subscription fields and unrelated progress. The first chapter journey deliberately misses its first task, so its two successful remaining tasks total 200/800 and yield the source 15-XP reward from a 30-XP lesson.

## Verification and remaining work

All 295 core tests pass, including raw source decks, name replacement, movement, retries, narration contracts, persistence and canonical preference rebasing. The current scoped simulator runs pass these checks: the eight source/native component pairs and complete texture catalog, the seven-task introductory game, the skip/relaunch/review introduction, and the three-task course review. Separate Firebase SDK checks pass concurrent recap claims and music preference retry, and the existing Tutor game-bonus regression passes. The current object checkpoint additionally passes four controller checks, two source/native observation comparisons in one test, and the complete physical-touch chapter journey with a distant prop examination. An isolated live backend check returns Spanish observations with Arabic names/translations without writing learner progress. Detailed durations and boundaries are in [VALIDATION.md](VALIDATION.md).

This is an ongoing parity correction. Ambient particles, moving NPCs, legacy object-search presentation, the full legacy exploration presentation, source AI prompt/choice preparation details, sentence-level progressive dialogue/translation, game sound effects, exact animation/color compositing and physical microphone/playback verification still need work. These are not established by the deck/helper checks or the initial eight component comparisons. Broader root-product surfaces remain tracked in [PARITY_AUDIT.md](PARITY_AUDIT.md).

No reference files or backend deployment were changed. The separate Piyali Firebase project and existing Cloudflare services remain in use.


Comparison examples: [world](native/rpg-world-en.png), [game companion](native/rpg-companion-en.png), [Arabic quest](native/rpg-quest-ar.png). Actual course flow: [dialogue](native/rpg-dialogue-product.png), [restored task](native/rpg-restored-product.png), [speech](native/rpg-speech-product.png), [recap](native/rpg-completion-product.png), [scaled lesson reward](native/rpg-reward-product.png).
