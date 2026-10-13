# Native conversation goals

The main Conversation practice mode, daily plate conversation activity and Tutor library open a native text/voice conversation. This ports the main web `Conversations.jsx` behavior, `conversationProgress.js` completion proof and quoted `performanceEloModel.js` Score contract. The reference checkout is read-only.

## Practice

Each session has a concise localized goal, conversation history and separate turn/goal/XP counters. The initial goal uses curriculum and personal interests; subsequent goals align with the tutor's pending question. Foundation goals require one small conversational move, typically a 3–8 word utterance. The actual web fallback catalog supplies 35 localized goals across seven CEFR levels when generation fails.

The grader compares the learner reply with the tutor line it answered, accepts imperfect target-language communication and distinguishes an unsuccessful attempt from a legitimate rejection of the goal's premise. A weak attempt receives guidance; two misses replace the goal. A rejected premise immediately redirects the conversation without a Score penalty. A completed goal advances the conversation. Replies shorter than three characters and unavailable grading count as neutral practice.

Learners can choose challenge level, interests, tutor personality and pronunciation coaching; reveal a foundation starter; translate or listen to messages; dictate replies; or use continuous Gemini Live audio. Pronunciation prompts require audio evidence. Starter reveals and translations grant no XP. New conversation resets session counters/history while preserving settings. Transcript saving creates a private note.

## Rewards and synchronization

Every actual learner turn counts once toward daily conversation activity, including misses. A successful or neutral turn earns 1–3 XP; a missed or rejected goal earns zero turn XP. Each newly completed goal earns a separate 2–4 XP bonus and one quoted Score result. Goal IDs include the target language and a persisted UUID. Repeated callbacks and retries cannot repeat the same turn reward.

Firestore transactions atomically claim the permanent native goal receipt, record the private `conversation_goals` achievement event, apply the quoted Score result and add XP/calendar activity. Concurrent devices can record distinct learner turns while only one claims a goal bonus and achievement. The bonus does not add another quest turn. Existing entitlements and unrelated web fields survive the transaction. Goal misses update the web Score summary, but do not enter companion memory; premise rejection does not change Score.

Private drafts are saved per language in `iosStateJSON`, retain at most 40 messages and are bounded to 24 KB as UTF-8 JSON. Drafts/settings use the existing native snapshot synchronization; concurrent message editing is last writer wins. Immutable reward/proof receipts synchronize independently. Drafts and transcripts are never published to Nostr.

Live audio maintains the previously spoken tutor line independently of the newly generated reply. Updated goals and guidance are sent as private `APP_CONTEXT_UPDATE` context with `turnComplete:false`; they do not create a learner turn or trigger an extra reply. Account, language and session fences reject delayed results after navigation or account changes. Leaving, backgrounding or losing subscription access stops microphone capture.

## Verification

The core fixtures export 42 quoted-worth cases and 84 complete graded Score buckets from the real web source. Tests compare rating changes, level counts, weak concepts, recent results and event idempotence. Additional cases verify distinct turn/goal XP, misses versus premise rejection, neutral turns, stable IDs, in-flight acknowledgment, language isolation, bounded drafts and correct voice turn context.

Real Firestore SDK emulator tests exercise concurrent completion and retries, restored drafts, daily turn counts, Score updates, protected subscription preservation and misses versus premise rejection. Simulator UI verification covers starter reveal, a failed reply, successful completion, the next goal and relaunch without duplicated XP. Its stub requires a debug build, both explicit offline/conversation fixture flags and a valid isolated UUID; it never creates an entitlement and is disabled in release builds.

The opt-in live check signs in with an isolated native Nostr identity, exercises correct/wrong-language grading, premise rejection, starter, translation, reply and contextual goal generation, then requests real Gemini Live PCM output after a private context update. It deletes its temporary authentication account and performs no production progress write. Run `python3 scripts/test-live-api.py --only conversation` with the ignored local Firebase configuration and registered App Check debug token. Simulator output confirms the service protocol, not physical-device microphone quality.

Refresh exported source fixtures with `node scripts/export-conversation-fixtures.mjs /absolute/path/to/reference/nosabos`.
