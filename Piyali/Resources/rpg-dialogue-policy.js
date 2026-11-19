var PiyaliRPGDialogue = (() => {
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
  var LANGUAGE_FALLBACK_LABELS = {
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
    ja: "Japanese (\u65E5\u672C\u8A9E)",
    ru: "Russian",
    de: "German",
    el: "Greek",
    pl: "Polish",
    ga: "Irish",
    yua: "Yucatec Maya"
  };
  var LANGUAGE_PROMPT_LABELS = {
    ar: "Egyptian Arabic (\u0627\u0644\u0639\u0631\u0628\u064A\u0629 \u0627\u0644\u0645\u0635\u0631\u064A\u0629)",
    zh: "Mandarin Chinese (\u666E\u901A\u8BDD\u4E2D\u6587)",
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
    ja: "Japanese (\u65E5\u672C\u8A9E)"
  };
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
  function getLanguagePromptName(code) {
    const normalized = normalizeSupportedCode(code);
    if (!normalized) return "";
    return LANGUAGE_PROMPT_LABELS[normalized] || LANGUAGE_FALLBACK_LABELS[normalized] || normalized.toUpperCase();
  }

  // ../nosabos/nosabos/src/utils/dialogueFormatting.js
  function cleanSpoken(s) {
    let res = String(s || "").trim();
    res = res.replace(/^[\"'\u201c\u2018]+|[\"'\u201d\u2019]+$/g, "").trim();
    if (res.endsWith(",")) {
      res = res.slice(0, -1).trim();
    }
    return res;
  }
  function cleanSubtext(s) {
    let res = String(s || "").trim();
    res = res.replace(/^[*_()[\]]+|[*_()[\]]+$/g, "").trim();
    return res;
  }
  function splitDialogueSubtext(rawText) {
    if (!rawText || typeof rawText !== "string") {
      return { subtext: "", spokenText: "" };
    }
    let text = rawText.trim();
    if (!text) return { subtext: "", spokenText: "" };
    if (text.startsWith('"') && text.endsWith('"') && (text.match(/"/g) || []).length === 2 || text.startsWith("'") && text.endsWith("'") && (text.match(/'/g) || []).length === 2 || text.startsWith("\u201C") && text.endsWith("\u201D") || text.startsWith("\u2018") && text.endsWith("\u2019")) {
      text = text.slice(1, -1).trim();
    }
    const leadingItalicMatch = text.match(/^([*_]{1,2})([^*_]+)\1\s*(?:[:,-]\s*)?([\s\S]+)$/);
    if (leadingItalicMatch) {
      return {
        subtext: cleanSubtext(leadingItalicMatch[2]),
        spokenText: cleanSpoken(leadingItalicMatch[3])
      };
    }
    const leadingParenMatch = text.match(/^(\([^)]{2,120}\)|\[[^\]]{2,120}\])\s*(?:[:,-]\s*)?([\s\S]+)$/);
    if (leadingParenMatch) {
      return {
        subtext: cleanSubtext(leadingParenMatch[1]),
        spokenText: cleanSpoken(leadingParenMatch[2])
      };
    }
    const narrationQuoteMatch = text.match(/^([^"\u201c\u2018]+?)(?:,\s*|:\s*|\s+)(["'\u201c\u2018])([\s\S]+?)\2(?:\s*\.?)*$/);
    if (narrationQuoteMatch) {
      const narration = cleanSubtext(narrationQuoteMatch[1]);
      const quoted = cleanSpoken(narrationQuoteMatch[3]);
      if (narration.length > 1 && quoted.length > 0) {
        return {
          subtext: narration,
          spokenText: quoted
        };
      }
    }
    const quoteNarrationMatch = text.match(/^(["'\u201c\u2018])([\s\S]+?)\1(?:,\s*|\s+)([^"\u201c\u2018]{2,80})$/);
    if (quoteNarrationMatch) {
      return {
        subtext: cleanSubtext(quoteNarrationMatch[3]),
        spokenText: cleanSpoken(quoteNarrationMatch[2])
      };
    }
    const colonMatch = text.match(/^([^:\n]{2,60}?(?:says|said|dice|dijo|dit|sagt|smiles|looks|laughs|replies|exclaims|giggles|shouts|whispers))\s*:\s*([\s\S]+)$/i);
    if (colonMatch) {
      return {
        subtext: cleanSubtext(colonMatch[1]),
        spokenText: cleanSpoken(colonMatch[2])
      };
    }
    const trailingItalicMatch = text.match(/^([\s\S]+?)\s*([*_]{1,2})([^*_]+)\2$/);
    if (trailingItalicMatch) {
      return {
        subtext: cleanSubtext(trailingItalicMatch[3]),
        spokenText: cleanSpoken(trailingItalicMatch[1])
      };
    }
    const trailingParenMatch = text.match(/^([\s\S]+?)\s*(\([^)\n]{2,80}\)|\[[^\]\n]{2,80}\])$/);
    if (trailingParenMatch) {
      return {
        subtext: cleanSubtext(trailingParenMatch[2]),
        spokenText: cleanSpoken(trailingParenMatch[1])
      };
    }
    return {
      subtext: "",
      spokenText: text
    };
  }

  // <stdin>
  function splitIntoSentences(text) {
    if (!text) return [];
    const result = text.match(/[^.!?¡¿。！？]*[.!?。！？]+/g);
    if (!result) return text.trim() ? [text.trim()] : [];
    const joined = result.join("");
    const remainder = text.slice(joined.length).trim();
    if (remainder) result.push(remainder);
    return result.map((s) => s.trim()).filter(Boolean);
  }
  function normalizeCharacterNameList(names = []) {
    return Array.from(
      new Set(names.map((name) => String(name || "").trim()).filter(Boolean))
    );
  }
  function plan(p) {
    const dialogue = p.dialogue || null, inventory = p.inventory || [], ui = p.ui || {}, objectSearchCopy = p.objectSearchCopy || {}, npcNameMap = Object.fromEntries((p.names || []).map((n, i) => [i, n])), supportLangName = getLanguagePromptName(p.support || "en") || p.support || "en";
    const buildCharacterRosterPrompt = () => {
      const assignedNames = normalizeCharacterNameList(
        Object.values(npcNameMap || {})
      );
      if (!assignedNames.length) return "";
      return [
        `Assigned character roster: ${assignedNames.join(", ")}.`,
        "Only use those exact names when referring to people in this scene.",
        "Do not invent, translate, swap, or mention any other person names.",
        "Prefer pronouns or second-person phrasing unless a roster name is truly necessary."
      ].join("\n");
    };
    const dialogueNpcText = (() => {
      const raw = dialogue?.npcReply || dialogue?.node?.npcLine || dialogue?.node?.prompt || dialogue?.question?.prompt || "";
      const { spokenText } = splitDialogueSubtext(raw);
      return spokenText || raw;
    })();
    const dialogueTextLines = (() => splitIntoSentences(dialogueNpcText))();
    const dialogueChoiceTexts = (() => {
      if (dialogue?.node?.responseMode !== "choice") return [];
      return (dialogue.node?.choices || []).map(
        (optRaw) => typeof optRaw === "string" ? optRaw : optRaw?.text || ""
      );
    })();
    const dialogueActionTargets = (() => {
      if (!dialogue?.node) return [];
      if (["gather", "objectSearch"].includes(dialogue.node.responseMode)) {
        const submitPrompt = dialogue.node.responseMode === "objectSearch" ? objectSearchCopy.chooseItem : objectSearchCopy.chooseItem;
        const continueLabel = dialogue.node.responseMode === "objectSearch" ? objectSearchCopy.continueSearching : objectSearchCopy.continueSearching;
        return [
          ...inventory.length > 0 ? [{ key: "submitPrompt", text: submitPrompt }] : [],
          { key: "continue", text: continueLabel }
        ];
      }
      if (dialogue.node.responseMode === "none") {
        return [{ key: "continue", text: ui.continue }];
      }
      return [];
    })();
    const translationTargets = [
      ...dialogueTextLines.map((text, index) => ({
        kind: "line",
        index,
        text
      })),
      ...dialogueChoiceTexts.map((text, index) => ({
        kind: "choice",
        index,
        text: String(text || "").trim()
      })).filter((entry) => entry.text),
      ...dialogueActionTargets.map((entry) => ({
        kind: "action",
        key: entry.key,
        text: String(entry.text || "").trim()
      })).filter((entry) => entry.text)
    ].filter((entry) => String(entry.text || "").trim());
    const prompt = [
      `Translate each entry below into ${supportLangName}.`,
      buildCharacterRosterPrompt(),
      "Preserve every character name exactly as written.",
      "Output plain text only.",
      `Return exactly ${translationTargets.length} line${translationTargets.length > 1 ? "s" : ""}.`,
      "Each line must be only the translation for the matching entry index.",
      "No numbering, labels, markdown, or commentary.",
      "",
      "Entries:",
      ...translationTargets.map(
        (entry, index) => `${index + 1}. ${entry.text}`
      )
    ].join("\n");
    ;
    return { text: dialogueNpcText, lines: dialogueTextLines, choices: dialogueChoiceTexts, actions: dialogueActionTargets, targets: translationTargets, prompt };
  }
  function initial(p) {
    const { lines: dialogueTextLines, choices: dialogueChoiceTexts, actions: dialogueActionTargets } = p;
    let state = {};
    const setLineTranslations = (v) => state.lineTranslations = v, setChoiceTranslations = (v) => state.choiceTranslations = v, setActionTranslations = (v) => state.actionTranslations = v;
    const nextLines = Array(dialogueTextLines.length).fill("");
    const nextChoices = Array(dialogueChoiceTexts.length).fill("");
    const nextActions = dialogueActionTargets.reduce((acc, entry) => {
      acc[entry.key] = "";
      return acc;
    }, {});
    setLineTranslations(dialogueTextLines.length ? [...nextLines] : null);
    setChoiceTranslations(dialogueChoiceTexts.length ? [...nextChoices] : null);
    setActionTranslations(
      dialogueActionTargets.length ? { ...nextActions } : null
    );
    return { ...state, receivedCount: 0, lineBuffer: "" };
  }
  function append(p) {
    const { lines: dialogueTextLines, choices: dialogueChoiceTexts, actions: dialogueActionTargets, targets: translationTargets } = p.plan;
    let state = p.state, nextLines = state.lineTranslations || [], nextChoices = state.choiceTranslations || [], nextActions = state.actionTranslations || {}, receivedCount = state.receivedCount || 0, lineBuffer = state.lineBuffer || "";
    const setLineTranslations = (v) => state.lineTranslations = v, setChoiceTranslations = (v) => state.choiceTranslations = v, setActionTranslations = (v) => state.actionTranslations = v;
    const syncTranslations = () => {
      setLineTranslations(dialogueTextLines.length ? [...nextLines] : null);
      setChoiceTranslations(
        dialogueChoiceTexts.length ? [...nextChoices] : null
      );
      setActionTranslations(
        dialogueActionTargets.length ? { ...nextActions } : null
      );
    };
    const applyLine = (rawLine) => {
      if (receivedCount >= translationTargets.length) return;
      const clean = String(rawLine || "").replace(/^\s*\d+[).:-]\s*/, "").trim();
      if (!clean) return;
      const target = translationTargets[receivedCount];
      if (target.kind === "line") {
        nextLines[target.index] = clean;
      } else if (target.kind === "choice") {
        nextChoices[target.index] = clean;
      } else if (target.kind === "action") {
        nextActions[target.key] = clean;
      }
      receivedCount += 1;
      syncTranslations();
    };
    const ct = p.chunk || "";
    lineBuffer += ct;
    const segments = lineBuffer.split(/\r?\n/);
    lineBuffer = segments.pop() || "";
    for (const seg of segments) applyLine(seg);
    ;
    if (p.final && lineBuffer.trim()) applyLine(lineBuffer);
    return { ...state, receivedCount, lineBuffer };
  }
  var api = { run(op, json) {
    const p = JSON.parse(json);
    let result;
    if (op === "plan") result = plan(p);
    else if (op === "initial") result = initial(p);
    else if (op === "append") result = append(p);
    else if (op === "presentation") {
      const dialogue = p.dialogue || { node: {} };
      const parsedReply = splitDialogueSubtext(
        dialogue.npcReply
      );
      const rawPrompt = dialogue.node?.npcLine || dialogue.node?.prompt || dialogue.question?.prompt || "";
      const parsedNode = splitDialogueSubtext(rawPrompt);
      const activeSceneLine = dialogue.sceneLine || (dialogue.npcReply ? parsedReply.subtext : dialogue.node?.sceneLine || parsedNode.subtext) || "";
      const activeSpokenPrompt = parsedNode.subtext ? parsedNode.spokenText : rawPrompt;
      const activeReplyText = parsedReply.subtext ? parsedReply.spokenText : dialogue.npcReply;
      ;
      result = { caption: activeSceneLine, prompt: activeSpokenPrompt, reply: activeReplyText, isReply: !!dialogue.npcReply };
    } else if (op === "motion") result = { "charDelayMs": 18, "fadeMilliseconds": 120, "timing": "ease-in" };
    else throw Error("Unknown original dialogue operation");
    return JSON.stringify(result ?? null);
  } };
  return __toCommonJS(stdin_exports);
})();

PiyaliRPGDialogue.api;
