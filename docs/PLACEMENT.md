# Starting-level self-assessment

The initial native prompt follows the main product's choice, two pages of five whole-row selections, and CEFR result. It uses the original localized copy, CEFR names/descriptions and cropped dog artwork exported by `scripts/export-placement-copy.mjs`. Selections survive back/forward navigation. Completely new starts at Pre-A1; a self-report uses the existing source placement calculation without awarding XP or clearing earned progress.

The reference result's Take proficiency test button navigates to `/proficiency`. That separate route is outside the requested native scope; the native result preserves it as a web link. It does not claim to port the separate test.

The quiz simulator journey exercised selection of common words through A1 placement and actual lesson access. The initial companion/setup/placement chain is now implemented; the original choice geometry, frame/header padding and palettes have been corrected using actual browser measurements. The source’s completely-new path and self-report/result are exercised within native first-run journeys, including Arabic dark, relaunch and language changes. See [FIRST_RUN.md](FIRST_RUN.md). Broader locale/layout and save-error presentation still need comparison.
