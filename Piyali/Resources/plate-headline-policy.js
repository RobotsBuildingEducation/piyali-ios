// Pure source policy. No host bindings, account credentials or networking.
var PiyaliPlateHeadline=(function(){
const LANGUAGE_PROMPT_NAMES = {
  en: "English",
  es: "Spanish",
  pt: "Portuguese",
  fr: "French",
  it: "Italian",
  de: "German",
  ja: "Japanese",
  zh: "Mandarin Chinese",
  ru: "Russian",
  ar: "Arabic",
  hi: "Hindi",
  nl: "Dutch",
  nah: "Eastern Huasteca Nahuatl",
  pl: "Polish",
  el: "Greek",
  ga: "Irish",
};
function resolveLanguageName(code) {
  const normalized = typeof code === "string" ? code.trim().toLowerCase() : "";
  return (
    LANGUAGE_PROMPT_NAMES[normalized] ||
    normalized.toUpperCase() ||
    "English"
  );
}
function normalizePlateLang(targetLang) {
  return typeof targetLang === "string" && targetLang.trim()
    ? targetLang.trim().toLowerCase()
    : "es";
}
function getStoredPlateHeadline(user, targetLang, dayKey, appLanguage = "en") {
  if (!user || !targetLang || !dayKey) return null;
  const langKey = normalizePlateLang(targetLang);
  const supportKey = typeof appLanguage === "string" ? appLanguage.trim().toLowerCase() : "en";
  const cached = user?.dailyPlateHeadline?.[langKey];
  if (
    cached &&
    cached.dayKey === dayKey &&
    cached.appLanguage === supportKey &&
    typeof cached.text === "string" &&
    cached.text.trim()
  ) {
    return cached.text.trim();
  }
  return null;
}
function isLessonCompleted(progress) {
  return Boolean(progress?.completed || progress?.isCompleted);
}
function findNextLessonFromUnits(units = [], userProgress = {}, targetLang = "es") {
  const languageLessons =
    userProgress?.languageLessons?.[targetLang] || userProgress?.lessons || {};

  for (const unit of units) {
    if (!unit?.lessons || !Array.isArray(unit.lessons)) continue;
    for (const lesson of unit.lessons) {
      const p = languageLessons[lesson.id];
      if (!isLessonCompleted(p)) {
        return { lesson, unit };
      }
    }
  }
  return null;
}
function getPlateTaskSummary(courses = [], user = {}, targetLang = "es", levelUnits = []) {
  const langKey = normalizePlateLang(targetLang);

  // Exclude repair and goal — the companion pet handles those
  const actionableCourses = courses.filter(
    (c) => c && c.kind && c.kind !== "repair" && c.kind !== "goal",
  );

  return actionableCourses.map((course) => {
    let topic = "";

    if (course.kind === "learn") {
      if (Array.isArray(levelUnits) && levelUnits.length > 0) {
        const next = findNextLessonFromUnits(levelUnits, user?.progress || {}, langKey);
        const titleVal = next?.lesson?.title || next?.unit?.title;
        topic = typeof titleVal === "object" ? titleVal?.en || Object.values(titleVal)[0] || "" : titleVal || "";
      }
      if (!topic) {
        topic = "Lesson";
      }
    } else if (course.kind === "speak") {
      topic = "Tutor conversation practice";
    } else if (course.kind === "review") {
      topic = "Vocabulary flashcard review";
    } else if (course.kind === "conversation") {
      topic = "Interactive conversation";
    } else if (course.kind === "phonics") {
      topic = "Phonics and pronunciation practice";
    } else {
      topic = `${course.kind} practice`;
    }

    const count = Number(course.count) || 0;
    const target = Number(course.target) || 1;

    return {
      kind: course.kind,
      topic,
      count,
      target,
      progress: `${count}/${target}`,
      done: count >= target,
    };
  });
}
function buildPlateHeadlinePrompt({ targetLang, appLanguage = "en", taskSummary = [] }) {
  const targetName = resolveLanguageName(targetLang);
  const supportName = resolveLanguageName(appLanguage);

  const tasksFormatted = taskSummary
    .map((t) => `- ${t.kind}: ${t.topic} (${t.progress} completed)`)
    .join("\n");

  return [
    `You are generating the single-sentence subtitle for "Today's Focus" in a language learning app.`,
    `Course: Learning ${targetName}.`,
    `OUTPUT LANGUAGE REQUIREMENT: You MUST write the sentence strictly in ${supportName}.`,
    ``,
    `Today's scheduled learning tasks:`,
    tasksFormatted || `- General lesson practice`,
    ``,
    `Write ONE crisp, inspiring sentence (maximum 12 words) in ${supportName} stating the real-world communication skill, moment, or capability we will cover today.`,
    `CRITICAL RULES:`,
    `- The entire sentence MUST be written in ${supportName}.`,
    `- Do NOT write in ${targetName} unless ${supportName} is ${targetName}.`,
    `- Do NOT mention XP, points, levels, tasks, exercises, or homework.`,
    `- Do NOT mention repairs, mistakes, or errors.`,
    `- Frame it as a human outcome (e.g. "Handle your first café order, including a follow-up question" or "Ask about someone's weekend plans with confidence").`,
    `- Return ONLY the plain sentence in ${supportName}, without quotes or markdown.`,
  ].join("\n");
}
function cleanHeadlineText(raw) {
  let text = String(raw || "").trim();
  if (text.startsWith("```")) {
    text = text.replace(/^```(?:json|text)?\s*/i, "").replace(/```$/, "").trim();
  }
  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  text = lines[0] || "";
  text = text.replace(/^["'“‘]+|["'”’]+$/g, "").trim();
  return text;
}
function run(operation,json){const p=JSON.parse(json);let value;if(operation==='summary')value=getPlateTaskSummary(p.courses,p.user,p.targetLang,p.levelUnits);else if(operation==='prompt')value=buildPlateHeadlinePrompt(p);else if(operation==='clean')value=cleanHeadlineText(p.text);else if(operation==='stored')value=getStoredPlateHeadline(p.user,p.targetLang,p.dayKey,p.appLanguage);else throw Error('Unknown headline operation');return JSON.stringify(value??null);}
return {run};
})();
