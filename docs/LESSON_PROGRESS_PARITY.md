# Lesson-owned XP correction

The reference's ordinary curriculum lessons complete when their own `earnedXp` reaches `xpReward`. Shared language XP, legacy `lessonStartXp` and `xpEarned`, or one correct answer in every mode do not satisfy this gate. Completion then awards the separate authored lesson bonus. Final quizzes, games, the introduction, personal goals and repair retain their separate rules.

Native starts and scoped positive practice awards now carry durable lesson metadata. Reading and story rewards carry their actual run's lesson ID; standalone Tutor, cards and conversations do not. Firestore reads the active lesson before writing, credits only `in_progress` documents, and uses practice receipts to prevent retries from duplicating work. A completion already present in the shared lesson document prevents another native bonus. The canonical counter imports from web progress and language-lesson documents; sync rebasing reapplies practice performed during a request.

The current lesson screen has an explicit Start action, saved XP progress and automatic threshold completion. It still needs the source lesson detail/session layout, tabs, completion celebration and guided-task modal sequencing. The old generic exercise screen still awards its legacy values until the typed exercise replacement is connected; this counter correction does not establish full lesson parity.

Validation: core counter, web-import and in-flight rebase checks; iOS Firestore emulator checks for concurrent 6/5-XP practice, retry deduplication, unrelated Tutor XP, resumed 50-XP threshold and separate completion bonus; an already-web-completed lesson cannot award again. Existing introduction and final-quiz restore checks pass alongside these. Tests use a demo project and isolated identities.
