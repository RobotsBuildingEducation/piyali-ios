# Original RPG dialogue and translations

The game now reserves the complete spoken prompt's layout while characters fade into view, then renders translations beside their matching sentences and choices. The previous native whole-paragraph translation lost those relationships. Choices remain immediately usable, as in the main web product.

`scripts/export-rpg-dialogue.mjs` reads the reference checkout without modifying it. It extracts the main component's sentence splitter, active caption/prompt/reply declarations, translation selectors, assigned-character roster, prompt, initial arrays and streamed line application. The bundled JavaScriptCore policy is pure; rendering, timers, accessibility and provider calls are native. The original asynchronous translation toggle also runs against inert provider chunks to produce seven trace fixtures; that test harness is omitted from the production bundle. Source hashes and adapters are recorded in `reference/rpg-dialogue-manifest.json`.

The original splitter has unusual punctuation behavior. For example, `¡Hola! ¿Cómo te llamas?` produces `Hola!`, `Cómo te llamas?` and a trailing `as?` fragment. This port retains the executed source behavior and covers it explicitly, rather than silently changing the web contract. Reply subtext follows the original caption selection; translated mode hides that caption and pairs the original spoken lines with their support-language translations.

Translation allocates the original empty line/choice arrays immediately. Stream chunks accumulate until a newline; blank lines and numbering prefixes are stripped, extra lines are ignored, and the final unterminated line is flushed. Completed lines appear independently while pending lines stay empty. Undo clears temporary translations and restores the original prompt/reveal. A provider error clears partial translations. Gemini streaming is preferred when Firebase is configured; a single Responses result is used only when Firebase is unavailable. A failed Gemini request does not silently switch providers.

Native cancellation additionally fences delayed callbacks after closing, changing a node/run/account/language, losing access or leaving the scene. Temporary translations never change attempts, task count, score, XP or the saved run. Reopening restores original content. The existing real access gate is used in both product and tests.

`RPGDialogueLabel` preserves full text for VoiceOver and stable layout. It uses the source 18 ms UTF-16 schedule and 120 ms CSS ease-in opacity curve, while keeping composed graphemes together to avoid torn emoji. Reduced Motion reveals all text immediately. Its display link stops on detach. Support text aligns to its language while the first strong character determines each paragraph direction, matching the source `unicode-bidi: plaintext` behavior. Arabic fallback glyphs stay upright while Latin glyphs retain synthesized italics. Translated choices inherit the source semibold treatment. Latin text uses a synthesized italic face when the bundled DM Sans font has none. Undo uses the original web icon.

## Evidence

- All 320 Core tests pass. The final scoped dialogue rerun also passes both tests, covering 303 original policy cases, seven original async traces and character timing boundaries.
- Five native controller/label checks cover exact trace snapshots, partial/final delivery, Undo, failure/retry, unchanged configuration, delayed callbacks, lost ownership, stable accessible layout and timer shutdown.
- The source/native harness mounts the actual web GameRouter/RPG component, adapting only provider I/O. It compares complete, undone, partial and failed translations at 402 × 874 in English/light and Arabic/dark. Captures are under `native/rpg-dialogue-{state}-{language}.png`.
- The complete original three-task chapter regression still passes, including retries, speech, relaunch, recap and the once-only scaled lesson reward.
- All six exported resources/fixtures/manifests/icons reproduce byte for byte in an isolated output directory.

The live Firebase/App Check translation invocation passes in 5.153 seconds with two Arabic sentence slots and three choice slots filled. It uses a fresh scoped key and removes its Auth identity; it writes no learner progress, awards or relay events. This single invocation does not establish output quality for every language.

The final eight-test simulator selection includes the complete translation/Undo/close/reopen/relaunch journey (107.870 seconds) and eight source/native states (35.352 seconds), with no failures or skips. The final direction/fallback-font correction passes all six source-comparison/controller checks again; its eight paired states take 35.676 seconds. Paired captures use that final run, while product captures use the preceding complete journey.

The final simulator and live-provider results are recorded in [VALIDATION.md](VALIDATION.md). Comparison images establish the covered states, not exact platform-wide typography or motion parity. Wider layouts, reply/legacy action translation presentations, full legacy search/exploration and generation/handoff, game sound effects, physical audio/VoiceOver and broader interruption permutations remain open.
