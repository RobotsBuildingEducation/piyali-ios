# Shared calendar day parity

The reference uses JavaScript Date's Gregorian year, month and day in the learner's local timezone. The initial Swift helper used Calendar.current, so a Buddhist preference could write 2569 keys and request 2569 monthly history, while an Islamic preference could write a different month/day and query year 1448. This also affected daily rollover, goals, review histories and the health worker's day accounting.

CalendarDay now constructs a Gregorian calendar with the supplied local timezone and stable ASCII date-key formatting. Shared new keys, shifts, rollover and Activity query years follow that contract. Activity and Goal Manager keep Gregorian weeks/months; visible dates on Today's Focus, Memory, Voice Journey, wallet receipts and subscription verification also explicitly use Gregorian dates while retaining the selected support language. The existing 24-hour health reset policy is unchanged.

The shift helper executes the source's civil-date construction at local noon, including overflow, the JavaScript 0–99 year rule and Pacific/Apia's skipped December 30, 2011. Applying a day duration after constructing that skipped date produces a different result, so the Swift constructor receives day plus offset directly.

## Source and regression checks

`node scripts/export-calendar-days.mjs` reads the reference without modifying it. It executes the actual DAY_KEY_RE, getLocalCalendarDayKey and shiftDayKey declarations in an isolated VM with explicit Node timezones. The [manifest](reference/calendar-days-manifest.json) records the source SHA-256. Both generated files reproduce byte for byte.

- 144 source timestamps across nine timezones, 720 date shifts and 351 validation/overflow/short-year/skipped-date edges run against all 16 Foundation calendar identifiers. Leap days, DST overlaps/gaps, year boundaries, fractional-offset zones and date-line zones are included.
- The existing 150 original health cases now run across all 16 calendar identifiers (2,400 combinations), including timezone/DST reset and decay behavior.
- The selected Core regression passes 27 tests in 8.990 seconds: CalendarDay, companion health/quests, sync, daily plate and immersion. Calendar-only checks also pass separately (three tests, 1.442s).
- PiyaliCalendarSystem1.xcresult passes the opt-in actual Buddhist process check (0.112s). This uses Foundation's actual Calendar.current, rather than just passing a different Calendar argument.
- PiyaliCalendarSDK2.xcresult passes four checks in 5.149 seconds with `-testLanguage th -testRegion TH`. PiyaliCalendarSDK3.xcresult passes the same four checks in 5.166 seconds with `-testLanguage ar -testRegion SA`. The tests assert the actual Buddhist and Islamic Umm al-Qura system identifiers. Import and award use the normal default calendar. Real Firebase SDK writes preserve 195 total XP, 50 daily XP, completed goal, 100% companion health, streak 3, canonical monthly history, membership and duplicate-retry behavior. Existing old-offline-award and monthly/legacy/snapshot separation contracts pass.

SDK checks use an isolated, HTTP-healthy local demo-project Firestore emulator on port 8330. The owned server is stopped after the database runs. There is no production backend/rules deployment, paid grant, public relay publication or regular-simulator test fixture.

## Product journeys

PiyaliCalendarJourney1.xcresult passes the initial English/light Buddhist and Arabic/dark Islamic entry → onboarding → Paper & Pencil → setup → placement → Activity → Companion → process-relaunch journeys (143.005s). Four existing Activity app checks pass in the same run. Actual app-process probes report system years 2569 and 1448, but canonical day 2026-10-28 and query year 2026 in both. January retains the original 250-XP history, the partial-day style, saved zero-goal marker and zero daily XP after restart. These probes record actual process settings without selecting a calendar or changing product state.

PiyaliCalendarJourney2.xcresult passes the final extended journey (173.875s). Each of the same isolated accounts then switches back to Gregorian without reset or re-onboarding and retains its January history and zero daily XP. [Four verified process probes](reference/calendar-system-probes.json) confirm Buddhist → Gregorian and Islamic Umm al-Qura → Gregorian, with canonical 2026 throughout. [Six product captures](reference/calendar-captures.json) retain the initial, restored and switched states; screenshot review confirms October's displayed month in both languages. [Exact result summaries](reference/calendar-tests.json) retain both successful and failed attempts.

## Preservation and limits

Old persisted keys and pending operation IDs are preserved. A historical key such as 2569-10-28 does not identify which calendar generated it; prior versions did not save that metadata. This change does not guess or automatically rekey ambiguous legacy history or receipts. The regression explicitly checks that their UUID, timestamp and raw date survive encoding/decoding unchanged. A read-only inspection of the regular simulator finds 122 readable state JSON files and 921 exact YYYY-MM-DD keys, all within 1900–2200; it finds no evidence requiring a historical repair there.

SDK1's first monthly-read check fails because its already-compiled test oracle creates Buddhist-year 2568/2570 document IDs. The emulator confirms those synthetic IDs; the production query correctly rejects them. The test oracle now explicitly selects Gregorian, and SDK2/SDK3 pass the final checks. SDK1's other three checks pass; the run as a whole is not represented as passing.

This fixes shared new day keys/query years and selected visible date formatting. It does not establish all-locale typography, complete legacy migration, physical-device presentation, accessibility or full functional/design parity. Those remain in [the audit](PARITY_AUDIT.md). [Activity](XP_ACTIVITY.md) retains its original source/native comparisons; [Paper & Pencil](PAPER_PENCIL.md) covers the current first-run suggestion. The web checkout remains read-only at 5c8f8f0595f31a0d6532d660cad73135e8223cc2.

## Next-day Focus and guided practice

The current web root schedules a refresh at local midnight as well as its periodic update. Returning to the tab also refreshes its day. Guided practice is restored for its original account, practice language and day. Daily Goal and Repair focus are cleared when their context changes.

The iPhone now schedules the first of its next regular update and the local day boundary. Foregrounding, a significant clock change or a system time-zone change refreshes the date and replaces the scheduled wake. The Focus screen and guided conductor calculate the date, tasks and completion details for the same day. Goal and Repair routes carry their own day context, so a stale route can leave the screen after the guided session has already been discarded. Ordinary browsing can stay open.

The read-only browser preview used the original Focus component and source guided-session predicate. With a saved Review from November 18 and a Learn plan for November 19, it showed Start tasks, 0% daily XP and 25 language XP. Start selected Learn. The isolated iPhone journey showed the same day and XP state after opening the older profile and again after relaunch. Start opened the unfinished Learn node from today's plan. The screenshots use different public test accounts and placement data, which produce different review targets and scores. The source image SHA-256 is `186480b1f23a0f0b9feb6470d578de0028e36dbd2a2a766671ec3430a36da043`. The native image SHA-256 is `e67fbd71ed6abc414760fce35fe1791ce90d48e27d903f75d2479391fc58740a`.

The main simulator run passed 11 checks in `/tmp/PiyaliDayRollover-b7e1d77f-4dd9-4f3d-a482-1724357a6923.xcresult`. These include the controlled midnight transition, the full guided completion sequence, next-day Focus relaunch and the returning course navigation. The 12 Core checks passed. The original JavaScript midnight helper and Swift agreed across both Los Angeles clock changes, Apia's skipped day and Kathmandu's quarter-hour offset.

Two follow-up iOS checks passed in `/tmp/PiyaliDayRollover-458c877e-4f2d-4fa7-a45a-380350f52e6b.xcresult`. The clock-controlled conductor dropped a queued prior-day celebration and retained its earned receipt and Activity history. The mounted native root received a time-zone notification after a process-local time-zone change. It prepared the new day's plan, cleared the old guided session and kept both the original receipt ID and its date. These checks leave physical foreground recovery and cross-day acknowledgment of every in-flight Goal and Repair mode open.
