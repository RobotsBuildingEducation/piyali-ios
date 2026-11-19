(()=>{const DEFAULT_TTS_VOICE = "ash";
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
const REALTIME_CACHE_FORMAT = "realtime-v7";
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
function sanitizeVoice(voice) {
  return SUPPORTED_TTS_VOICES.has(voice) ? voice : DEFAULT_TTS_VOICE;
}
function getCacheKey(
  text,
  langTag,
  responseFormat = DEFAULT_TTS_FORMAT,
  voice = DEFAULT_TTS_VOICE,
  personality = "",
) {
  const normalizedText = (text || "").trim().replace(/\s+/g, " ");
  const normalizedPersonality = (personality || "").trim().replace(/\s+/g, " ");
  return [
    "v2",
    responseFormat,
    langTag,
    sanitizeVoice(voice),
    normalizedPersonality,
    normalizedText,
  ].join("::");
}return{run(op,json){const p=JSON.parse(json);if(op==='key')return JSON.stringify(getCacheKey(p.text,p.langTag||TTS_LANG_TAG[p.language]||TTS_LANG_TAG.es,REALTIME_CACHE_FORMAT,p.voice,p.personality));if(op==='rules')return JSON.stringify({ttlMilliseconds:CACHE_TTL_MS,format:REALTIME_CACHE_FORMAT});throw Error(op)}}})()
