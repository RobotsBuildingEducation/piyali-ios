// Original Tutor visible text and replay fallback rules. Media/cache I/O is native.
(function(){let randomDefaultTTSVoice=null;const RANDOM_DEFAULT_TTS_VOICE_KEY='unused-native';const DEFAULT_TTS_VOICE = "ash";
const TTS_LANG_TAG = {
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
  yua: "es-MX",
};
const SUPPORTED_TTS_VOICES = new Set([
  "alloy",
  "echo",
  "shimmer",
  "coral",
  "verse",
  "ballad",
  "ash",
  "sage",
  "marin",
  "cedar",
]);
function getRandomDefaultTTSVoice() {
  if (randomDefaultTTSVoice) return randomDefaultTTSVoice;

  try {
    if (typeof window !== "undefined") {
      window.localStorage?.removeItem(RANDOM_DEFAULT_TTS_VOICE_KEY);
    }
  } catch {
    // Local storage may be blocked; fall back to in-memory default.
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
function getBaseLanguageCode(code) {
  return String(code || "")
    .trim()
    .toLowerCase()
    .split(/[-_]/)[0];
}
function sanitizeTutorAssistantText(text = "", { trim = true } = {}) {
  const value = String(text || "")
    .replace(/<\/?\s*(?:pause|break|silence)\b[^>]*>/gi, " ")
    .replace(/<\s*\/?\s*(?:pause|break|silence)\s*$/gi, "")
    .replace(/\[\s*(?:pause|break|silence)\s*\]/gi, " ")
    .replace(/\(\s*(?:pause|break|silence)\s*\)/gi, " ")
    .replace(/\s+([,.;:!?])/g, "$1")
    .replace(/([¿¡])\s+/g, "$1")
    .replace(/[ \t]{2,}/g, " ");
  return trim ? value.trim() : value;
}
function getTutorMessageVisibleText(message) {
  return sanitizeTutorAssistantText(
    `${message?.textFinal || ""}${message?.textStream || ""}`,
  );
}
return {run:function(input){const p=JSON.parse(input),mid=p.id,messagesRef={current:p.messages||[]},voiceRef={current:p.voice},targetLangRef={current:p.target};function plan(){      const message = messagesRef.current.find((item) => item.id === mid);
      const text = getTutorMessageVisibleText(message);
      if (!text || message?.role !== "assistant") {

        return;
      }

      const langCode =
        getBaseLanguageCode(message.lang || targetLangRef.current) ||
        getBaseLanguageCode(targetLangRef.current) ||
        "es";

const langTag=TTS_LANG_TAG[langCode]||TTS_LANG_TAG.es;return {text,voice:getPreferredTTSVoice(voiceRef.current),langTag,language:getBaseLanguageCode(langTag)}}return JSON.stringify(plan()||null)}}})()