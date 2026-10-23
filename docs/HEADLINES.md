# Today's Focus headline

The home subtitle now follows the reference's task-derived headline policy, primary-provider stream, cache guards and fallback presentation. This is a scoped part of the broader parity correction.

## Source contract and native behavior

`scripts/export-headline-policy.mjs` extracts only the nine pure declarations from `src/utils/dailyPlateHeadline.js`. The [manifest](reference/headline-source-manifest.json) records the source hash and 60 source-executed summary/prompt/cleaning/cache cases. `plate-headline-policy.js` runs in JavaScriptCore without host bindings, networking, identity material or arbitrary evaluator input. Native supplies JSON arguments through the bridge.

The source selects the next unfinished skill-tree lesson, using `completed` or `isCompleted`, then summarizes the scheduled courses. Goal and repair courses are excluded. Native reconstructs that progress map from saved completions and lesson work, loads the bundled curriculum and includes the original Pre-A1 introduction before ordinary lessons. Private goals, notes, keys and account identifiers are not prompt inputs. A built-app test checks the actual introductory topic, the next bundled lesson and exclusion of private-data sentinels.

Header preparation reads a generated per-language ID/title projection rather than decoding and bridging the entire lesson content on the UI actor. The exporter compares projected/full input through the original helper at all 8,848 possible next-lesson positions in the bundled levels; every topic agrees. The Spanish projection is 46,264 JSON bytes versus about 10.9 MB for the full curriculum. On the QA simulator the bundled-topic test falls from 5.237s to 0.108s, with the first prompt itself measured at 0.032s. These are scoped simulator observations, not physical-device benchmarks. Regenerate the header projections with `node scripts/export-headline-policy.mjs` whenever the bundled curriculum changes.

The original prompt asks for one human communication outcome, no more than twelve words, in the interface language. It excludes XP, levels, homework and mistakes. The original cleaner removes surrounding fences/quotes and keeps the first nonempty line. Native applies it to every accumulated stream update and to the final response. The original 14-point size/19.6-point line-box treatment and the source three-dot loading state replace the static subtitle. The complete banner still takes priority and suppresses new requests.

Gemini uses the existing configured Firebase AI backend and `generateContentStream`. The existing authenticated Cloudflare Responses route remains the recovery path. That worker returns a complete body, so **Responses recovery currently produces one final update rather than the reference's possible stream**. Equivalent fallback-provider streaming remains open; the primary Gemini path streams now.

A failed generation keeps any partial sentence already shown, without caching it. If no text arrived, the original localized fallback subtitle appears. Headline generation does not lock practice or replace the companion acknowledgement.

## Cache, concurrency and offline restoration

The canonical Firestore field is unchanged from the source:

```json
{"dailyPlateHeadline":{"es":{"dayKey":"2026-10-23","appLanguage":"en","text":"Ask about today's plans with confidence."}}}
```

There is one entry per practice language. A day/interface-language mismatch is a miss; switching back after another interface language replaced that entry can require generation again, as on the web. Native persists the cache and dirty entries locally with backward-compatible optional Codable fields. Only dirty language entries are merged to Firestore. Canonical headlines are deliberately omitted from `iosStateJSON` to avoid a second cloud authority.

The existing sync queue retries offline writes. Acknowledgement rebasing keeps a headline generated while an older save was in flight. Sibling-language entries, XP and paid verification remain intact. Entries retain the source's last-successful-write semantics across days and interface languages; a date-order rule would incorrectly reject a valid device-local day after timezone changes. A mismatched day/interface language is never displayed as a cached hit.

The controller scopes requests by account, practice language, interface language and local day. It rejects late updates/finals after a scope change or departure. The final save additionally checks the current model/account/day. This is intentionally stricter than the web helper, whose in-flight store write can finish after its component stopped displaying the result. The existing root minute clock supplies day changes.

## Verification

- Eleven selected Core tests pass, including all 60 actual source-policy cases and eight existing sync-contract regressions.
- Six final native/emulator tests pass in `Headline-MetadataFinal.xcresult`: five controller/prompt tests and a Firestore race/retry test. They cover partial/final cleaning, saved-cache/cleared/unavailable-policy behavior, departure cancellation, late account/language/day updates, real bundled lesson selection, concurrent language merges, source-compatible last-write ordering across date changes, canonical-only cloud authority and unchanged XP/membership/`patreonVerified`.
- Four headline UI journeys pass in the same final bundle: partial → final → relaunch with generation unavailable, English-to-French switching during generation and cached restoration, unavailable-generation fallback without blocking the welcome, and Arabic/dark content/bounds/relaunch. Together with the six unit/emulator cases, the final bundle reports ten passes, no failures and no skips. The two existing English/light and Arabic/dark companion/editor/immersion regressions also pass in `Headline-Journeys.xcresult`.
- Nineteen backend/rules tests pass with no skips. The headline write is allowed for its authenticated Nostr owner and denied for another learner, guest, anonymous login and public-demo identity; combining it with a paid-verification change is denied. Production rules and the worker were not changed or redeployed.
- The opt-in native live check passes in 7.245 seconds. It explicitly verifies the provider used: Gemini emits three updates each for English, French and Arabic; forced Responses emits one update. Prompts use public directions/tutor material and a disposable identity. This checks the actual configured services, not the offline UI fixture.

Reproduce the live service check with `python3 scripts/test-live-api.py --only headline`. The existing wrapper supplies the debug token through the process environment; no token belongs in source, URLs, screenshots or test output excerpts.

## Rendered evidence

The target-owned read-only source preview supplies cached sample sentences to the unmodified `DailyPlateHome` component. It does not create a real web learner or invoke a provider. [English](reference/headline-layout-en.json), [French](reference/headline-layout-fr.json) and [Arabic](reference/headline-layout-ar.json) measurements record the original typography; their source captures are [English](reference/headline-cached-en-402.png), [French](reference/headline-cached-fr-402.png) and [Arabic](reference/headline-cached-ar-402.png).

Native captures show [partial text](native/headline-partial.png), [final text](native/headline-final.png), [restoration without generation](native/headline-restored.png), [French](native/headline-french.png) [fallback](native/headline-fallback.png) and [Arabic/dark restoration](native/headline-arabic-dark.png). The final suite repeats the Arabic/dark headline/relaunch check. The compact [source/native comparison](native/headline-comparison.png) crops the native iOS chrome and labels that crop; complete native captures remain available alongside it. These deterministic UI fixtures test rendering and persistence, while the separate live check tests provider transport and real output.

The [Arabic comparison](native/headline-comparison-ar.png) shows different system-font glyphs/weight between the macOS source preview and native iOS. An iOS WebKit source baseline is still needed before treating Arabic typography as matched or changing it to imitate the desktop fallback. Bounds/content/relaunch checks do not establish glyph-level design parity.

Returning-day companion blueprints/repair recaps, the header/timer, activity heatmap, reward-retry/choreography and other product flows remain tracked in [TODAY_FOCUS.md](TODAY_FOCUS.md) and [PARITY_AUDIT.md](PARITY_AUDIT.md).
