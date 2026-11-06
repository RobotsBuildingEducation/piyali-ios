# Focused Tutor continuity through worth and completion acknowledgment — 2026-11-06

Reference: read-only `RobotsBuildingEducation/nosabos` at **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `574929b`. This advances FUNC-03 and VERIFY-02; overall functional and design parity remains **In progress**.

## Source behavior and reproduced gap

The original `completeTutorLessonFromXp` stops voice and awaits all turn award promises before banking a focused completion. Goal Tutor records one production attempt with `tutor:<goalId>:<day>` evidence and no completion bonus. Repair Tutor banks its original repair step and then adds 12 XP. A demonstrated repair can therefore finish after one five-XP turn, for 17 total XP; its visible lesson progress is 42%. XP alone must not invent demonstrated repair evidence. A Phonics lesson that falls back to Tutor still completes the original Phonics task, without ordinary Tutor-path or Speak activity progress.

The new reproduction terminated a focused session while the final question worth was pending, restored the actual private account file and waited for delivery. Account turn XP returned, but the dependent completion was lost: Goal remained unfinished and Repair lost its 12-XP bonus, repair count and reinforcement. The baseline test fails in 18.859 seconds. Earlier ordinary pending-worth recovery remains separately documented in [PENDING_LEARNING_RECOVERY.md](PENDING_LEARNING_RECOVERY.md).

The source's in-memory promises do not survive destruction of its JavaScript runtime. Persisting this dependency on iPhone is a native lifecycle adaptation for the handoff's retry/relaunch requirement, not a claim that the web stores an identical continuation schema.

## Native behavior

An account-private focused run stores the original goal or narrowed repair step, lesson, required XP, earned XP, genuine repair evidence, dependent outcome IDs and completion receipt ID. The accepted turn and run update enter the same private learner snapshot. Partial focused progress restores disconnected with empty private chat and no automatic voice start. Ready work resumes only for its owner and matching target, support language, goal/repair context and current day.

The finalizer coalesces concurrent resumes, waits for original worth deliveries and saves a stable Goal attempt or Repair completion. It persists that identity before cloud sync, retains it after a failed or lost response and retires the run only after acknowledgment. A stale acknowledgment cannot resurrect a retired run. Firebase canonical hints omit the private run, and remote-only loading rejects an injected hint continuation.

The root restores the special course and actual Tutor fallback surface. Earned work remains visible at the 300-account-XP boundary while Retry saves the same completion. Repair restoration accepts its matching ready run even when its raw local counter has advanced ahead of the confirmed route. The access-change handler preserves that ready run while lesson preparation finishes. The error text and Retry button have independent accessibility identifiers. Once acknowledged, the next activity remains behind subscription; relaunch does not reconnect voice or award another completion. Recovery access cannot generate a new companion plan.

## Verification

The final `/tmp/PiyaliFocusedTutorRecoveryFinal20261106.xcresult` passes **16 tests, zero failures or skips**: 14 app/source/SDK checks in 111.966 seconds and two complete native UI journeys in 194.572 seconds. The Goal journey passes in 108.912 seconds; Repair passes in 85.660 seconds. Both use normal fresh signup/setup/navigation and real process termination. Only authored public plan/cache prerequisites and external provider/persistence I/O are fixtures; earned turns, answers and completion counters are not seeded in these journeys.

The affected Core run passes **37 tests in 22.360 seconds**, including the private run's serialization, legacy schema, stable receipt identity, acknowledgment rebase and retirement, plus all **1,215 existing original Tutor policy cases**. These Core files are unchanged in the final tested implementation. Earlier ordinary Tutor and receipt contracts also pass within the retained broader run; that mixed bundle remains recorded as failed overall.

The real local Firebase SDK test commits a completion, loses its response, restores the private account file and retries. Goal and Repair each retain one completion receipt, their original progression and XP, and no ordinary Tutor-path record. Canonical foreign membership fields remain intact; hints omit the private run and an injected hint cannot restart it. Rendered controller checks additionally cover partial progress, genuine versus XP-only repair proof, an already advanced raw repair count with an unacknowledged route, support/account replacement and access fencing. A returning companion plan is generated at 299 XP but cannot be generated through an earned-work bypass at 300.

Six read-only QA phase audits compare each actual journey before termination, during offline save and after the final relaunch:

| Counter | Goal: worth → save → settled | Repair: worth → save → settled |
| --- | --- | --- |
| Account earned XP | 20 → 25 → 25 | 0 → 17 → 17 |
| Daily XP | 25 → 25 → 25 | 5 → 17 → 17 |
| Graded attempts | 4 → 5 → 5 | 0 → 1 → 1 |
| Trial account XP | 299 → 304 → 304 | 299 → 316 → 316 |
| Pending worth | 1 → 0 → 0 | 1 → 0 → 0 |
| Focused private runs | 1 → 1 → 0 | 1 → 1 → 0 |
| Original Phonics Goal / repair progress | 0 → 2 → 2 | 0 → 1 → 1 |
| Pending completion | 0 → 1 → 0 | 0 → 1 → 0 |

The run hash is unchanged between worth and save. Settled XP/assessment counts equal the save phase; ordinary Tutor/Phonics records and Speak activity remain zero. Repair's original pronunciation Memory is reinforced. No profile, key or private identity is exported.

Four original component/native pairs were visually inspected, with source left and native right: [Goal English/light](native/focused-tutor-recovery-b269524d/pair-goal-en.png), [Goal Arabic/dark](native/focused-tutor-recovery-b269524d/pair-goal-ar.png), [Repair English/light](native/focused-tutor-recovery-b269524d/pair-repair-en.png) and [Repair Arabic/dark](native/focused-tutor-recovery-b269524d/pair-repair-ar.png). Titles, localized progress and the focused lesson layout agree. Small footer offsets, shadow strength and orb/eye rendering remain visibly different. These are component pairs, not whole authenticated web shells.

The [full native recovery contact sheet](native/focused-tutor-recovery-b269524d/native-recovery-contact.png) shows the actual product's pending worth, restored Retry, acknowledged paywall and gated relaunch for both journeys. [The evidence manifest](native/focused-tutor-recovery-b269524d/manifest.json) hashes **41 artifacts**, retaining original screenshot bytes, geometry/SDK traces, six audits, source callback cases, diagnostic/final results and exact commands. The QA-installed executable and Swift debug library hashes match the final built products.

The retained [original asynchronous callback oracle](native/focused-tutor-recovery-b269524d/source-completion-oracle.json) executes the unmodified source callback with explicit public voice, persistence, analytics and celebration I/O. Its 16 cases cover Goal/Repair, original Tutor/Phonics mode, English/Arabic, held award promises and successful/failed banking. They verify ordering, source event fields, the Repair-only bonus and the source's replay/failure guards. This is not a mounted authenticated browser or source Firebase test.

[Diagnostic result summaries](native/focused-tutor-recovery-b269524d/diagnostic-results.json) retain failed runs as failed. The work exposed and corrected the source's narrowed repair-plan shape, a receipt-path test assumption, a trial transition interrupting preparation, a parent accessibility identifier overriding Retry, and the Repair raw/confirmed routing guard. A broader run also found an older helper test assuming immediate confirmed progress and a new generation control using a same-day note that the source excludes. Receipt-backed acknowledgment and yesterday's eligible public note are the correct test prerequisites.

## Remaining limits

This checkpoint covers matching **current-day** focused runs. Day rollover, plan replacement after a queued completion, cross-device chronology and broader concurrent-flow recovery still need end-to-end evidence. It does not recover historical sessions that never saved this private run. An interrupted remote worth request may run again; the earned delivery and completion receipt retain their own stable identities.

Public I/O fixtures and component pairs do not prove live model quality, full authenticated browser routing, production Firebase, physical microphone/output behavior, full-shell geometry or complete RTL/accessibility parity. Tutor capture/setup and partial-PCM boundaries, whole-screen orb/layout differences, wider Story/Conversation and other mode contexts, Teams lifecycle, paid and wallet verification, physical devices, release signing and App Check remain open in [PARITY_HANDOFF.md](PARITY_HANDOFF.md). The separate Firebase/Cloudflare services are preserved. No merge, deployment or App Store publication is included.
