# Shared Memory duplicate capture — 2026-11-05

Reference: read-only `RobotsBuildingEducation/nosabos` at **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `c87aab4`. This advances FUNC-03 and shared Memory behavior; the full parity objective remains **In progress**.

## Behavior corrected

The original `captureCompanionMemory` strengthens an existing same-day/source-mode/concept note. It retains its ID, original expected answer, correction, CEFR/context and lifecycle; replaces the submitted answer only when the new answer is nonempty; refreshes the localized companion summary; and caps severity at three. A support-language change clears old mistake/tip/enriched fields until enrichment. Duplicate updates retain the note's array position; a new concept is inserted at the front.

Native previously replaced both correction fields with the second capture, erased the previous answer on an empty response, retained an English summary after changing support language and sorted a repeated note to the front. The new one-test reproduction failed **four assertions in 0.188 seconds**. The shared reducer now follows the source fields and ordering, retaining reinforcement and foreign web data. Language aliases, English-parenthetical cleanup and summary templates follow the original source rules. The summary templates, support codes and cleanup tokens are generated from the read-only source into `CompanionMemory.swift`.

The untruncated cleaned concept is retained in the private capture event. The source matches against that full value even though its displayed note concept is capped at 240 characters. The metadata survives private serialization, old events without it still decode, and Tutor enrichment receives the full concept. Existing stale-date protection remains: an older cross-device event can strengthen severity without replacing a newer answer. Existing expiry pruning also remains; those concurrency/pruning safeguards are not a claim of identical unconditional web bucket writes.

The Arabic repeated-count badge now carries an RTL mark so its visible numeral/multiplication order matches the actual source. The final English and Arabic pairs were inspected. Small vertical/text, glyph and shadow differences remain; complete-shell/accessibility design is still open.

## Source and runtime verification

The exporter preserves the original pre-persistence capture block with an explicit note-bucket snapshot. Before exporting each new fixture, it independently executes the **complete original asynchronous callback** with public store/persistence/evidence/enrichment I/O adapters. The **203 added cases** cover same/changed/aliased support languages, severity, empty/new answers, source mode, reinforcement, unrelated note ordering, concept cleaning, empty concepts, new-day separation and long concepts. Memory now has **267 source cases**, with all **64 previous cases unchanged**. The native reducer is compared against those 203 complete-function results, including whole note arrays.

The final Core run passes **23 tests in 0.780 seconds**, including Memory, original-source comparisons, full-concept/legacy decoding, Goal diversion and sync contracts. Exporting unchanged source data is byte-stable and no longer touches the generated Swift file's modification time. Because `export-memory.mjs` can regenerate Swift, run it only when Swift builds/tests are terminal.

`/tmp/PiyaliMemoryDuplicateVerified20261105.xcresult` passes **24 checks, zero failures or skips**: 22 app/source/SDK checks in 113.171 seconds and two complete native UI journeys in 105.762 seconds. The six real local Firebase SDK checks cover repeated/stale writes, first-correction retention, array order, foreign timestamps, reinforcement, changed support language, stale enrichment, two clients and unchanged XP. Native checks also retain ordinary provider gates, semantic/late capture, owner/request fences, drawer refresh and full-concept enrichment.

The two UI journeys create fresh accounts through normal entry/setup/menu, capture one or two Tutor slips, open enriched Memory after End and restore it after actual process termination. The repeated journey changes the second provider correction to `Buen día`; the visible and restored note retains `Hola`, the second answer, severity two and its first enrichment. Read-only QA audits find one note, one enrichment and exactly one/two capture receipts, with zero XP, assessments, bonus receipts or pending Tutor outcomes.

A later presentation-only change corrected the Arabic badge. `/tmp/PiyaliMemoryDuplicateRTL20261105.xcresult` then passes the two-language repeated-capture/render comparison in **20.744 seconds** on that final presentation. English UI behavior is unchanged. No Swift production/test or fixture content changes follow that final visual run.

The first integrated run retained a failed SDK assertion: a timestamp created from fractional `Date()` nanoseconds was rounded by Firestore by 120 ns. The duplicate/order/lifecycle assertions, original source/native comparison (24.154 seconds) and repeated UI journey (56.246 seconds) passed in that batch. The fixture now uses an exactly representable public timestamp; the later six-contract SDK batch passes. An intermediate Core run also exposed the old fixture-count assertion and an obsolete expectation that new-language judge feedback was already-enriched text; the original callback cases establish the corrected expectations. Failed/partial runs are retained as such.

[The hashed evidence manifest](native/memory-duplicate-b269524d/manifest.json) includes final component pairs/traces, two complete native repeated-journey frames, both QA audits, exact commands, source-case audit, Core results and passing/failed result summaries.

- [English/light, source left and native right](native/memory-duplicate-b269524d/pair-repeated-en.png)
- [Arabic/dark after the RTL correction](native/memory-duplicate-b269524d/pair-repeated-ar.png)
- [Same enriched note after native process relaunch](native/memory-duplicate-b269524d/native-product-relaunch.png)

## Scope and remaining work

The browser comparison invokes the actual original capture callback twice, patches the original user store through a local persistence adapter and renders the actual `NotesDrawer`. It starts with empty Memory. It does not execute source Firebase, learning-evidence storage or enrichment network requests. The native comparison uses two ordinary Tutor inputs through its real controller. Captured times are aligned for equivalent records; independently generated IDs are checked for stability within each app. This is stronger capture/drawer evidence than a prefilled row, but does not establish the full authenticated web route or physical speech.

The capture comparison deliberately holds enrichment empty. Its trace retains native notes before and after opening the drawer: the existing native blank-tip fallback can mark a pending note enriched after an empty response, unlike the disabled source-localization boundary. That shared failure behavior remains open. The legacy generic non-Tutor builder can also accept feedback as already-enriched content and lacks the shared immediate enrichment path used by Tutor. Source capture-level repair learning evidence needs reconciliation; native repair-completion evidence alone does not prove it. Those initial/enrichment/evidence gaps are not closed by this merge correction.

Actual process termination during pending enrichment/quote delivery, focused completion restoration, wider day/concurrent/support changes, audio/setup/capture, whole-shell RTL/accessibility, real-device/service/payment/release checks and all other open handoff rows remain. The separate native Firebase/Cloudflare services, reference repository, regular simulator and pre-existing emulator/preview processes are preserved. No merge, deployment, release or complete-parity claim follows from this checkpoint.
