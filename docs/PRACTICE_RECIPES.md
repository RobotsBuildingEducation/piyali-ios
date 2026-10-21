# Original exercise instructions, native interactions

The old native `ExerciseView` collapses vocabulary/grammar into one generic question. The correction is in progress. The new recipe engine is groundwork; it is not yet a replacement exercise screen or evidence that exercise parity is complete.

`scripts/export-practice-recipes.mjs` reads the reference’s actual grammar, vocabulary and lesson-flashcard generation/grading builders. It follows their lexical dependencies and emits only the required pure policies into a bundled JavaScript asset. A manifest records the original file hashes and selected bindings. React screens, web audio, network calls, storage and reward effects are excluded. Three explicit adapters supply native read-only progress, original language-name strings and omitted flag renderers.

Swift uses the system JavaScriptCore interpreter for these bundled instruction builders, passing JSON data through a typed boundary. The UI, question state, grading/reward orchestration, audio and persistence remain native Swift. The engine has no native host functions and receives no private keys, authentication tokens or device APIs. The per-call progress adapter resets on every invocation.

Keeping the authored instructions avoids inventing a different lesson generator while the native interactions are ported. The export includes fill, single/multiple choice, speaking, matching, translation/word-bank, repeat and lesson flashcards, plus their original judge prompts. It also includes all nine Delight policies, normalization, readiness, grading/XP helpers and the original prepared-question selector. Native question parsing, controls, provider orchestration, rewards, help, completion and lifecycle still need integration and verification.

136 reference output fixtures cover both modules, eight standard formats, nine Delight variants, four language/level pairs and bilingual instructions. Comparing them in JavaScriptCore validates the interpreter boundary; it does not validate AI output or a complete learning journey. Additional checks cover the quiz deck's 16 unique formats without flashcards, repeat/listening directions, non-binary model-judged responses and distinct clue/quiz rewards.

An optional numeric `randomSeed` makes the source builders' blank/choice-count variations reproducible across export, iOS and resumed preparation. It temporarily supplies a deterministic uniform generator and restores `Math.random` after the call. Unseeded calls retain the original randomness.
