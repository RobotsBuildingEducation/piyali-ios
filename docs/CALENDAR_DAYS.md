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
