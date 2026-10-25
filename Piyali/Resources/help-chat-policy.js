var PiyaliHelp = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // <stdin>
  var stdin_exports = {};
  __export(stdin_exports, {
    api: () => api
  });

  // flags:flags
  var brazilianFlag = () => null;
  var chineseFlag = () => null;
  var egyptianFlag = () => null;
  var frenchFlag = () => null;
  var germanFlag = () => null;
  var greekFlag = () => null;
  var indianFlag = () => null;
  var irishFlag = () => null;
  var italianFlag = () => null;
  var japaneseFlag = () => null;
  var mexicanFlag = () => null;
  var netherlandsFlag = () => null;
  var polishFlag = () => null;
  var russianFlag = () => null;
  var usaFlag = () => null;

  // ../nosabos/nosabos/src/constants/supportLanguages.js
  var SUPPORT_LANGUAGE_CODES = Object.freeze([
    "en",
    "es",
    "pt",
    "it",
    "fr",
    "de",
    "ja",
    "hi",
    "ar",
    "zh"
  ]);

  // ../nosabos/nosabos/src/constants/languages.js
  var DEFAULT_SUPPORT_LANGUAGE = "en";
  var DEFAULT_TARGET_LANGUAGE = "es";
  var LANGUAGE_META = [
    {
      value: "ar",
      languageKey: "language_ar",
      practiceKey: "onboarding_practice_ar",
      tier: "stable",
      supportTier: "stable",
      practiceEnabled: false,
      flag: egyptianFlag
    },
    {
      value: "nl",
      languageKey: "language_nl",
      practiceKey: "onboarding_practice_nl",
      tier: "stable",
      flag: netherlandsFlag
    },
    {
      value: "en",
      languageKey: "language_en",
      practiceKey: "onboarding_practice_en",
      tier: "stable",
      flag: usaFlag
    },
    {
      value: "fr",
      languageKey: "language_fr",
      practiceKey: "onboarding_practice_fr",
      tier: "stable",
      flag: frenchFlag
    },
    {
      value: "de",
      languageKey: "language_de",
      practiceKey: "onboarding_practice_de",
      tier: "stable",
      flag: germanFlag
    },
    {
      value: "it",
      languageKey: "language_it",
      practiceKey: "onboarding_practice_it",
      tier: "stable",
      flag: italianFlag
    },
    {
      value: "hi",
      languageKey: "language_hi",
      practiceKey: "onboarding_practice_hi",
      tier: "stable",
      supportTier: "stable",
      practiceEnabled: false,
      flag: indianFlag
    },
    {
      value: "zh",
      languageKey: "language_zh",
      practiceKey: "onboarding_practice_zh",
      tier: "stable",
      supportTier: "stable",
      practiceEnabled: false,
      flag: chineseFlag
    },
    {
      value: "pt",
      languageKey: "language_pt",
      practiceKey: "onboarding_practice_pt",
      tier: "stable",
      flag: brazilianFlag
    },
    {
      value: "es",
      languageKey: "language_es",
      practiceKey: "onboarding_practice_es",
      tier: "stable",
      flag: mexicanFlag
    },
    {
      value: "nah",
      languageKey: "language_nah",
      practiceKey: "onboarding_practice_nah",
      tier: "alpha",
      // Temporarily hidden from practice-language selectors. Keep the language
      // registered so existing user data and the underlying implementation work.
      selectorHidden: true,
      flag: mexicanFlag
    },
    {
      value: "yua",
      languageKey: "language_yua",
      practiceKey: "onboarding_practice_yua",
      tier: "alpha",
      // Temporarily hidden from practice-language selectors. Keep the language
      // registered so existing user data and the underlying implementation work.
      selectorHidden: true,
      flag: mexicanFlag
    },
    {
      value: "el",
      languageKey: "language_el",
      practiceKey: "onboarding_practice_el",
      tier: "beta",
      flag: greekFlag
    },
    {
      value: "ja",
      languageKey: "language_ja",
      practiceKey: "onboarding_practice_ja",
      tier: "beta",
      supportTier: "stable",
      flag: japaneseFlag
    },
    {
      value: "ru",
      languageKey: "language_ru",
      practiceKey: "onboarding_practice_ru",
      tier: "beta",
      flag: russianFlag
    },
    {
      value: "pl",
      languageKey: "language_pl",
      practiceKey: "onboarding_practice_pl",
      tier: "beta",
      flag: polishFlag
    },
    {
      value: "ga",
      languageKey: "language_ga",
      practiceKey: "onboarding_practice_ga",
      tier: "beta",
      flag: irishFlag
    }
  ];
  var SUPPORTED_LANGUAGE_CODES_SET = new Set(
    LANGUAGE_META.map((item) => item.value)
  );
  var PRACTICE_LANGUAGE_CODES_BASE = LANGUAGE_META.filter(
    (item) => item.practiceEnabled !== false
  ).map((item) => item.value);
  var PRACTICE_LANGUAGE_CODES_SET = new Set(PRACTICE_LANGUAGE_CODES_BASE);
  var SUPPORT_LANGUAGE_CODES_BASE = [...SUPPORT_LANGUAGE_CODES];
  var SUPPORT_LANGUAGE_CODES_SET = new Set(SUPPORT_LANGUAGE_CODES_BASE);
  var normalizeCode = (raw) => String(raw || "").trim().toLowerCase();
  var normalizeSupportedCode = (raw) => {
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
  var PRACTICE_LANGUAGE_CODES = [...PRACTICE_LANGUAGE_CODES_BASE];
  var SUPPORT_LANGUAGE_CODES2 = SUPPORT_LANGUAGE_CODES_BASE.filter(
    (code) => SUPPORTED_LANGUAGE_CODES_SET.has(code)
  );
  var ALPHABET_LANGUAGE_CODES = [...PRACTICE_LANGUAGE_CODES];
  function normalizeSupportLanguage(code, fallback = DEFAULT_SUPPORT_LANGUAGE) {
    const normalized = normalizeSupportedCode(code);
    if (SUPPORT_LANGUAGE_CODES_SET.has(normalized)) return normalized;
    return fallback;
  }
  function normalizePracticeLanguage(code, fallback = DEFAULT_TARGET_LANGUAGE) {
    const normalized = normalizeSupportedCode(code);
    if (SUPPORTED_LANGUAGE_CODES_SET.has(normalized)) return normalized;
    return fallback;
  }

  // ../nosabos/nosabos/src/utils/germanCopy.js
  var GERMAN_COPY = {
    "Save failed": "Speichern fehlgeschlagen",
    "Error al guardar": "Speichern fehlgeschlagen",
    "Show translation": "\xDCbersetzung anzeigen",
    "Subscription passcode is not configured": "Abonnement-Zugangscode ist nicht konfiguriert",
    "Passcode accepted": "Zugangscode akzeptiert",
    "Failed to save passcode": "Zugangscode konnte nicht gespeichert werden",
    "Connect your account to use this feature.": "Verbinde dein Konto, um diese Funktion zu nutzen.",
    "Account required": "Konto erforderlich",
    "Connect your account to analyze your level.": "Verbinde dein Konto, um dein Niveau zu analysieren.",
    "Analysis complete": "Analyse abgeschlossen",
    "Assigned level: {level}.": "Zugewiesenes Niveau: {level}.",
    "Analysis failed": "Analyse fehlgeschlagen",
    "Please try again later.": "Bitte versuche es sp\xE4ter erneut.",
    "Couldn't find the current user.": "Der aktuelle Benutzer wurde nicht gefunden.",
    Help: "Hilfe",
    Cards: "Karten",
    Notes: "Notizen",
    Alphabet: "Alphabet",
    Path: "Pfad",
    Conversation: "Gespr\xE4ch",
    Mode: "Modus",
    "Start proficiency test": "Einstufungstest starten",
    "Lesson Complete!": "Lektion abgeschlossen!",
    "XP Earned": "XP verdient",
    "Experience Points": "Erfahrungspunkte",
    Continue: "Weiter",
    "Keep learning": "Weiterlernen",
    Goal: "Ziel",
    "Daily goal reached!": "Tagesziel erreicht!",
    "You hit your XP goal for today.": "Du hast dein XP-Ziel f\xFCr heute erreicht.",
    "Streak protected": "Serie gesch\xFCtzt",
    "Enter the passcode": "Zugangscode eingeben",
    Verifying: "Wird gepr\xFCft",
    Submit: "Absenden",
    "Invalid passcode. Please try again.": "Ung\xFCltiger Zugangscode. Bitte versuche es erneut.",
    "Browser is blocking the mic for this site. Click the lock icon \u2192 Site settings \u2192 Microphone \u2192 Allow, then reload.": "Der Browser blockiert das Mikrofon f\xFCr diese Website. Klicke auf das Schloss \u2192 Website-Einstellungen \u2192 Mikrofon \u2192 Zulassen und lade neu.",
    "Microphone requires HTTPS (or localhost). Open the app over https:// and try again.": "Das Mikrofon ben\xF6tigt HTTPS (oder localhost). \xD6ffne die App \xFCber https:// und versuche es erneut.",
    "The microphone is busy (Zoom/Teams/Discord). Close other apps using the mic and try again.": "Das Mikrofon ist belegt (Zoom/Teams/Discord). Schlie\xDFe andere Apps mit Mikrofonzugriff und versuche es erneut.",
    "No microphone was found or it\u2019s disabled at the OS level.": "Es wurde kein Mikrofon gefunden oder es ist im Betriebssystem deaktiviert.",
    "Requested audio constraints are not supported by your mic.": "Die angeforderten Audioeinstellungen werden von deinem Mikrofon nicht unterst\xFCtzt.",
    "Microphone error. If permissions look allowed, reload the page and try again.": "Mikrofonfehler. Wenn die Berechtigungen korrekt aussehen, lade die Seite neu und versuche es erneut.",
    "Your chats": "Deine Chats",
    "No saved chats": "Keine gespeicherten Chats",
    Delete: "L\xF6schen",
    "Morpheme mode": "Morphem-Modus",
    "Break down words": "W\xF6rter zerlegen",
    "New chat": "Neuer Chat",
    Menu: "Men\xFC",
    Morphemes: "Morpheme",
    "Save chat": "Chat speichern",
    "What do you want to learn today?": "Was m\xF6chtest du heute lernen?",
    "Stop voice chat": "Sprachchat stoppen",
    "Start voice chat": "Sprachchat starten",
    Play: "Abspielen",
    "Ask about this lesson...": "Frag etwas zu dieser Lektion...",
    Send: "Senden",
    Stop: "Stopp",
    "Immersion & Score": "Immersion & Punktzahl",
    "3 tasks to use your language outside the app": "3 Aufgaben, um deine Sprache au\xDFerhalb der App zu nutzen",
    "Next batch in": "N\xE4chster Stapel in",
    "Creating tasks...": "Aufgaben werden erstellt...",
    "Try again": "Erneut versuchen",
    "No tasks yet.": "Noch keine Aufgaben.",
    "Claim +15 XP": "+15 XP abholen",
    Claiming: "Wird abgeholt",
    Claimed: "Abgeholt",
    "Failed to award reward": "Belohnung konnte nicht vergeben werden",
    "Ready to refresh": "Bereit zum Aktualisieren",
    "Could not generate tasks. Please try again.": "Aufgaben konnten nicht erstellt werden. Bitte versuche es erneut.",
    "Enter a display name": "Anzeigenamen eingeben",
    "Display name updated": "Anzeigename aktualisiert",
    Error: "Fehler",
    "Get full access to more education apps and content": "Erhalte vollen Zugriff auf weitere Bildungs-Apps und Inhalte",
    "Create display name": "Anzeigenamen erstellen",
    "Saving\u2026": "Wird gespeichert\u2026",
    "Wallet not ready": "Wallet nicht bereit",
    "Please try again in a moment.": "Bitte versuche es gleich noch einmal.",
    "Invalid key": "Ung\xFCltiger Schl\xFCssel",
    "Key must start with 'nsec'.": "Der Schl\xFCssel muss mit \u201Ensec\u201C beginnen.",
    "Couldn't create wallet": "Wallet konnte nicht erstellt werden",
    "Failed to create wallet": "Wallet konnte nicht erstellt werden",
    "Select an identity": "Identit\xE4t ausw\xE4hlen",
    "Choose who receives your deposits before continuing.": "W\xE4hle aus, wer deine Einzahlungen erh\xE4lt, bevor du fortf\xE4hrst.",
    "Couldn't create invoice": "Rechnung konnte nicht erstellt werden",
    "Failed to initiate deposit": "Einzahlung konnte nicht gestartet werden",
    "Address copied": "Adresse kopiert",
    "Lightning invoice copied to clipboard.": "Lightning-Rechnung in die Zwischenablage kopiert.",
    "Bitcoin wallet": "Bitcoin-Wallet",
    "Loading wallet\u2026": "Wallet wird geladen\u2026",
    "Choose a recipient": "Empf\xE4nger ausw\xE4hlen",
    "Select an option to enable deposits.": "W\xE4hle eine Option, um Einzahlungen zu aktivieren.",
    "Create wallet": "Wallet erstellen",
    "Creating wallet\u2026": "Wallet wird erstellt\u2026",
    "Copy key": "Schl\xFCssel kopieren",
    "Copy Secret Key": "Geheimen Schl\xFCssel kopieren",
    "Secret key required": "Geheimer Schl\xFCssel erforderlich",
    "Maybe later": "Vielleicht sp\xE4ter",
    Done: "Fertig",
    Close: "Schlie\xDFen",
    "View site": "Website ansehen",
    "Join us on Patreon": "Unterst\xFCtze uns auf Patreon",
    Join: "Beitreten",
    "Change display name": "Anzeigenamen \xE4ndern",
    "Display name": "Anzeigename",
    "Save": "Speichern",
    "Saving": "Speichern"
  };
  var getGermanCopy = (text) => {
    if (typeof text !== "string") return "";
    return GERMAN_COPY[text] || "";
  };

  // ../nosabos/nosabos/src/utils/assistantLanguagePolicy.js
  function buildAssistantLanguagePolicy({
    supportLanguageName,
    targetLanguageName
  }) {
    const support = String(supportLanguageName || "the support language").trim();
    const target = String(targetLanguageName || "the target language").trim();
    return [
      `LANGUAGE CONTRACT: Write every learner-facing sentence in ${support}.`,
      `Use ${target} only for exact exercise words, answers, or examples that the learner is studying.`,
      `Do not use English or any other third language unless it is ${support} or ${target}.`,
      `Translate all headings, grammar terms, labels, definitions, glosses, and parenthetical explanations into ${support}.`,
      `Before responding, silently rewrite any third-language prose into ${support}.`
    ].join(" ");
  }

  // ../nosabos/nosabos/src/utils/helpChatMorpheme.js
  var hasMorphemeBreakdown = (text) => /(^|\n)\s*\*\*[^*\n]+\*\*\s*=\s*\S+/m.test(String(text || ""));
  var cleanPlanValue = (value) => String(value || "").replace(/^\/\/\s*/, "").replace(/^[“”"']+|[“”"']+$/g, "").trim();
  var buildMorphemeTranslationPlanPrompt = ({
    targetLanguageName,
    supportLanguageName,
    question
  }) => [
    "Determine the translation direction for a language-learning morpheme tool.",
    `The target/practice language is ${targetLanguageName}.`,
    `The learner's support language is ${supportLanguageName}.`,
    "",
    "If SOURCE_TEXT is in the support language:",
    `- translation: translate it into ${targetLanguageName}.`,
    "- targetText: use that target-language translation.",
    "",
    "If SOURCE_TEXT is in the target language:",
    `- translation: translate it into ${supportLanguageName}.`,
    "- targetText: copy the original target-language SOURCE_TEXT.",
    "",
    "targetText must ALWAYS contain the target-language wording whose morphemes should be analyzed.",
    "For names or forms that conventionally stay unchanged, preserve them.",
    "Return ONLY valid JSON with exactly these string fields:",
    '{"translation":"direct translation of the complete source","targetText":"exact target-language text to analyze"}',
    "",
    "SOURCE_TEXT:",
    question
  ].join("\n");
  var parseMorphemeTranslationPlan = (text) => {
    const raw = String(text || "").trim();
    const jsonStart = raw.indexOf("{");
    const jsonEnd = raw.lastIndexOf("}");
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      try {
        const parsed = JSON.parse(raw.slice(jsonStart, jsonEnd + 1));
        return {
          translation: cleanPlanValue(parsed?.translation),
          targetText: cleanPlanValue(parsed?.targetText)
        };
      } catch {
      }
    }
    const translation = raw.match(
      /(?:^|\n)\s*(?:translation|traducción)\s*:\s*(.+)/i
    )?.[1];
    const targetText = raw.match(
      /(?:^|\n)\s*(?:targetText|target text)\s*:\s*(.+)/i
    )?.[1];
    return {
      translation: cleanPlanValue(translation),
      targetText: cleanPlanValue(targetText)
    };
  };
  var buildMorphemeBreakdownPrompt = ({
    targetLanguageName,
    supportLanguageName,
    targetText
  }) => [
    `Analyze the morphemes in this exact ${targetLanguageName} text:`,
    targetText,
    "",
    "Analyze all and only the target-language words above.",
    "Do not translate or analyze any source-language wording.",
    "Do not create an example sentence, add related words, or rewrite the text.",
    `Write every morpheme meaning and grammatical explanation in ${supportLanguageName}.`,
    "Return ONLY the breakdown, with no heading or introductory paragraph.",
    "",
    "Use this format for each target-language word:",
    "**word** = part1 + part2 + part3",
    "- part1: meaning or grammatical function",
    "- part2: meaning or grammatical function",
    '\u2192 "concise whole-word gloss"',
    "",
    "If a word cannot be meaningfully divided, do not invent a split:",
    "**word** = word",
    "- word: single morpheme (brief meaning or function)",
    '\u2192 "concise whole-word gloss"'
  ].join("\n");

  // <stdin>
  var ARABIC_SUPPORT_COPY = {
    "No messages": "\u0645\u0627 \u0641\u064A\u0634 \u0631\u0633\u0627\u0626\u0644",
    "No messages to save.": "\u0645\u0627 \u0641\u064A\u0634 \u0631\u0633\u0627\u0626\u0644 \u062A\u062A\u0633\u062C\u0651\u0644.",
    "Saved chat": "\u0645\u062D\u0627\u062F\u062B\u0629 \u0645\u062D\u0641\u0648\u0638\u0629",
    "Chat saved": "\u0627\u062A\u062D\u0641\u0638\u062A \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629",
    "Chat deleted": "\u0627\u062A\u062D\u0630\u0641\u062A \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629",
    "Sorry, I couldn\u2019t complete that request. Please try again.": "\u0622\u0633\u0641\u060C \u0645\u0627 \u0642\u062F\u0631\u062A\u0634 \u0623\u0643\u0645\u0651\u0644 \u0627\u0644\u0637\u0644\u0628 \u062F\u0647. \u062C\u0631\u0651\u0628 \u0645\u0631\u0629 \u062A\u0627\u0646\u064A\u0629.",
    "Chat error": "\u062E\u0637\u0623 \u0641\u064A \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629",
    "Connection error": "\u062E\u0637\u0623 \u0641\u064A \u0627\u0644\u0627\u062A\u0635\u0627\u0644",
    "Your chats": "\u0645\u062D\u0627\u062F\u062B\u0627\u062A\u0643",
    "No saved chats": "\u0645\u0627 \u0641\u064A\u0634 \u0645\u062D\u0627\u062F\u062B\u0627\u062A \u0645\u062D\u0641\u0648\u0638\u0629",
    Delete: "\u062D\u0630\u0641",
    "Morpheme mode": "\u0648\u0636\u0639 \u0627\u0644\u0645\u0648\u0631\u0641\u064A\u0645\u0627\u062A",
    "Break down words": "\u0642\u0633\u0651\u0645 \u0627\u0644\u0643\u0644\u0645\u0627\u062A",
    "New chat": "\u0645\u062D\u0627\u062F\u062B\u0629 \u062C\u062F\u064A\u062F\u0629",
    Help: "\u0645\u0633\u0627\u0639\u062F\u0629",
    Menu: "\u0627\u0644\u0642\u0627\u0626\u0645\u0629",
    Morphemes: "\u0645\u0648\u0631\u0641\u064A\u0645\u0627\u062A",
    "Save chat": "\u0627\u062D\u0641\u0638 \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629",
    "What do you want to learn today?": "\u062D\u0627\u0628\u0628 \u062A\u062A\u0639\u0644\u0645 \u0625\u064A\u0647 \u0627\u0644\u0646\u0647\u0627\u0631\u062F\u0647\u061F",
    "Stop voice chat": "\u0623\u0648\u0642\u0641 \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629 \u0627\u0644\u0635\u0648\u062A\u064A\u0629",
    "Start voice chat": "\u0627\u0628\u062F\u0623 \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629 \u0627\u0644\u0635\u0648\u062A\u064A\u0629",
    Play: "\u062A\u0634\u063A\u064A\u0644",
    "Ask about this lesson...": "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0627\u0644\u062F\u0631\u0633 \u062F\u0647...",
    Send: "\u0625\u0631\u0633\u0627\u0644",
    Stop: "\u0625\u064A\u0642\u0627\u0641"
  };
  var CHINESE_SUPPORT_COPY = {
    "No messages": "\u6CA1\u6709\u6D88\u606F",
    "No messages to save.": "\u6CA1\u6709\u53EF\u4FDD\u5B58\u7684\u6D88\u606F\u3002",
    "Saved chat": "\u5DF2\u4FDD\u5B58\u7684\u804A\u5929",
    "Chat saved": "\u804A\u5929\u5DF2\u4FDD\u5B58",
    "Chat deleted": "\u804A\u5929\u5DF2\u5220\u9664",
    "Sorry, I couldn\u2019t complete that request. Please try again.": "\u62B1\u6B49\uFF0C\u6211\u65E0\u6CD5\u5B8C\u6210\u8FD9\u4E2A\u8BF7\u6C42\u3002\u8BF7\u518D\u8BD5\u4E00\u6B21\u3002",
    "Chat error": "\u804A\u5929\u9519\u8BEF",
    "Connection error": "\u8FDE\u63A5\u9519\u8BEF",
    "Your chats": "\u4F60\u7684\u804A\u5929",
    "No saved chats": "\u6CA1\u6709\u4FDD\u5B58\u7684\u804A\u5929",
    Delete: "\u5220\u9664",
    "Morpheme mode": "\u8BED\u7D20\u6A21\u5F0F",
    "Break down words": "\u62C6\u89E3\u8BCD\u8BED",
    "New chat": "\u65B0\u804A\u5929",
    Help: "\u5E2E\u52A9",
    Menu: "\u83DC\u5355",
    Morphemes: "\u8BED\u7D20",
    "Save chat": "\u4FDD\u5B58\u804A\u5929",
    "What do you want to learn today?": "\u4ECA\u5929\u4F60\u60F3\u5B66\u4EC0\u4E48\uFF1F",
    "Stop voice chat": "\u505C\u6B62\u8BED\u97F3\u804A\u5929",
    "Start voice chat": "\u5F00\u59CB\u8BED\u97F3\u804A\u5929",
    Play: "\u64AD\u653E",
    "Ask about this lesson...": "\u8BE2\u95EE\u8FD9\u4E2A\u8BFE\u7A0B...",
    Send: "\u53D1\u9001",
    Stop: "\u505C\u6B62"
  };
  var LANG_COLORS = {
    es: { bg: "yellow.500", label: "ES" },
    en: { bg: "blue.600", label: "EN" },
    pt: { bg: "green.600", label: "PT" },
    fr: { bg: "purple.600", label: "FR" },
    it: { bg: "orange.600", label: "IT" },
    hi: { bg: "orange.500", label: "HI" },
    zh: { bg: "red.600", label: "ZH" },
    nl: { bg: "orange.400", label: "NL" },
    nah: { bg: "teal.600", label: "NAH" },
    ru: { bg: "cyan.600", label: "RU" },
    de: { bg: "var(--app-gray-500-surface)", label: "DE" },
    el: { bg: "blue.400", label: "EL" },
    pl: { bg: "pink.600", label: "PL" },
    ga: { bg: "green.500", label: "GA" },
    yua: { bg: "purple.500", label: "YUA" }
  };
  function supportCopy(lang, en, es, it, fr, ja, pt = null, hi = null, ar = null) {
    if (lang === "de") return getGermanCopy(en) || en;
    if (lang === "zh") return CHINESE_SUPPORT_COPY[en] || en;
    if (lang === "ar") {
      if (ar) return ar;
      return ARABIC_SUPPORT_COPY[en] || en;
    }
    if (lang === "ja") return ja || en;
    if (lang === "fr") return fr || en;
    if (lang === "it") return it || en;
    if (lang === "pt") return pt || en;
    if (lang === "hi") return hi || en;
    if (lang === "es") return es || en;
    return en;
  }
  var nameForLanguage = (code) => {
    return {
      es: "Spanish (espa\xF1ol)",
      en: "English",
      pt: "Portuguese (portugu\xEAs brasileiro)",
      fr: "French (fran\xE7ais)",
      it: "Italian (italiano)",
      hi: "Hindi (\u0939\u093F\u0902\u0926\u0940)",
      ja: "Japanese (\u65E5\u672C\u8A9E)",
      ar: "Egyptian Arabic (\u0627\u0644\u0639\u0631\u0628\u064A\u0629 \u0627\u0644\u0645\u0635\u0631\u064A\u0629)",
      zh: "Mandarin Chinese (\u666E\u901A\u8BDD\u4E2D\u6587)",
      nl: "Dutch (Nederlands)",
      nah: "Eastern Huasteca Nahuatl (n\xE1huatl huasteco oriental)",
      ru: "Russian (\u0440\u0443\u0441\u0441\u043A\u0438\u0439)",
      de: "German (Deutsch)",
      el: "Greek (\u0395\u03BB\u03BB\u03B7\u03BD\u03B9\u03BA\u03AC)",
      pl: "Polish (polski)",
      ga: "Irish (Gaeilge)",
      yua: "Yucatec Maya (maaya t'aan)"
    }[code] || code;
  };
  var splitMainAndGloss = (text) => {
    const lines = String(text || "").split("\n");
    const i = lines.findIndex((l) => l.trim().startsWith("// "));
    if (i === -1) return { main: text, gloss: "" };
    const gloss = lines[i].replace(/^\/\/\s?/, "").trim();
    const main = lines.filter((_, idx) => idx !== i).join("\n").trim();
    return { main, gloss };
  };
  var getOrderedMessages = (list = []) => list.map((message, index) => ({
    message,
    index,
    sortOrder: Number.isFinite(message?.sortOrder) ? message.sortOrder : index
  })).sort((a, b) => {
    if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
    const aCreatedAt = Number.isFinite(a.message?.createdAt) ? a.message.createdAt : 0;
    const bCreatedAt = Number.isFinite(b.message?.createdAt) ? b.message.createdAt : 0;
    if (aCreatedAt !== bCreatedAt) return aCreatedAt - bCreatedAt;
    return a.index - b.index;
  }).map(({ message }) => message);
  var api = { run(op, json) {
    const p = JSON.parse(json || "{}"), progress = p.progress || {}, appLanguage = p.appLanguage || "en", uiLang = normalizeSupportLanguage(appLanguage, DEFAULT_SUPPORT_LANGUAGE), messages = p.messages || [], question = p.question || "", morphemeMode = false, buildInstruction = () => {
      const lvl = progress?.level || "beginner";
      const supportRaw = progress?.supportLang === "bilingual" ? "bilingual" : normalizeSupportLanguage(
        progress?.supportLang,
        DEFAULT_SUPPORT_LANGUAGE
      );
      const supportLang = supportRaw === "bilingual" ? normalizeSupportLanguage(appLanguage, DEFAULT_SUPPORT_LANGUAGE) : supportRaw;
      const targetLang = normalizePracticeLanguage(progress?.targetLang, "es");
      const primaryLang = supportLang;
      const focus = (progress?.helpRequest || "").slice(0, 200);
      const showTranslations = typeof progress?.showTranslations === "boolean" ? progress.showTranslations : true;
      const strict = primaryLang === "es" ? "Responde totalmente en espa\xF1ol (idioma de apoyo/soporte), aunque el usuario escriba en otro idioma." : primaryLang === "zh" ? "\u8BF7\u5B8C\u5168\u4F7F\u7528\u666E\u901A\u8BDD\u4E2D\u6587\u4F5C\u4E3A\u652F\u6301\u8BED\u8A00\u56DE\u7B54\uFF0C\u5373\u4F7F\u7528\u6237\u7528\u5176\u4ED6\u8BED\u8A00\u4E66\u5199\u3002" : primaryLang === "ar" ? "\u0631\u062F \u0628\u0627\u0644\u0643\u0627\u0645\u0644 \u0628\u0627\u0644\u0645\u0635\u0631\u064A/\u0627\u0644\u0639\u0631\u0628\u064A\u0629 \u0627\u0644\u0645\u0635\u0631\u064A\u0629 \u0643\u0644\u063A\u0629 \u0627\u0644\u062F\u0639\u0645\u060C \u062D\u062A\u0649 \u0644\u0648 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645 \u0643\u062A\u0628 \u0628\u0644\u063A\u0629 \u062A\u0627\u0646\u064A\u0629." : primaryLang === "en" ? "Respond entirely in English (the support language), even if the user writes in another language." : `Respond entirely in ${nameForLanguage(
        primaryLang
      )} (support language), even if the user writes in another language.`;
      const levelHint = (() => {
        if (primaryLang === "es") {
          return lvl === "beginner" ? "Usa oraciones cortas y simples." : lvl === "intermediate" ? "S\xE9 conciso y natural." : "S\xE9 muy breve y con tono nativo.";
        }
        if (primaryLang === "pt") {
          return lvl === "beginner" ? "Use frases curtas e simples." : lvl === "intermediate" ? "Seja conciso e natural." : "Seja bem breve e com tom nativo.";
        }
        if (primaryLang === "ar") {
          return lvl === "beginner" ? "\u0627\u0633\u062A\u062E\u062F\u0645 \u062C\u0645\u0644 \u0642\u0635\u064A\u0631\u0629 \u0648\u0628\u0633\u064A\u0637\u0629." : lvl === "intermediate" ? "\u062E\u0644\u064A\u0643 \u0645\u062E\u062A\u0635\u0631 \u0648\u0637\u0628\u064A\u0639\u064A." : "\u062E\u0644\u064A\u0643 \u0645\u062E\u062A\u0635\u0631 \u062C\u062F\u064B\u0627 \u0648\u0637\u0628\u064A\u0639\u064A.";
        }
        if (primaryLang === "hi") {
          return lvl === "beginner" ? "\u091B\u094B\u091F\u0947 \u0914\u0930 \u0938\u0930\u0932 \u0935\u093E\u0915\u094D\u092F \u092A\u094D\u0930\u092F\u094B\u0917 \u0915\u0930\u0947\u0902\u0964" : lvl === "intermediate" ? "\u0938\u0902\u0915\u094D\u0937\u093F\u092A\u094D\u0924 \u0914\u0930 \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0930\u0939\u0947\u0902\u0964" : "\u092C\u0939\u0941\u0924 \u0938\u0902\u0915\u094D\u0937\u093F\u092A\u094D\u0924 \u0914\u0930 \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0930\u0939\u0947\u0902\u0964";
        }
        if (primaryLang === "zh") {
          return lvl === "beginner" ? "\u4F7F\u7528\u7B80\u77ED\u3001\u7B80\u5355\u7684\u53E5\u5B50\u3002" : lvl === "intermediate" ? "\u4FDD\u6301\u7B80\u6D01\u81EA\u7136\u3002" : "\u975E\u5E38\u7B80\u6D01\uFF0C\u5E76\u4F7F\u7528\u81EA\u7136\u8BED\u6C14\u3002";
        }
        if (primaryLang === "en") {
          return lvl === "beginner" ? "Use short, simple sentences." : lvl === "intermediate" ? "Be concise and natural." : "Be very succinct and native-like.";
        }
        return lvl === "beginner" ? "Use short, simple sentences." : lvl === "intermediate" ? "Be concise and natural." : "Be succinct and native-like.";
      })();
      const glossLang = showTranslations && targetLang !== primaryLang ? targetLang : null;
      const glossHuman = glossLang ? nameForLanguage(glossLang) : "";
      const supportNote = primaryLang === "pt" ? `Explique e oriente em ${nameForLanguage(
        primaryLang
      )}. Inclua exemplos ou frases em ${nameForLanguage(
        targetLang
      )} apenas quando ajudarem, mas mantenha a explica\xE7\xE3o em ${nameForLanguage(
        primaryLang
      )}.` : primaryLang === "ar" ? `\u0627\u0634\u0631\u062D \u0648\u0648\u062C\u0651\u0647 \u0628\u0640 ${nameForLanguage(
        primaryLang
      )}. \u0636\u064A\u0641 \u0623\u0645\u062B\u0644\u0629 \u0623\u0648 \u062C\u0645\u0644 \u0628\u0640 ${nameForLanguage(
        targetLang
      )} \u0628\u0633 \u0644\u0645\u0627 \u062A\u0643\u0648\u0646 \u0645\u0641\u064A\u062F\u0629\u060C \u0648\u062E\u0644\u064A \u0627\u0644\u0634\u0631\u062D \u0627\u0644\u0623\u0633\u0627\u0633\u064A \u0628\u0640 ${nameForLanguage(
        primaryLang
      )}.` : primaryLang === "hi" ? `${nameForLanguage(
        primaryLang
      )} \u092E\u0947\u0902 \u0938\u092E\u091D\u093E\u090F\u0901 \u0914\u0930 \u092E\u093E\u0930\u094D\u0917\u0926\u0930\u094D\u0936\u0928 \u0926\u0947\u0902\u0964 ${nameForLanguage(
        targetLang
      )} \u0915\u0947 \u0909\u0926\u093E\u0939\u0930\u0923 \u092F\u093E \u0935\u093E\u0915\u094D\u092F \u0915\u0947\u0935\u0932 \u0924\u092D\u0940 \u0936\u093E\u092E\u093F\u0932 \u0915\u0930\u0947\u0902 \u091C\u092C \u0935\u0947 \u092E\u0926\u0926 \u0915\u0930\u0947\u0902, \u0932\u0947\u0915\u093F\u0928 \u092E\u0941\u0916\u094D\u092F \u0935\u094D\u092F\u093E\u0916\u094D\u092F\u093E ${nameForLanguage(
        primaryLang
      )} \u092E\u0947\u0902 \u0930\u0916\u0947\u0902\u0964` : primaryLang === "zh" ? `\u7528${nameForLanguage(
        primaryLang
      )}\u89E3\u91CA\u548C\u6307\u5BFC\u3002\u53EA\u6709\u5728\u6709\u5E2E\u52A9\u65F6\u624D\u52A0\u5165${nameForLanguage(
        targetLang
      )}\u7684\u4F8B\u53E5\u6216\u77ED\u8BED\uFF0C\u4F46\u4E3B\u8981\u89E3\u91CA\u5FC5\u987B\u4FDD\u6301${nameForLanguage(
        primaryLang
      )}\u3002` : `Explica y gu\xEDa en ${nameForLanguage(
        primaryLang
      )}. Incluye ejemplos o frases en ${nameForLanguage(
        targetLang
      )} solo cuando ayuden, pero mant\xE9n la explicaci\xF3n en ${nameForLanguage(
        primaryLang
      )}.`;
      const glossLine = glossLang ? primaryLang === "pt" ? `Depois da explica\xE7\xE3o, adicione uma \xFAnica linha de exemplo ou tradu\xE7\xE3o em ${glossHuman}. Coloque-a em uma nova linha que comece com "// ".` : primaryLang === "ar" ? `\u0628\u0639\u062F \u0627\u0644\u0634\u0631\u062D\u060C \u0636\u064A\u0641 \u0633\u0637\u0631 \u0648\u0627\u062D\u062F \u0628\u0633 \u0643\u0645\u062B\u0627\u0644 \u0623\u0648 \u062A\u0631\u062C\u0645\u0629 \u0628\u0640 ${glossHuman}. \u0627\u0628\u062F\u0623 \u0627\u0644\u0633\u0637\u0631 \u0627\u0644\u062C\u062F\u064A\u062F \u0628\u0640 "// ".` : primaryLang === "hi" ? `\u0935\u094D\u092F\u093E\u0916\u094D\u092F\u093E \u0915\u0947 \u092C\u093E\u0926 ${glossHuman} \u092E\u0947\u0902 \u0909\u0926\u093E\u0939\u0930\u0923 \u092F\u093E \u0905\u0928\u0941\u0935\u093E\u0926 \u0915\u0940 \u0915\u0947\u0935\u0932 \u090F\u0915 \u092A\u0902\u0915\u094D\u0924\u093F \u091C\u094B\u0921\u093C\u0947\u0902\u0964 \u0909\u0938\u0947 \u0928\u0908 \u092A\u0902\u0915\u094D\u0924\u093F \u092E\u0947\u0902 "// " \u0938\u0947 \u0936\u0941\u0930\u0942 \u0915\u0930\u0947\u0902\u0964` : `Despu\xE9s de la explicaci\xF3n, a\xF1ade una sola l\xEDnea de ejemplo o traducci\xF3n en ${glossHuman}. Ponla en una nueva l\xEDnea que comience con "// ".` : primaryLang === "pt" ? "N\xE3o adicione tradu\xE7\xF5es extras." : primaryLang === "ar" ? "\u0645\u0627 \u062A\u0636\u064A\u0641\u0634 \u062A\u0631\u062C\u0645\u0627\u062A \u0632\u064A\u0627\u062F\u0629." : primaryLang === "hi" ? "\u0905\u0924\u093F\u0930\u093F\u0915\u094D\u0924 \u0905\u0928\u0941\u0935\u093E\u0926 \u0928 \u091C\u094B\u0921\u093C\u0947\u0902\u0964" : "No a\xF1adas traducciones adicionales.";
      return [
        "You are a helpful language study buddy for quick questions.",
        strict,
        `The learner practices ${nameForLanguage(
          targetLang
        )}; their support/UI language is ${nameForLanguage(primaryLang)}.`,
        buildAssistantLanguagePolicy({
          supportLanguageName: nameForLanguage(primaryLang),
          targetLanguageName: nameForLanguage(targetLang)
        }),
        levelHint,
        focus ? `Focus area: ${focus}.` : "",
        supportNote,
        "Keep replies \u2264 60 words.",
        glossLine,
        "Use concise Markdown when helpful (bullets, **bold**, code, tables)."
      ].filter(Boolean).join(" ");
    }, buildHistoryBlock = () => {
      const last = getOrderedMessages(messages).slice(-6);
      if (!last.length) return "";
      const lines = last.map(
        (m) => m.role === "user" ? `User: ${m.text}` : `Assistant: ${m.text}`
      );
      return lines.join("\n");
    }, buildRealtimeInstructions = () => {
      const lvl = progress?.level || "beginner";
      const targetLang = normalizePracticeLanguage(progress?.targetLang, "es");
      const supportLang = normalizeSupportLanguage(
        progress?.supportLang,
        DEFAULT_SUPPORT_LANGUAGE
      );
      const focus = (progress?.helpRequest || "").slice(0, 200);
      const nameFor = (code) => ({
        es: "Spanish",
        en: "English",
        pt: "Portuguese",
        fr: "French",
        it: "Italian",
        hi: "Hindi",
        ja: "Japanese",
        ar: "Egyptian Arabic",
        zh: "Mandarin Chinese",
        nl: "Dutch",
        nah: "Eastern Huasteca Nahuatl",
        ru: "Russian",
        de: "German",
        el: "Greek",
        pl: "Polish",
        ga: "Irish",
        yua: "Yucatec Maya"
      })[code] || code;
      const levelHint = lvl === "beginner" ? "Speak slowly, clearly, and keep sentences simple." : lvl === "intermediate" ? "Be concise and natural in the support language." : "Be succinct, natural, and keep it mostly in the support language.";
      return [
        "You are a helpful language study buddy for quick voice conversations.",
        `The learner is practicing ${nameFor(targetLang)}.`,
        `Their native/support language is ${nameFor(supportLang)}.`,
        buildAssistantLanguagePolicy({
          supportLanguageName: nameFor(supportLang),
          targetLanguageName: nameFor(targetLang)
        }),
        `Level: ${lvl}. ${levelHint}`,
        focus ? `Focus area: ${focus}.` : "",
        "Keep responses brief (under 30 seconds of speech).",
        "Be encouraging and helpful. Correct mistakes gently.",
        `Speak and explain mainly in ${nameFor(
          supportLang
        )} (support language). Include ${nameFor(
          targetLang
        )} examples or phrases when they help, but keep guidance in ${nameFor(
          supportLang
        )}.`
      ].filter(Boolean).join(" ");
    }, buildRealtimeTurnDetection = () => ({
      type: "server_vad",
      silence_duration_ms: 2e3,
      threshold: 0.35,
      prefix_padding_ms: 120,
      interrupt_response: false
    });
    let result;
    if (op === "copy") result = (() => ({
      noMessagesTitle: supportCopy(
        uiLang,
        "No messages",
        "Sin mensajes",
        "Nessun messaggio",
        "Aucun message",
        "\u30E1\u30C3\u30BB\u30FC\u30B8\u306A\u3057",
        "Sem mensagens",
        "\u0915\u094B\u0908 \u0938\u0902\u0926\u0947\u0936 \u0928\u0939\u0940\u0902"
      ),
      noMessagesDesc: supportCopy(
        uiLang,
        "No messages to save.",
        "No hay mensajes para guardar.",
        "Non ci sono messaggi da salvare.",
        "Aucun message a enregistrer.",
        "\u4FDD\u5B58\u3059\u308B\u30E1\u30C3\u30BB\u30FC\u30B8\u304C\u3042\u308A\u307E\u305B\u3093\u3002",
        "Nenhuma mensagem para salvar.",
        "\u0938\u0939\u0947\u091C\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0915\u094B\u0908 \u0938\u0902\u0926\u0947\u0936 \u0928\u0939\u0940\u0902 \u0939\u0948\u0964"
      ),
      savedChatTitle: supportCopy(
        uiLang,
        "Saved chat",
        "Chat guardado",
        "Chat salvata",
        "Chat enregistre",
        "\u30C1\u30E3\u30C3\u30C8\u3092\u4FDD\u5B58\u3057\u307E\u3057\u305F",
        "Chat salvo",
        "\u0938\u0939\u0947\u091C\u0940 \u0917\u0908 \u091A\u0948\u091F"
      ),
      chatSavedTitle: supportCopy(
        uiLang,
        "Chat saved",
        "Chat guardado",
        "Chat salvata",
        "Chat enregistre",
        "\u30C1\u30E3\u30C3\u30C8\u3092\u4FDD\u5B58\u3057\u307E\u3057\u305F",
        "Chat salvo",
        "\u091A\u0948\u091F \u0938\u0939\u0947\u091C \u0932\u0940 \u0917\u0908"
      ),
      chatDeletedTitle: supportCopy(
        uiLang,
        "Chat deleted",
        "Chat eliminado",
        "Chat eliminata",
        "Chat supprime",
        "\u30C1\u30E3\u30C3\u30C8\u3092\u524A\u9664\u3057\u307E\u3057\u305F",
        "Chat exclu\xEDdo",
        "\u091A\u0948\u091F \u0939\u091F\u093E \u0926\u0940 \u0917\u0908"
      ),
      requestFailed: supportCopy(
        uiLang,
        "Sorry, I couldn\u2019t complete that request. Please try again.",
        "Lo siento, no pude completar esa solicitud. Int\xE9ntalo nuevamente.",
        "Mi dispiace, non sono riuscito a completare la richiesta. Riprova.",
        "Desole, je n'ai pas pu terminer cette demande. Reessaie.",
        "\u3059\u307F\u307E\u305B\u3093\u3001\u305D\u306E\u30EA\u30AF\u30A8\u30B9\u30C8\u3092\u5B8C\u4E86\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002\u3082\u3046\u4E00\u5EA6\u304A\u8A66\u3057\u304F\u3060\u3055\u3044\u3002",
        "Desculpe, n\xE3o consegui concluir essa solicita\xE7\xE3o. Tente novamente.",
        "\u092E\u093E\u092B\u093C \u0915\u0940\u091C\u093F\u090F, \u092E\u0948\u0902 \u092F\u0939 \u0905\u0928\u0941\u0930\u094B\u0927 \u092A\u0942\u0930\u093E \u0928\u0939\u0940\u0902 \u0915\u0930 \u0938\u0915\u093E\u0964 \u0915\u0943\u092A\u092F\u093E \u092B\u093F\u0930 \u0938\u0947 \u0915\u094B\u0936\u093F\u0936 \u0915\u0930\u0947\u0902\u0964"
      ),
      chatErrorTitle: supportCopy(
        uiLang,
        "Chat error",
        "Error de chat",
        "Errore chat",
        "Erreur de chat",
        "\u30C1\u30E3\u30C3\u30C8\u30A8\u30E9\u30FC",
        "Erro no chat",
        "\u091A\u0948\u091F \u0924\u094D\u0930\u0941\u091F\u093F"
      ),
      connectionErrorTitle: supportCopy(
        uiLang,
        "Connection error",
        "Error de conexi\xF3n",
        "Errore di connessione",
        "Erreur de connexion",
        "\u63A5\u7D9A\u30A8\u30E9\u30FC",
        "Erro de conex\xE3o",
        "\u0915\u0928\u0947\u0915\u094D\u0936\u0928 \u0924\u094D\u0930\u0941\u091F\u093F"
      ),
      yourChats: supportCopy(
        uiLang,
        "Your chats",
        "Tus chats",
        "Le tue chat",
        "Tes chats",
        "\u3042\u306A\u305F\u306E\u30C1\u30E3\u30C3\u30C8",
        "Seus chats",
        "\u0906\u092A\u0915\u0940 \u091A\u0948\u091F\u094D\u0938"
      ),
      noSavedChats: supportCopy(
        uiLang,
        "No saved chats",
        "No hay chats guardados",
        "Nessuna chat salvata",
        "Aucun chat enregistre",
        "\u4FDD\u5B58\u6E08\u307F\u30C1\u30E3\u30C3\u30C8\u306F\u3042\u308A\u307E\u305B\u3093",
        "Nenhum chat salvo",
        "\u0915\u094B\u0908 \u0938\u0939\u0947\u091C\u0940 \u0917\u0908 \u091A\u0948\u091F \u0928\u0939\u0940\u0902"
      ),
      delete: supportCopy(
        uiLang,
        "Delete",
        "Eliminar",
        "Elimina",
        "Supprimer",
        "\u524A\u9664",
        "Excluir",
        "\u0939\u091F\u093E\u090F\u0902"
      ),
      morphemeMode: supportCopy(
        uiLang,
        "Morpheme mode",
        "Modo morfemas",
        "Modalit\xE0 morfemi",
        "Mode morphemes",
        "\u5F62\u614B\u7D20\u30E2\u30FC\u30C9",
        "Modo morfemas",
        "\u092E\u0949\u0930\u094D\u092B\u0940\u092E \u092E\u094B\u0921"
      ),
      breakDownWords: supportCopy(
        uiLang,
        "Break down words",
        "Desglosa palabras",
        "Scomponi le parole",
        "Decomposer les mots",
        "\u5358\u8A9E\u3092\u5206\u89E3",
        "Quebrar palavras",
        "\u0936\u092C\u094D\u0926\u094B\u0902 \u0915\u094B \u0924\u094B\u0921\u093C\u0915\u0930 \u0938\u092E\u091D\u093E\u090F\u0902"
      ),
      newChat: supportCopy(
        uiLang,
        "New chat",
        "Nuevo chat",
        "Nuova chat",
        "Nouveau chat",
        "\u65B0\u3057\u3044\u30C1\u30E3\u30C3\u30C8",
        "Novo chat",
        "\u0928\u0908 \u091A\u0948\u091F"
      ),
      help: supportCopy(
        uiLang,
        "Help",
        "Ayuda",
        "Aiuto",
        "Aide",
        "\u30D8\u30EB\u30D7",
        "Ajuda",
        "\u092E\u0926\u0926"
      ),
      menu: supportCopy(
        uiLang,
        "Menu",
        "Men\xFA",
        "Menu",
        "Menu",
        "\u30E1\u30CB\u30E5\u30FC",
        "Menu",
        "\u092E\u0947\u0928\u0942"
      ),
      morphemes: supportCopy(
        uiLang,
        "Morphemes",
        "Morfemas",
        "Morfemi",
        "Morphemes",
        "\u5F62\u614B\u7D20",
        "Morfemas",
        "\u092E\u0949\u0930\u094D\u092B\u0940\u092E"
      ),
      saveChat: supportCopy(
        uiLang,
        "Save chat",
        "Guardar",
        "Salva chat",
        "Enregistrer le chat",
        "\u30C1\u30E3\u30C3\u30C8\u3092\u4FDD\u5B58",
        "Salvar chat",
        "\u091A\u0948\u091F \u0938\u0939\u0947\u091C\u0947\u0902"
      ),
      emptyPrompt: supportCopy(
        uiLang,
        "What do you want to learn today?",
        "\xBFQu\xE9 quieres aprender hoy?",
        "Che cosa vuoi imparare oggi?",
        "Qu'est-ce que tu veux apprendre aujourd'hui ?",
        "\u4ECA\u65E5\u306F\u4F55\u3092\u5B66\u3073\u305F\u3044\u3067\u3059\u304B\uFF1F",
        "O que voc\xEA quer aprender hoje?",
        "\u0906\u091C \u0906\u092A \u0915\u094D\u092F\u093E \u0938\u0940\u0916\u0928\u093E \u091A\u093E\u0939\u0924\u0947 \u0939\u0948\u0902?"
      ),
      stopVoiceChat: supportCopy(
        uiLang,
        "Stop voice chat",
        "Detener chat de voz",
        "Interrompi chat vocale",
        "Arreter le chat vocal",
        "\u97F3\u58F0\u30C1\u30E3\u30C3\u30C8\u3092\u505C\u6B62",
        "Encerrar chat por voz",
        "\u0935\u0949\u0907\u0938 \u091A\u0948\u091F \u0930\u094B\u0915\u0947\u0902"
      ),
      startVoiceChat: supportCopy(
        uiLang,
        "Start voice chat",
        "Iniciar chat de voz",
        "Avvia chat vocale",
        "Demarrer le chat vocal",
        "\u97F3\u58F0\u30C1\u30E3\u30C3\u30C8\u3092\u958B\u59CB",
        "Iniciar chat por voz",
        "\u0935\u0949\u0907\u0938 \u091A\u0948\u091F \u0936\u0941\u0930\u0942 \u0915\u0930\u0947\u0902"
      ),
      play: supportCopy(
        uiLang,
        "Play",
        "Reproducir",
        "Riproduci",
        "Lire",
        "\u518D\u751F",
        "Reproduzir",
        "\u091A\u0932\u093E\u090F\u0902"
      ),
      askPlaceholder: supportCopy(
        uiLang,
        "Ask about this lesson...",
        "Pregunta sobre esta lecci\xF3n...",
        "Chiedi qualcosa su questa lezione...",
        "Pose une question sur cette lecon...",
        "\u3053\u306E\u30EC\u30C3\u30B9\u30F3\u306B\u3064\u3044\u3066\u8CEA\u554F...",
        "Pergunte sobre esta li\xE7\xE3o...",
        "\u0907\u0938 \u092A\u093E\u0920 \u0915\u0947 \u092C\u093E\u0930\u0947 \u092E\u0947\u0902 \u092A\u0942\u091B\u0947\u0902..."
      ),
      send: supportCopy(
        uiLang,
        "Send",
        "Enviar",
        "Invia",
        "Envoyer",
        "\u9001\u4FE1",
        "Enviar",
        "\u092D\u0947\u091C\u0947\u0902"
      ),
      stop: supportCopy(
        uiLang,
        "Stop",
        "Detener",
        "Ferma",
        "Arreter",
        "\u505C\u6B62",
        "Parar",
        "\u0930\u094B\u0915\u0947\u0902"
      )
    }))();
    else if (op === "instruction") result = buildInstruction();
    else if (op === "prompt") {
      const instruction = buildInstruction(), historyBlock = buildHistoryBlock();
      result = morphemeMode ? "" : instruction + "\n\n" + (historyBlock ? `Previous conversation (for context, keep answers concise):
${historyBlock}

` : "") + `User question:
${question}`;
    } else if (op === "split") result = splitMainAndGloss(p.text);
    else if (op === "order") result = getOrderedMessages(messages);
    else if (op === "planPrompt") result = buildMorphemeTranslationPlanPrompt({ targetLanguageName: nameForLanguage(normalizePracticeLanguage(progress.targetLang, "es")), supportLanguageName: nameForLanguage(normalizeSupportLanguage(progress.supportLang === "bilingual" ? appLanguage : progress.supportLang, DEFAULT_SUPPORT_LANGUAGE)), question });
    else if (op === "parsePlan") result = parseMorphemeTranslationPlan(p.text);
    else if (op === "breakdownPrompt") result = buildMorphemeBreakdownPrompt({ targetLanguageName: nameForLanguage(normalizePracticeLanguage(progress.targetLang, "es")), supportLanguageName: nameForLanguage(normalizeSupportLanguage(progress.supportLang === "bilingual" ? appLanguage : progress.supportLang, DEFAULT_SUPPORT_LANGUAGE)), targetText: p.text });
    else if (op === "hasBreakdown") result = hasMorphemeBreakdown(p.text);
    else if (op === "session") {
      const instructions = buildRealtimeInstructions(), voiceName = p.voice || "ash";
      result = {
        type: "realtime",
        instructions,
        output_modalities: ["audio"],
        audio: {
          input: {
            turn_detection: buildRealtimeTurnDetection(),
            transcription: { model: "gpt-4o-mini-transcribe" }
          },
          output: {
            format: { type: "audio/pcm", rate: 24e3 },
            voice: voiceName
          }
        }
      };
    } else if (op === "voiceTimeout") {
      let milliseconds = null, changed = false;
      const AUTO_DISCONNECT_MS = 15e3, clearRealtimeAutoStopTimer = () => {
        milliseconds = null;
        changed = true;
      }, scheduleRealtimeAutoStop = () => {
        milliseconds = AUTO_DISCONNECT_MS;
        changed = true;
      }, realtimeAliveRef = { current: true }, realtimeAutoStopTimerRef = {}, stopRealtimeRef = { current: () => {
      } }, currentAssistantIdRef = {}, ensurePendingRealtimeTurn = () => {
      }, disableRealtimeVAD = () => {
      }, enableRealtimeVAD = () => {
      }, findRealtimeTurnForResponse = () => ({}), ensureRealtimeAssistantMessage = () => "", setTimeout = (_, ms) => {
        milliseconds = ms;
        changed = true;
        return 1;
      };
      (function(evt) {
        const data = JSON.parse(evt.data);
        const eventType = data.type;
        const responseId = data.response_id || data.response?.id || data.id || null;
        if (eventType === "input_audio_buffer.speech_started") {
          clearRealtimeAutoStopTimer();
          return;
        }
        if (eventType === "input_audio_buffer.speech_stopped" || eventType === "input_audio_buffer.committed") {
          clearRealtimeAutoStopTimer();
          ensurePendingRealtimeTurn();
          disableRealtimeVAD();
          if (realtimeAliveRef.current) {
            realtimeAutoStopTimerRef.current = setTimeout(() => {
              if (!realtimeAliveRef.current) return;
              stopRealtimeRef.current();
            }, 25e3);
          }
          return;
        }
        if (eventType === "response.created") {
          clearRealtimeAutoStopTimer();
          const turn = findRealtimeTurnForResponse(responseId);
          currentAssistantIdRef.current = ensureRealtimeAssistantMessage(
            turn,
            responseId
          );
          disableRealtimeVAD();
          if (realtimeAliveRef.current) {
            realtimeAutoStopTimerRef.current = setTimeout(() => {
              if (!realtimeAliveRef.current) return;
              stopRealtimeRef.current();
            }, 45e3);
          }
          return;
        }
        if (eventType === "response.output_audio.done" || eventType === "output_audio.done" || eventType === "output_audio_buffer.stopped" || eventType === "response.canceled") {
          enableRealtimeVAD();
          if (realtimeAliveRef.current) scheduleRealtimeAutoStop();
          return;
        }
      })({ data: JSON.stringify(p.event || { type: p.type }) });
      result = { changed, milliseconds };
    } else if (op === "badge") result = LANG_COLORS[p.target] || LANG_COLORS.es;
    else throw Error("Unknown Help operation");
    return JSON.stringify(result ?? null);
  } };
  return __toCommonJS(stdin_exports);
})();

PiyaliHelp.api;
