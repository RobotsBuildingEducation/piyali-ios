// Generated source policies; Swift owns persistence, provider calls and UI.
(function(){const SystemDate=globalThis.Date;let Date=SystemDate,p={},requests=[],index=0;
const console={error:()=>{}};function callNativeResponses(request){requests.push(request.input);const value=(p.responses||[])[index++];if(value?.nativeFailure)throw Error('provider');return value||'';}
// src/constants/supportLanguages.js
const M9=(function(){
const SUPPORT_LANGUAGE_CODES = Object.freeze([
  "en",
  "es",
  "pt",
  "it",
  "fr",
  "de",
  "ja",
  "hi",
  "ar",
  "zh",
]);
return {SUPPORT_LANGUAGE_CODES};})();
// src/constants/languages.js
const M0=(function(){const egyptianFlag=null;
const netherlandsFlag=null;
const usaFlag=null;
const frenchFlag=null;
const germanFlag=null;
const italianFlag=null;
const indianFlag=null;
const chineseFlag=null;
const brazilianFlag=null;
const mexicanFlag=null;
const greekFlag=null;
const japaneseFlag=null;
const russianFlag=null;
const polishFlag=null;
const irishFlag=null;
const CANONICAL_SUPPORT_LANGUAGE_CODES=M9.SUPPORT_LANGUAGE_CODES;
const DEFAULT_SUPPORT_LANGUAGE = "en";
const LANGUAGE_FALLBACK_LABELS = {
  ar: "Egyptian Arabic",
  zh: "Mandarin Chinese",
  en: "English",
  es: "Spanish",
  pt: "Portuguese",
  fr: "French",
  it: "Italian",
  hi: "Hindi",
  nl: "Dutch",
  nah: "Eastern Huasteca Nahuatl",
  ja: "Japanese (日本語)",
  ru: "Russian",
  de: "German",
  el: "Greek",
  pl: "Polish",
  ga: "Irish",
  yua: "Yucatec Maya",
};
const LANGUAGE_PROMPT_LABELS = {
  ar: "Egyptian Arabic (العربية المصرية)",
  zh: "Mandarin Chinese (普通话中文)",
  es: "Spanish (espanol)",
  en: "English",
  pt: "Portuguese (portugues brasileiro)",
  fr: "French (francais)",
  it: "Italian (italiano)",
  hi: "Hindi (hindi)",
  nl: "Dutch (Nederlands)",
  nah: "Eastern Huasteca Nahuatl (nahuatl huasteco oriental)",
  ru: "Russian",
  de: "German (Deutsch)",
  el: "Greek",
  pl: "Polish (polski)",
  ga: "Irish (Gaeilge)",
  yua: "Yucatec Maya (maaya t'aan)",
  ja: "Japanese (日本語)",
};
const LANGUAGE_META = [
  {
    value: "ar",
    languageKey: "language_ar",
    practiceKey: "onboarding_practice_ar",
    tier: "stable",
    supportTier: "stable",
    practiceEnabled: false,
    flag: egyptianFlag,
  },
  {
    value: "nl",
    languageKey: "language_nl",
    practiceKey: "onboarding_practice_nl",
    tier: "stable",
    flag: netherlandsFlag,
  },
  {
    value: "en",
    languageKey: "language_en",
    practiceKey: "onboarding_practice_en",
    tier: "stable",
    flag: usaFlag,
  },
  {
    value: "fr",
    languageKey: "language_fr",
    practiceKey: "onboarding_practice_fr",
    tier: "stable",
    flag: frenchFlag,
  },
  {
    value: "de",
    languageKey: "language_de",
    practiceKey: "onboarding_practice_de",
    tier: "stable",
    flag: germanFlag,
  },
  {
    value: "it",
    languageKey: "language_it",
    practiceKey: "onboarding_practice_it",
    tier: "stable",
    flag: italianFlag,
  },
  {
    value: "hi",
    languageKey: "language_hi",
    practiceKey: "onboarding_practice_hi",
    tier: "stable",
    supportTier: "stable",
    practiceEnabled: false,
    flag: indianFlag,
  },
  {
    value: "zh",
    languageKey: "language_zh",
    practiceKey: "onboarding_practice_zh",
    tier: "stable",
    supportTier: "stable",
    practiceEnabled: false,
    flag: chineseFlag,
  },
  {
    value: "pt",
    languageKey: "language_pt",
    practiceKey: "onboarding_practice_pt",
    tier: "stable",
    flag: brazilianFlag,
  },
  {
    value: "es",
    languageKey: "language_es",
    practiceKey: "onboarding_practice_es",
    tier: "stable",
    flag: mexicanFlag,
  },
  {
    value: "nah",
    languageKey: "language_nah",
    practiceKey: "onboarding_practice_nah",
    tier: "alpha",
    // Temporarily hidden from practice-language selectors. Keep the language
    // registered so existing user data and the underlying implementation work.
    selectorHidden: true,
    flag: mexicanFlag,
  },
  {
    value: "yua",
    languageKey: "language_yua",
    practiceKey: "onboarding_practice_yua",
    tier: "alpha",
    // Temporarily hidden from practice-language selectors. Keep the language
    // registered so existing user data and the underlying implementation work.
    selectorHidden: true,
    flag: mexicanFlag,
  },
  {
    value: "el",
    languageKey: "language_el",
    practiceKey: "onboarding_practice_el",
    tier: "beta",
    flag: greekFlag,
  },
  {
    value: "ja",
    languageKey: "language_ja",
    practiceKey: "onboarding_practice_ja",
    tier: "beta",
    supportTier: "stable",
    flag: japaneseFlag,
  },
  {
    value: "ru",
    languageKey: "language_ru",
    practiceKey: "onboarding_practice_ru",
    tier: "beta",
    flag: russianFlag,
  },
  {
    value: "pl",
    languageKey: "language_pl",
    practiceKey: "onboarding_practice_pl",
    tier: "beta",
    flag: polishFlag,
  },
  {
    value: "ga",
    languageKey: "language_ga",
    practiceKey: "onboarding_practice_ga",
    tier: "beta",
    flag: irishFlag,
  },
];
const SUPPORTED_LANGUAGE_CODES_SET = new Set(
  LANGUAGE_META.map((item) => item.value),
);
const SUPPORT_LANGUAGE_CODES_BASE = [...CANONICAL_SUPPORT_LANGUAGE_CODES];
const SUPPORT_LANGUAGE_CODES_SET = new Set(SUPPORT_LANGUAGE_CODES_BASE);
const LANGUAGE_LOCALES = {
  ar: "ar-EG",
  zh: "zh-CN",
  en: "en-US",
  es: "es-MX",
  pt: "pt-BR",
  fr: "fr-FR",
  it: "it-IT",
  hi: "hi-IN",
  nl: "nl-NL",
  nah: "es-MX",
  ja: "ja-JP",
  ru: "ru-RU",
  de: "de-DE",
  el: "el-GR",
  pl: "pl-PL",
  ga: "ga-IE",
  yua: "es-MX",
};
const normalizeCode = (raw) => String(raw || "").trim().toLowerCase();
const normalizeSupportedCode = (raw) => {
  const normalized = normalizeCode(raw);
  if (!normalized) return "";
  if (normalized === "arz") return "ar";
  if (normalized === "cmn") return "zh";
  if (SUPPORTED_LANGUAGE_CODES_SET.has(normalized)) return normalized;
  const [base] = normalized.split(/[-_]/);
  if (base === "arz" && SUPPORTED_LANGUAGE_CODES_SET.has("ar")) return "ar";
  if (base === "cmn" && SUPPORTED_LANGUAGE_CODES_SET.has("zh")) return "zh";
  if (SUPPORTED_LANGUAGE_CODES_SET.has(base)) return base;
  return normalized;
};
function normalizeSupportLanguage(
  code,
  fallback = DEFAULT_SUPPORT_LANGUAGE,
) {
  const normalized = normalizeSupportedCode(code);
  if (SUPPORT_LANGUAGE_CODES_SET.has(normalized)) return normalized;
  return fallback;
}
function getLanguagePromptName(code) {
  const normalized = normalizeSupportedCode(code);
  if (!normalized) return "";
  return (
    LANGUAGE_PROMPT_LABELS[normalized] ||
    LANGUAGE_FALLBACK_LABELS[normalized] ||
    normalized.toUpperCase()
  );
}
function getLanguageLocale(code, fallback = "en-US") {
  const normalized = normalizeSupportedCode(code);
  return LANGUAGE_LOCALES[normalized] || fallback;
}
return {getLanguageLocale,normalizeSupportedCode,normalizeCode,SUPPORTED_LANGUAGE_CODES_SET,LANGUAGE_META,egyptianFlag,netherlandsFlag,usaFlag,frenchFlag,germanFlag,italianFlag,indianFlag,chineseFlag,brazilianFlag,mexicanFlag,greekFlag,japaneseFlag,russianFlag,polishFlag,irishFlag,LANGUAGE_LOCALES,getLanguagePromptName,LANGUAGE_PROMPT_LABELS,LANGUAGE_FALLBACK_LABELS,normalizeSupportLanguage,DEFAULT_SUPPORT_LANGUAGE,SUPPORT_LANGUAGE_CODES_SET,SUPPORT_LANGUAGE_CODES_BASE,CANONICAL_SUPPORT_LANGUAGE_CODES};})();
// src/utils/dailyPlate.js
const M6=(function(){
function normalizePlateLang(targetLang) {
  return typeof targetLang === "string" && targetLang.trim()
    ? targetLang.trim().toLowerCase()
    : "es";
}
return {normalizePlateLang};})();
// src/utils/userDataSchema.js
const M8=(function(){
function getLocalCalendarDayKey(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
return {getLocalCalendarDayKey};})();
// src/utils/flashcardReview.js
const M7=(function(){const getLocalCalendarDayKey=M8.getLocalCalendarDayKey;
function coerceDate(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}
function getLocalDayKey(value) {
  const date = coerceDate(value);
  if (!date) return null;
  return getLocalCalendarDayKey(date) || null;
}
return {getLocalDayKey,coerceDate,getLocalCalendarDayKey};})();
// src/utils/germanCopy.js
const M10=(function(){
const GERMAN_COPY = {
  "Save failed": "Speichern fehlgeschlagen",
  "Error al guardar": "Speichern fehlgeschlagen",
  "Show translation": "Übersetzung anzeigen",
  "Subscription passcode is not configured":
    "Abonnement-Zugangscode ist nicht konfiguriert",
  "Passcode accepted": "Zugangscode akzeptiert",
  "Failed to save passcode": "Zugangscode konnte nicht gespeichert werden",
  "Connect your account to use this feature.":
    "Verbinde dein Konto, um diese Funktion zu nutzen.",
  "Account required": "Konto erforderlich",
  "Connect your account to analyze your level.":
    "Verbinde dein Konto, um dein Niveau zu analysieren.",
  "Analysis complete": "Analyse abgeschlossen",
  "Assigned level: {level}.": "Zugewiesenes Niveau: {level}.",
  "Analysis failed": "Analyse fehlgeschlagen",
  "Please try again later.": "Bitte versuche es später erneut.",
  "Couldn't find the current user.": "Der aktuelle Benutzer wurde nicht gefunden.",
  Help: "Hilfe",
  Cards: "Karten",
  Notes: "Notizen",
  Alphabet: "Alphabet",
  Path: "Pfad",
  Conversation: "Gespräch",
  Mode: "Modus",
  "Start proficiency test": "Einstufungstest starten",
  "Lesson Complete!": "Lektion abgeschlossen!",
  "XP Earned": "XP verdient",
  "Experience Points": "Erfahrungspunkte",
  Continue: "Weiter",
  "Keep learning": "Weiterlernen",
  Goal: "Ziel",
  "Daily goal reached!": "Tagesziel erreicht!",
  "You hit your XP goal for today.": "Du hast dein XP-Ziel für heute erreicht.",
  "Streak protected": "Serie geschützt",
  "Enter the passcode": "Zugangscode eingeben",
  Verifying: "Wird geprüft",
  Submit: "Absenden",
  "Invalid passcode. Please try again.":
    "Ungültiger Zugangscode. Bitte versuche es erneut.",
  "Browser is blocking the mic for this site. Click the lock icon → Site settings → Microphone → Allow, then reload.":
    "Der Browser blockiert das Mikrofon für diese Website. Klicke auf das Schloss → Website-Einstellungen → Mikrofon → Zulassen und lade neu.",
  "Microphone requires HTTPS (or localhost). Open the app over https:// and try again.":
    "Das Mikrofon benötigt HTTPS (oder localhost). Öffne die App über https:// und versuche es erneut.",
  "The microphone is busy (Zoom/Teams/Discord). Close other apps using the mic and try again.":
    "Das Mikrofon ist belegt (Zoom/Teams/Discord). Schließe andere Apps mit Mikrofonzugriff und versuche es erneut.",
  "No microphone was found or it’s disabled at the OS level.":
    "Es wurde kein Mikrofon gefunden oder es ist im Betriebssystem deaktiviert.",
  "Requested audio constraints are not supported by your mic.":
    "Die angeforderten Audioeinstellungen werden von deinem Mikrofon nicht unterstützt.",
  "Microphone error. If permissions look allowed, reload the page and try again.":
    "Mikrofonfehler. Wenn die Berechtigungen korrekt aussehen, lade die Seite neu und versuche es erneut.",
  "Your chats": "Deine Chats",
  "No saved chats": "Keine gespeicherten Chats",
  Delete: "Löschen",
  "Morpheme mode": "Morphem-Modus",
  "Break down words": "Wörter zerlegen",
  "New chat": "Neuer Chat",
  Menu: "Menü",
  Morphemes: "Morpheme",
  "Save chat": "Chat speichern",
  "What do you want to learn today?": "Was möchtest du heute lernen?",
  "Stop voice chat": "Sprachchat stoppen",
  "Start voice chat": "Sprachchat starten",
  Play: "Abspielen",
  "Ask about this lesson...": "Frag etwas zu dieser Lektion...",
  Send: "Senden",
  Stop: "Stopp",
  "Immersion & Score": "Immersion & Punktzahl",
  "3 tasks to use your language outside the app":
    "3 Aufgaben, um deine Sprache außerhalb der App zu nutzen",
  "Next batch in": "Nächster Stapel in",
  "Creating tasks...": "Aufgaben werden erstellt...",
  "Try again": "Erneut versuchen",
  "No tasks yet.": "Noch keine Aufgaben.",
  "Claim +15 XP": "+15 XP abholen",
  Claiming: "Wird abgeholt",
  Claimed: "Abgeholt",
  "Failed to award reward": "Belohnung konnte nicht vergeben werden",
  "Ready to refresh": "Bereit zum Aktualisieren",
  "Could not generate tasks. Please try again.":
    "Aufgaben konnten nicht erstellt werden. Bitte versuche es erneut.",
  "Enter a display name": "Anzeigenamen eingeben",
  "Display name updated": "Anzeigename aktualisiert",
  Error: "Fehler",
  "Get full access to more education apps and content":
    "Erhalte vollen Zugriff auf weitere Bildungs-Apps und Inhalte",
  "Create display name": "Anzeigenamen erstellen",
  "Saving…": "Wird gespeichert…",
  "Wallet not ready": "Wallet nicht bereit",
  "Please try again in a moment.": "Bitte versuche es gleich noch einmal.",
  "Invalid key": "Ungültiger Schlüssel",
  "Key must start with 'nsec'.": "Der Schlüssel muss mit „nsec“ beginnen.",
  "Couldn't create wallet": "Wallet konnte nicht erstellt werden",
  "Failed to create wallet": "Wallet konnte nicht erstellt werden",
  "Select an identity": "Identität auswählen",
  "Choose who receives your deposits before continuing.":
    "Wähle aus, wer deine Einzahlungen erhält, bevor du fortfährst.",
  "Couldn't create invoice": "Rechnung konnte nicht erstellt werden",
  "Failed to initiate deposit": "Einzahlung konnte nicht gestartet werden",
  "Address copied": "Adresse kopiert",
  "Lightning invoice copied to clipboard.":
    "Lightning-Rechnung in die Zwischenablage kopiert.",
  "Bitcoin wallet": "Bitcoin-Wallet",
  "Loading wallet…": "Wallet wird geladen…",
  "Choose a recipient": "Empfänger auswählen",
  "Select an option to enable deposits.":
    "Wähle eine Option, um Einzahlungen zu aktivieren.",
  "Create wallet": "Wallet erstellen",
  "Creating wallet…": "Wallet wird erstellt…",
  "Copy key": "Schlüssel kopieren",
  "Copy Secret Key": "Geheimen Schlüssel kopieren",
  "Secret key required": "Geheimer Schlüssel erforderlich",
  "Maybe later": "Vielleicht später",
  Done: "Fertig",
  Close: "Schließen",
  "View site": "Website ansehen",
  "Join us on Patreon": "Unterstütze uns auf Patreon",
  Join: "Beitreten",
  "Change display name": "Anzeigenamen ändern",
  "Display name": "Anzeigename",
  "Save": "Speichern",
  "Saving": "Speichern",
};
const getGermanCopy = (text) => {
  if (typeof text !== "string") return "";
  return GERMAN_COPY[text] || "";
};
return {getGermanCopy,GERMAN_COPY};})();
// src/utils/companionMemoryCopy.js
const M3=(function(){const normalizeSupportLanguage=M0.normalizeSupportLanguage;
const DEFAULT_SUPPORT_LANGUAGE=M0.DEFAULT_SUPPORT_LANGUAGE;
const getGermanCopy=M10.getGermanCopy;
const memoryCopy = (lang, copy) => {
  const normalized = normalizeSupportLanguage(lang, DEFAULT_SUPPORT_LANGUAGE);
  if (copy[normalized]) return copy[normalized];
  if (normalized === "de") return getGermanCopy(copy.en) || copy.en;
  return copy.en;
};
const MEMORY_CARD_COPY = {
  youSaid: {
    en: "You said",
    es: "Dijiste",
    pt: "Você disse",
    fr: "Tu as dit",
    it: "Hai detto",
    de: "Du sagtest",
    ja: "あなたの答え",
    zh: "你的回答",
    ru: "Ты сказал",
    ar: "إجابتك",
    hi: "आपने कहा",
  },
  correct: {
    en: "Correction",
    es: "Corrección",
    pt: "Correção",
    fr: "Correction",
    it: "Correzione",
    de: "Korrektur",
    ja: "訂正",
    zh: "更正",
    ru: "Исправление",
    ar: "التصحيح",
    hi: "सुधार",
  },
  noAnswer: {
    en: "No answer given",
    es: "Sin respuesta",
    pt: "Sem resposta",
    fr: "Pas de réponse",
    it: "Nessuna risposta",
    de: "Keine Antwort",
    ja: "回答なし",
    zh: "未作答",
    ru: "Нет ответа",
    ar: "بدون إجابة",
    hi: "कोई उत्तर नहीं",
  },
};
const MEMORY_DRAWER_COPY = {
  title: {
    en: "Memory",
    es: "Memoria",
    pt: "Memória",
    fr: "Mémoire",
    it: "Memoria",
    de: "Gedächtnis",
    ja: "メモリー",
    zh: "记忆",
    ru: "Память",
    ar: "الذاكرة",
    hi: "मेमोरी",
  },
  subtitle: {
    en: "What your companion saved to practice",
    es: "Lo que tu compañero guardó para practicar",
    pt: "O que seu companheiro guardou para praticar",
    fr: "Ce que ton compagnon a gardé à réviser",
    it: "Ciò che il tuo compagno ha salvato da ripassare",
    de: "Was dein Begleiter zum Üben gemerkt hat",
    ja: "あなたの相棒が練習用に保存したもの",
    zh: "你的伙伴为练习保存的内容",
    ru: "Что твой компаньон сохранил для практики",
    ar: "اللي حفظه رفيقك علشان تتمرن عليه",
    hi: "आपके साथी ने अभ्यास के लिए क्या सहेजा",
  },
  empty: {
    en: "Nothing saved yet. When something trips you up, your companion tucks it here for tomorrow.",
    es: "Nada guardado aún. Cuando algo te cueste, tu compañero lo guardará aquí para mañana.",
    pt: "Nada guardado ainda. Quando algo te pegar, seu companheiro guarda aqui para amanhã.",
    fr: "Rien de gardé pour l'instant. Quand quelque chose te bloque, ton compagnon le range ici pour demain.",
    it: "Ancora niente. Quando qualcosa ti mette in difficoltà, il tuo compagno lo salva qui per domani.",
    de: "Noch nichts gemerkt. Wenn dich etwas ins Stolpern bringt, legt es dein Begleiter für morgen hierher.",
    ja: "まだ何もありません。つまずいたことは、相棒が明日のためにここに保存します。",
    zh: "还没有保存内容。当你卡住时，伙伴会把它存到这里，留到明天。",
    ru: "Пока пусто. Когда что-то даётся трудно, компаньон сохранит это здесь на завтра.",
    ar: "لسه مفيش حاجة. لما حاجة تصعّب عليك، رفيقك يحفظها هنا لبكرة.",
    hi: "अभी कुछ सहेजा नहीं गया। जब कुछ कठिन लगेगा, आपका साथी उसे कल के लिए यहाँ रख देगा।",
  },
  todayHeading: {
    en: "Saved today",
    es: "Guardado hoy",
    pt: "Guardado hoje",
    fr: "Gardé aujourd'hui",
    it: "Salvato oggi",
    de: "Heute gemerkt",
    ja: "今日保存した分",
    zh: "今天保存",
    ru: "Сохранено сегодня",
    ar: "اتحفظ النهاردة",
    hi: "आज सहेजा",
  },
  yesterdayHeading: {
    en: "From yesterday",
    es: "De ayer",
    pt: "De ontem",
    fr: "D'hier",
    it: "Da ieri",
    de: "Von gestern",
    ja: "昨日の分",
    zh: "来自昨天",
    ru: "Со вчера",
    ar: "من إمبارح",
    hi: "कल से",
  },
  savedNotesHeading: {
    en: "Notes",
    es: "Notas",
    pt: "Notas",
    fr: "Notes",
    it: "Note",
    de: "Notizen",
    ja: "メモ",
    zh: "笔记",
    ru: "Заметки",
    ar: "الملاحظات",
    hi: "नोट्स",
  },
};
const MEMORY_STATUS_COPY = {
  captured: {
    en: "Saved for tomorrow",
    es: "Guardado para mañana",
    pt: "Guardado para amanhã",
    fr: "Gardé pour demain",
    it: "Salvato per domani",
    de: "Für morgen gemerkt",
    ja: "明日のために保存",
    zh: "为明天保存",
    ru: "Сохранено на завтра",
    ar: "محفوظ لبكرة",
    hi: "कल के लिए सहेजा",
  },
  queued_for_repair: {
    en: "Lined up to repair",
    es: "Listo para reparar",
    pt: "Pronto para reparar",
    fr: "Prêt à réparer",
    it: "Pronto da rinforzare",
    de: "Zum Auffrischen bereit",
    ja: "リペア予定",
    zh: "待修复",
    ru: "В очереди на повтор",
    ar: "جاهز للمراجعة",
    hi: "मरम्मत के लिए तैयार",
  },
  used_in_quest: {
    en: "In today's focus",
    es: "En el enfoque de hoy",
    pt: "No foco de hoje",
    fr: "Dans le focus du jour",
    it: "Nel focus di oggi",
    de: "Im heutigen Fokus",
    ja: "今日のフォーカスに登場",
    zh: "在今日重点中",
    ru: "В фокусе дня",
    ar: "في تركيز اليوم",
    hi: "आज के फ़ोकस में",
  },
  reinforced: {
    en: "Repaired",
    es: "Reparado",
    pt: "Reparado",
    fr: "Réparé",
    it: "Rinforzato",
    de: "Aufgefrischt",
    ja: "リペア済み",
    zh: "已修复",
    ru: "Повторено",
    ar: "اتراجع",
    hi: "मरम्मत हो गई",
  },
  expiring: {
    en: "Expires after today",
    es: "Expira después de hoy",
    pt: "Expira depois de hoje",
    fr: "Expire après aujourd'hui",
    it: "Scade dopo oggi",
    de: "Läuft nach heute ab",
    ja: "今日を過ぎると消えます",
    zh: "今天之后过期",
    ru: "Исчезнет после сегодня",
    ar: "هيختفي بعد النهاردة",
    hi: "आज के बाद समाप्त",
  },
};
function memoryStatusLabel(lang, status) {
  return memoryCopy(lang, MEMORY_STATUS_COPY[status] || MEMORY_STATUS_COPY.captured);
}
return {memoryStatusLabel,memoryCopy,normalizeSupportLanguage,DEFAULT_SUPPORT_LANGUAGE,getGermanCopy,MEMORY_STATUS_COPY,MEMORY_CARD_COPY,MEMORY_DRAWER_COPY};})();
// src/utils/companionMemory.js
const M2=(function(){const getLanguagePromptName=M0.getLanguagePromptName;
const normalizePlateLang=M6.normalizePlateLang;
const getLocalDayKey=M7.getLocalDayKey;
const normalizeSupportLanguage=M0.normalizeSupportLanguage;
const DEFAULT_SUPPORT_LANGUAGE=M0.DEFAULT_SUPPORT_LANGUAGE;
const memoryStatusLabel=M3.memoryStatusLabel;
const callResponses=callNativeResponses;
const DAY_MS = 24 * 60 * 60 * 1000;
const SUPPORT_SCRIPT_REQUIREMENTS = {
  ar: { name: "Arabic script", pattern: /[\u0600-\u06ff]/u },
  hi: { name: "Devanagari script", pattern: /[\u0900-\u097f]/u },
  ja: {
    name: "Japanese script",
    pattern: /[\u3040-\u30ff\u3400-\u9fff]/u,
  },
  ru: { name: "Cyrillic script", pattern: /[\u0400-\u04ff]/u },
  zh: { name: "Chinese characters", pattern: /[\u3400-\u9fff]/u },
};
const DISTINCTIVE_ENGLISH_WORDS = new Set([
  "answer",
  "answered",
  "captured",
  "correct",
  "ends",
  "exercise",
  "goodbye",
  "greeting",
  "greetings",
  "hello",
  "instead",
  "learner",
  "means",
  "mistake",
  "practice",
  "reinforced",
  "remember",
  "repaired",
  "said",
  "saved",
  "should",
  "starts",
  "tense",
  "today",
  "tomorrow",
  "word",
  "wrong",
  "your",
]);
function normalizeMemorySupportLang(supportLang) {
  return normalizeSupportLanguage(supportLang, DEFAULT_SUPPORT_LANGUAGE);
}
function supportLanguageGuard(supportLang) {
  const code = normalizeMemorySupportLang(supportLang);
  const languageName = getLanguagePromptName(code) || langName(code);
  const script = SUPPORT_SCRIPT_REQUIREMENTS[code];
  return [
    `The UI/support language is ${languageName}.`,
    `The "did" and "tip" values MUST be written entirely in natural ${languageName}.`,
    code === "en"
      ? ""
      : `Do not write either value in English and do not add an English translation.`,
    script
      ? `Use ${script.name}; do not romanize or transliterate the ${languageName} text.`
      : "",
  ]
    .filter(Boolean)
    .join(" ");
}
function distinctiveEnglishWordCount(text) {
  return (
    String(text || "")
      .toLowerCase()
      .match(/[a-z]+/g)
      ?.filter((word) => DISTINCTIVE_ENGLISH_WORDS.has(word)).length || 0
  );
}
function memoryTextMatchesSupportLanguage(text, supportLang) {
  const value = String(text || "").trim();
  if (!value) return true;
  const code = normalizeMemorySupportLang(supportLang);
  const script = SUPPORT_SCRIPT_REQUIREMENTS[code];
  if (script && !script.pattern.test(value)) return false;
  if (code === "en") return true;
  const englishWordCount = distinctiveEnglishWordCount(value);
  return script ? englishWordCount === 0 : englishWordCount < 2;
}
function cleanMemoryConceptForSupportLanguage(concept, supportLang) {
  const value = String(concept || "").trim();
  const code = normalizeMemorySupportLang(supportLang);
  if (!value || code === "en") return value;
  return value
    .replace(/\s*\(([^()]*)\)/g, (match, parenthetical) =>
      distinctiveEnglishWordCount(parenthetical) > 0 ? "" : match,
    )
    .replace(/\s+/g, " ")
    .trim();
}
function enrichmentMatchesSupportLanguage(fields, supportLang) {
  return (
    memoryTextMatchesSupportLanguage(fields?.mistake, supportLang) &&
    memoryTextMatchesSupportLanguage(fields?.tip, supportLang)
  );
}
function memoryNoteMatchesSupportLanguage(note, supportLang) {
  const normalizedSupportLang = normalizeMemorySupportLang(supportLang);
  return (
    normalizeMemorySupportLang(note?.supportLang) === normalizedSupportLang &&
    enrichmentMatchesSupportLanguage(note, normalizedSupportLang)
  );
}
const MEMORY_STATUS = {
  captured: "captured",
  queuedForRepair: "queued_for_repair",
  usedInQuest: "used_in_quest",
  reinforced: "reinforced",
  expired: "expired",
};
function getCompanionDayKey(now = new Date()) {
  return getLocalDayKey(now) || "";
}
function getYesterdayKey(now = new Date()) {
  return getLocalDayKey(new Date(now.getTime() - DAY_MS)) || "";
}
function readBucket(user, langKey) {
  const bucket = user?.companionMemory?.[langKey];
  const notes = Array.isArray(bucket?.notes) ? bucket.notes : [];
  return {
    notes,
    lastPrunedDayKey:
      typeof bucket?.lastPrunedDayKey === "string"
        ? bucket.lastPrunedDayKey
        : "",
  };
}
function getCompanionNotes(user = {}, targetLang = "es") {
  return readBucket(user, normalizePlateLang(targetLang)).notes;
}
function enrichNoteFields({
  concept,
  userAnswer,
  expectedAnswer,
  targetLang,
  supportLang,
  sourceMode,
}) {
  const targetName = langName(targetLang);
  const normalizedSupportLang = normalizeMemorySupportLang(supportLang);
  const supportName = langName(normalizedSupportLang);
  const languageGuard = supportLanguageGuard(normalizedSupportLang);
  const input = [
    `A learner studying ${targetName} just slipped up during a ${sourceMode} exercise.`,
    `Prompt / concept: ${concept}`,
    userAnswer
      ? `What the learner answered: ${userAnswer}`
      : `The learner could not produce an answer.`,
    expectedAnswer ? `Expected answer: ${expectedAnswer}` : "",
    `Explain the slip warmly and concretely so a teammate could repair it tomorrow.`,
    languageGuard,
    `Write "did" and "tip" in ${supportName}. Write "fix" in ${targetName} when it's a word/phrase, otherwise in ${supportName}.`,
    `Return ONLY strict minified JSON, no markdown, exactly:`,
    `{"did":"<${supportName} only: what specifically was wrong, <=14 words>","fix":"<the correct form or answer>","tip":"<${supportName} only: one short encouraging memory tip, <=16 words>"}`,
  ]
    .filter(Boolean)
    .join("\n");

  const parseFields = (raw) => {
    const parsed = parseBlueprintJson(raw); // tolerant {...} extractor, reused
    if (!parsed) return null;
    const did = String(parsed.did || "").trim().slice(0, 200);
    const fix = String(parsed.fix || "").trim().slice(0, 200);
    const tip = String(parsed.tip || "").trim().slice(0, 200);
    if (!did && !fix && !tip) return null;
    return { mistake: did, correction: fix, tip };
  };

  let fields = null;
  try {
    fields = parseFields(callResponses({ input }));
  } catch {
    return null;
  }
  if (!fields) return null;

  // Script-based support languages are easy to validate deterministically.
  // If the first pass leaks English, give the model one focused localization
  // pass. Never persist the leaked support text if that repair still fails.
  if (!enrichmentMatchesSupportLanguage(fields, normalizedSupportLang)) {
    const retryInput = [
      `Localize this language-learning memory record for a ${supportName} UI.`,
      languageGuard,
      `Keep "fix" in ${targetName}. Preserve its meaning exactly.`,
      `Return ONLY strict minified JSON with keys "did", "fix", and "tip".`,
      JSON.stringify({
        did: fields.mistake,
        fix: fields.correction || expectedAnswer || "",
        tip: fields.tip,
      }),
    ].join("\n");
    try {
      const repaired = parseFields(callResponses({ input: retryInput }));
      if (repaired) fields = repaired;
    } catch {
      // The original target-language correction remains useful below.
    }
  }

  if (!enrichmentMatchesSupportLanguage(fields, normalizedSupportLang)) {
    return {
      mistake: "",
      correction: String(expectedAnswer || fields.correction || "").slice(
        0,
        200,
      ),
      tip: "",
    };
  }
  return fields;
}
const MEMORY_SUMMARY_PROMPT_VERSION = "v3";
function memoryLogSignature(notes = [], supportLang = "en") {
  return `${MEMORY_SUMMARY_PROMPT_VERSION}|${supportLang}|${notes
    .map((n) => `${n.id}:${n.status}:${n.severity || 1}:${n.enriched ? 1 : 0}`)
    .join("|")}`;
}
function generateMemorySummaryText({ notes, langKey, supportLang }) {
  const targetName = langName(langKey);
  const supportName = langName(supportLang);
  const todayKey = getCompanionDayKey();
  const yKey = getYesterdayKey();
  const feed = notes.map((n) => ({
    when:
      n.createdDayKey === todayKey
        ? "today"
        : n.createdDayKey === yKey
          ? "yesterday"
          : n.createdDayKey,
    concept: cleanMemoryConceptForSupportLanguage(n.concept, supportLang),
    learnerAnswer: n.userAnswer || "",
    correctAnswer: n.expectedAnswer || n.correction || "",
    whatWentWrong: n.mistake || "",
    activity: n.sourceMode || "",
    status: memoryStatusLabel(supportLang, n.status),
    timesMissed: n.severity || 1,
  }));
  const input = [
    `You write the digest line at the top of a mistake log for a ${targetName} course. Here is the current log (JSON):`,
    JSON.stringify(feed),
    `Write a compact plain-text digest of the log in ${supportName}: the dominant pattern across the slips, what was repaired, and what is still open. Name the actual concepts, quoting ${targetName} words verbatim.`,
    `Never repeat JSON field names or internal status codes. Express each status naturally in ${supportName}.`,
    supportLanguageGuard(supportLang),
    `Dry, factual, matter-of-fact — like case notes. State only what the log shows. No greeting, no praise, no encouragement, no advice, no "we"/"let's", and do not address the learner. Terse fragments are fine. 1-3 short sentences, max 40 words, plain text only — no lists, no markdown, no emojis.`,
  ].join("\n");

  const cleanSummary = (raw) =>
    String(raw || "")
      .replace(/\s+/g, " ")
      .replace(/^["'“”]+|["'“”]+$/g, "")
      .trim()
      .slice(0, 480);

  let summary = "";
  try {
    summary = cleanSummary(callResponses({ input }));
  } catch {
    return "";
  }
  if (!summary) return "";
  if (!memoryTextMatchesSupportLanguage(summary, supportLang)) {
    const retryInput = [
      `Rewrite this mistake-log digest entirely in ${supportName}.`,
      supportLanguageGuard(supportLang),
      `Preserve quoted ${targetName} words verbatim. Do not repeat internal JSON keys or English status codes.`,
      `Return only the localized plain-text digest, with no markdown:`,
      summary,
    ].join("\n");
    try {
      summary = cleanSummary(callResponses({ input: retryInput }));
    } catch {
      return "";
    }
  }
  return memoryTextMatchesSupportLanguage(summary, supportLang) ? summary : "";
}
const BATCH_LANG_NAMES = {
  en: "English",
  es: "Spanish",
  pt: "Portuguese",
  fr: "French",
  it: "Italian",
  de: "German",
  ja: "Japanese",
  zh: "Chinese",
  ru: "Russian",
  ar: "Arabic",
  hi: "Hindi",
};
function langName(code) {
  return (
    getLanguagePromptName(code) ||
    BATCH_LANG_NAMES[normalizePlateLang(code)] ||
    BATCH_LANG_NAMES[code] ||
    code
  );
}
function parseBlueprintJson(raw) {
  if (!raw) return null;
  let text = String(raw).trim();
  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) text = fence[1].trim();
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) return null;
  try {
    const obj = JSON.parse(text.slice(start, end + 1));
    return obj && typeof obj === "object" ? obj : null;
  } catch {
    return null;
  }
}
return {generateMemorySummaryText,langName,getLanguagePromptName,BATCH_LANG_NAMES,normalizePlateLang,getCompanionDayKey,getLocalDayKey,getYesterdayKey,DAY_MS,cleanMemoryConceptForSupportLanguage,normalizeMemorySupportLang,normalizeSupportLanguage,DEFAULT_SUPPORT_LANGUAGE,distinctiveEnglishWordCount,DISTINCTIVE_ENGLISH_WORDS,memoryStatusLabel,supportLanguageGuard,SUPPORT_SCRIPT_REQUIREMENTS,callResponses,memoryTextMatchesSupportLanguage,enrichNoteFields,parseBlueprintJson,enrichmentMatchesSupportLanguage,memoryLogSignature,MEMORY_SUMMARY_PROMPT_VERSION,memoryNoteMatchesSupportLanguage,getCompanionNotes,readBucket,MEMORY_STATUS};})();
// src/utils/voiceJourneyCopy.js
const M4=(function(){
const en = {
  repairs: "Repairs", goals: "Goals", notes: "Notes", journey: "Journey",
  testJourney: "Test Journey · Session {n}",
  title: "Listen to how far you’ve come", subtitle: "Your practice. Your voice. Your journey.",
  session: "Session {n}", sessions: "{n} sessions completed", sessionCompleted: "1 session completed", rule: "One session is one fully completed Today’s Focus tasks.",
  next: "Next recording at session {n}", allUnlocked: "Every milestone unlocked. Your practice continues.",
  locked: "Locked", expired: "Expired", ready: "Ready to record", saved: "Recording saved", first: "Your starting point",
  unlocked: "You’ve unlocked a new voice memory", intro: "Save a short recording when you complete Today's Focus sessions. Return at each milestone to hear what changes.",
  promptLabel: "Your speaking prompt", prompt: "Introduce yourself, say something you enjoy, and ask a question.",
  promptHelp: "Choose something you can revisit. Use this same prompt for future recordings.",
  speakIn: "Speak in {language}. A few words are a great start.", privacy: "Recordings are encrypted and saved to your account. Only record what you want to keep. You can delete them anytime.",
  record: "Record my voice", stop: "Stop recording", save: "Save recording", again: "Try again", later: "Maybe later", done: "Done",
  limit: "Up to 45 seconds. Save only when you’re happy with it.", recording: "Recording · {n}s / 45s", starting: "Opening microphone…", saving: "Saving…",
  supportLabel: "How did you approach it?", independent: "On my own", hints: "With hints or a sentence starter",
  listen: "Listen", delete: "Delete recording", deleteConfirm: "Delete this recording?", cancel: "Keep it", deleted: "Recording deleted",
  captured: "Recorded at session {n}", compare: "Hear your starting point alongside this moment.", view: "View Journey",
  yourJourney: "Your Journey",
  error: "That didn’t work. Please try again.", micError: "Couldn’t open the microphone. Check microphone access and try again.",
  unsupported: "Recording isn’t supported in this browser. Try a browser with microphone recording support.",
  signer: "Your account extension needs NIP-44 encryption support to save or play private recordings.",
  loading: "Loading your journey…", empty: "Complete your first Today’s Focus quest to unlock your first voice memory.",
  baselineLoading: "Loading your original prompt…", playbackError: "Couldn’t play this recording in this browser.",
  download: "Download recording", ownVoice: "Your voice", preview: "Preview your recording", retry: "Try again",
  currentGoal: "Your goal", active: "Active", paused: "Paused", achieved: "Achieved",
  goalIntro: "What Piyali has learned from your practice toward this goal.",
  demonstrated: "What you’ve demonstrated", openCapabilities: "What you’re working on", usefulLanguage: "Useful expressions",
  nextPractice: "Next practice", todayAction: "Today’s action", why: "Why this helps", goalEmpty: "As you practice toward this goal, your learning evidence will appear here.",
  modeled: "With a model", prompted: "With prompts", lightlySupported: "With a little help", transferred: "Used in a new situation", recognition: "Recognition",
};
const es = {
  repairs: "Repasos", goals: "Metas", notes: "Notas", journey: "Camino",
  testJourney: "Probar camino · Sesión {n}",
  title: "Escucha cuánto has avanzado", subtitle: "Tu práctica. Tu voz. Tu camino.",
  session: "Sesión {n}", sessions: "{n} sesiones completadas", sessionCompleted: "1 sesión completada", rule: "Una sesión es una misión completa del Enfoque de hoy.",
  next: "Próxima grabación en la sesión {n}", allUnlocked: "Desbloqueaste todos los hitos. Tu práctica continúa.",
  locked: "Bloqueado", expired: "Expirado", ready: "Listo para grabar", saved: "Grabación guardada", first: "Tu punto de partida",
  unlocked: "Desbloqueaste un nuevo recuerdo de tu voz", intro: "Guarda una grabación corta cuando completes sesiones del Enfoque de hoy. Vuelve en cada hito para escuchar lo que cambia.",
  promptLabel: "Tu tema para hablar", prompt: "Preséntate, menciona algo que disfrutas y haz una pregunta.",
  promptHelp: "Elige algo que puedas retomar. Usa este mismo tema en futuras grabaciones.",
  speakIn: "Habla en {language}. Unas pocas palabras son un gran comienzo.", privacy: "Tus grabaciones se cifran y se guardan en tu cuenta. Graba solo lo que quieras conservar. Puedes borrarlas cuando quieras.",
  record: "Grabar mi voz", stop: "Detener grabación", save: "Guardar grabación", again: "Volver a intentar", later: "Quizás después", done: "Listo",
  limit: "Hasta 45 segundos. Guarda solo cuando estés a gusto con el resultado.", recording: "Grabando · {n}s / 45s", starting: "Abriendo el micrófono…", saving: "Guardando…",
  supportLabel: "¿Cómo lo hiciste?", independent: "Por mi cuenta", hints: "Con pistas o una frase de apoyo",
  listen: "Escuchar", delete: "Borrar grabación", deleteConfirm: "¿Borrar esta grabación?", cancel: "Conservar", deleted: "Grabación borrada",
  captured: "Grabado en la sesión {n}", compare: "Escucha tu punto de partida junto a este momento.", view: "Ver camino",
  yourJourney: "Tu camino",
  error: "No se pudo completar. Inténtalo de nuevo.", micError: "No se pudo abrir el micrófono. Revisa los permisos e inténtalo de nuevo.",
  unsupported: "Este navegador no permite grabar. Prueba otro navegador que admita grabación con micrófono.",
  signer: "Tu extensión de cuenta necesita cifrado NIP-44 para guardar o reproducir grabaciones privadas.",
  loading: "Cargando tu camino…", empty: "Completa tu primera misión del Enfoque de hoy para desbloquear tu primer recuerdo de voz.",
  baselineLoading: "Cargando tu tema original…", playbackError: "No se pudo reproducir esta grabación en este navegador.",
  download: "Descargar grabación", ownVoice: "Tu voz", preview: "Escucha tu grabación", retry: "Reintentar",
  currentGoal: "Tu meta", active: "Activa", paused: "En pausa", achieved: "Lograda",
  goalIntro: "Lo que Piyali ha aprendido de tu práctica hacia esta meta.",
  demonstrated: "Lo que has demostrado", openCapabilities: "Lo que estás practicando", usefulLanguage: "Expresiones útiles",
  nextPractice: "Próxima práctica", todayAction: "Acción de hoy", why: "Por qué ayuda", goalEmpty: "A medida que practiques hacia esta meta, aquí aparecerá la evidencia de tu aprendizaje.",
  modeled: "Con un modelo", prompted: "Con pistas", lightlySupported: "Con un poco de ayuda", transferred: "Usado en una situación nueva", recognition: "Reconocimiento",
};
const pt = {
  repairs: "Revisões", goals: "Metas", notes: "Notas", journey: "Jornada",
  testJourney: "Testar jornada · Sessão {n}",
  yourJourney: "Sua jornada", title: "Ouça o quanto você evoluiu", subtitle: "Sua prática. Sua voz. Sua jornada.",
  session: "Sessão {n}", sessions: "{n} sessões concluídas", sessionCompleted: "1 sessão concluída", rule: "Uma sessão = uma missão completa do Foco de hoje.",
  next: "Próxima gravação na sessão {n}", allUnlocked: "Todos os marcos desbloqueados. Sua prática continua.",
  locked: "Bloqueado", expired: "Expirado", ready: "Pronto para gravar", saved: "Gravação salva", first: "Seu ponto de partida",
  intro: "Salve uma gravação curta ao concluir sessões do Foco de hoje. Volte a cada marco para ouvir o que mudou.",
  record: "Gravar minha voz", stop: "Parar gravação", save: "Salvar gravação", again: "Tentar novamente", later: "Mais tarde", done: "Concluído",
  limit: "Até 45 segundos. Salve apenas quando estiver satisfeito.", recording: "Gravando · {n}s / 45s", starting: "Abrindo microfone…", saving: "Salvando…",
  view: "Ver jornada", download: "Baixar gravação", ownVoice: "Sua voz", preview: "Prévia da gravação", retry: "Tentar novamente",
  error: "Não funcionou. Tente novamente.", micError: "Não foi possível abrir o microfone. Verifique as permissões e tente novamente.",
  loading: "Carregando sua jornada…", empty: "Conclua sua primeira missão do Foco de hoje para desbloquear sua primeira memória de voz.",
};
const fr = {
  repairs: "Révisions", goals: "Objectifs", notes: "Notes", journey: "Parcours",
  testJourney: "Tester le parcours · Session {n}",
  yourJourney: "Votre parcours", title: "Écoutez le chemin parcouru", subtitle: "Votre pratique. Votre voix. Votre parcours.",
  session: "Session {n}", sessions: "{n} sessions terminées", sessionCompleted: "1 session terminée", rule: "Une session = une quête complète du Focus du jour.",
  next: "Prochain enregistrement à la session {n}", allUnlocked: "Toutes les étapes débloquées. Votre pratique continue.",
  locked: "Verrouillé", expired: "Expiré", ready: "Prêt à enregistrer", saved: "Enregistrement sauvegardé", first: "Votre point de départ",
  intro: "Enregistrez un court extrait lorsque vous terminez des sessions du Focus du jour. Revenez à chaque étape pour entendre vos progrès.",
  record: "Enregistrer ma voix", stop: "Arrêter l'enregistrement", save: "Enregistrer", again: "Réessayer", later: "Plus tard", done: "Terminé",
  limit: "Jusqu'à 45 secondes. Sauvegardez quand vous êtes satisfait.", recording: "Enregistrement · {n}s / 45s", starting: "Activation du micro…", saving: "Sauvegarde…",
  view: "Voir le parcours", download: "Télécharger l'enregistrement", ownVoice: "Votre voix", preview: "Aperçu de l'enregistrement", retry: "Réessayer",
  error: "Une erreur est survenue. Veuillez réessayer.", micError: "Impossible d'accéder au micro. Vérifiez les autorisations et réessayez.",
  loading: "Chargement de votre parcours…", empty: "Terminez votre première quête du Focus du jour pour débloquer votre premier enregistrement vocal.",
};
const it = {
  repairs: "Ripasso", goals: "Obiettivi", notes: "Note", journey: "Percorso",
  testJourney: "Prova percorso · Sessione {n}",
  yourJourney: "Il tuo percorso", title: "Ascolta quanta strada hai fatto", subtitle: "La tua pratica. La tua voce. Il tuo percorso.",
  session: "Sessione {n}", sessions: "{n} sessioni completate", sessionCompleted: "1 sessione completata", rule: "Una sessione = una missione completa del Focus di oggi.",
  next: "Prossima registrazione alla sessione {n}", allUnlocked: "Tutti i traguardi sbloccati. La tua pratica continua.",
  locked: "Bloccato", expired: "Scaduto", ready: "Pronto per registrare", saved: "Registrazione salvata", first: "Il tuo punto di partenza",
  intro: "Salva una breve registrazione quando completi le sessioni del Focus di oggi. Torna a ogni traguardo per ascoltare cosa cambia.",
  record: "Registra la mia voce", stop: "Interrompi registrazione", save: "Salva registrazione", again: "Riprova", later: "Più tardi", done: "Fatto",
  limit: "Fino a 45 secondi. Salva quando ti soddisfa.", recording: "Registrazione · {n}s / 45s", starting: "Apertura microfono…", saving: "Salvataggio…",
  view: "Vedi percorso", download: "Scarica registrazione", ownVoice: "La tua voce", preview: "Ascolta l'anteprima", retry: "Riprova",
  error: "Si è verificato un errore. Riprova.", micError: "Impossibile aprire il microfono. Controlla i permessi e riprova.",
  loading: "Caricamento percorso…", empty: "Completa la tua prima missione del Focus di oggi per sbloccare la tua prima registrazione vocale.",
};
const de = {
  repairs: "Nachbessern", goals: "Ziele", notes: "Notizen", journey: "Lernreise",
  testJourney: "Lernreise testen · Sitzung {n}",
  yourJourney: "Deine Lernreise", title: "Höre, wie weit du gekommen bist", subtitle: "Deine Übung. Deine Stimme. Deine Lernreise.",
  session: "Sitzung {n}", sessions: "{n} Sitzungen abgeschlossen", sessionCompleted: "1 Sitzung abgeschlossen", rule: "Eine Sitzung = eine vollständige Mission des Heutigen Fokus.",
  next: "Nächste Aufnahme bei Sitzung {n}", allUnlocked: "Alle Meilensteine freigeschaltet. Deine Übung geht weiter.",
  locked: "Gesperrt", expired: "Abgelaufen", ready: "Bereit zur Aufnahme", saved: "Aufnahme gespeichert", first: "Dein Ausgangspunkt",
  intro: "Speichere eine kurze Aufnahme, wenn du Sitzungen des Heutigen Fokus abschließt. Kehre bei jedem Meilenstein zurück, um deine Fortschritte zu hören.",
  record: "Meine Stimme aufnehmen", stop: "Aufnahme beenden", save: "Aufnahme speichern", again: "Erneut versuchen", later: "Später", done: "Fertig",
  limit: "Bis zu 45 Sekunden. Speichere erst, wenn du zufrieden bist.", recording: "Aufnahme · {n}s / 45s", starting: "Mikrofon wird aktiviert…", saving: "Wird gespeichert…",
  view: "Lernreise ansehen", download: "Aufnahme herunterladen", ownVoice: "Deine Stimme", preview: "Vorschau anhören", retry: "Erneut versuchen",
  error: "Das hat nicht geklappt. Bitte versuche es erneut.", micError: "Mikrofon konnte nicht geöffnet werden. Überprüfe die Berechtigungen und versuche es erneut.",
  loading: "Lernreise wird geladen…", empty: "Schließe deine erste Mission des Heutigen Fokus ab, um deine erste Sprachaufnahme freizuschalten.",
};
const ja = {
  repairs: "復習", goals: "目標", notes: "メモ", journey: "歩み",
  testJourney: "歩みをテスト · セッション {n}",
  yourJourney: "あなたの歩み", title: "成長した自分の声を聞いてみよう", subtitle: "あなたの練習。あなたの声。あなたの歩み。",
  session: "セッション {n}", sessions: "{n} 回のセッションを完了", sessionCompleted: "1 回のセッションを完了", rule: "1セッション = 「今日のフォーカス」のクエストを1つ完全に達成。",
  next: "次の録音：セッション {n}", allUnlocked: "すべてのマイルストーンを解除しました。練習を続けましょう。",
  locked: "未解除", expired: "期限切れ", ready: "録音可能", saved: "録音を保存しました", first: "最初のスタート地点",
  intro: "「今日のフォーカス」セッションを完了したら、短い音声を保存しましょう。各マイルストーンに戻って変化を聞き比べてみてください。",
  record: "声を録音する", stop: "録音を停止", save: "録音を保存", again: "もう一度録音", later: "後で", done: "完了",
  limit: "最大45秒。納得がいったら保存してください。", recording: "録音中 · {n}秒 / 45秒", starting: "マイクを起動中…", saving: "保存中…",
  view: "歩みを見る", download: "録音をダウンロード", ownVoice: "あなたの声", preview: "録音のプレビュー", retry: "再試行",
  error: "エラーが発生しました。もう一度お試しください。", micError: "マイクを開けませんでした。マイクへのアクセス権限を確認してください。",
  loading: "読み込み中…", empty: "「今日のフォーカス」を初めて達成すると、最初の声の記録が解除されます。",
};
const zh = {
  repairs: "巩固", goals: "目标", notes: "笔记", journey: "成长之路",
  testJourney: "测试成长之路 · 第 {n} 次练习",
  yourJourney: "你的成长之路", title: "听听你走了多远", subtitle: "你的练习。你的声音。你的成长之路。",
  session: "第 {n} 次练习", sessions: "已完成 {n} 次练习", sessionCompleted: "已完成 1 次练习", rule: "1次练习 = 完整完成一次“今日重点”任务。",
  next: "下一次录音在第 {n} 次练习", allUnlocked: "已解锁所有里程碑。继续保持练习！",
  locked: "未解锁", expired: "已过期", ready: "可以录音", saved: "录音已保存", first: "你的起点",
  intro: "完成“今日重点”练习后保存一段简短录音。在每个里程碑回顾以聆听自己的变化。",
  record: "录制我的声音", stop: "停止录音", save: "保存录音", again: "重新录制", later: "稍后再说", done: "完成",
  limit: "最多45秒。满意后再保存。", recording: "录音中 · {n}秒 / 45秒", starting: "正在开启麦克风…", saving: "正在保存…",
  view: "查看成长之路", download: "下载录音", ownVoice: "你的声音", preview: "试听录音", retry: "重试",
  error: "操作失败，请重试。", micError: "无法访问麦克风，请检查麦克风权限后重试。",
  loading: "正在加载…", empty: "完成你的第一个“今日重点”任务即可解锁首个语音记录。",
};
const ru = {
  repairs: "Повторение", goals: "Цели", notes: "Заметки", journey: "Путь",
  testJourney: "Протестировать путь · Сессия {n}",
  yourJourney: "Ваш путь", title: "Послушайте, как далеко вы продвинулись", subtitle: "Ваша практика. Ваш голос. Ваш путь.",
  session: "Сессия {n}", sessions: "Завершено сессий: {n}", sessionCompleted: "Завершена 1 сессия", rule: "Одна сессия = одно полностью выполненное задание Фокуса дня.",
  next: "Следующая запись на сессии {n}", allUnlocked: "Все этапы разблокированы. Продолжайте практику.",
  locked: "Заблокировано", expired: "Истекло", ready: "Готово к записи", saved: "Запись сохранена", first: "Ваша отправная точка",
  intro: "Сохраняйте короткую запись после завершения сессий Фокуса дня. Возвращайтесь на каждом этапе, чтобы услышать, как меняется ваша речь.",
  record: "Записать мой голос", stop: "Остановить запись", save: "Сохранить запись", again: "Попробовать снова", later: "Позже", done: "Готово",
  limit: "До 45 секунд. Сохраняйте, когда будете довольны результатом.", recording: "Запись · {n}с / 45с", starting: "Включение микрофона…", saving: "Сохранение…",
  view: "Посмотреть путь", download: "Скачать запись", ownVoice: "Ваш голос", preview: "Прослушать запись", retry: "Повторить",
  error: "Не удалось выполнить. Пожалуйста, попробуйте снова.", micError: "Не удалось включить микрофон. Проверьте разрешения и попробуйте снова.",
  loading: "Загрузка…", empty: "Выполните первое задание Фокуса дня, чтобы открыть первую запись голоса.",
};
const hi = {
  repairs: "दोहराव", goals: "लक्ष्य", notes: "नोट्स", journey: "सफ़र",
  testJourney: "सफ़र का परीक्षण · सत्र {n}",
  yourJourney: "आपका सफ़र", title: "सुनें कि आप कितनी दूर आ गए हैं", subtitle: "आपका अभ्यास। आपकी आवाज़। आपका सफ़र।",
  session: "सत्र {n}", sessions: "{n} सत्र पूरे हुए", sessionCompleted: "1 सत्र पूरा हुआ", rule: "एक सत्र = आज का फ़ोकस का एक पूर्ण कार्य।",
  next: "अगली रिकॉर्डिंग सत्र {n} पर", allUnlocked: "सभी पड़ाव अनलॉक हो गए। आपका अभ्यास जारी है।",
  locked: "लॉक किया गया", expired: "समाप्त", ready: "रिकॉर्ड करने के लिए तैयार", saved: "रिकॉर्डिंग सहेजी गई", first: "आपका शुरुआती बिंदु",
  intro: "आज का फ़ोकस सत्र पूरा करने पर एक छोटी रिकॉर्डिंग सहेजें। क्या बदलाव आया है, यह सुनने के लिए हर पड़ाव पर लौटें।",
  record: "अपनी आवाज़ रिकॉर्ड करें", stop: "रिकॉर्डिंग रोकें", save: "रिकॉर्डिंग सहेजें", again: "फिर से प्रयास करें", later: "बाद में", done: "हो गया",
  limit: "45 सेकंड तक। संतुष्ट होने पर ही सहेजें।", recording: "रिकॉर्डिंग · {n} से / 45 से", starting: "माइक शुरू हो रहा है…", saving: "सहेजा जा रहा है…",
  view: "सफ़र देखें", download: "रिकॉर्डिंग डाउनलोड करें", ownVoice: "आपकी आवाज़", preview: "रिकॉर्डिंग सुनें", retry: "पुनः प्रयास करें",
  error: "यह काम नहीं किया। कृपया पुनः प्रयास करें।", micError: "माइक नहीं खोला जा सका। अनुमति जांचें और पुनः प्रयास करें।",
  loading: "लोड हो रहा है…", empty: "अपनी पहली आवाज़ रिकॉर्डिंग अनलॉक करने के लिए आज का फ़ोकस का पहला कार्य पूरा करें।",
};
const ar = {
  repairs: "مراجعة", goals: "أهداف", notes: "ملاحظات", journey: "رحلة",
  testJourney: "اختبار الرحلة · الجلسة {n}",
  yourJourney: "رحلتك", title: "استمع إلى مدى تقدمك", subtitle: "تدريبك. صوتك. رحلتك.",
  session: "الجلسة {n}", sessions: "اكتملت {n} جلسات", sessionCompleted: "اكتملت جلسة واحدة", rule: "جلسة واحدة = مهمة تركيز اليوم مكتملة بالكامل.",
  next: "التسجيل التالي في الجلسة {n}", allUnlocked: "تم فتح جميع المراحل. استمر في التدريب.",
  locked: "مقفل", expired: "منتهي الصلاحية", ready: "جاهز للتسجيل", saved: "تم حفظ التسجيل", first: "نقطة بدايتك",
  intro: "احفظ تسجيلاً قصيرًا عند إكمال جلسات تركيز اليوم. عُد عند كل مرحلة لتستمع إلى التغييرات.",
  record: "تسجيل صوتي", stop: "إيقاف التسجيل", save: "حفظ التسجيل", again: "المحاولة مرة أخرى", later: "ربما لاحقًا", done: "تم",
  limit: "حتى 45 ثانية. احفظ فقط عندما تكون راضيًا عنه.", recording: "جارٍ التسجيل · {n}ث / 45ث", starting: "جارٍ فتح الميكروفون…", saving: "جارٍ الحفظ…",
  view: "عرض الرحلة", download: "تنزيل التسجيل", ownVoice: "صوتك", preview: "معاينة التسجيل", retry: "إعادة المحاولة",
  error: "لم ينجح ذلك. يرجى المحاولة مرة أخرى.", micError: "تعذر فتح الميكروفون. يرجى التحقق من الأذونات والمحاولة مرة أخرى.",
  loading: "جارٍ التحميل…", empty: "أكمل أول مهمة في تركيز اليوم لفتح أول تسجيل صوتي لك.",
};
const tabs = {
  pt: ["Revisões", "Metas", "Notas", "Jornada"], fr: ["Révisions", "Objectifs", "Notes", "Parcours"],
  it: ["Ripasso", "Obiettivi", "Note", "Percorso"], de: ["Nachbessern", "Ziele", "Notizen", "Lernreise"],
  ja: ["復習", "目標", "メモ", "歩み"], zh: ["巩固", "目标", "笔记", "成长之路"],
  ru: ["Повторение", "Цели", "Заметки", "Путь"], hi: ["दोहराव", "लक्ष्य", "नोट्स", "सफ़र"], ar: ["مراجعة", "أهداف", "ملاحظات", "رحلة"],
};
const dictionaries = { en, es, pt, fr, it, de, ja, zh, ru, hi, ar };
function journeyCopy(lang, key, values = {}) {
  if (key === "sessions" && Number(values.n) === 1) key = "sessionCompleted";
  const normalized = String(lang || "").toLowerCase().split(/[-_]/)[0];
  const tabIndex = ["repairs", "goals", "notes", "journey"].indexOf(key);
  const dict = dictionaries[lang] || dictionaries[normalized];
  const activeLang = dictionaries[lang] ? lang : (dictionaries[normalized] ? normalized : "en");
  const value = dict?.[key] || (tabIndex >= 0 ? tabs[activeLang]?.[tabIndex] : null) || en[key] || key;
  return value.replace(/\{(\w+)\}/g, (match, name) => values[name] ?? match);
}
return {journeyCopy,dictionaries,en,es,pt,fr,it,de,ja,zh,ru,hi,ar,tabs};})();
// src/utils/voiceJourneyModel.js
const M5=(function(){
const JOURNEY_MILESTONES = Object.freeze([1, 5, 15, 30, 45, 60, 90, 120, 150]);
const QUESTS_PER_JOURNEY_SESSION = 1;
function journeySessionCount(journey = {}) {
  const count = Number(journey.completedQuests);
  return Math.floor((Number.isFinite(count) ? Math.max(0, count) : 0) / QUESTS_PER_JOURNEY_SESSION);
}
function completeJourneyQuest(journey = {}, alreadyCounted = false, now = new Date().toISOString()) {
  if (alreadyCounted) return journey;
  const previousCount = Number(journey.completedQuests);
  const completedQuests = (Number.isFinite(previousCount) ? Math.max(0, Math.floor(previousCount)) : 0) + 1;
  const next = { ...journey, version: 1, completedQuests, updatedAt: now };
  next.unlockedAt = { ...journey.unlockedAt };
  for (const milestone of JOURNEY_MILESTONES) {
    if (milestone <= journeySessionCount(next) && !next.unlockedAt[milestone]) next.unlockedAt[milestone] = now;
  }
  return next;
}
function pendingJourneyMilestone(journey = {}) {
  const milestone = JOURNEY_MILESTONES.findLast(number => number <= journeySessionCount(journey));
  return milestone && milestone > (Number(journey.lastPromptedMilestone) || 0) && !journey.recordings?.[milestone]
    ? milestone : null;
}
function journeyBaseline(journey = {}) {
  // Filling in a skipped early milestone must not replace the learner's
  // actual first recording as their starting point.
  return JOURNEY_MILESTONES.filter(milestone => journey.recordings?.[milestone])
    .sort((a, b) => (Date.parse(journey.recordings[a].createdAt) || 0) - (Date.parse(journey.recordings[b].createdAt) || 0) || a - b)[0] || null;
}
function isJourneyMilestoneExpired(journey = {}, milestone) {
  const index = JOURNEY_MILESTONES.indexOf(milestone);
  if (index === -1) return false;
  if (journey.recordings?.[milestone]) return false;
  const count = journeySessionCount(journey);
  if (count < milestone) return false;
  const nextMilestone = JOURNEY_MILESTONES[index + 1];
  return Boolean(nextMilestone && count >= nextMilestone);
}
function canRecordJourneyMilestone(journey = {}, milestone) {
  if (!JOURNEY_MILESTONES.includes(milestone)) return false;
  if (journey?.recordings?.[milestone]) return false;
  const count = journeySessionCount(journey);
  if (milestone > count) return false;
  if (isJourneyMilestoneExpired(journey, milestone)) return false;
  return true;
}
return {JOURNEY_MILESTONES,journeySessionCount,QUESTS_PER_JOURNEY_SESSION,completeJourneyQuest,pendingJourneyMilestone,journeyBaseline,isJourneyMilestoneExpired,canRecordJourneyMilestone};})();
// src/components/NotesDrawer.jsx
const M11=(function(){
const CEFR_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"];
const CEFR_COLORS = {
  A1: "#3B82F6",
  A2: "#22C55E",
  B1: "#EAB308",
  B2: "#F97316",
  C1: "#EF4444",
  C2: "#A855F7",
};
const CEFR_TEXT_COLORS = {
  A1: "white",
  A2: "#083344",
  B1: "#3b2f13",
  B2: "#431407",
  C1: "white",
  C2: "white",
};
const MODULE_LABELS = {
  flashcard: {
    en: "Flashcard",
    es: "Tarjeta",
    pt: "Cartão",
    it: "Scheda",
    fr: "Carte",
    ja: "フラッシュカード",
    hi: "फ्लैशकार्ड",
    ar: "بطاقة",
    zh: "抽认卡",
    de: "Karte",
  },
  vocabulary: {
    en: "Vocabulary",
    es: "Vocabulario",
    pt: "Vocabulário",
    it: "Vocabolario",
    fr: "Vocabulaire",
    ja: "語彙",
    hi: "शब्दावली",
    ar: "المفردات",
    zh: "词汇",
    de: "Wortschatz",
  },
  grammar: {
    en: "Grammar",
    es: "Gramática",
    pt: "Gramática",
    it: "Grammatica",
    fr: "Grammaire",
    ja: "文法",
    hi: "व्याकरण",
    ar: "القواعد",
    zh: "语法",
    de: "Grammatik",
  },
};
return {CEFR_LEVELS,CEFR_COLORS,CEFR_TEXT_COLORS,MODULE_LABELS};})();
// src/components/CompanionMemoryList.jsx
const M12=(function(){const MEMORY_STATUS=M2.MEMORY_STATUS;
const SOURCE_LABELS = {
  flashcard: {
    en: "Flashcard",
    es: "Tarjeta",
    pt: "Cartão",
    it: "Scheda",
    fr: "Carte",
    de: "Karte",
    ja: "カード",
    zh: "抽认卡",
    ru: "Карточка",
    hi: "फ्लैशकार्ड",
    ar: "بطاقة",
  },
  vocabulary: {
    en: "Vocabulary",
    es: "Vocabulario",
    pt: "Vocabulário",
    it: "Vocabolario",
    fr: "Vocabulaire",
    de: "Wortschatz",
    ja: "語彙",
    zh: "词汇",
    ru: "Лексика",
    hi: "शब्दावली",
    ar: "مفردات",
  },
  grammar: {
    en: "Grammar",
    es: "Gramática",
    pt: "Gramática",
    it: "Grammatica",
    fr: "Grammaire",
    de: "Grammatik",
    ja: "文法",
    zh: "语法",
    ru: "Грамматика",
    hi: "व्याकरण",
    ar: "قواعد",
  },
  tutor: {
    en: "Tutor",
    es: "Tutor",
    pt: "Tutor",
    it: "Tutor",
    fr: "Tuteur",
    de: "Tutor",
    ja: "チューター",
    zh: "导师",
    ru: "Репетитор",
    hi: "ट्यूटर",
    ar: "المعلّم",
  },
  conversation: {
    en: "Conversation",
    es: "Conversación",
    pt: "Conversa",
    it: "Conversazione",
    fr: "Conversation",
    de: "Gespräch",
    ja: "会話",
    zh: "对话",
    ru: "Разговор",
    hi: "बातचीत",
    ar: "محادثة",
  },
  phonics: {
    en: "Phonics",
    es: "Fonética",
    pt: "Fonética",
    it: "Fonetica",
    fr: "Phonétique",
    de: "Phonetik",
    ja: "発音",
    zh: "拼读",
    ru: "Фонетика",
    hi: "ध्वनि",
    ar: "صوتيات",
  },
};
const STATUS_ACCENT = {
  captured: { fg: "#2563EB", bg: "rgba(37, 99, 235, 0.14)" },
  used_in_quest: { fg: "#7C3AED", bg: "rgba(124, 58, 237, 0.14)" },
  reinforced: { fg: "#0d9488", bg: "rgba(13, 148, 136, 0.16)" },
  expiring: { fg: "#C2620E", bg: "rgba(194, 98, 14, 0.16)" },
};
function resolveStatus(note, isYesterday) {
  if (note.status === MEMORY_STATUS.reinforced) return "reinforced";
  if (note.status === MEMORY_STATUS.usedInQuest) return "used_in_quest";
  // Yesterday's leftovers that weren't reinforced will be pruned tonight.
  if (isYesterday) return "expiring";
  return "captured";
}
return {SOURCE_LABELS,STATUS_ACCENT,resolveStatus,MEMORY_STATUS};})();
// src/utils/noteGeneration.js
const M1=(function(){const getLanguagePromptName=M0.getLanguagePromptName;
const callResponses=callNativeResponses;
const DEFAULT_RESPONSES_MODEL='source-default';
const LANG_NAME = (code) => getLanguagePromptName(code) || code;
function generateNoteContent({
  concept,
  userAnswer,
  wasCorrect,
  targetLang,
  supportLang,
  cefrLevel,
  moduleType,
}) {
  const targetLangName = LANG_NAME(targetLang);
  const supportLangName = LANG_NAME(supportLang);

  const prompt = `You are a language learning assistant. Generate a study note for a ${cefrLevel} level student learning ${targetLangName}.

Topic/Concept: "${concept}"
${
  userAnswer
    ? `User's answer: "${userAnswer}" (${wasCorrect ? "correct" : "incorrect"})`
    : ""
}
Module: ${moduleType}

Generate:
1. EXAMPLE: A short, practical example sentence in ${targetLangName} using this concept. Keep it appropriate for ${cefrLevel} level.
2. SUMMARY: A 1-2 sentence explanation in ${supportLangName} that helps the student remember this concept.${
    !wasCorrect ? " Include a brief tip about common mistakes." : ""
  }

Reply in this exact JSON format (no markdown, just raw JSON):
{"example": "...", "summary": "..."}`;

  try {
    const response = callResponses({
      model: DEFAULT_RESPONSES_MODEL,
      input: prompt,
    });

    // Try to parse JSON from response
    const trimmed = (response || "").trim();

    // Find JSON in response
    const jsonMatch = trimmed.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        example: parsed.example || `Example for "${concept}"`,
        summary: parsed.summary || `Study note for "${concept}"`,
      };
    }

    // Fallback if parsing fails
    return {
      example: `Example: ${concept}`,
      summary: `Practice this ${cefrLevel} ${moduleType} concept regularly.`,
    };
  } catch (error) {
    console.error("Error generating note content:", error);
    // Return fallback content
    return {
      example: `${concept}`,
      summary: `Keep practicing this ${cefrLevel} level concept.`,
    };
  }
}
return {generateNoteContent,LANG_NAME,getLanguagePromptName,callResponses,DEFAULT_RESPONSES_MODEL};})();
return {run:function(operation,json){p=JSON.parse(json||'{}');requests=[];index=0;const now=p.now?new SystemDate(p.now):new SystemDate();Date=class extends SystemDate{constructor(...args){super(...(args.length?args:[now.getTime()]));}static now(){return now.getTime();}};const lang=p.language||'en',locale=M0.getLanguageLocale(lang);const clearAllLabel=lang === "ja"
      ? "すべて削除"
      : lang === "zh"
        ? "全部清除"
        : lang === "fr"
          ? "Tout effacer"
          : lang === "pt"
            ? "Limpar tudo"
            : lang === "it"
              ? "Cancella tutto"
              : lang === "de"
                ? "Alle löschen"
                : lang === "hi"
                  ? "सब साफ़ करें"
                  : lang === "ar"
                    ? "امسح الكل"
                    : lang === "es"
                      ? "Borrar todo"
                      : "Clear all";
const lessonLabel=lang === "ja"
      ? "レッスン"
      : lang === "zh"
        ? "课程"
        : lang === "fr"
          ? "Lecon"
          : lang === "pt"
            ? "Licao"
            : lang === "it"
              ? "Lezione"
              : lang === "de"
                ? "Lektion"
                : lang === "hi"
                  ? "पाठ"
                  : lang === "ar"
                    ? "الدرس"
                    : lang === "es"
                      ? "Lección"
                      : "Lesson";
const noNotesLabel=lang === "ja"
      ? "メモなし"
      : lang === "zh"
        ? "没有笔记"
        : lang === "fr"
          ? "Aucune note"
          : lang === "pt"
            ? "Sem notas"
            : lang === "it"
              ? "Nessuna nota"
              : lang === "de"
                ? "Keine Notizen"
                : lang === "hi"
                  ? "कोई नोट नहीं"
                  : lang === "ar"
                    ? "مفيش ملاحظات"
                    : lang === "es"
                      ? "Sin notas"
                      : "No notes";
const noteTitleFallback=lang === "ja"
      ? "メモ"
      : lang === "zh"
        ? "笔记"
        : lang === "fr"
          ? "Note"
          : lang === "pt"
            ? "Nota"
            : lang === "it"
              ? "Nota"
              : lang === "de"
                ? "Notiz"
                : lang === "hi"
                  ? "नोट"
                  : lang === "ar"
                    ? "ملاحظة"
                    : lang === "es"
                      ? "Nota"
                      : "Note";
const formatNoteCountLabel=(count) => {
    const formattedCount = new Intl.NumberFormat(locale).format(count);

    if (lang === "ja") {
      return `${formattedCount}件のメモ`;
    }

    if (lang === "zh") {
      return `${formattedCount} 条笔记`;
    }

    if (lang === "ar") {
      return `${formattedCount} ${count === 1 ? "ملاحظة" : "ملاحظات"}`;
    }

    if (lang === "fr") {
      return `${formattedCount} ${count === 1 ? "note" : "notes"}`;
    }

    if (lang === "pt") {
      return `${formattedCount} ${count === 1 ? "nota" : "notas"}`;
    }

    if (lang === "it") {
      return `${formattedCount} ${count === 1 ? "nota" : "note"}`;
    }

    if (lang === "de") {
      return `${formattedCount} ${count === 1 ? "Notiz" : "Notizen"}`;
    }

    if (lang === "hi") {
      return `${formattedCount} नोट`;
    }

    if (lang === "es") {
      return `${formattedCount} ${count === 1 ? "nota" : "notas"}`;
    }

    return `${formattedCount} ${count === 1 ? "note" : "notes"}`;
  };
const listenLabel=lang === "ja"
      ? "聞く"
      : lang === "zh"
        ? "聆听"
        : lang === "fr"
          ? "Ecouter"
          : lang === "pt"
            ? "Ouvir"
            : lang === "it"
              ? "Ascolta"
              : lang === "de"
                ? "Anhören"
                : lang === "hi"
                  ? "सुनें"
                  : lang === "ar"
                    ? "اسمع"
                    : lang === "es"
                      ? "Escuchar"
                      : "Listen";
const deleteNoteLabel=lang === "ja"
      ? "メモを削除"
      : lang === "zh"
        ? "删除笔记"
        : lang === "fr"
          ? "Supprimer la note"
          : lang === "pt"
            ? "Excluir nota"
            : lang === "it"
              ? "Elimina nota"
              : lang === "de"
                ? "Notiz löschen"
                : lang === "hi"
                  ? "नोट हटाएं"
                  : lang === "ar"
                    ? "احذف الملاحظة"
                    : lang === "es"
                      ? "Eliminar nota"
                      : "Delete note";
const m=M2,c=M3,j=M5;let value;
if(operation==='note')value=M1.generateNoteContent({...p,targetLang:p.target||'es',supportLang:lang});
else if(operation==='summary')value=m.generateMemorySummaryText({notes:p.notes||[],langKey:p.target||'es',supportLang:lang});
else if(operation==='enrich')value=m.enrichNoteFields({...p.note,targetLang:p.target||'es',supportLang:lang});
else if(operation==='signature')value=m.memoryLogSignature(p.notes||[],lang);
else if(operation==='localized')value=m.memoryNoteMatchesSupportLanguage(p.note,lang);
else if(operation==='clean')value=m.cleanMemoryConceptForSupportLanguage(p.text,lang);
else if(operation==='status')value=M12.resolveStatus(p.note,p.yesterday);
else if(operation==='journey')value={count:j.journeySessionCount(p.data),pending:j.pendingJourneyMilestone(p.data),baseline:j.journeyBaseline(p.data),milestones:j.JOURNEY_MILESTONES.map(n=>({number:n,expired:j.isJourneyMilestoneExpired(p.data,n),ready:j.canRecordJourneyMilestone(p.data,n)}))};
else if(operation==='copy')value={locale,drawer:Object.fromEntries(Object.entries(c.MEMORY_DRAWER_COPY).map(([k,v])=>[k,c.memoryCopy(lang,v)])),card:Object.fromEntries(Object.entries(c.MEMORY_CARD_COPY).map(([k,v])=>[k,c.memoryCopy(lang,v)])),status:Object.fromEntries(['captured','used_in_quest','reinforced','expiring'].map(k=>[k,c.memoryStatusLabel(lang,k)])),source:Object.fromEntries(Object.entries(M12.SOURCE_LABELS).map(([k,v])=>[k,c.memoryCopy(lang,v)])),accent:M12.STATUS_ACCENT,levels:M11.CEFR_LEVELS,colors:M11.CEFR_COLORS,textColors:M11.CEFR_TEXT_COLORS,modules:Object.fromEntries(Object.entries(M11.MODULE_LABELS).map(([k,v])=>[k,v[lang]||v.en])),labels:{clearAllLabel,lessonLabel,noNotesLabel,noteTitleFallback,listenLabel,deleteNoteLabel,count:formatNoteCountLabel(p.count||0)}};
else if(operation==='journeyCopy')value=M4.journeyCopy(lang,p.key,p.values||{});
else throw Error('Unknown Memory policy '+operation);
return JSON.stringify({value:value??null,requests});}};})()