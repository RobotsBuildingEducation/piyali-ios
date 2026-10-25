var SettingsSource = (() => {
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
    const normalized2 = normalizeCode(raw);
    if (!normalized2) return "";
    if (normalized2 === "arz") return "ar";
    if (normalized2 === "cmn") return "zh";
    if (SUPPORTED_LANGUAGE_CODES_SET.has(normalized2)) return normalized2;
    const [base] = normalized2.split(/[-_]/);
    if (base === "arz" && SUPPORTED_LANGUAGE_CODES_SET.has("ar")) return "ar";
    if (base === "cmn" && SUPPORTED_LANGUAGE_CODES_SET.has("zh")) return "zh";
    if (SUPPORTED_LANGUAGE_CODES_SET.has(base)) return base;
    return normalized2;
  };
  var PRACTICE_LANGUAGE_CODES = [...PRACTICE_LANGUAGE_CODES_BASE];
  var SUPPORT_LANGUAGE_CODES2 = SUPPORT_LANGUAGE_CODES_BASE.filter(
    (code) => SUPPORTED_LANGUAGE_CODES_SET.has(code)
  );
  var ALPHABET_LANGUAGE_CODES = [...PRACTICE_LANGUAGE_CODES];
  function normalizeSupportLanguage(code, fallback = DEFAULT_SUPPORT_LANGUAGE) {
    const normalized2 = normalizeSupportedCode(code);
    if (SUPPORT_LANGUAGE_CODES_SET.has(normalized2)) return normalized2;
    return fallback;
  }
  function normalizePracticeLanguage(code, fallback = DEFAULT_TARGET_LANGUAGE) {
    const normalized2 = normalizeSupportedCode(code);
    if (SUPPORTED_LANGUAGE_CODES_SET.has(normalized2)) return normalized2;
    return fallback;
  }

  // ../nosabos/nosabos/src/utils/openaiTutorVoices.js
  var DEFAULT_OPENAI_TUTOR_VOICE = "marin";
  var OPENAI_TUTOR_VOICE_VALUES = ["cedar", "marin"];
  var LEGACY_OPENAI_VOICE_MIGRATION = {
    alloy: "cedar",
    ash: "cedar",
    ballad: "cedar",
    echo: "cedar",
    verse: "cedar",
    coral: "marin",
    sage: "marin",
    shimmer: "marin"
  };
  function normalizeOpenAITutorVoice(voice) {
    const key = String(voice || "").trim().toLowerCase();
    if (OPENAI_TUTOR_VOICE_VALUES.includes(key)) return key;
    return LEGACY_OPENAI_VOICE_MIGRATION[key] || DEFAULT_OPENAI_TUTOR_VOICE;
  }

  // ../nosabos/nosabos/src/utils/geminiLiveVoices.js
  var DEFAULT_GEMINI_LIVE_VOICE = "Vindemiatrix";
  var GEMINI_LIVE_VOICE_DESCRIPTIONS = {
    Vindemiatrix: {
      en: "Relaxed",
      es: "Relajada",
      pt: "Descontra\xEDda",
      it: "Rilassata",
      fr: "D\xE9tendue",
      de: "Entspannt",
      ja: "\u843D\u3061\u7740\u3044\u305F",
      hi: "\u0936\u093E\u0902\u0924 \u0914\u0930 \u0938\u0939\u091C",
      ar: "\u0647\u0627\u062F\u0626\u0629 \u0648\u0645\u0631\u064A\u062D\u0629",
      zh: "\u8F7B\u677E\u81EA\u7136"
    },
    Enceladus: {
      en: "Polished",
      es: "Pulido",
      pt: "Polido",
      it: "Raffinato",
      fr: "Soign\xE9",
      de: "Geschliffen",
      ja: "\u6D17\u7DF4\u3055\u308C\u305F",
      hi: "\u0938\u0941\u0932\u091D\u093E \u0939\u0941\u0906",
      ar: "\u0645\u0647\u0630\u0628 \u0648\u0645\u062A\u0642\u0646",
      zh: "\u6210\u719F\u5E72\u7EC3"
    },
    Zephyr: {
      en: "Bright",
      es: "Brillante",
      pt: "Brilhante",
      it: "Brillante",
      fr: "\xC9clatante",
      de: "Hell",
      ja: "\u660E\u308B\u3044",
      hi: "\u0909\u091C\u094D\u091C\u094D\u0935\u0932",
      ar: "\u0645\u0634\u0631\u0642\u0629",
      zh: "\u660E\u6717\u6E05\u6F88"
    },
    Charon: {
      en: "Friendly",
      es: "Amigable",
      pt: "Amig\xE1vel",
      it: "Amichevole",
      fr: "Chaleureux",
      de: "Freundlich",
      ja: "\u89AA\u3057\u307F\u3084\u3059\u3044",
      hi: "\u092E\u093F\u0924\u094D\u0930\u0935\u0924",
      ar: "\u0648\u062F\u0648\u062F",
      zh: "\u4EB2\u5207\u53CB\u597D"
    }
  };
  var GEMINI_LIVE_VOICE_OPTIONS = [
    {
      value: "Vindemiatrix",
      label: "Naomi",
      type: "girl",
      description: "Relaxed",
      descriptionByLang: GEMINI_LIVE_VOICE_DESCRIPTIONS.Vindemiatrix
    },
    {
      value: "Enceladus",
      label: "John",
      type: "boy",
      description: "Polished",
      descriptionByLang: GEMINI_LIVE_VOICE_DESCRIPTIONS.Enceladus
    },
    {
      value: "Zephyr",
      label: "Zephyr",
      type: "girl",
      description: "Bright",
      descriptionByLang: GEMINI_LIVE_VOICE_DESCRIPTIONS.Zephyr
    },
    {
      value: "Charon",
      label: "Michael",
      type: "boy",
      description: "Friendly",
      descriptionByLang: GEMINI_LIVE_VOICE_DESCRIPTIONS.Charon
    }
  ];
  var LEGACY_ALIASES = {
    // Spelling variants
    vindematrix: "Vindemiatrix",
    vindemeatrix: "Vindemiatrix",
    // OpenAI voice settings map to Naomi (Vindemiatrix)
    marin: "Vindemiatrix",
    cedar: "Vindemiatrix",
    alloy: "Vindemiatrix",
    echo: "Vindemiatrix",
    ash: "Vindemiatrix",
    ballad: "Vindemiatrix",
    coral: "Vindemiatrix",
    sage: "Vindemiatrix",
    shimmer: "Vindemiatrix",
    verse: "Vindemiatrix",
    // Previous Gemini nicknames / mappings
    trey: "Enceladus",
    sadachbia: "Enceladus",
    chloe: "Vindemiatrix",
    gacrux: "Vindemiatrix",
    david: "Charon",
    algenib: "Charon",
    puck: "Charon",
    fenrir: "Charon",
    kore: "Zephyr",
    aoede: "Zephyr"
  };
  var GEMINI_LIVE_VOICE_BY_KEY = new Map([
    ...GEMINI_LIVE_VOICE_OPTIONS.map((option) => [
      option.value.toLowerCase(),
      option.value
    ]),
    ...GEMINI_LIVE_VOICE_OPTIONS.map((option) => [
      option.label.toLowerCase(),
      option.value
    ])
  ]);
  function normalizeGeminiLiveVoice(voice) {
    const key = String(voice || "").trim().toLowerCase();
    if (LEGACY_ALIASES[key]) return LEGACY_ALIASES[key];
    return GEMINI_LIVE_VOICE_BY_KEY.get(key) || DEFAULT_GEMINI_LIVE_VOICE;
  }
  function getGeminiLiveVoiceOption(voice) {
    const normalized2 = normalizeGeminiLiveVoice(voice);
    return GEMINI_LIVE_VOICE_OPTIONS.find((option) => option.value === normalized2) || GEMINI_LIVE_VOICE_OPTIONS[0];
  }

  // <stdin>
  var normalizeThemeMode = (mode) => mode === "dark" ? "dark" : "light";
  var p = {};
  var translations = { "en": { "DEFAULT_PERSONA": "A friendly and helpful assistant", "onboarding_persona_default_example": "A friendly and helpful assistant" }, "es": { "DEFAULT_PERSONA": "Un asistente amable y servicial.", "onboarding_persona_default_example": "Como una t\xF3xica sarc\xE1stica y medio amistosa." }, "it": { "DEFAULT_PERSONA": "Un assistente amichevole e disponibile", "onboarding_persona_default_example": "Un assistente amichevole e disponibile" }, "fr": { "DEFAULT_PERSONA": "Un assistant amical et serviable", "onboarding_persona_default_example": "Un assistant amical et serviable" }, "de": { "DEFAULT_PERSONA": "Ein freundlicher und hilfreicher Assistent", "onboarding_persona_default_example": "Ein freundlicher und hilfreicher Assistent" }, "ja": { "DEFAULT_PERSONA": "\u89AA\u5207\u3067\u30D5\u30EC\u30F3\u30C9\u30EA\u30FC\u306A\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8", "onboarding_persona_default_example": "\u89AA\u5207\u3067\u30D5\u30EC\u30F3\u30C9\u30EA\u30FC\u306A\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8" }, "ar": { "DEFAULT_PERSONA": "\u0645\u0633\u0627\u0639\u062F \u0648\u062F\u0648\u062F \u0648\u0645\u0641\u064A\u062F", "onboarding_persona_default_example": "\u0645\u0633\u0627\u0639\u062F \u0648\u062F\u0648\u062F \u0648\u0645\u0641\u064A\u062F" }, "hi": { "DEFAULT_PERSONA": "\u090F\u0915 \u092E\u093F\u0924\u094D\u0930\u0935\u0924 \u0914\u0930 \u0938\u0939\u093E\u092F\u0915 \u0938\u0939\u093E\u092F\u0915", "onboarding_persona_default_example": "\u090F\u0915 \u092E\u093F\u0924\u094D\u0930\u0935\u0924 \u0914\u0930 \u0938\u0939\u093E\u092F\u0915 \u0938\u0939\u093E\u092F\u0915" }, "pt": { "DEFAULT_PERSONA": "Um assistente amig\xE1vel e prestativo", "onboarding_persona_default_example": "Um assistente amig\xE1vel e prestativo" }, "zh": { "DEFAULT_PERSONA": "\u53CB\u597D\u4E14\u4E50\u4E8E\u52A9\u4EBA\u7684\u52A9\u624B", "onboarding_persona_default_example": "\u53CB\u597D\u4E14\u4E50\u4E8E\u52A9\u4EBA\u7684\u52A9\u624B" }, "ru": {} };
  var DEFAULT_VOICE_PAUSE_MS = 1200;
  var isOpenAITutorProvider = () => p.provider === "openai";
  var personaDefaultFor = (lang) => translations?.[lang]?.DEFAULT_PERSONA || translations?.[lang]?.onboarding_persona_default_example || translations?.en?.onboarding_persona_default_example || "";
  var normalizePersonaValue = (value) => String(value || "").trim().replace(/\s+/g, " ").replace(/[.!]+$/g, "").toLocaleLowerCase();
  var isDefaultPersonaValue = (value) => {
    if (value === void 0 || value === null) return true;
    const normalized2 = normalizePersonaValue(value);
    if (!normalized2) return false;
    return ["en", "es", "pt", "it", "fr", "de", "ja", "hi", "ar", "zh"].some(
      (lang) => normalized2 === normalizePersonaValue(translations?.[lang]?.DEFAULT_PERSONA) || normalized2 === normalizePersonaValue(
        translations?.[lang]?.onboarding_persona_default_example
      )
    );
  };
  var personaForSupportLanguage = (currentPersona, supportLang) => {
    if (currentPersona === void 0 || currentPersona === null) {
      return personaDefaultFor(supportLang) || "";
    }
    if (!isDefaultPersonaValue(currentPersona)) return currentPersona;
    return personaDefaultFor(supportLang) || currentPersona || "";
  };
  function migrateToCEFRLevel(level) {
    const migrations = {
      beginner: "Pre-A1",
      intermediate: "B1",
      advanced: "C1"
    };
    return migrations[level] || level || "Pre-A1";
  }
  var DEFAULT_TTS_VOICE = "ash";
  var SUPPORTED_TTS_VOICES = /* @__PURE__ */ new Set([
    "alloy",
    "echo",
    "shimmer",
    "coral",
    "verse",
    "ballad",
    "ash",
    "sage",
    "marin",
    "cedar"
  ]);
  var TTS_VOICE_OPTIONS = [
    { value: "alloy", type: "boy", description: "Balanced and neutral" },
    { value: "coral", type: "girl", description: "Bright and friendly" },
    { value: "ash", type: "boy", description: "Calm and steady" },
    { value: "shimmer", type: "girl", description: "Soft and upbeat" },
    { value: "ballad", type: "boy", description: "Smooth and dramatic" },
    { value: "sage", type: "girl", description: "Warm and composed" },
    { value: "cedar", type: "boy", description: "Deep and grounded" },
    { value: "marin", type: "girl", description: "Cheerful and warm" },
    { value: "echo", type: "boy", description: "Crisp and energetic" },
    { value: "verse", type: "boy", description: "Expressive and clear" }
  ];
  function sanitizeVoice(voice) {
    return SUPPORTED_TTS_VOICES.has(voice) ? voice : DEFAULT_TTS_VOICE;
  }
  function normalizeTTSVoice(voice) {
    return sanitizeVoice(voice);
  }
  function getTTSVoiceOption(voice) {
    const normalized2 = sanitizeVoice(voice);
    return TTS_VOICE_OPTIONS.find((option) => option.value === normalized2) || TTS_VOICE_OPTIONS[0];
  }
  var TTS_LANG_TAG = {
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
    ru: "ru-RU",
    ja: "ja-JP",
    de: "de-DE",
    el: "el-GR",
    pl: "pl-PL",
    ga: "ga-IE",
    yua: "es-MX"
  };
  var OPENAI_TUTOR_VOICE_OPTIONS = TTS_VOICE_OPTIONS.filter(
    (option) => OPENAI_TUTOR_VOICE_VALUES.includes(option.value)
  );
  function getTutorVoiceOptions() {
    return isOpenAITutorProvider() ? OPENAI_TUTOR_VOICE_OPTIONS : GEMINI_LIVE_VOICE_OPTIONS;
  }
  function normalizeTutorVoice(voice) {
    return isOpenAITutorProvider() ? normalizeOpenAITutorVoice(voice) : normalizeGeminiLiveVoice(voice);
  }
  function getTutorVoiceOption(voice) {
    return isOpenAITutorProvider() ? getTTSVoiceOption(normalizeOpenAITutorVoice(voice)) : getGeminiLiveVoiceOption(voice);
  }
  var VOICE_PREVIEW_TEXT = {
    ar: "\u0623\u0647\u0644\u0627\u060C \u0633\u0646\u062A\u062F\u0631\u0628 \u0645\u0639\u0627.",
    de: "Hallo, wir ueben zusammen.",
    el: "\u0393\u03B5\u03B9\u03B1 \u03C3\u03BF\u03C5, \u03B1\u03C2 \u03B5\u03BE\u03B1\u03C3\u03BA\u03B7\u03B8\u03BF\u03CD\u03BC\u03B5 \u03BC\u03B1\u03B6\u03AF.",
    en: "Hi, I am ready to practice with you.",
    es: "Hola, vamos a practicar juntos.",
    fr: "Bonjour, on va pratiquer ensemble.",
    ga: "Dia duit, cleachtfaimid le cheile.",
    hi: "\u0928\u092E\u0938\u094D\u0924\u0947, \u091A\u0932\u094B \u0938\u093E\u0925 \u0905\u092D\u094D\u092F\u093E\u0938 \u0915\u0930\u0947\u0902.",
    it: "Ciao, pratichiamo insieme.",
    ja: "\u3053\u3093\u306B\u3061\u306F\u3002\u4E00\u7DD2\u306B\u7DF4\u7FD2\u3057\u307E\u3057\u3087\u3046\u3002",
    nah: "Hola, vamos a practicar juntos.",
    nl: "Hallo, we oefenen samen.",
    pl: "Czesc, pocwiczmy razem.",
    pt: "Ola, vamos praticar juntos.",
    ru: "\u041F\u0440\u0438\u0432\u0435\u0442, \u0434\u0430\u0432\u0430\u0439 \u043F\u043E\u0442\u0440\u0435\u043D\u0438\u0440\u0443\u0435\u043C\u0441\u044F.",
    yua: "Hola, vamos a practicar juntos.",
    zh: "\u4F60\u597D\uFF0C\u6211\u4EEC\u4E00\u8D77\u7EC3\u4E60\u5427\u3002"
  };
  var VOICE_PREVIEW_LINES = {
    alloy: {
      en: "I'll keep things clear and steady while you practice.",
      es: "Mantendr\xE9 la pr\xE1ctica clara y estable para ti.",
      pt: "Vou manter a pr\xE1tica clara e equilibrada para voc\xEA.",
      it: "Terr\xF2 la pratica chiara e stabile per te.",
      fr: "Je garde la pratique claire et stable pour toi.",
      de: "Ich halte das Training klar und ausgeglichen.",
      ja: "\u306F\u3063\u304D\u308A\u843D\u3061\u7740\u3044\u305F\u58F0\u3067\u7DF4\u7FD2\u3092\u652F\u3048\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0905\u092D\u094D\u092F\u093E\u0938 \u0915\u094B \u0938\u093E\u092B\u093C \u0914\u0930 \u0938\u0902\u0924\u0941\u0932\u093F\u0924 \u0930\u0916\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062E\u0644\u0651\u064A \u0627\u0644\u062A\u0645\u0631\u064A\u0646 \u0648\u0627\u0636\u062D \u0648\u0645\u062A\u0648\u0627\u0632\u0646.",
      zh: "\u6211\u4F1A\u7528\u6E05\u695A\u7A33\u5B9A\u7684\u58F0\u97F3\u966A\u4F60\u7EC3\u4E60\u3002"
    },
    coral: {
      en: "I'll bring a bright, friendly spark to each practice round.",
      es: "Le dar\xE9 a cada pr\xE1ctica un toque brillante y amable.",
      pt: "Vou trazer um toque claro e amig\xE1vel para cada pr\xE1tica.",
      it: "Porter\xF2 una scintilla vivace e amichevole a ogni pratica.",
      fr: "J'apporte une touche claire et amicale a chaque pratique.",
      de: "Ich bringe eine helle, freundliche Note in jede \xDCbung.",
      ja: "\u660E\u308B\u304F\u89AA\u3057\u307F\u3084\u3059\u3044\u58F0\u3067\u7DF4\u7FD2\u3092\u9032\u3081\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0939\u0930 \u0905\u092D\u094D\u092F\u093E\u0938 \u092E\u0947\u0902 \u091A\u092E\u0915\u0926\u093E\u0930 \u0914\u0930 \u0926\u094B\u0938\u094D\u0924\u093E\u0928\u093E \u090A\u0930\u094D\u091C\u093E \u0932\u093E\u090A\u0901\u0917\u0940\u0964",
      ar: "\u0647\u0636\u064A\u0641 \u0644\u0643\u0644 \u062A\u0645\u0631\u064A\u0646 \u0644\u0645\u0633\u0629 \u0645\u0634\u0631\u0642\u0629 \u0648\u0648\u062F\u0648\u062F\u0629.",
      zh: "\u6211\u4F1A\u7528\u660E\u4EAE\u53CB\u597D\u7684\u8BED\u6C14\u966A\u4F60\u7EC3\u4E60\u3002"
    },
    ash: {
      en: "I'll keep a calm pace and give you room to think.",
      es: "Ir\xE9 con calma y te dar\xE9 espacio para pensar.",
      pt: "Vou manter um ritmo calmo e dar espa\xE7o para voc\xEA pensar.",
      it: "Terr\xF2 un ritmo calmo e ti dar\xF2 spazio per pensare.",
      fr: "Je garde un rythme calme pour te laisser reflechir.",
      de: "Ich halte ein ruhiges Tempo und lasse dir Zeit zum Denken.",
      ja: "\u843D\u3061\u7740\u3044\u305F\u30DA\u30FC\u30B9\u3067\u3001\u8003\u3048\u308B\u6642\u9593\u3092\u4F5C\u308A\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0936\u093E\u0902\u0924 \u0917\u0924\u093F \u0930\u0916\u0942\u0901\u0917\u0940 \u0914\u0930 \u0938\u094B\u091A\u0928\u0947 \u0915\u0940 \u091C\u0917\u0939 \u0926\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062D\u0627\u0641\u0638 \u0639\u0644\u0649 \u0625\u064A\u0642\u0627\u0639 \u0647\u0627\u062F\u064A \u0648\u0623\u062F\u064A\u0643 \u0648\u0642\u062A \u062A\u0641\u0643\u0631.",
      zh: "\u6211\u4F1A\u4FDD\u6301\u5E73\u9759\u8282\u594F\uFF0C\u7ED9\u4F60\u601D\u8003\u7684\u7A7A\u95F4\u3002"
    },
    shimmer: {
      en: "I'll keep things light, upbeat, and easy to follow.",
      es: "Har\xE9 que todo se sienta ligero, animado y f\xE1cil de seguir.",
      pt: "Vou deixar tudo leve, animado e f\xE1cil de acompanhar.",
      it: "Render\xF2 tutto leggero, allegro e facile da seguire.",
      fr: "Je rends la pratique legere, dynamique et facile a suivre.",
      de: "Ich halte alles leicht, lebendig und gut verst\xE4ndlich.",
      ja: "\u3084\u308F\u3089\u304B\u304F\u8EFD\u5FEB\u306B\u3001\u308F\u304B\u308A\u3084\u3059\u304F\u9032\u3081\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0905\u092D\u094D\u092F\u093E\u0938 \u0915\u094B \u0939\u0932\u094D\u0915\u093E, \u0909\u0924\u094D\u0938\u093E\u0939\u093F\u0924 \u0914\u0930 \u0906\u0938\u093E\u0928 \u0930\u0916\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062E\u0644\u0651\u064A \u0627\u0644\u062A\u0645\u0631\u064A\u0646 \u062E\u0641\u064A\u0641 \u0648\u0645\u0628\u0647\u062C \u0648\u0633\u0647\u0644 \u0627\u0644\u0645\u062A\u0627\u0628\u0639\u0629.",
      zh: "\u6211\u4F1A\u8BA9\u7EC3\u4E60\u8F7B\u5FEB\u3001\u79EF\u6781\u53C8\u5BB9\u6613\u8DDF\u4E0A\u3002"
    },
    ballad: {
      en: "I'll add a smooth, story-like rhythm to your practice.",
      es: "Le dar\xE9 a tu pr\xE1ctica un ritmo fluido, como una historia.",
      pt: "Vou dar \xE0 sua pr\xE1tica um ritmo fluido, como uma hist\xF3ria.",
      it: "Dar\xF2 alla pratica un ritmo fluido, quasi narrativo.",
      fr: "Je donne a ta pratique un rythme fluide, presque narratif.",
      de: "Ich gebe deinem Training einen weichen, erz\xE4hlerischen Rhythmus.",
      ja: "\u7269\u8A9E\u306E\u3088\u3046\u306B\u306A\u3081\u3089\u304B\u306A\u30EA\u30BA\u30E0\u3067\u7DF4\u7FD2\u3057\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0905\u092D\u094D\u092F\u093E\u0938 \u092E\u0947\u0902 \u0915\u0939\u093E\u0928\u0940 \u091C\u0948\u0938\u093E \u092E\u0941\u0932\u093E\u092F\u092E \u0932\u092F \u091C\u094B\u0921\u093C\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062F\u064A \u062A\u0645\u0631\u064A\u0646\u0643 \u0625\u064A\u0642\u0627\u0639 \u0633\u0644\u0633 \u0643\u0623\u0646\u0647 \u062D\u0643\u0627\u064A\u0629.",
      zh: "\u6211\u4F1A\u7528\u6D41\u7545\u3001\u6709\u6545\u4E8B\u611F\u7684\u8282\u594F\u966A\u4F60\u7EC3\u4E60\u3002"
    },
    sage: {
      en: "I'll guide you with a warm, thoughtful tone.",
      es: "Te guiar\xE9 con un tono c\xE1lido y reflexivo.",
      pt: "Vou guiar voc\xEA com um tom acolhedor e cuidadoso.",
      it: "Ti guider\xF2 con un tono caldo e riflessivo.",
      fr: "Je te guide avec une voix chaleureuse et posee.",
      de: "Ich begleite dich mit einem warmen, bedachten Ton.",
      ja: "\u6E29\u304B\u304F\u843D\u3061\u7740\u3044\u305F\u58F0\u3067\u4E01\u5BE7\u306B\u5C0E\u304D\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0917\u0930\u094D\u092E\u091C\u094B\u0936\u0940 \u092D\u0930\u0947 \u0914\u0930 \u0938\u094B\u091A-\u0938\u092E\u091D\u0915\u0930 \u092C\u094B\u0932\u0947 \u0917\u090F \u0938\u094D\u0935\u0930 \u092E\u0947\u0902 \u092E\u093E\u0930\u094D\u0917\u0926\u0930\u094D\u0936\u0928 \u0915\u0930\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u0631\u0634\u062F\u0643 \u0628\u0646\u0628\u0631\u0629 \u062F\u0627\u0641\u0626\u0629 \u0648\u0645\u062A\u0632\u0646\u0629.",
      zh: "\u6211\u4F1A\u7528\u6E29\u6696\u6C89\u7A33\u7684\u8BED\u6C14\u5F15\u5BFC\u4F60\u3002"
    },
    cedar: {
      en: "I'll keep the session grounded with a deeper, steady sound.",
      es: "Mantendr\xE9 la sesi\xF3n firme con una voz profunda y estable.",
      pt: "Vou manter a sess\xE3o firme com uma voz profunda e est\xE1vel.",
      it: "Terr\xF2 la sessione ben salda con una voce profonda e stabile.",
      fr: "Je garde la session bien ancree avec une voix profonde et stable.",
      de: "Ich halte die Sitzung mit einer tiefen, festen Stimme geerdet.",
      ja: "\u6DF1\u304F\u5B89\u5B9A\u3057\u305F\u58F0\u3067\u3001\u7DF4\u7FD2\u3092\u3057\u3063\u304B\u308A\u652F\u3048\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0917\u0939\u0930\u0940 \u0914\u0930 \u0938\u094D\u0925\u093F\u0930 \u0906\u0935\u093E\u091C\u093C \u0938\u0947 \u0938\u0924\u094D\u0930 \u0915\u094B \u0938\u0902\u092D\u093E\u0932\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062D\u0627\u0641\u0638 \u0639\u0644\u0649 \u0627\u0644\u062C\u0644\u0633\u0629 \u062B\u0627\u0628\u062A\u0629 \u0628\u0635\u0648\u062A \u0623\u0639\u0645\u0642 \u0648\u0631\u0627\u0633\u064A.",
      zh: "\u6211\u4F1A\u7528\u4F4E\u6C89\u7A33\u5B9A\u7684\u58F0\u97F3\u8BA9\u7EC3\u4E60\u66F4\u8E0F\u5B9E\u3002"
    },
    marin: {
      en: "I'll keep practice cheerful, warm, and encouraging.",
      es: "Mantendr\xE9 la pr\xE1ctica alegre, c\xE1lida y motivadora.",
      pt: "Vou manter a pr\xE1tica alegre, acolhedora e motivadora.",
      it: "Terr\xF2 la pratica solare, calda e incoraggiante.",
      fr: "Je garde la pratique joyeuse, chaleureuse et encourageante.",
      de: "Ich halte das Training fr\xF6hlich, warm und ermutigend.",
      ja: "\u660E\u308B\u304F\u6E29\u304B\u3044\u58F0\u3067\u3001\u524D\u5411\u304D\u306B\u5FDC\u63F4\u3057\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0905\u092D\u094D\u092F\u093E\u0938 \u0915\u094B \u0916\u0941\u0936\u092E\u093F\u091C\u093E\u091C, \u0917\u0930\u094D\u092E\u091C\u094B\u0936\u0940 \u092D\u0930\u093E \u0914\u0930 \u092A\u094D\u0930\u0947\u0930\u0915 \u0930\u0916\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062E\u0644\u064A \u0627\u0644\u062A\u0645\u0631\u064A\u0646 \u0645\u0631\u062D \u0648\u062F\u0627\u0641\u064A \u0648\u0645\u0634\u062C\u0639.",
      zh: "\u6211\u4F1A\u8BA9\u7EC3\u4E60\u8F7B\u677E\u6E29\u6696\uFF0C\u4E5F\u66F4\u6709\u9F13\u52B1\u611F\u3002"
    },
    echo: {
      en: "I'll keep feedback crisp, energetic, and direct.",
      es: "Har\xE9 que la retroalimentaci\xF3n sea clara, en\xE9rgica y directa.",
      pt: "Vou deixar o feedback n\xEDtido, energ\xE9tico e direto.",
      it: "Dar\xF2 feedback nitidi, energici e diretti.",
      fr: "Je donne des retours nets, energiques et directs.",
      de: "Ich gebe klares, energiegeladenes und direktes Feedback.",
      ja: "\u6B6F\u5207\u308C\u3088\u304F\u3001\u30A8\u30CD\u30EB\u30AE\u30C3\u30B7\u30E5\u306B\u30D5\u30A3\u30FC\u30C9\u30D0\u30C3\u30AF\u3057\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u092A\u094D\u0930\u0924\u093F\u0915\u094D\u0930\u093F\u092F\u093E \u0915\u094B \u0938\u094D\u092A\u0937\u094D\u091F, \u090A\u0930\u094D\u091C\u093E\u0935\u093E\u0928 \u0914\u0930 \u0938\u0940\u0927\u093E \u0930\u0916\u0942\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062F\u064A\u0643 \u0645\u0644\u0627\u062D\u0638\u0627\u062A \u0648\u0627\u0636\u062D\u0629 \u0648\u062D\u064A\u0648\u064A\u0629 \u0648\u0645\u0628\u0627\u0634\u0631\u0629.",
      zh: "\u6211\u4F1A\u7ED9\u4F60\u6E05\u6670\u3001\u6709\u6D3B\u529B\u3001\u76F4\u63A5\u7684\u53CD\u9988\u3002"
    },
    verse: {
      en: "I'll make each phrase expressive, clear, and easy to repeat.",
      es: "Har\xE9 que cada frase sea expresiva, clara y f\xE1cil de repetir.",
      pt: "Vou deixar cada frase expressiva, clara e f\xE1cil de repetir.",
      it: "Render\xF2 ogni frase espressiva, chiara e facile da ripetere.",
      fr: "Je rends chaque phrase expressive, claire et facile a repeter.",
      de: "Ich mache jeden Satz ausdrucksstark, klar und leicht zu wiederholen.",
      ja: "\u8868\u73FE\u8C4A\u304B\u3067\u660E\u77AD\u306B\u3001\u7E70\u308A\u8FD4\u3057\u3084\u3059\u304F\u8A71\u3057\u307E\u3059\u3002",
      hi: "\u092E\u0948\u0902 \u0939\u0930 \u0935\u093E\u0915\u094D\u092F \u0915\u094B \u0905\u092D\u093F\u0935\u094D\u092F\u0915\u094D\u0924\u093F\u092A\u0942\u0930\u094D\u0923, \u0938\u093E\u092B\u093C \u0914\u0930 \u0926\u094B\u0939\u0930\u093E\u0928\u0947 \u092E\u0947\u0902 \u0906\u0938\u093E\u0928 \u092C\u0928\u093E\u090A\u0901\u0917\u0940\u0964",
      ar: "\u0647\u062E\u0644\u064A \u0643\u0644 \u062C\u0645\u0644\u0629 \u0645\u0639\u0628\u0631\u0629 \u0648\u0648\u0627\u0636\u062D\u0629 \u0648\u0633\u0647\u0644\u0629 \u0627\u0644\u062A\u0643\u0631\u0627\u0631.",
      zh: "\u6211\u4F1A\u8BA9\u6BCF\u53E5\u8BDD\u8868\u8FBE\u6E05\u695A\uFF0C\u4E5F\u66F4\u5BB9\u6613\u8DDF\u8BFB\u3002"
    }
  };
  function getVoicePreviewText(voiceValue, language, normalizeVoice = normalizeTTSVoice) {
    const normalizedVoice = normalizeVoice(voiceValue);
    const voiceLines = VOICE_PREVIEW_LINES[normalizedVoice];
    return voiceLines?.[language] || voiceLines?.en || VOICE_PREVIEW_TEXT[language] || VOICE_PREVIEW_TEXT.en;
  }
  function getPreviewLanguage(targetLang, supportLang) {
    const normalizedSupport = normalizeSupportLanguage(
      supportLang,
      DEFAULT_SUPPORT_LANGUAGE
    );
    if (TTS_LANG_TAG[normalizedSupport]) return normalizedSupport;
    const normalizedTarget = normalizePracticeLanguage(
      targetLang,
      DEFAULT_TARGET_LANGUAGE
    );
    if (TTS_LANG_TAG[normalizedTarget]) return normalizedTarget;
    return DEFAULT_TARGET_LANGUAGE;
  }
  function normalized() {
    const partial = p.partial || {}, latestUser = p.user || {}, themeMode = p.theme || "light", pendingLangRef = { current: p.pendingSupport || null };
    const clampPause = (v) => {
      const n = Number.isFinite(v) ? Math.round(v) : DEFAULT_VOICE_PAUSE_MS;
      return Math.max(200, Math.min(4e3, Math.round(n / 100) * 100));
    };
    const prev = latestUser?.progress || {
      level: "Pre-A1",
      supportLang: "en",
      voice: "marin",
      tutorVoice: normalizeTutorVoice(),
      tutorVoicePersona: translations?.en?.onboarding_persona_default_example || "",
      targetLang: "es",
      showTranslations: true,
      pauseMs: DEFAULT_VOICE_PAUSE_MS,
      helpRequest: "",
      practicePronunciation: false
    };
    const nextSupportLang = normalizeSupportLanguage(
      pendingLangRef.current ?? partial.supportLang ?? prev.supportLang,
      DEFAULT_SUPPORT_LANGUAGE
    );
    const nextVoicePersona = personaForSupportLanguage(
      partial.tutorVoicePersona ?? partial.voicePersona ?? prev.tutorVoicePersona ?? prev.voicePersona,
      nextSupportLang
    ) ?? "";
    const next = {
      ...prev,
      // Preserve all existing progress data including XP
      level: migrateToCEFRLevel(partial.level ?? prev.level) ?? "Pre-A1",
      supportLang: nextSupportLang,
      // Only normalize an EXPLICIT voice change. Unrelated settings saves must
      // not rewrite the stored voice, or flipping the realtime provider would
      // clobber the other provider's saved pick on the next save.
      tutorVoice: partial.tutorVoice !== void 0 ? normalizeTutorVoice(partial.tutorVoice) : prev.tutorVoice ?? normalizeTutorVoice(prev.voice),
      tutorVoicePersona: nextVoicePersona.slice(0, 240),
      targetLang: normalizePracticeLanguage(
        partial.targetLang ?? prev.targetLang,
        DEFAULT_TARGET_LANGUAGE
      ),
      showTranslations: typeof (partial.showTranslations ?? prev.showTranslations) === "boolean" ? partial.showTranslations ?? prev.showTranslations : true,
      pauseMs: clampPause(partial.pauseMs ?? prev.pauseMs),
      helpRequest: String(partial.helpRequest ?? prev.helpRequest ?? "").slice(
        0,
        600
      ),
      practicePronunciation: typeof (partial.practicePronunciation ?? prev.practicePronunciation) === "boolean" ? partial.practicePronunciation ?? prev.practicePronunciation : false
    };
    const nextThemeMode = normalizeThemeMode(
      partial.themeMode ?? latestUser?.themeMode ?? themeMode
    );
    const derivedAppLanguage = normalizeSupportLanguage(
      next.supportLang,
      DEFAULT_SUPPORT_LANGUAGE
    );
    ;
    return { progress: next, themeMode: nextThemeMode, appLanguage: derivedAppLanguage, helpRequest: next.helpRequest || "", practicePronunciation: next.practicePronunciation };
  }
  var api = { run(op, json) {
    p = JSON.parse(json || "{}");
    p.provider = p.provider || "openai";
    const lang = p.language || "en";
    let value;
    if (op === "normalize") value = normalized();
    else if (op === "persona") value = { default: personaDefaultFor(lang), isDefault: isDefaultPersonaValue(p.value), localized: personaForSupportLanguage(p.value, lang) };
    else if (op === "voices") value = { options: getTutorVoiceOptions(), voice: normalizeTutorVoice(p.voice), selected: getTutorVoiceOption(p.voice) };
    else if (op === "preview") {
      const language = getPreviewLanguage(p.target || "es", lang), sanitizedVoice = normalizeTutorVoice(p.voice), personality = String(p.persona || ""), targetLangTag = TTS_LANG_TAG[language] || TTS_LANG_TAG.es;
      const text = getVoicePreviewText(sanitizedVoice, language, normalizeTutorVoice);
      const previewPrompt = [
        personality ? `Use this tutor personality and style: ${String(personality).slice(0, 240)}.` : "Use a friendly, encouraging tutor style.",
        `Speak in ${language}.`,
        `Say only this short voice preview, without adding extra words: ${text || "Hi, I am ready to practice with you."}`
      ].join(" ");
      ;
      value = { voice: sanitizedVoice, language, text, session: p.provider === "gemini" ? { provider: "gemini", voice: sanitizedVoice, instructions: "", previewPrompt, inputLanguageCodes: [], includeTranscriptions: false } : {
        type: "realtime",
        output_modalities: ["audio"],
        instructions: personality ? `You are ${personality}, speaking in the ${targetLangTag} locale. Use the correct pronunciation for that language. You will receive text to read aloud. Read the text EXACTLY as written - word for word, verbatim, but in the voice and tone of your character. Do not interpret, respond to, answer, or comment on the content. Do not have a conversation. Do not add any words. Simply narrate the exact text provided with your character's vocal qualities. Begin immediately with the first word of the text; never preface it with acknowledgments like "Understood" or "Okay".` : `You are an audiobook narrator speaking in the ${targetLangTag} locale. Use the correct pronunciation for that language. You will receive text to read aloud. Read the text EXACTLY as written - word for word, verbatim. Do not interpret, respond to, answer, or comment on the content. Do not have a conversation. Do not add any words. Simply narrate the exact text provided. Begin immediately with the first word of the text; never preface it with acknowledgments like "Understood" or "Okay".`,
        audio: {
          input: { turn_detection: null },
          output: {
            format: { type: "audio/pcm", rate: 24e3 },
            voice: sanitizedVoice
          }
        }
      } };
    } else throw Error("Unknown Settings operation");
    return JSON.stringify(value);
  } };
  return __toCommonJS(stdin_exports);
})();

SettingsSource.api;
