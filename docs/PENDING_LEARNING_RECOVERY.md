# Pending Memory and Tutor worth across process termination — 2026-11-06

Reference: read-only `RobotsBuildingEducation/nosabos` at **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `ca26049`. This advances pending-operation recovery in FUNC-03 and VERIFY-02. Overall functional/design parity remains **In progress**.

## Behavior and native lifecycle adaptation

The source persists a deterministic Memory note, then launches an enrichment promise. A completed failure leaves that note unenriched; opening an already localized note does not retry merely because the tip is blank. The preceding shared-Memory checkpoint preserves those rules. The in-memory promise itself does not survive a destroyed JavaScript runtime. Native termination recovery here is a lifecycle adaptation requested by the handoff, not a claim that the source persists the same job schema.

A fresh ordinary matching journey reproduced a native gap: terminating while the provider was held preserved the base note, but relaunch never completed its interrupted enrichment. The reproduction fails in **117.175 seconds**. Its read-only pending-state audit preserves one capture, assessment and repair-evidence event, no enrichment and zero XP. No notes or progress were seeded.

Native now writes an account-bound private enrichment intent before starting the provider request. It retains the frozen note version and full concept, including content beyond the display limit. Boot/content reload and sync resume that explicit unfinished request. Repeated resume calls coalesce. A later slip refreshes the source note timestamp and replaces an obsolete pending version; an old callback cannot overwrite it. Changing accounts cancels current tasks while retaining unfinished work in the original account's file. A new target selection does not redirect an existing request into another language bucket. Expired, replaced or already enriched notes retire obsolete work.

Both success and a completed failure retire the private request. Failure still leaves the source base note pending; neither repeated boot/sync nor an imported pending note without an intent invents an AI retry. A later qualifying slip may retry. Successful enrichment patches the latest matching note, preserving reinforcement, and queues one existing localization delivery. Capture learning evidence, XP and assessment are not replayed by enrichment recovery.

The private continuation is excluded from Firebase snapshots and ignored in remote-only server hints. A canonical acknowledgment retains the local unfinished job; a stale acknowledgment cannot resurrect a finished one. This does not promise exactly one remote model request after a process dies between a provider response and local persistence. A request may be repeated; note effects and learning/reward deliveries retain their separate idempotency boundaries.

Tutor question-worth delivery already has a private intent. A separate actual-termination journey passes its baseline in **53.508 seconds**, preserving lesson/day progress and recovering one account award/assessment without reconnecting Tutor or restoring private chat. Its settled QA counters show one 3-XP turn, one assessment and no duplicate reward. The final pending/settled audits below independently verify this transition again.

## Verification

The corrected Core run passes **39 affected checks in 0.972 seconds**: Memory/source-policy/sync, Tutor outcome and Goal capture contracts, including new full-context private restoration, stale acknowledgment, replacement-version and legacy schema cases. All 411 existing Memory source cases remain in that policy suite.

The final `/tmp/PiyaliPendingLearningVerified20261106.xcresult` passes **41 tests, zero failures or skips**: 38 app/source/SDK checks in 148.397 seconds and three complete native UI journeys in 213.982 seconds. This includes nine real local Firebase SDK contracts and English/light plus Arabic/dark comparisons against original source capture/enrichment/learning evidence and actual NotesDrawer components. The original single/repeated Tutor source comparisons and existing quote/owner/bonus boundaries also pass.

The complete native journeys create fresh accounts through normal entry/navigation; they seed no Memory or progress. Only the external provider response is held before termination. Each journey then relaunches twice:

| Journey | Time | Verified pending → settled counters |
| --- | --- | --- |
| Ordinary course matching miss → Skip → Memory | 104.351 s | Same note ID; one pending request becomes zero; one enrichment; capture/assessment/repair evidence remain one each; account/day XP remain zero. |
| Tutor low-confidence semantic slip → End → Memory | 54.705 s | Same note ID; one pending request becomes zero; one capture/enrichment; zero XP, assessments or repair-evidence events. |
| Earned late Tutor turn with original worth pending | 54.926 s | Lesson/day XP are four before termination while account XP/assessment are zero; restore delivers four account XP, one turn receipt and one assessment; no pending worth, bonus or Memory remains. |

Six read-only phase audits capture the actual private-file counters before termination and after the final relaunch; a cross-phase check verifies the stable Memory IDs and unchanged earned Tutor amount. These are queued local receipts in the offline product journeys, complemented by the separate real Firebase SDK contracts. The new SDK case retains the full 241-character concept after a canonical capture acknowledgment, excludes the private intent from server hints, rejects an injected hint-only continuation, retains the local intent and persists one localization after stale/repeated saves.

The earlier eight targeted app/SDK checks pass in 28.103 seconds. Retained diagnostics include the failing Memory UI reproduction, an internal delivery-signature build failure and new Core fixtures initially using an expired date/incorrect first-version assumption. The source refreshes a duplicate's `createdAt`; the corrected fixture and worker retain that behavior rather than forcing an obsolete request to remain current. A baseline pending-worth audit initially expected two turns from distinct late phrases; the source credits one question turn, and the final audits check one. Failed attempts remain labeled as such.

I inspected the final source/native pairs and six full native pending/restored frames. Original content and ordering remain aligned; small vertical spacing, glyph and shadow differences, surrounding-shell geometry, orb rendering and accessibility retain their broader design gates. This checkpoint adds lifecycle recovery without a new presentation replacement.

- [English/light — source left, native right](native/pending-learning-b269524d/pair-enriched-en.png)
- [Arabic/dark — source left, native right](native/pending-learning-b269524d/pair-enriched-ar.png)
- [Full native pending/restored journeys](native/pending-learning-b269524d/native-pending-restored-contact.png)

[The evidence manifest](native/pending-learning-b269524d/manifest.json) hashes **42 artifacts** and records screenshot/trace provenance, original source and final native hashes, all six phase audits, passing/failed summaries, exact commands and byte-stable 411-case regeneration.

## Scope and remaining work

Only external provider responses and voice protocol I/O are delayed through explicit DEBUG/offline/valid-UUID QA gates. Product signup, navigation, capture, private writes, termination, restoration and receipt paths remain the real native implementation. Provider-response fixtures do not prove live AI quality, physical speech or full authenticated browser routing. Source/native drawers are rechecked separately against original callbacks/components; complete surrounding shells and accessibility retain their broader gates.

Dependent focused Tutor completion restoration, wider concurrency/day changes, source connection fallback and partial audio capture, whole-shell motion/keyboard/RTL/accessibility, physical-device and service/payment/release requirements remain open. No reference edit, Firebase/Cloudflare deployment, merge, App Store publication or overall-completion claim is included.
