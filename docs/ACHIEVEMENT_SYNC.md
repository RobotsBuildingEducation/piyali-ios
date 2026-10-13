# Main-product achievements

The bundled catalog contains 75 Piyali IDs: 72 progression achievements and three legacy tutor-level awards. Titles/descriptions retain the reference locales, and saved awards use catalog version 8 and the permanent number/orb metadata.

`AchievementProgress` ports the reference's completion rules. Completing a higher proficiency level proves earlier levels in that same track; placement and practice Score do not prove completion. Course counts use one language at a time. Successful flashcard exercises count once per card/language, while full flashcard-course completion requires SRS graduation. Goals require every assigned mode; repairs require the committed activity threshold and saved repair items. Authored phonics decks require success for every card.

Private Firebase records use the web schema:

- `users/{npub}/achievements/{id}` stores the permanent award, original positive unlock timestamp and metadata. A real award replaces a preview; replay preserves an existing real award.
- `users/{npub}/achievementProgress/nosabos/events/{hash}` stores `source`, `metric`, `completionId`, `version`. The hash is SHA-256 of JavaScript's JSON-encoded `[metric, completionId]` tuple, including Unicode and literal slashes. Stable event IDs deduplicate retries and other devices.
- `users/{npub}/achievementMigrations/nosabos_v1` marks history catch-up complete only after all proof and award writes succeed.
- `users/{npub}/alphabetPractice/{language_card}` stores native pronunciation successes. The existing practice receipt prevents duplicate XP and duplicate correct-count writes.

The first catch-up reads saved course/card/phonics/quest documents and legacy profile maps. Compact summaries retain concurrent counts through a transaction. Normal sync reads compact summaries and changed card/phonics records; it does not repeat the full historical scan. Confirmed award/ledger listeners retain received records, and incoming awards update the native collection. Source cache entries are scoped by Firebase app and npub. Achievements never grant subscription access or additional XP.

The independent Firebase project is `piyali-ios`. Matching the web's record format does not connect it to the original web Firebase project. These records restore across native devices using the same key/project. Signed Nostr collection restoration/publication connects to the same relay format used by both hosts; see [NOSTR_ACHIEVEMENTS.md](NOSTR_ACHIEVEMENTS.md).

The current native reflection flow does not yet produce the web's full `realWorldTasks` checklist. Historical checklist proofs are reconciled. Explicit native conversation-goal completion also remains to be ported; conversation milestones retain existing distinct completed-goal events.

Verification covers 576 rule comparisons against the actual reference source, 63 card cases, goal/repair/immersion and phonics proofs, ledger union, Unicode/slash document hashes, timestamp preservation, preview replacement, earlier-level awards, native phonics, concurrent card writes and idempotent catch-up. Production rules restrict these private records to the authenticated Nostr owner and reject other achievement-progress source namespaces.
