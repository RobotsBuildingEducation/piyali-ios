# Native authored adventures

The main Adventure practice mode and curriculum Game Reviews now open a SwiftUI RPG with the reference app's authored episode content, seeded map geometry, NPCs and seven-task story structure. Simple native controls provide map movement, walking to characters, choice tasks, spoken or typed roleplay, character audio and a recap. Visual assets and animations remain deferred.

## Content and play

The read-only export executes the actual reference `manifests.js`, `profile.js`, `legacyScenario.js`, chapter review context and speech matcher. It includes all 12 episodes at seven CEFR levels, 14 target languages and ten support languages: 11,760 free episode variants and 1,246 distinct unit reviews with localized variants. Map geometry is deduplicated inside each compressed language resource. The chapter's actual lessons, objectives and word pool constrain unit stories; a market setting does not introduce unrelated food vocabulary.

The reference dealer produces fewer than seven tasks in 45 reviews when the chapter's strict card pool runs out. The native exporter fills the missing beat IDs with existing tasks from that same chapter and retains a double-weighted finale. Existing answers remain intact. This is a deliberate native fallback repair; the reference files are unchanged.

Local authored play works without a subscription or network. Subscribers can request a connected story through the authenticated Cloudflare Responses service. The native validator requires seven tasks, exactly two or three speech invitations, three valid options per choice, nonempty dialogue/examples and the reference script guards. The worker supplies fixed strict `rpg_story`/`rpg_speech` JSON schemas and honors bounded reasoning settings for the configured model. The client selects the completed answer and rejects incomplete/refused responses instead of concatenating separate JSON messages. Invalid or unavailable generation falls back to the bundled episode. Spoken character lines are separated from stage directions before playback.

Choice scoring is 100, 50 or 25 points according to retries. Three wrong choices reveal the answer and advance with zero points. Spoken roleplay always advances after a nonempty reply: full/partial/miss gives 100/50/25 points. Online grading reacts to meaning rather than requiring a verbatim example; offline phrase matching uses the web thresholds and normalization rules. Text transcripts do not support precise pronunciation judgments. The finale doubles its points. Continue explicitly advances each resolved task.

## Completion and private state

Scores range from 0 to 800. Three stars require 720 points and two require 560. The 30 XP unit reward scales to 15/22/30 XP at one/two/three stars. Free episodes grant no lesson XP. RPG points do not change the global performance Score. The recap completes the ordinary curriculum lesson once, records the score/stars/episode and queues the shared lesson transaction. Generic lesson controls cannot bypass the game recap.

Firebase atomically claims the existing stable lesson receipt. Concurrent native completions with different scores retain the first completion reward and game result; retries add no XP, lesson count or extra achievement proof. Protected subscription fields survive the write. The existing lesson completion proof feeds ordinary curriculum achievements and daily practice.

Per-language saved runs retain map position, task, retries, score, misses and the latest 14 dialogue lines. At most three language drafts are retained. Local persistence restores a run after termination; `iosStateJSON` snapshots restore it across native devices. Simultaneous draft edits use last writer wins, independently of transaction-protected rewards. Saving dialogue creates a private note. Neither drafts nor notes are automatically published to Nostr. Account/language/session fences reject stale generated results, and navigation or backgrounding stops speech capture/playback.

## Verification and scope

Core checks compare 42 scoring cases, 182 speech matches, 15 prepared story cases and ten dialogue splits against executed web helpers. Content checks validate all free variants and unit reviews, seven tasks, eight score weights, valid NPC assignments, single correct answers, examples and reachable NPC map positions. Additional tests cover retries, speech idempotence, collision/pathfinding, persistence, language isolation and once-only recap XP.

The simulator play test passed with the actual bundled first Spanish unit review, no model stub or subscription grant, three wrong choices, spoken replies, restarts and a single 22 XP reward. A separate Firestore SDK emulator contract passed concurrent scores, restored drafts and repeated completion. The opt-in live check passed a chapter-grounded story and full/wrong-language NPC replies with an isolated native identity, deletes its temporary authentication account and writes no production learner progress.

Run `swift test`, `scripts/test-firestore.sh`, `scripts/test-ios.sh -only-testing:PiyaliUITests/RPGPlayTests`, or `python3 scripts/test-live-api.py --only rpg`. Refresh resources and fixtures with `node scripts/export-rpg-content.mjs /absolute/path/to/reference/nosabos`; `--fixtures-only` refreshes source comparisons and the UI play fixture from existing exported content.

This ports the authored episode route used by curriculum Game Reviews. The separate legacy scenario engine's room travel, inventory, object-search and portal gameplay is now connected through Explore connected rooms; see [EXPLORATION.md](EXPLORATION.md). Graphics, physical-device speech quality checks and paid-member verification remain outside the verified simulator boundaries.

Provider format and reasoning support follow [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs), [GPT-6 Luna](https://developers.openai.com/api/docs/models/gpt-6-luna) and the [completed-answer phase documentation](https://developers.openai.com/api/docs/guides/reasoning#phase-parameter). The worker retains its model/prompt/output allowlists, 40-second deadline, authentication and rate limits.

Verified native worker deployment: `d4694eb2-8d76-4c7c-b2d0-818499d6e679` (2026-10-13). All 91 core tests, 49 native SDK checks (29 scoped skips), the RPG simulator play test and 12 backend checks passed.
