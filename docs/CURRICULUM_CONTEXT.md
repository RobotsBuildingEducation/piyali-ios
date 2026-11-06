# Authored curriculum context

Grammar/vocabulary and curriculum realtime now receive `buildGameReviewContext` output from the original web policy. The pure interpreter bundle includes its manual agenda and curriculum dependencies, with source hashes and no host APIs. Native unit/lesson adapters restore tutorial/game flags and the selected CEFR level. This includes Spanish manual objectives, the target-language adapter, and review/quiz context construction. Dynamic goal/repair payloads retain their own focused context; free practice has no artificial curriculum restriction.

For the actual first Spanish lesson, the source context contains seven family objectives starting with `mamá`; a broad topic label alone was insufficient. Original builders now include the lesson's objectives, forms, examples and evidence in their instructions. The source's deterministic grounding acceptance guard is applied to grammar matching's left/right pairs. It is not imposed on formats whose web renderer does not use it.

Introductory exports now retain the selected level as `cefrLevel`, including B2 and other adapted stages. Existing resource content was preserved while adding this metadata; generated adventures were not rerolled. Completed introductions can also restart their six activities for review while retaining the original completion receipt.

Validation includes 19 affected core checks, bundled instruction/judge checks in the iPhone runtime, and a simulator journey through introduction/resume/completion/replay with no duplicate bonus. An opt-in provider test prepared vocabulary and matching from the actual My Family agenda. These checks cover the new context path, not complete content or visual parity. Run `python3 scripts/test-live-api.py --only lesson-content` for that provider check.

Reading, stories, games and final quizzes still need a full audit of context preparation and source-specific interactions. Assessment for remaining engines and the prepared-question pipeline and the original voice transport remain separate outstanding work.

Grammar/vocabulary and curriculum realtime now save source difficulty quotes and apply them to progress; see [the assessment checkpoint](QUESTION_WORTH.md).
