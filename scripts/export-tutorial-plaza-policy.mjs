import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";
import { gunzipSync } from "node:zlib";

const reference = path.resolve(process.argv[2] ?? "../nosabos/nosabos");
const requireReference = createRequire(path.join(reference, "package.json"));
const { build } = requireReference("esbuild");
const flags = "brazilian chinese egyptian french german greek indian irish italian japanese mexican netherlands polish russian usa";
const adapters = {
  three: "export class CanvasTexture { constructor(image) { this.image = image; } } export const NearestFilter = 1003, SRGBColorSpace = 'srgb';",
  responses: "export const callResponses = request => globalThis.piyaliLegacyResponses(request);",
  terms: "export const loadMultiLevelLearningPath = async () => { throw Error('Tutorial terms must come from its lesson'); };",
  flags: flags.split(" ").map(name => `export const ${name}Flag = null;`).join("\n"),
};
const plugin = {
  name: "native-tutorial-inputs",
  setup(builder) {
    builder.onResolve({ filter: /^three$/ }, () => ({ path: "three", namespace: "native" }));
    builder.onResolve({ filter: /\/utils\/llm$/ }, () => ({ path: "responses", namespace: "native" }));
    builder.onResolve({ filter: /\/data\/skillTree\/index\.js$/ }, () => ({ path: "terms", namespace: "native" }));
    builder.onResolve({ filter: /\/flagsIcons\/flags$/ }, () => ({ path: "flags", namespace: "native" }));
    builder.onLoad({ filter: /.*/, namespace: "native" }, ({ path: key }) => ({ contents: adapters[key] }));
  },
};

const tutor = await readFile(path.join(reference, "src/components/Tutor.jsx"), "utf8");
const failureCopyStart = tutor.indexOf('en: "The game could not start. Please try again."');
const failureCopyEnd = tutor.indexOf("\n          })", failureCopyStart);
if (failureCopyStart < 0 || failureCopyEnd < failureCopyStart) throw Error("The localized game failure copy moved");
const failureCopy = tutor.slice(failureCopyStart, failureCopyEnd);

const rpg = await readFile(path.join(reference, "src/components/RPGGame/index.jsx"), "utf8");
function between(start, end, after = 0) {
  const first = rpg.indexOf(start, after);
  const last = rpg.indexOf(end, first + start.length);
  if (first < 0 || last < 0) throw Error("Missing source dialogue section: " + start);
  return rpg.slice(first, last);
}

// The plaza has no authored environment ID. It uses the same neutral grade
// and indoor pool/mote textures already exported from the civic renderer.
const library = JSON.parse(gunzipSync(await readFile(new URL("../Piyali/Resources/rpg-environment.json.gz", import.meta.url))));
const civic = Object.values(library.plans).find(plan => plan.identity.environment === "civic");
const atmosphereImages = {
  grade: civic.grade,
  pool: civic.layers.find(layer => layer.z === 55).image,
  mote: civic.layers.find(layer => layer.motion?.kind === "mote").image,
};
const rendererStart = rpg.indexOf("const TILE = activeMap.tileSize || scenario.tileSize;");
const atmosphereSeed = between("const ambientSeedKey =", "    const getTile =", rendererStart);
const poolAndMoteSetup = between("const ambientPoolTexture =", "    const worldObjects =", rendererStart);
const atmosphere = `
export function atmosphere(input) {
  const { width: MAP_W, height: MAP_H, id, trees } = JSON.parse(input);
  const TILE = 32, isOutdoorMap = false;
  const scenario = { id }, activeMap = scenario;
  ${atmosphereSeed}
  // The original tile loop consumes one draw for each animated tree
  // before it places the light pools and motes.
  for (let i = 0; i < trees; i++) ambientRandom();
  const images = ${JSON.stringify(atmosphereImages)};
  const document = { createElement: () => ({ getContext: () => ({ fillRect() {} }) }) };
  const makeSoftDiscTexture = () => images.pool;
  const ambientLightGroup = { add() {} }, ambientMoteGroup = { add() {} }, ambientMotes = [];
  const pools = [];
  const THREE = {
    CanvasTexture: class {},
    PlaneGeometry: class { constructor(width, height) { Object.assign(this, { width, height }); } },
    MeshBasicMaterial: class { constructor(options) { Object.assign(this, options); } },
    Mesh: class {
      constructor(geometry, material) {
        Object.assign(this, { geometry, material, rotation: { z: 0 } });
        this.position = { set(x, y) { Object.assign(this, { x, y }); } };
        this.scale = { x: 1, y: 1, set(x, y) { Object.assign(this, { x, y }); } };
        if (material.map === images.pool) pools.push(this);
      }
    },
  };
  ${poolAndMoteSetup}
  const layer = (mesh, image, blend, smooth, motion) => ({
    image, blend, smooth, motion,
    x: mesh.position.x, y: mesh.position.y,
    width: mesh.geometry.width, height: mesh.geometry.height, z: mesh.renderOrder,
    scaleX: mesh.scale.x, scaleY: mesh.scale.y,
    rotation: mesh.rotation.z, alpha: mesh.material.opacity,
  });
  return JSON.stringify({
    identity: { scenario: id, map: id, environment: "", area: "", decorKinds: [] },
    grade: images.grade,
    layers: [
      ...pools.map(mesh => layer(mesh, images.pool, "add", true)),
      ...ambientMotes.map(({ mesh, ...motion }) => layer(mesh, images.mote, "normal", false, { ...motion, kind: "mote" })),
    ],
  });
}
`;

const choiceStart = rpg.indexOf("const generateDynamicChoices =");
const bridgeStart = rpg.indexOf("// Pre-generate contextual player bridge");
const choices = between("const prompt = buildStrictDialoguePrompt(", "\n\n      try {", choiceStart);
const bridge = between("const bridgePrompt = buildStrictDialoguePrompt(", "\n      callResponses", bridgeStart);
const greeting = between("const npcGreetPrompt = buildStrictDialoguePrompt(", "\n          return callResponses", bridgeStart);
const dialoguePolicy = `
${between("function escapeRegExp(", "function applyNameMappingDeep(")}
${between("function normalizeCharacterNameList(", "\n}", rpg.indexOf("function applyNameMappingDeep("))}
}

export function dialogue(operation, raw) {
  const { lesson, target: targetLang, support: supportLang, user, npcName, personality,
    seed, npcPersonality, history: historyContext, npcLine, answer: heard, nextNodeLine, npcNameMap,
    roster, bridgeLine: text, response, firstNextNodeId } = JSON.parse(raw);
  const history = historyContext;
  const useMemo = fn => fn();
  const useCallback = fn => fn;
  const useUserStore = { getState: () => ({ user }) };
  const reviewContext = lesson.gameReviewContext || buildGameReviewContext({ lesson, targetLang });
  const cefrLevel = reviewContext?.cefrLevel || lesson.content?.game?.cefrLevel || null;
  const adaptiveCefrLevel = reviewContext?.isTutorial ? cefrLevel :
    generationPerformanceContextFor(user, targetLang).suggestedQuestionLevel;
  const supportLangName = getLanguagePromptName(supportLang) || supportLang;
  ${between("const cefrDialogueRule = useMemo", "  const localStorageSettings = ")}
  ${between("const targetLangName = useMemo", "  const objectExamineCefrPromptRule = ")}
  ${between("const strictTargetLanguageGuard = useMemo", "  const objectExaminePromptContext = ")}
  ${between("const buildCharacterRosterPrompt = useCallback", "  // Authored-episode speech turns")}
  // These names are already assigned by Swift before any dialogue opens.
  for (const name of roster) npcNameMap[name] ??= name;
  const node = { npcLine };
  const nextNpcName = npcName;
  switch (operation) {
    case "choice": { ${choices} return prompt; }
    case "bridge": { ${bridge} return bridgePrompt; }
    case "greeting": { ${greeting} return npcGreetPrompt; }
    case "speech": return buildDynamicSpeechReplyPrompt({ npcName, heard, seed, historyContext, personality, npcLine, nextNodeLine });
    case "responseLine": return applyNameMappingToText((response || "").trim(), npcNameMap);
    case "responseChoices": {
      const match = (response || "").match(/\\[[\\s\\S]*\\]/);
      if (!match) return "[]";
      const parsed = JSON.parse(match[0]);
      if (!Array.isArray(parsed) || parsed.length < 2) return "[]";
      return JSON.stringify(parsed.slice(0, 3).map(c => {
        const rawReply = applyNameMappingToText(String(c.reply || c.npcReply || ""), npcNameMap);
        const { subtext, spokenText } = splitDialogueSubtext(rawReply);
        return {
          text: applyNameMappingToText(String(c.text || ""), npcNameMap),
          npcReply: spokenText || rawReply,
          sceneLine: subtext || null,
          nextNodeId: firstNextNodeId,
        };
      }));
    }
  }
}
`;

// The browser holds the generated scenario in memory. Swift serializes its
// resolved world and owns the provider requests, saved run, and renderer.
const terrain = await readFile(new URL("./tutorial-plaza-pixels.js", import.meta.url), "utf8");
const entry = `
import { generateScenarioWithAI, TUTORIAL_MAP_ID, mulberry32 } from './src/components/RPGGame/scenarios.js';
import { createGroundDecalTexture, createGroundLayerCanvas, createSpriteTexture, createTileTexture } from './src/components/RPGGame/pixelArt.js';
import { buildGameReviewContext } from './src/utils/gameReviewContext.js';
import { generationPerformanceContextFor } from './src/utils/performanceEloModel.js';

import { getLanguagePromptName } from './src/constants/languages.js';
import { getAdultBeginnerToneRule } from './src/utils/adultBeginnerTone.js';
import { splitDialogueSubtext } from './src/utils/dialogueFormatting.js';

let pending, result;
globalThis.piyaliLegacyResponses = request => new Promise((resolve, reject) => {
  pending = { request, resolve, reject };
});

function serialize(scenario, target, level) {
  const tiles = scenario.generate();
  const solidTiles = Object.entries(scenario.tiles).filter(([, tile]) => tile.solid).map(([id]) => Number(id));
  const placements = scenario.gatherPlacements?.length ? scenario.gatherPlacements : [];
  if (!placements.length && scenario.quest?.gatherData?.all?.length) {
    const occupied = new Set(scenario.npcs.map(npc => npc.tx + "," + npc.ty));
    occupied.add(scenario.playerStart.x + "," + scenario.playerStart.y);
    for (const item of scenario.quest.gatherData.all) {
      for (let attempt = 0; attempt < 80; attempt++) {
        const tx = 2 + Math.floor(Math.random() * (scenario.mapWidth - 4));
        const ty = 2 + Math.floor(Math.random() * (scenario.mapHeight - 4));
        const key = tx + "," + ty;
        if (solidTiles.includes(tiles[ty * scenario.mapWidth + tx]) || occupied.has(key)) continue;
        occupied.add(key);
        placements.push({ ...item, tx, ty });
        break;
      }
    }
  }
  const map = {
    id: scenario.id, name: scenario.name, portals: [],
    world: {
      width: scenario.mapWidth, height: scenario.mapHeight, start: scenario.playerStart,
      tiles, solidTiles,
      objects: scenario.objects || [],
    },
  };
  return {
    id: scenario.id, theme: "tutorial", level, baseLanguage: target, name: scenario.name,
    startMapId: scenario.id, maps: [map], quest: scenario.quest,
    tileDefinitions: scenario.tiles,
    npcs: scenario.npcs.map(npc => ({ ...npc, mapId: scenario.id })),
    gatherPlacements: placements.map(item => ({ ...item, mapId: item.mapId || scenario.id })),
  };
}

${terrain}
${atmosphere}
${dialoguePolicy}

export function start(input) {
  const { lesson, target, support, user, testSeed } = JSON.parse(input);
  if (Number.isInteger(testSeed)) Math.random = mulberry32(testSeed);
  const game = lesson.content.game;
  const context = lesson.gameReviewContext || buildGameReviewContext({ lesson, targetLang: target });
  const terms = [...(context?.reviewTerms || []), ...(game.focusPoints || []), ...(game.unitTopics || []),
    game.topic, game.unitTitle].filter(Boolean);
  const level = context?.cefrLevel || game.cefrLevel || "A1";
  const performance = generationPerformanceContextFor(user, target);
  generateScenarioWithAI(game.sceneId || TUTORIAL_MAP_ID, target, support, terms, level, context, performance)
    .then(scenario => { result = { world: serialize(scenario, target, level) }; })
    .catch(() => { result = { failed: true }; });
}

export function next() {
  return JSON.stringify(result || (pending ? {
    prompt: pending.request.input,
    generationConfig: pending.request.generationConfig,
  } : {}));
}

export function failureMessage(language) {
  const copy = { ${failureCopy} };
  return copy[language] || copy.en;
}

export function reply(value, failed) {
  const request = pending;
  pending = undefined;
  if (failed) request.reject(Error("Provider request failed"));
  else request.resolve(value);
}
`;

const scenarioSource = await readFile(path.join(reference, "src/components/RPGGame/scenarios.js"), "utf8");
if (!scenarioSource.includes('export const TUTORIAL_MAP_ID = "tutorialPlaza"')) {
  throw Error("The original tutorial map changed");
}
const { outputFiles } = await build({
  stdin: { contents: entry, resolveDir: reference, sourcefile: "tutorial-plaza-entry.js" },
  plugins: [plugin], bundle: true, write: false, platform: "neutral", format: "iife",
  globalName: "PiyaliTutorialPlaza", target: "es2020", minify: true, legalComments: "none",
});
await writeFile(new URL("../Piyali/Resources/tutorial-plaza-policy.js", import.meta.url), outputFiles[0].contents);
