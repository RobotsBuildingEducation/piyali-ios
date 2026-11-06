var SourceReadingStoryAudio = (() => {
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

  // ../nosabos/nosabos/src/features/stories/storyCharacters.js
  var DEFAULT_STORY_VOICE = "ash";
  var RPG_STORY_CHARACTERS = [
    {
      id: "hamster",
      name: "Sheilfer",
      role: "radio host / narrator",
      voice: "echo",
      personality: "the narrator of the app, a relaxed but confident male voice guiding the experience",
      portraitIndex: "33",
      portraitPool: ["33", "26", "25", "22"]
    },
    {
      id: "frog",
      name: "Jiraiya",
      role: "wise elder / toad sage",
      voice: "ash",
      personality: "an ancient male toad sage, wise and measured with a deep gravelly tone",
      portraitIndex: "29",
      portraitPool: ["29", "32", "36"]
    },
    {
      id: "purple-girl",
      name: "Yoruichi",
      role: "spirited martial artist / cheerful adventurer",
      voice: "marin",
      personality: "a joyful woman with a Japanese accent, warm and enthusiastic",
      portraitIndex: "31",
      portraitPool: ["31", "39", "34"]
    },
    {
      id: "cat",
      name: "Neko",
      role: "witty companion / playful feline",
      voice: "sage",
      personality: "a sarcastic female cat humanoid, dry wit and playful disdain in every word",
      portraitIndex: "40",
      portraitPool: ["40", "38", "37", "28", "24"]
    },
    {
      id: "yachiru",
      name: "Yachiru",
      role: "cheerful companion / energetic friend",
      voice: "shimmer",
      personality: "an adorable, bubbly companion with childlike energy, excitable, warm, and playful",
      portraitIndex: "18",
      portraitPool: ["18", "20", "21", "23", "27", "30", "35"]
    }
  ];
  var USER_CHARACTER = {
    id: "user",
    name: "You",
    role: "learner / radio caller / conversational partner",
    isUser: true,
    portraitIndex: "35",
    petType: "ghost",
    portraitPool: ["35", "36", "31", "24"]
  };
  function getUserPetType(user = null) {
    let pet = null;
    if (typeof window !== "undefined") {
      try {
        const storedRpg = window.localStorage?.getItem("nosabos:rpg-companion:v2") || window.localStorage?.getItem("nosabos:rpg-companion:v1");
        pet = (storedRpg && storedRpg.trim().toLowerCase() !== "girl" ? storedRpg : null) || window.localStorage?.getItem("dailyGoalPetType");
      } catch {
      }
    }
    if (!pet && user) {
      pet = user?.dailyGoalPetType || user?.petType || user?.rpgCompanion;
    }
    const norm = String(pet || "").trim().toLowerCase();
    if (!norm || norm === "girl") {
      return "ghost";
    }
    const validPetTypes = ["ghost", "alien", "robot", "slime", "dog", "axolotl"];
    return validPetTypes.includes(norm) ? norm : "ghost";
  }
  function isUserCharacter(name, user = null) {
    if (!name || typeof name !== "string") return false;
    const norm = name.trim().toLowerCase();
    if (norm === "you" || norm === "t\xFA" || norm === "toi" || norm === "du" || norm === "tu") return true;
    if (user?.name && norm === user.name.trim().toLowerCase()) return true;
    if (user?.displayName && norm === user.displayName.trim().toLowerCase()) return true;
    return false;
  }
  function getStoryCharacter(name, user = null) {
    if (!name || typeof name !== "string") return null;
    if (isUserCharacter(name, user)) {
      return {
        ...USER_CHARACTER,
        name: user?.name || user?.displayName || "You",
        petType: getUserPetType(user)
      };
    }
    const norm = name.trim().toLowerCase();
    const match = RPG_STORY_CHARACTERS.find(
      (c) => c.name.toLowerCase() === norm || c.id.toLowerCase() === norm
    );
    if (match) return match;
    const hash = Array.from(norm).reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const fallbackId = String(hash % 40 + 1);
    return {
      id: norm,
      name: name.trim(),
      role: "character",
      voice: DEFAULT_STORY_VOICE,
      personality: null,
      portraitIndex: fallbackId
    };
  }
  function getStoryCharacterVoice(name, user = null) {
    if (isUserCharacter(name, user)) {
      return user?.progress?.voice || DEFAULT_STORY_VOICE;
    }
    const char = getStoryCharacter(name, user);
    return char?.voice || DEFAULT_STORY_VOICE;
  }
  function getStoryCharacterPersonality(name) {
    if (isUserCharacter(name)) return null;
    const char = getStoryCharacter(name);
    return char?.personality || null;
  }

  // <stdin>
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
  var LOW_LATENCY_TTS_FORMAT = "wav";
  var RANDOM_DEFAULT_TTS_VOICE_KEY = "nosabos:realtime-mini-default-voice";
  var randomDefaultTTSVoice = null;
  function sanitizeVoice(voice) {
    return SUPPORTED_TTS_VOICES.has(voice) ? voice : DEFAULT_TTS_VOICE;
  }
  function getRandomDefaultTTSVoice() {
    if (randomDefaultTTSVoice) return randomDefaultTTSVoice;
    try {
      if (typeof window !== "undefined") {
        window.localStorage?.removeItem(RANDOM_DEFAULT_TTS_VOICE_KEY);
      }
    } catch {
    }
    randomDefaultTTSVoice = DEFAULT_TTS_VOICE;
    return randomDefaultTTSVoice;
  }
  function getPreferredTTSVoice(...candidates) {
    for (const voice of candidates) {
      if (SUPPORTED_TTS_VOICES.has(voice)) return voice;
    }
    return getRandomDefaultTTSVoice();
  }
  var BCP47 = {
    es: { tts: "es-MX" },
    en: { tts: "en-US" },
    ar: { tts: "ar-EG" },
    zh: { tts: "zh-CN" },
    pt: { tts: "pt-BR" },
    fr: { tts: "fr-FR" },
    it: { tts: "it-IT" },
    ja: { tts: "ja-JP" },
    nl: { tts: "nl-NL" },
    nah: { tts: "es-MX" },
    ru: { tts: "ru-RU" },
    de: { tts: "de-DE" },
    el: { tts: "el-GR" },
    yua: { tts: "es-MX" }
  };
  function storyRequest(p) {
    const turn = p.turn, user = p.user || null, targetLang = p.language;
    const voice = getStoryCharacterVoice(turn.speaker, user);
    const personality = getStoryCharacterPersonality(turn.speaker);
    return {
      text: turn.target,
      langTag: TTS_LANG_TAG[targetLang] || targetLang,
      voice,
      personality: personality || void 0
    };
  }
  function readingRequest(p) {
    const text = p.text, langTag = (BCP47[p.language] || BCP47.es).tts;
    return {
      text,
      langTag: langTag || TTS_LANG_TAG.es,
      voice: getPreferredTTSVoice(),
      responseFormat: LOW_LATENCY_TTS_FORMAT
    };
  }
  function build(op, p) {
    const request = op === "story" ? storyRequest(p) : readingRequest(p), targetLangTag = request.langTag, sanitizedVoice = sanitizeVoice(request.voice), personality = request.personality;
    return { request, session: {
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
  }
  var api = { run(op, json) {
    return JSON.stringify(build(op, JSON.parse(json)));
  } };
  return __toCommonJS(stdin_exports);
})();

SourceReadingStoryAudio.api;
