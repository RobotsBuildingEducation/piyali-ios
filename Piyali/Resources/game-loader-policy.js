var PiyaliGameLoader = (() => {
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

  // ../nosabos/nosabos/src/components/rpgCompanionSprites.js
  var T = 48;
  var DOG = {
    fur: "#d97706",
    furDark: "#a85d04",
    furLight: "#e5952a",
    belly: "#fef3c7",
    ear: "#92400e",
    paw: "#78350f",
    accent: "#2563eb",
    nose: "#111827",
    tongue: "#fb7185",
    eyeWhite: "#ffffff",
    eyePupil: "#1f2937",
    outline: "#1a1a2e"
  };
  var ALIEN = {
    body: "#9a7fd6",
    body2: "#7c5fc0",
    eye: "#2a1f45",
    leg: "#5a3fa6"
  };
  function drawDogCharacter(ctx, px, py, dir, frame) {
    const cx = px * T + T / 2;
    const cy = py * T + T / 2;
    const phase = frame % 6;
    const stride = phase === 1 || phase === 5 ? 2 : phase === 3 ? -2 : 0;
    const bob = phase === 2 || phase === 4 ? -2 : 0;
    const tailWag = phase % 2 === 0 ? -2 : 2;
    const by = cy + 6;
    const headY = by - 28 + bob;
    ctx.fillStyle = "rgba(0,0,0,0.2)";
    ctx.beginPath();
    ctx.ellipse(cx, by + 4, 12, 4, 0, 0, Math.PI * 2);
    ctx.fill();
    const d = (fs, rx, ry, rw, rh) => {
      ctx.fillStyle = fs;
      ctx.fillRect(rx, ry, rw, rh);
    };
    if (dir === "down" || dir === "idle") {
      d(DOG.furDark, cx - 2 + tailWag, by - 22 + bob, 4, 6);
      d(DOG.fur, cx - 10, by - 18 + bob, 20, 14);
      d(DOG.belly, cx - 6, by - 12 + bob, 12, 10);
      d(DOG.accent, cx - 10, by - 18 + bob, 20, 4);
      d(DOG.paw, cx - 8 + stride, by - 2, 6, 5);
      d(DOG.paw, cx + 2 - stride, by - 2, 6, 5);
      d(DOG.fur, cx - 10, headY, 20, 16);
      d(DOG.furLight, cx - 8, headY + 2, 16, 10);
      d(DOG.ear, cx - 14, headY + 2, 6, 14);
      d(DOG.ear, cx + 8, headY + 2, 6, 14);
      d(DOG.belly, cx - 6, headY + 8, 12, 8);
      d(DOG.eyeWhite, cx - 6, headY + 6, 4, 4);
      d(DOG.eyeWhite, cx + 2, headY + 6, 4, 4);
      d(DOG.eyePupil, cx - 5, headY + 7, 3, 3);
      d(DOG.eyePupil, cx + 3, headY + 7, 3, 3);
      d(DOG.nose, cx - 2, headY + 10, 4, 3);
      if (phase % 4 < 2) d(DOG.tongue, cx - 1, headY + 13, 3, 4);
    } else if (dir === "up") {
      d(DOG.furDark, cx - 10, by - 18 + bob, 20, 14);
      d(DOG.fur, cx - 8, by - 16 + bob, 16, 10);
      d(DOG.accent, cx - 10, by - 18 + bob, 20, 4);
      d(DOG.furDark, cx - 2 + tailWag, by - 24 + bob, 4, 8);
      d(DOG.furLight, cx - 1 + tailWag, by - 24 + bob, 2, 4);
      d(DOG.paw, cx - 8 + stride, by - 2, 6, 5);
      d(DOG.paw, cx + 2 - stride, by - 2, 6, 5);
      d(DOG.furDark, cx - 10, headY, 20, 16);
      d(DOG.fur, cx - 8, headY + 2, 16, 12);
      d(DOG.ear, cx - 14, headY + 2, 6, 14);
      d(DOG.ear, cx + 8, headY + 2, 6, 14);
    } else {
      if (dir === "right") {
        ctx.save();
        ctx.translate(cx, 0);
        ctx.scale(-1, 1);
        ctx.translate(-cx, 0);
      }
      const offX = cx - 12;
      d(DOG.furDark, cx + 6 - tailWag, by - 22 + bob, 4, 8);
      d(DOG.furLight, cx + 7 - tailWag, by - 22 + bob, 2, 4);
      d(DOG.fur, offX, by - 18 + bob, 20, 14);
      d(DOG.belly, offX + 4, by - 12 + bob, 12, 10);
      d(DOG.accent, offX, by - 18 + bob, 20, 4);
      d(DOG.paw, offX + 2 + stride, by - 2, 6, 5);
      d(DOG.paw, offX + 12 - stride, by - 2, 6, 5);
      const hx = cx - 12;
      d(DOG.fur, hx, headY, 20, 16);
      d(DOG.ear, hx - 4, headY + 2, 6, 14);
      d(DOG.belly, hx - 2, headY + 8, 10, 8);
      d(DOG.eyeWhite, hx + 4, headY + 6, 4, 4);
      d(DOG.eyePupil, hx + 4, headY + 7, 3, 3);
      d(DOG.nose, hx - 1, headY + 10, 3, 3);
      if (phase % 4 < 2) d(DOG.tongue, hx - 1, headY + 13, 3, 3);
      if (dir === "right") ctx.restore();
    }
  }
  function drawAlienCharacter(ctx, px, py, dir, frame) {
    const cx = px * T + T / 2;
    const cy = py * T + T / 2;
    const phase = frame % 6;
    const stride = phase === 1 || phase === 5 ? 1 : phase === 3 ? -1 : 0;
    const bob = phase === 2 || phase === 4 ? -1 : 0;
    const by = cy + 6;
    const top = by - 21 + bob;
    const d = (fs, rx, ry, rw, rh) => {
      ctx.fillStyle = fs;
      ctx.fillRect(rx, ry, rw, rh);
    };
    ctx.fillStyle = "rgba(0,0,0,0.2)";
    ctx.beginPath();
    ctx.ellipse(cx, by + 4, 12, 4, 0, 0, Math.PI * 2);
    ctx.fill();
    const ly = by - 1;
    d(ALIEN.leg, cx - 10 + stride, ly, 3, 4);
    d(ALIEN.leg, cx - 5, ly, 3, 4);
    d(ALIEN.leg, cx + 1, ly, 3, 4);
    d(ALIEN.leg, cx + 6 - stride, ly, 3, 4);
    d(ALIEN.body, cx - 8, top, 16, 1);
    d(ALIEN.body, cx - 10, top + 1, 20, 1);
    d(ALIEN.body, cx - 12, top + 2, 24, 1);
    d(ALIEN.body, cx - 13, top + 3, 26, 16);
    d(ALIEN.body, cx - 12, top + 19, 24, 1);
    d(ALIEN.body, cx - 10, top + 20, 20, 1);
    d(ALIEN.body, cx - 8, top + 21, 16, 1);
    d(ALIEN.body2, cx - 10, top + 20, 20, 1);
    d(ALIEN.body2, cx - 8, top + 21, 16, 1);
    const E = ALIEN.eye;
    if (dir === "up") {
      d(ALIEN.body2, cx - 9, top + 7, 18, 2);
    } else if (dir === "left" || dir === "right") {
      if (dir === "right") {
        ctx.save();
        ctx.translate(cx, 0);
        ctx.scale(-1, 1);
        ctx.translate(-cx, 0);
      }
      d(E, cx - 7, top + 8, 2, 2);
      d(E, cx - 2, top + 8, 2, 2);
      d(E, cx - 6, top + 15, 3, 1);
      if (dir === "right") ctx.restore();
    } else {
      d(E, cx - 4, top + 8, 2, 2);
      d(E, cx + 2, top + 8, 2, 2);
      d(E, cx - 2, top + 15, 1, 1);
      d(E, cx + 1, top + 15, 1, 1);
      d(E, cx - 1, top + 16, 2, 1);
    }
  }
  var GHOST = {
    body: "#e6ecfa",
    body2: "#c2cde8",
    bodyLight: "#f3f6fe",
    eye: "#2f3566"
  };
  var GHOST_HW = [
    3,
    5,
    7,
    8,
    9,
    10,
    11,
    11,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12,
    12
  ];
  function drawGhostCharacter(ctx, px, py, dir, frame) {
    const cx = px * T + T / 2;
    const cy = py * T + T / 2;
    const bob = Math.round(Math.sin(frame * 0.2) * 1.5);
    const gy = cy - 20 + bob;
    const lean = dir === "left" ? -1 : dir === "right" ? 1 : 0;
    const d = (fs, rx, ry, rw, rh) => {
      ctx.fillStyle = fs;
      ctx.fillRect(rx, ry, rw, rh);
    };
    ctx.fillStyle = "rgba(0,0,0,0.16)";
    ctx.beginPath();
    ctx.ellipse(cx, cy + 11, 9, 3, 0, 0, Math.PI * 2);
    ctx.fill();
    for (let i = 0; i < GHOST_HW.length; i++) {
      d(GHOST.body, cx - GHOST_HW[i], gy + i, 2 * GHOST_HW[i], 1);
    }
    const b = gy + GHOST_HW.length;
    d(GHOST.body, cx - 12, b, 7, 1);
    d(GHOST.body, cx - 3, b, 6, 1);
    d(GHOST.body, cx + 5, b, 7, 1);
    d(GHOST.body, cx - 11, b + 1, 5, 1);
    d(GHOST.body, cx - 2, b + 1, 4, 1);
    d(GHOST.body, cx + 6, b + 1, 5, 1);
    for (let i = 4; i < GHOST_HW.length; i++) {
      d(GHOST.body2, cx + GHOST_HW[i] - 1, gy + i, 1, 1);
    }
    d(GHOST.body2, cx - 11, b + 1, 5, 1);
    d(GHOST.body2, cx - 2, b + 1, 4, 1);
    d(GHOST.body2, cx + 6, b + 1, 5, 1);
    d(GHOST.bodyLight, cx - 6, gy + 2, 3, 1);
    d(GHOST.bodyLight, cx - 8, gy + 3, 2, 1);
    d(GHOST.bodyLight, cx - 9, gy + 4, 2, 1);
    const E = GHOST.eye, y = gy + 12;
    if (dir === "up") {
      d(GHOST.body2, cx - 7, gy + 11, 14, 1);
      d(GHOST.body2, cx - 5, gy + 14, 10, 1);
      d(GHOST.bodyLight, cx - 5, gy + 5, 2, 1);
      return;
    }
    if (dir === "left") {
      d(E, cx - 7, y, 1, 3);
      d(E, cx - 8, y + 1, 1, 1);
      d(E, cx - 10, y + 5, 2, 1);
      return;
    }
    if (dir === "right") {
      d(E, cx + 7, y, 1, 3);
      d(E, cx + 8, y + 1, 1, 1);
      d(E, cx + 9, y + 5, 2, 1);
      return;
    }
    d(E, cx - 8 + lean, y, 1, 3);
    d(E, cx - 9 + lean, y + 1, 1, 1);
    d(E, cx - 7 + lean, y + 1, 1, 1);
    d(E, cx + 8 + lean, y, 1, 3);
    d(E, cx + 9 + lean, y + 1, 1, 1);
    d(E, cx + 7 + lean, y + 1, 1, 1);
  }
  var ROBOT = {
    metal: "#9fb4c9",
    metalDark: "#7891ab",
    screen: "#222a38",
    eye: "#5fe0d8",
    bulb: "#f0934e",
    wheel: "#3a4452"
  };
  function drawRobotCharacter(ctx, px, py, dir, frame) {
    const cx = px * T + T / 2;
    const cy = py * T + T / 2;
    const phase = frame % 6;
    const blink = phase < 3;
    const d = (fs, rx, ry, rw, rh) => {
      ctx.fillStyle = fs;
      ctx.fillRect(rx, ry, rw, rh);
    };
    const M = ROBOT.metal, MD = ROBOT.metalDark, S = ROBOT.screen, E = ROBOT.eye, BU = ROBOT.bulb, WH = ROBOT.wheel;
    ctx.fillStyle = "rgba(0,0,0,0.2)";
    ctx.beginPath();
    ctx.ellipse(cx, cy + 11, 11, 3, 0, 0, Math.PI * 2);
    ctx.fill();
    d(M, cx - 1, cy - 19, 2, 4);
    d(BU, cx - 1, cy - 22, 2, 2);
    if (blink) d(BU, cx, cy - 23, 1, 1);
    d(M, cx - 9, cy - 16, 18, 1);
    d(M, cx - 10, cy - 15, 20, 8);
    d(M, cx - 9, cy - 7, 18, 1);
    d(MD, cx + 9, cy - 15, 1, 8);
    d(MD, cx - 10, cy - 8, 20, 1);
    if (dir === "up") {
      d(MD, cx - 6, cy - 14, 12, 6);
      d(M, cx - 5, cy - 13, 10, 1);
      d(M, cx - 5, cy - 11, 10, 1);
      d(M, cx - 5, cy - 9, 10, 1);
    } else {
      d(S, cx - 7, cy - 14, 14, 6);
      const lean = dir === "left" ? -2 : dir === "right" ? 2 : 0;
      d(E, cx - 5 + lean, cy - 12, 2, 2);
      d(E, cx + 3 + lean, cy - 12, 2, 2);
    }
    d(M, cx - 8, cy - 5, 16, 1);
    d(M, cx - 9, cy - 4, 18, 7);
    d(M, cx - 8, cy + 3, 16, 1);
    d(MD, cx + 8, cy - 4, 1, 7);
    d(M, cx - 11, cy - 3, 2, 4);
    d(M, cx + 9, cy - 3, 2, 4);
    d(E, cx - 1, cy - 2, 2, 2);
    d(WH, cx - 7, cy + 4, 14, 4);
    d(MD, cx - 7, cy + 7, 14, 1);
    d(M, cx - 6 + frame % 6, cy + 5, 1, 2);
    d(M, cx - 1, cy + 5, 2, 2);
  }
  var SLIME = {
    body: "#5fc92e",
    outline: "#39791a",
    hi: "#8ed848",
    eye: "#26391a",
    gold: "#f7c948"
  };
  var SLIME_HW = [
    3,
    5,
    7,
    9,
    10,
    11,
    12,
    12,
    13,
    13,
    14,
    14,
    14,
    14,
    13,
    13,
    12,
    10,
    7
  ];
  function drawSlimeCharacter(ctx, px, py, dir, frame) {
    const cx = px * T + T / 2;
    const cy = py * T + T / 2;
    const hop = Math.round(Math.abs(Math.sin(frame * 0.16)) * 2);
    const topY = cy - 9 - hop;
    const lean = dir === "left" ? -1 : dir === "right" ? 1 : 0;
    const d = (fs, rx, ry, rw, rh) => {
      ctx.fillStyle = fs;
      ctx.fillRect(rx, ry, rw, rh);
    };
    const O = SLIME.outline, B = SLIME.body, H = SLIME.hi, E = SLIME.eye, G = SLIME.gold;
    ctx.fillStyle = "rgba(0,0,0,0.2)";
    ctx.beginPath();
    ctx.ellipse(cx, cy + 11, 12, 3, 0, 0, Math.PI * 2);
    ctx.fill();
    if (dir === "left") {
      d(O, cx, topY - 2, 1, 2);
      d(O, cx - 1, topY - 3, 1, 1);
      d(O, cx - 2, topY - 4, 1, 1);
      d(O, cx - 3, topY - 4, 1, 1);
      d(B, cx - 7, topY - 6, 3, 3);
      d(O, cx - 7, topY - 7, 3, 1);
      d(O, cx - 7, topY - 3, 3, 1);
      d(O, cx - 8, topY - 6, 1, 3);
      d(O, cx - 4, topY - 6, 1, 3);
    } else if (dir === "up") {
      d(O, cx, topY - 2, 1, 2);
      d(O, cx, topY - 4, 1, 2);
      d(B, cx - 1, topY - 7, 3, 3);
      d(O, cx - 1, topY - 8, 3, 1);
      d(O, cx - 1, topY - 4, 3, 1);
      d(O, cx - 2, topY - 7, 1, 3);
      d(O, cx + 2, topY - 7, 1, 3);
    } else {
      d(O, cx, topY - 2, 1, 2);
      d(O, cx + 1, topY - 3, 1, 1);
      d(O, cx + 2, topY - 4, 1, 1);
      d(O, cx + 3, topY - 4, 1, 1);
      d(B, cx + 4, topY - 6, 3, 3);
      d(O, cx + 4, topY - 7, 3, 1);
      d(O, cx + 4, topY - 3, 3, 1);
      d(O, cx + 3, topY - 6, 1, 3);
      d(O, cx + 7, topY - 6, 1, 3);
    }
    for (let i = 0; i < SLIME_HW.length; i++) {
      const w = SLIME_HW[i];
      d(O, cx - w, topY + i, 2 * w, 1);
      if (i > 0 && i < SLIME_HW.length - 1) d(B, cx - (w - 1), topY + i, 2 * (w - 1), 1);
    }
    d(H, cx - 4, topY + 1, 8, 1);
    d(H, cx - 7, topY + 2, 4, 1);
    d(H, cx + 4, topY + 2, 4, 1);
    const ey = topY + 5, lx = lean;
    if (dir === "up") {
      d(O, cx - 5, topY + 8, 10, 1);
      d(O, cx - 3, topY + 11, 6, 1);
      return;
    }
    if (dir === "left" || dir === "right") {
      const eyeX = dir === "right" ? cx + 4 : cx - 8;
      const glintX = dir === "right" ? eyeX : eyeX + 1;
      d(E, eyeX, ey, 4, 1);
      d(E, eyeX - 1, ey + 1, 6, 4);
      d(E, eyeX, ey + 5, 4, 1);
      d(G, glintX, ey + 2, 3, 1);
      d(G, glintX + 1, ey + 1, 1, 1);
      if (dir === "right") {
        d(E, cx + 2, topY + 12, 1, 1);
        d(E, cx + 3, topY + 13, 1, 1);
        d(E, cx + 4, topY + 12, 1, 1);
      } else {
        d(E, cx - 4, topY + 12, 1, 1);
        d(E, cx - 3, topY + 13, 1, 1);
        d(E, cx - 2, topY + 12, 1, 1);
      }
      return;
    }
    d(E, cx - 7 + lx, ey, 4, 1);
    d(E, cx - 8 + lx, ey + 1, 6, 4);
    d(E, cx - 7 + lx, ey + 5, 4, 1);
    d(G, cx - 7 + lx, ey + 2, 3, 1);
    d(G, cx - 6 + lx, ey + 1, 1, 1);
    d(E, cx + 4 + lx, ey, 4, 1);
    d(E, cx + 3 + lx, ey + 1, 6, 4);
    d(E, cx + 4 + lx, ey + 5, 4, 1);
    d(G, cx + 4 + lx, ey + 2, 3, 1);
    d(G, cx + 5 + lx, ey + 1, 1, 1);
    d(E, cx - 3, topY + 12, 1, 1);
    d(E, cx - 2, topY + 13, 1, 1);
    d(E, cx - 1, topY + 12, 1, 1);
    d(E, cx, topY + 12, 1, 1);
    d(E, cx + 1, topY + 13, 1, 1);
    d(E, cx + 2, topY + 12, 1, 1);
  }
  var AXOLOTL = {
    body: "#f9a8d4",
    bodyLt: "#fbcfe8",
    belly: "#fdf2f8",
    gill: "#fb7185",
    gillTip: "#f43f5e",
    gillSoft: "#fecdd3",
    cheek: "#f472b6",
    eye: "#3f1d2b",
    smile: "#be185d"
  };
  function drawAxolotlCharacter(ctx, px, py, dir, frame) {
    const cx = px * T + T / 2;
    const cy = py * T + T / 2;
    const bob = Math.round(Math.sin(frame * 0.2) * 1.5);
    const lean = dir === "left" ? -1 : dir === "right" ? 1 : 0;
    const P = AXOLOTL;
    const a = (fs, lx, ly, w, h) => {
      ctx.fillStyle = fs;
      ctx.fillRect(cx + lx - 24, cy - 28 + bob + ly, w, h);
    };
    ctx.fillStyle = "rgba(0,0,0,0.16)";
    ctx.beginPath();
    ctx.ellipse(cx, cy + 11, 9, 3, 0, 0, Math.PI * 2);
    ctx.fill();
    if (dir === "up") {
      a(P.gill, 13, 10, 4, 3);
      a(P.gillTip, 11, 9, 2, 2);
      a(P.gillSoft, 14, 11, 1, 1);
      a(P.gill, 12, 14, 4, 3);
      a(P.gillTip, 10, 15, 2, 2);
      a(P.gillSoft, 13, 15, 1, 1);
      a(P.gill, 11, 18, 4, 3);
      a(P.gillTip, 9, 20, 2, 2);
      a(P.gillSoft, 12, 19, 1, 1);
      a(P.gill, 31, 10, 4, 3);
      a(P.gillTip, 35, 9, 2, 2);
      a(P.gillSoft, 33, 11, 1, 1);
      a(P.gill, 32, 14, 4, 3);
      a(P.gillTip, 36, 15, 2, 2);
      a(P.gillSoft, 34, 15, 1, 1);
      a(P.gill, 33, 18, 4, 3);
      a(P.gillTip, 37, 20, 2, 2);
      a(P.gillSoft, 35, 19, 1, 1);
      a(P.body, 20, 8, 8, 1);
      a(P.body, 18, 9, 12, 1);
      a(P.body, 17, 10, 14, 2);
      a(P.body, 16, 12, 16, 1);
      a(P.body, 15, 13, 18, 3);
      a(P.body, 14, 16, 20, 7);
      a(P.body, 15, 23, 18, 3);
      a(P.body, 16, 26, 15, 2);
      a(P.body, 18, 28, 12, 1);
      a(P.bodyLt, 22, 11, 4, 1);
      a(P.bodyLt, 22, 12, 3, 10);
      a(P.bodyLt, 21, 22, 5, 1);
      a(P.body, 13, 23, 3, 3);
      a(P.body, 32, 23, 3, 3);
      a(P.body, 18, 29, 5, 3);
      a(P.body, 25, 29, 5, 3);
      a(P.bodyLt, 18, 31, 5, 1);
      a(P.bodyLt, 25, 31, 5, 1);
      a(P.body, 33, 24, 4, 4);
      a(P.bodyLt, 34, 23, 5, 1);
      a(P.body, 37, 22, 3, 4);
      a(P.bodyLt, 38, 21, 4, 1);
      return;
    }
    if (dir === "left" || dir === "right") {
      if (dir === "right") {
        ctx.save();
        ctx.translate(cx, 0);
        ctx.scale(-1, 1);
        ctx.translate(-cx, 0);
      }
      a(P.body, 31, 23, 6, 5);
      a(P.bodyLt, 35, 22, 4, 1);
      a(P.body, 37, 21, 3, 4);
      a(P.bodyLt, 39, 20, 4, 1);
      a(P.gill, 10, 11, 4, 3);
      a(P.gillTip, 8, 10, 2, 2);
      a(P.gillSoft, 11, 12, 1, 1);
      a(P.gill, 9, 15, 4, 3);
      a(P.gillTip, 7, 16, 2, 2);
      a(P.gillSoft, 10, 16, 1, 1);
      a(P.gill, 10, 19, 4, 3);
      a(P.gillTip, 8, 21, 2, 2);
      a(P.gillSoft, 11, 20, 1, 1);
      a(P.body, 15, 10, 14, 1);
      a(P.body, 13, 11, 18, 1);
      a(P.body, 12, 12, 21, 2);
      a(P.body, 10, 14, 25, 4);
      a(P.body, 11, 18, 24, 6);
      a(P.body, 13, 24, 20, 3);
      a(P.body, 16, 27, 14, 1);
      a(P.bodyLt, 13, 12, 6, 1);
      a(P.bodyLt, 12, 13, 5, 2);
      a(P.belly, 18, 18, 11, 5);
      a(P.belly, 20, 23, 8, 1);
      a(P.body, 14, 24, 4, 2);
      a(P.body, 26, 26, 5, 3);
      a(P.bodyLt, 26, 28, 5, 1);
      a(P.cheek, 11, 18, 3, 2);
      a(P.eye, 14, 14, 2, 1);
      a(P.eye, 13, 15, 4, 1);
      a(P.eye, 14, 16, 2, 1);
      a("#ffffff", 14, 14, 1, 1);
      a(P.smile, 11, 20, 2, 1);
      if (dir === "right") ctx.restore();
      return;
    }
    a(P.gill, 13, 10, 4, 3);
    a(P.gillTip, 11, 9, 2, 2);
    a(P.gillSoft, 14, 11, 1, 1);
    a(P.gill, 12, 14, 4, 3);
    a(P.gillTip, 10, 15, 2, 2);
    a(P.gillSoft, 13, 15, 1, 1);
    a(P.gill, 11, 18, 4, 3);
    a(P.gillTip, 9, 20, 2, 2);
    a(P.gillSoft, 12, 19, 1, 1);
    a(P.gill, 31, 10, 4, 3);
    a(P.gillTip, 35, 9, 2, 2);
    a(P.gillSoft, 33, 11, 1, 1);
    a(P.gill, 32, 14, 4, 3);
    a(P.gillTip, 36, 15, 2, 2);
    a(P.gillSoft, 34, 15, 1, 1);
    a(P.gill, 33, 18, 4, 3);
    a(P.gillTip, 37, 20, 2, 2);
    a(P.gillSoft, 35, 19, 1, 1);
    a(P.body, 20, 8, 8, 1);
    a(P.body, 18, 9, 12, 1);
    a(P.body, 17, 10, 14, 2);
    a(P.body, 16, 12, 16, 1);
    a(P.body, 15, 13, 18, 3);
    a(P.body, 14, 16, 20, 7);
    a(P.body, 15, 23, 18, 3);
    a(P.body, 16, 26, 15, 2);
    a(P.body, 18, 28, 12, 1);
    a(P.bodyLt, 17, 11, 5, 1);
    a(P.bodyLt, 16, 12, 5, 2);
    a(P.belly, 19, 18, 10, 1);
    a(P.belly, 18, 19, 12, 7);
    a(P.belly, 19, 26, 10, 1);
    a(P.body, 13, 23, 3, 3);
    a(P.body, 32, 23, 3, 3);
    a(P.body, 18, 29, 5, 3);
    a(P.body, 25, 29, 5, 3);
    a(P.bodyLt, 18, 31, 5, 1);
    a(P.bodyLt, 25, 31, 5, 1);
    a(P.cheek, 16, 17, 3, 2);
    a(P.cheek, 29, 17, 3, 2);
    const eye = (lx) => {
      a(P.eye, lx + lean, 13, 2, 1);
      a(P.eye, lx - 1 + lean, 14, 4, 1);
      a(P.eye, lx + lean, 15, 2, 1);
      a("#ffffff", lx + lean, 13, 1, 1);
    };
    eye(18);
    eye(28);
    a(P.smile, 21, 18, 1, 1);
    a(P.smile, 26, 18, 1, 1);
    a(P.smile, 22, 19, 4, 1);
    a(P.smile, 23, 20, 2, 1);
  }

  // ../nosabos/nosabos/src/utils/gameLoadingMessages.js
  var GAME_LOADING_MESSAGES = {
    en: [
      "Building your world...",
      "Placing NPCs...",
      "Writing quest dialogue...",
      "Generating vocabulary challenges...",
      "Designing the map layout...",
      "Preparing language puzzles...",
      "Setting the scene...",
      "Crafting your adventure..."
    ],
    es: [
      "Construyendo tu mundo...",
      "Colocando NPCs...",
      "Escribiendo di\xE1logos de misi\xF3n...",
      "Generando desaf\xEDos de vocabulario...",
      "Dise\xF1ando el mapa...",
      "Preparando acertijos de idiomas...",
      "Ambientando la escena...",
      "Creando tu aventura..."
    ],
    it: [
      "Costruendo il tuo mondo...",
      "Posizionando i personaggi...",
      "Scrivendo i dialoghi della missione...",
      "Generando sfide di vocabolario...",
      "Progettando la mappa...",
      "Preparando i rompicapo linguistici...",
      "Ambientando la scena...",
      "Creando la tua avventura..."
    ],
    pt: [
      "Construindo o seu mundo...",
      "Posicionando NPCs...",
      "Escrevendo di\xE1logos da miss\xE3o...",
      "Gerando desafios de vocabul\xE1rio...",
      "Desenhando o mapa...",
      "Preparando enigmas de idioma...",
      "Montando a cena...",
      "Criando a sua aventura..."
    ],
    fr: [
      "Construction de votre monde...",
      "Placement des PNJ...",
      "Ecriture des dialogues de quete...",
      "Generation des defis de vocabulaire...",
      "Conception de la carte...",
      "Preparation des enigmes de langue...",
      "Mise en scene...",
      "Creation de votre aventure..."
    ],
    de: [
      "Deine Welt wird gebaut...",
      "Figuren werden platziert...",
      "Quest-Dialoge werden geschrieben...",
      "Wortschatz-Herausforderungen werden erstellt...",
      "Das Kartenlayout wird entworfen...",
      "Sprachr\xE4tsel werden vorbereitet...",
      "Die Szene wird eingerichtet...",
      "Dein Abenteuer wird geschmiedet..."
    ],
    ja: [
      "\u3042\u306A\u305F\u306E\u4E16\u754C\u3092\u4F5C\u3063\u3066\u3044\u307E\u3059...",
      "NPC\u3092\u914D\u7F6E\u3057\u3066\u3044\u307E\u3059...",
      "\u30AF\u30A8\u30B9\u30C8\u306E\u4F1A\u8A71\u3092\u66F8\u3044\u3066\u3044\u307E\u3059...",
      "\u8A9E\u5F59\u30C1\u30E3\u30EC\u30F3\u30B8\u3092\u751F\u6210\u3057\u3066\u3044\u307E\u3059...",
      "\u30DE\u30C3\u30D7\u3092\u8A2D\u8A08\u3057\u3066\u3044\u307E\u3059...",
      "\u8A00\u8A9E\u30D1\u30BA\u30EB\u3092\u6E96\u5099\u3057\u3066\u3044\u307E\u3059...",
      "\u5834\u9762\u3092\u6574\u3048\u3066\u3044\u307E\u3059...",
      "\u5192\u967A\u3092\u7D44\u307F\u7ACB\u3066\u3066\u3044\u307E\u3059..."
    ],
    hi: [
      "\u0906\u092A\u0915\u0940 \u0926\u0941\u0928\u093F\u092F\u093E \u092C\u0928\u093E\u0908 \u091C\u093E \u0930\u0939\u0940 \u0939\u0948...",
      "NPC \u0915\u094B \u0930\u0916\u093E \u091C\u093E \u0930\u0939\u093E \u0939\u0948...",
      "\u0915\u094D\u0935\u0947\u0938\u094D\u091F \u0915\u0947 \u0938\u0902\u0935\u093E\u0926 \u0932\u093F\u0916\u0947 \u091C\u093E \u0930\u0939\u0947 \u0939\u0948\u0902...",
      "\u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u091A\u0941\u0928\u094C\u0924\u093F\u092F\u093E\u0902 \u0924\u0948\u092F\u093E\u0930 \u0915\u0940 \u091C\u093E \u0930\u0939\u0940 \u0939\u0948\u0902...",
      "\u092E\u093E\u0928\u091A\u093F\u0924\u094D\u0930 \u0915\u093E \u0932\u0947\u0906\u0909\u091F \u092C\u0928\u093E\u092F\u093E \u091C\u093E \u0930\u0939\u093E \u0939\u0948...",
      "\u092D\u093E\u0937\u093E \u092A\u0939\u0947\u0932\u093F\u092F\u093E\u0902 \u0924\u0948\u092F\u093E\u0930 \u0915\u0940 \u091C\u093E \u0930\u0939\u0940 \u0939\u0948\u0902...",
      "\u0926\u0943\u0936\u094D\u092F \u0938\u091C\u093E\u092F\u093E \u091C\u093E \u0930\u0939\u093E \u0939\u0948...",
      "\u0906\u092A\u0915\u093E \u0930\u094B\u092E\u093E\u0902\u091A \u0924\u0948\u092F\u093E\u0930 \u0915\u093F\u092F\u093E \u091C\u093E \u0930\u0939\u093E \u0939\u0948..."
    ],
    ar: [
      "\u0628\u0646\u0643\u0648\u0651\u0646 \u0639\u0627\u0644\u0645\u0643...",
      "\u0628\u0646\u062D\u0637 \u0627\u0644\u0634\u062E\u0635\u064A\u0627\u062A...",
      "\u0628\u0646\u0643\u062A\u0628 \u062D\u0648\u0627\u0631 \u0627\u0644\u0645\u0647\u0645\u0629...",
      "\u0628\u0646\u062C\u0647\u0632 \u062A\u062D\u062F\u064A\u0627\u062A \u0627\u0644\u0645\u0641\u0631\u062F\u0627\u062A...",
      "\u0628\u0646\u0631\u0633\u0645 \u062E\u0631\u064A\u0637\u0629 \u0627\u0644\u0645\u0643\u0627\u0646...",
      "\u0628\u0646\u062D\u0636\u0651\u0631 \u0623\u0644\u063A\u0627\u0632 \u0627\u0644\u0644\u063A\u0629...",
      "\u0628\u0646\u0638\u0628\u0637 \u0627\u0644\u0645\u0634\u0647\u062F...",
      "\u0628\u0646\u0635\u0646\u0639 \u0645\u063A\u0627\u0645\u0631\u062A\u0643..."
    ],
    zh: [
      "\u6B63\u5728\u6784\u5EFA\u4F60\u7684\u4E16\u754C...",
      "\u6B63\u5728\u653E\u7F6E\u89D2\u8272...",
      "\u6B63\u5728\u7F16\u5199\u4EFB\u52A1\u5BF9\u8BDD...",
      "\u6B63\u5728\u751F\u6210\u8BCD\u6C47\u6311\u6218...",
      "\u6B63\u5728\u8BBE\u8BA1\u5730\u56FE\u5E03\u5C40...",
      "\u6B63\u5728\u51C6\u5907\u8BED\u8A00\u8C1C\u9898...",
      "\u6B63\u5728\u5E03\u7F6E\u573A\u666F...",
      "\u6B63\u5728\u6253\u9020\u4F60\u7684\u5192\u9669..."
    ]
  };

  // <stdin>
  var TILE = 16;
  var SCALE = 3;
  var T2 = TILE * SCALE;
  var MOVE_COOLDOWN = 130;
  var GRASS = 0;
  var PATH = 1;
  var WATER = 2;
  var TREE = 4;
  var FLOWER = 5;
  var SIGN = 6;
  var CHEST = 7;
  var ROCK = 8;
  var BRIDGE = 9;
  var LAMP = 11;
  var DOOR = 12;
  var FLOOR = 13;
  var WALL_TOP = 14;
  var BOOKSHELF = 15;
  var TABLE = 16;
  var RUG = 17;
  var FIREPLACE = 18;
  var SOFA = 19;
  var BED = 20;
  var WINDOW_TILE = 21;
  var DESK = 22;
  var PLANT_POT = 23;
  var SOLID_TILES = /* @__PURE__ */ new Set([TREE, WATER, ROCK, WALL_TOP, BOOKSHELF, FIREPLACE, SOFA, BED, WINDOW_TILE, DESK]);
  var INTERACT_TILES = /* @__PURE__ */ new Set([SIGN, CHEST, LAMP, PLANT_POT, TABLE]);
  function createRng(seed) {
    let s = seed | 0;
    return () => {
      s = s + 1831565813 | 0;
      let t = Math.imul(s ^ s >>> 15, 1 | s);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  function pick(rng, arr) {
    return arr[Math.floor(rng() * arr.length)];
  }
  function shuffle(rng, arr) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }
  var GRASS_PALETTES = [
    ["#3a7d44", "#2d6b35", "#4a8c54"],
    ["#2e8b57", "#228b22", "#3cb371"],
    ["#4a7c59", "#3a6b48", "#5a9c6a"],
    ["#6b8e23", "#556b2f", "#7caa2d"],
    ["#3a6e3a", "#2d5c2d", "#4a8a4a"]
  ];
  var WATER_PALETTES = [
    { base: "#2a6faa", highlight: "#4a9fdd" },
    { base: "#1a5f8a", highlight: "#3a8fcc" },
    { base: "#2a5f9a", highlight: "#5aaedd" },
    { base: "#1e6090", highlight: "#4090c0" },
    { base: "#2a7ab8", highlight: "#5ab0e8" }
  ];
  var PATH_PALETTES = [
    ["#c4a46c", "#b89a62", "#d4b47c"],
    ["#b09060", "#a08050", "#c0a070"],
    ["#c8a878", "#b89868", "#d8b888"],
    ["#a89070", "#988060", "#b8a080"],
    ["#d4b080", "#c4a070", "#e4c090"]
  ];
  var LEAF_PALETTES = [
    ["#2d8c3a", "#1a7028", "#40a050"],
    ["#1a6e28", "#105a1e", "#2a8838"],
    ["#2a9040", "#1a7a30", "#3aa850"],
    ["#3a8a30", "#2a7a20", "#4aa040"],
    ["#228833", "#187028", "#30a040"]
  ];
  var TRUNK_COLORS = ["#5a3a1a", "#4a3018", "#6a4a2a", "#3a2810", "#5a4020"];
  var OUTDOOR_NAMES = {
    en: [
      "Town Plaza",
      "Village Green",
      "Forest Clearing",
      "Riverside Park",
      "Sunset Meadow",
      "Moonlit Garden",
      "Cobblestone Square",
      "Whispering Grove",
      "Lantern Court",
      "Wildflower Field"
    ],
    es: [
      "Plaza del Pueblo",
      "Jard\xEDn del Pueblo",
      "Claro del Bosque",
      "Parque del R\xEDo",
      "Pradera del Atardecer",
      "Jard\xEDn de Luna",
      "Plaza de Adoquines",
      "Arboleda Susurrante",
      "Patio de Faroles",
      "Campo de Flores"
    ],
    pt: [
      "Pra\xE7a da Cidade",
      "Jardim do Vilarejo",
      "Clareira da Floresta",
      "Parque \xE0 Beira do Rio",
      "Prado do P\xF4r do Sol",
      "Jardim ao Luar",
      "Pra\xE7a de Paralelep\xEDpedos",
      "Bosque Sussurrante",
      "P\xE1tio das Lanternas",
      "Campo de Flores Silvestres"
    ],
    it: [
      "Piazza del paese",
      "Prato del villaggio",
      "Radura del bosco",
      "Parco sul fiume",
      "Prato del tramonto",
      "Giardino al chiaro di luna",
      "Piazza di ciottoli",
      "Boschetto sussurrante",
      "Cortile delle lanterne",
      "Campo di fiori"
    ],
    fr: [
      "Place du village",
      "Prairie du village",
      "Clairiere de la foret",
      "Parc de la riviere",
      "Prairie du couchant",
      "Jardin au clair de lune",
      "Place pavee",
      "Bosquet murmureur",
      "Cour des lanternes",
      "Champ de fleurs"
    ],
    ja: [
      "\u753A\u306E\u5E83\u5834",
      "\u6751\u306E\u7DD1\u5730",
      "\u68EE\u306E\u7A7A\u304D\u5730",
      "\u5DDD\u8FBA\u306E\u516C\u5712",
      "\u5915\u713C\u3051\u306E\u8349\u539F",
      "\u6708\u660E\u304B\u308A\u306E\u5EAD",
      "\u77F3\u7573\u306E\u5E83\u5834",
      "\u3055\u3055\u3084\u304F\u6728\u7ACB",
      "\u30E9\u30F3\u30BF\u30F3\u306E\u4E2D\u5EAD",
      "\u91CE\u82B1\u306E\u91CE\u539F"
    ],
    hi: [
      "\u0928\u0917\u0930 \u091A\u094C\u0915",
      "\u0917\u093E\u0901\u0935 \u0915\u093E \u092E\u0948\u0926\u093E\u0928",
      "\u091C\u0902\u0917\u0932 \u0915\u0940 \u0916\u0941\u0932\u0940 \u091C\u0917\u0939",
      "\u0928\u0926\u0940 \u0915\u093F\u0928\u093E\u0930\u0947 \u0915\u093E \u0909\u0926\u094D\u092F\u093E\u0928",
      "\u0938\u0942\u0930\u094D\u092F\u093E\u0938\u094D\u0924 \u0915\u093E \u092E\u0948\u0926\u093E\u0928",
      "\u091A\u093E\u0901\u0926\u0928\u0940 \u092C\u0917\u0940\u091A\u093E",
      "\u092A\u0924\u094D\u0925\u0930\u094B\u0902 \u0935\u093E\u0932\u093E \u091A\u094C\u0915",
      "\u092B\u0941\u0938\u092B\u0941\u0938\u093E\u0924\u093E \u0909\u092A\u0935\u0928",
      "\u0932\u093E\u0932\u091F\u0947\u0928 \u0906\u0901\u0917\u0928",
      "\u091C\u0902\u0917\u0932\u0940 \u092B\u0942\u0932\u094B\u0902 \u0915\u093E \u092E\u0948\u0926\u093E\u0928"
    ]
  };
  var INDOOR_ROOM_TYPES = [
    {
      type: "library",
      names: {
        en: ["Ancient Library", "Reading Room", "Scholar's Study", "Book Nook", "Dusty Archives"],
        es: ["Biblioteca Antigua", "Sala de Lectura", "Estudio del Erudito", "Rinc\xF3n de Libros", "Archivos Polvorientos"],
        pt: ["Biblioteca Antiga", "Sala de Leitura", "Est\xFAdio do Erudito", "Cantinho dos Livros", "Arquivos empoeirados"],
        it: ["Biblioteca antica", "Sala di lettura", "Studio dello studioso", "Angolo dei libri", "Archivi polverosi"],
        fr: ["Bibliotheque ancienne", "Salle de lecture", "Bureau du savant", "Coin des livres", "Archives poussiereuses"],
        ja: ["\u53E4\u3044\u56F3\u66F8\u9928", "\u8AAD\u66F8\u5BA4", "\u5B66\u8005\u306E\u66F8\u658E", "\u672C\u306E\u5C0F\u90E8\u5C4B", "\u307B\u3053\u308A\u3063\u307D\u3044\u8CC7\u6599\u5BA4"],
        hi: ["\u092A\u094D\u0930\u093E\u091A\u0940\u0928 \u092A\u0941\u0938\u094D\u0924\u0915\u093E\u0932\u092F", "\u092A\u0920\u0928 \u0915\u0915\u094D\u0937", "\u0935\u093F\u0926\u094D\u0935\u093E\u0928 \u0915\u093E \u0905\u0927\u094D\u092F\u092F\u0928 \u0915\u0915\u094D\u0937", "\u092A\u0941\u0938\u094D\u0924\u0915 \u0915\u094B\u0928\u093E", "\u0927\u0942\u0932 \u092D\u0930\u093E \u0905\u092D\u093F\u0932\u0947\u0916\u093E\u0917\u093E\u0930"]
      },
      wallFurniture: [BOOKSHELF, WINDOW_TILE],
      centerFurniture: [TABLE, DESK, PLANT_POT],
      hasRug: true
    },
    {
      type: "cabin",
      names: {
        en: ["Cozy Cabin", "Warm Cottage", "Traveler's Rest", "Fireside Lodge", "Mountain Hut"],
        es: ["Caba\xF1a Acogedora", "Casita C\xE1lida", "Descanso del Viajero", "Refugio junto al Fuego", "Caba\xF1a de Monta\xF1a"],
        pt: ["Cabana Aconchegante", "Casinha Quentinha", "Descanso do Viajante", "Ref\xFAgio da Lareira", "Cabana da Montanha"],
        it: ["Baita accogliente", "Casetta calda", "Riposo del viaggiatore", "Rifugio del focolare", "Capanna di montagna"],
        fr: ["Cabane douillette", "Maison chaleureuse", "Repos du voyageur", "Refuge du foyer", "Cabane de montagne"],
        ja: ["\u5C45\u5FC3\u5730\u306E\u3088\u3044\u5C0F\u5C4B", "\u6696\u304B\u306A\u30B3\u30C6\u30FC\u30B8", "\u65C5\u4EBA\u306E\u4F11\u61A9\u6240", "\u6696\u7089\u306E\u30ED\u30C3\u30B8", "\u5C71\u5C0F\u5C4B"],
        hi: ["\u0906\u0930\u093E\u092E\u0926\u093E\u092F\u0915 \u0915\u0941\u091F\u093F\u092F\u093E", "\u0917\u0930\u092E\u093E\u0939\u091F \u092D\u0930\u0940 \u0915\u0941\u091F\u093F\u092F\u093E", "\u092F\u093E\u0924\u094D\u0930\u0940 \u0935\u093F\u0936\u094D\u0930\u093E\u092E", "\u0905\u0902\u0917\u0940\u0920\u0940 \u0935\u093E\u0932\u093E \u0906\u0936\u094D\u0930\u092F", "\u092A\u0939\u093E\u0921\u093C\u0940 \u091D\u094B\u0902\u092A\u0921\u093C\u0940"]
      },
      wallFurniture: [FIREPLACE, WINDOW_TILE, BED],
      centerFurniture: [TABLE, SOFA, PLANT_POT],
      hasRug: true
    },
    {
      type: "workshop",
      names: {
        en: ["Artisan Workshop", "Craft Room", "Maker's Space", "Tinkerer's Lab", "Inventor's Den"],
        es: ["Taller Artesanal", "Sala de Manualidades", "Espacio Creativo", "Laboratorio del Inventor", "Guarida del Creador"],
        pt: ["Oficina Artesanal", "Sala de Artesanato", "Espa\xE7o Criativo", "Laborat\xF3rio do Inventor", "Ref\xFAgio do Criador"],
        it: ["Bottega artigiana", "Stanza dei lavori manuali", "Spazio creativo", "Laboratorio dell'inventore", "Rifugio del creatore"],
        fr: ["Atelier artisanal", "Salle de creation", "Espace creatif", "Laboratoire de l'inventeur", "Repaire du createur"],
        ja: ["\u8077\u4EBA\u306E\u5DE5\u623F", "\u30AF\u30E9\u30D5\u30C8\u30EB\u30FC\u30E0", "\u3082\u306E\u3065\u304F\u308A\u7A7A\u9593", "\u767A\u660E\u5BB6\u306E\u30E9\u30DC", "\u5275\u4F5C\u8005\u306E\u96A0\u308C\u5BB6"],
        hi: ["\u0915\u093E\u0930\u0940\u0917\u0930 \u0915\u093E\u0930\u094D\u092F\u0936\u093E\u0932\u093E", "\u0939\u0941\u0928\u0930 \u0915\u0915\u094D\u0937", "\u0928\u093F\u0930\u094D\u092E\u093E\u0924\u093E \u0915\u093E \u0938\u094D\u0925\u093E\u0928", "\u091C\u0941\u0917\u093E\u0921\u093C\u0942 \u0915\u0940 \u092A\u094D\u0930\u092F\u094B\u0917\u0936\u093E\u0932\u093E", "\u0906\u0935\u093F\u0937\u094D\u0915\u093E\u0930\u0915 \u0915\u093E \u0905\u0921\u094D\u0921\u093E"]
      },
      wallFurniture: [BOOKSHELF, DESK, WINDOW_TILE],
      centerFurniture: [TABLE, PLANT_POT, DESK],
      hasRug: false
    },
    {
      type: "bedroom",
      names: {
        en: ["Guest Room", "Cozy Bedroom", "Dreamer's Chamber", "Nap Room", "Rest Haven"],
        es: ["Habitaci\xF3n de Hu\xE9spedes", "Dormitorio Acogedor", "C\xE1mara del So\xF1ador", "Sala de Siesta", "Refugio de Descanso"],
        pt: ["Quarto de H\xF3spedes", "Quarto Aconchegante", "Quarto do Sonhador", "Sala da Soneca", "Ref\xFAgio do Descanso"],
        it: ["Camera degli ospiti", "Camera accogliente", "Stanza del sognatore", "Sala del riposo", "Rifugio tranquillo"],
        fr: ["Chambre d'amis", "Chambre douillette", "Chambre du reveur", "Salle de sieste", "Havre de repos"],
        ja: ["\u5BA2\u5BA4", "\u5C45\u5FC3\u5730\u306E\u3088\u3044\u5BDD\u5BA4", "\u5922\u898B\u308B\u4EBA\u306E\u90E8\u5C4B", "\u663C\u5BDD\u306E\u90E8\u5C4B", "\u4F11\u606F\u306E\u96A0\u308C\u5BB6"],
        hi: ["\u0905\u0924\u093F\u0925\u093F \u0915\u0915\u094D\u0937", "\u0906\u0930\u093E\u092E\u0926\u093E\u092F\u0915 \u0936\u092F\u0928\u0915\u0915\u094D\u0937", "\u0938\u094D\u0935\u092A\u094D\u0928\u0926\u0930\u094D\u0936\u0940 \u0915\u093E \u0915\u0915\u094D\u0937", "\u091D\u092A\u0915\u0940 \u0915\u0915\u094D\u0937", "\u0935\u093F\u0936\u094D\u0930\u093E\u092E \u0906\u0936\u094D\u0930\u092F"]
      },
      wallFurniture: [BED, WINDOW_TILE, BOOKSHELF],
      centerFurniture: [DESK, PLANT_POT, TABLE],
      hasRug: true
    },
    {
      type: "lounge",
      names: {
        en: ["Lounge", "Common Room", "Gathering Hall", "Social Corner", "Tea Room"],
        es: ["Sal\xF3n", "Sala Com\xFAn", "Sala de Reuniones", "Rinc\xF3n Social", "Sala de T\xE9"],
        pt: ["Sala", "Sala Comum", "Sal\xE3o de Encontros", "Cantinho Social", "Sala de Ch\xE1"],
        it: ["Salotto", "Sala comune", "Sala degli incontri", "Angolo sociale", "Sala da t\xE8"],
        fr: ["Salon", "Salle commune", "Hall de rencontre", "Coin social", "Salon de the"],
        ja: ["\u30E9\u30A6\u30F3\u30B8", "\u8AC7\u8A71\u5BA4", "\u96C6\u4F1A\u30DB\u30FC\u30EB", "\u4EA4\u6D41\u30B3\u30FC\u30CA\u30FC", "\u30C6\u30A3\u30FC\u30EB\u30FC\u30E0"],
        hi: ["\u092C\u0948\u0920\u0915", "\u0938\u093E\u092E\u093E\u0928\u094D\u092F \u0915\u0915\u094D\u0937", "\u092E\u093F\u0932\u0928 \u0938\u092D\u093E\u0917\u093E\u0930", "\u0938\u093E\u092E\u093E\u091C\u093F\u0915 \u0915\u094B\u0928\u093E", "\u091A\u093E\u092F \u0915\u0915\u094D\u0937"]
      },
      wallFurniture: [WINDOW_TILE, FIREPLACE, BOOKSHELF],
      centerFurniture: [SOFA, TABLE, PLANT_POT],
      hasRug: true
    }
  ];
  var SIGN_MESSAGES = {
    en: [
      "Welcome, adventurer! Explore while your game loads.",
      "Tip: Talk to NPCs in the real game to practice vocabulary!",
      "Fun fact: Language learning is like leveling up your brain.",
      "Pro tip: Complete quests to earn XP and unlock new lessons!",
      "The bridge connects two worlds... just like languages do.",
      "Try entering the doorways to discover new rooms!",
      "Every word you learn is a step on a grand adventure.",
      "The more you explore, the more you discover!",
      "Secret: some paths lead to hidden treasures...",
      "Did you know? This map changes every time you load!",
      "Languages open doors to new worlds. Literally!",
      "Keep exploring! There's always something new to find."
    ],
    es: [
      "\xA1Bienvenido, aventurero! Explora mientras carga tu juego.",
      "Consejo: \xA1Habla con los NPCs en el juego real para practicar!",
      "Dato curioso: Aprender idiomas es como subir de nivel tu cerebro.",
      "Consejo pro: \xA1Completa misiones para ganar XP y desbloquear lecciones!",
      "El puente conecta dos mundos... igual que los idiomas.",
      "\xA1Intenta entrar por las puertas para descubrir nuevas salas!",
      "Cada palabra que aprendes es un paso en una gran aventura.",
      "\xA1Cuanto m\xE1s exploras, m\xE1s descubres!",
      "Secreto: algunos caminos llevan a tesoros escondidos...",
      "\xBFSab\xEDas? \xA1Este mapa cambia cada vez que cargas!",
      "Los idiomas abren puertas a nuevos mundos. \xA1Literalmente!",
      "\xA1Sigue explorando! Siempre hay algo nuevo que encontrar."
    ],
    pt: [
      "Bem-vindo, aventureiro! Explore enquanto o jogo carrega.",
      "Dica: fale com os NPCs no jogo principal para praticar!",
      "Curiosidade: aprender idiomas \xE9 como subir de n\xEDvel no c\xE9rebro.",
      "Dica extra: complete miss\xF5es para ganhar XP e desbloquear li\xE7\xF5es!",
      "A ponte liga dois mundos... assim como os idiomas.",
      "Tente entrar pelas portas para descobrir salas novas!",
      "Cada palavra aprendida \xE9 um passo em uma grande aventura.",
      "Quanto mais voc\xEA explora, mais descobre!",
      "Segredo: alguns caminhos levam a tesouros escondidos...",
      "Sabia? Este mapa muda toda vez que voc\xEA carrega!",
      "Os idiomas abrem portas para mundos novos. Literalmente!",
      "Continue explorando! Sempre h\xE1 algo novo para encontrar."
    ],
    it: [
      "Benvenuto, avventuriero! Esplora mentre il gioco carica.",
      "Consiglio: parla con i personaggi nel gioco per fare pratica.",
      "Curiosit\xE0: imparare lingue \xE8 come far salire di livello il cervello.",
      "Consiglio pro: completa missioni per guadagnare XP e sbloccare nuove lezioni.",
      "Il ponte collega due mondi... proprio come fanno le lingue.",
      "Prova a entrare dalle porte per scoprire nuove stanze.",
      "Ogni parola che impari \xE8 un passo in una grande avventura.",
      "Pi\xF9 esplori, pi\xF9 scopri.",
      "Segreto: alcuni sentieri portano a tesori nascosti...",
      "Lo sapevi? Questa mappa cambia ogni volta che carichi.",
      "Le lingue aprono porte verso nuovi mondi. Letteralmente.",
      "Continua a esplorare! C'\xE8 sempre qualcosa di nuovo da trovare."
    ],
    fr: [
      "Bienvenue, aventurier ! Explore pendant que ton jeu charge.",
      "Astuce : parle aux PNJ dans le vrai jeu pour pratiquer le vocabulaire.",
      "Le savais-tu ? Apprendre une langue, c'est comme faire monter ton cerveau de niveau.",
      "Astuce pro : termine des quetes pour gagner de l'XP et debloquer des lecons.",
      "Le pont relie deux mondes... comme les langues.",
      "Essaie d'entrer par les portes pour decouvrir de nouvelles salles.",
      "Chaque mot appris est un pas dans une grande aventure.",
      "Plus tu explores, plus tu decouvres.",
      "Secret : certains chemins menent a des tresors caches...",
      "Le savais-tu ? Cette carte change a chaque chargement.",
      "Les langues ouvrent des portes vers de nouveaux mondes. Litteralement.",
      "Continue a explorer ! Il y a toujours quelque chose de nouveau."
    ],
    ja: [
      "\u3088\u3046\u3053\u305D\u3001\u5192\u967A\u8005\uFF01\u30B2\u30FC\u30E0\u306E\u8AAD\u307F\u8FBC\u307F\u4E2D\u306B\u63A2\u7D22\u3057\u307E\u3057\u3087\u3046\u3002",
      "\u30D2\u30F3\u30C8: \u672C\u7DE8\u3067\u306FNPC\u3068\u8A71\u3057\u3066\u8A9E\u5F59\u3092\u7DF4\u7FD2\u3067\u304D\u307E\u3059\u3002",
      "\u8C46\u77E5\u8B58: \u8A00\u8A9E\u5B66\u7FD2\u306F\u8133\u306E\u30EC\u30D9\u30EB\u30A2\u30C3\u30D7\u306B\u4F3C\u3066\u3044\u307E\u3059\u3002",
      "\u30D7\u30ED\u306E\u30D2\u30F3\u30C8: \u30AF\u30A8\u30B9\u30C8\u3092\u5B8C\u4E86\u3057\u3066XP\u3092\u7372\u5F97\u3057\u3001\u65B0\u3057\u3044\u30EC\u30C3\u30B9\u30F3\u3092\u958B\u653E\u3057\u307E\u3057\u3087\u3046\u3002",
      "\u6A4B\u306F2\u3064\u306E\u4E16\u754C\u3092\u3064\u306A\u304E\u307E\u3059\u3002\u8A00\u8A9E\u3068\u540C\u3058\u3067\u3059\u3002",
      "\u5165\u53E3\u306B\u5165\u3063\u3066\u65B0\u3057\u3044\u90E8\u5C4B\u3092\u898B\u3064\u3051\u3066\u307F\u307E\u3057\u3087\u3046\u3002",
      "\u899A\u3048\u308B\u5358\u8A9E\u306F\u3069\u308C\u3082\u5927\u5192\u967A\u306E\u4E00\u6B69\u3067\u3059\u3002",
      "\u63A2\u7D22\u3059\u308B\u307B\u3069\u3001\u767A\u898B\u304C\u5897\u3048\u307E\u3059\u3002",
      "\u79D8\u5BC6: \u96A0\u3055\u308C\u305F\u5B9D\u7269\u3078\u7D9A\u304F\u9053\u3082\u3042\u308A\u307E\u3059...",
      "\u77E5\u3063\u3066\u3044\u307E\u3057\u305F\u304B\uFF1F\u3053\u306E\u30DE\u30C3\u30D7\u306F\u8AAD\u307F\u8FBC\u3080\u305F\u3073\u306B\u5909\u308F\u308A\u307E\u3059\u3002",
      "\u8A00\u8A9E\u306F\u65B0\u3057\u3044\u4E16\u754C\u3078\u306E\u6249\u3092\u958B\u304D\u307E\u3059\u3002\u6587\u5B57\u901A\u308A\u3067\u3059\u3002",
      "\u63A2\u7D22\u3092\u7D9A\u3051\u307E\u3057\u3087\u3046\uFF01\u3044\u3064\u3082\u65B0\u3057\u3044\u767A\u898B\u304C\u3042\u308A\u307E\u3059\u3002"
    ],
    hi: [
      "\u0938\u094D\u0935\u093E\u0917\u0924 \u0939\u0948, \u0938\u093E\u0939\u0938\u0940 \u092F\u093E\u0924\u094D\u0930\u0940! \u0916\u0947\u0932 \u0932\u094B\u0921 \u0939\u094B\u0924\u0947 \u0938\u092E\u092F \u0918\u0942\u092E\u093F\u090F\u0964",
      "\u0938\u0941\u091D\u093E\u0935: \u0905\u0938\u0932\u0940 \u0917\u0947\u092E \u092E\u0947\u0902 NPC \u0938\u0947 \u092C\u093E\u0924 \u0915\u0930\u0915\u0947 \u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u0915\u093E \u0905\u092D\u094D\u092F\u093E\u0938 \u0915\u0930\u0947\u0902!",
      "\u092E\u091C\u093C\u0947\u0926\u093E\u0930 \u092C\u093E\u0924: \u092D\u093E\u0937\u093E \u0938\u0940\u0916\u0928\u093E \u0905\u092A\u0928\u0947 \u0926\u093F\u092E\u093E\u0917 \u0915\u094B \u0932\u0947\u0935\u0932 \u0905\u092A \u0915\u0930\u0928\u0947 \u091C\u0948\u0938\u093E \u0939\u0948\u0964",
      "\u092A\u094D\u0930\u094B \u091F\u093F\u092A: \u0915\u094D\u0935\u0947\u0938\u094D\u091F \u092A\u0942\u0930\u0940 \u0915\u0930\u0915\u0947 XP \u0915\u092E\u093E\u090F\u0901 \u0914\u0930 \u0928\u090F \u092A\u093E\u0920 \u0916\u094B\u0932\u0947\u0902!",
      "\u092F\u0939 \u092A\u0941\u0932 \u0926\u094B \u0926\u0941\u0928\u093F\u092F\u093E\u0913\u0902 \u0915\u094B \u091C\u094B\u0921\u093C\u0924\u093E \u0939\u0948... \u0920\u0940\u0915 \u092D\u093E\u0937\u093E\u0913\u0902 \u0915\u0940 \u0924\u0930\u0939\u0964",
      "\u0928\u0908 \u091C\u0917\u0939\u0947\u0902 \u0916\u094B\u091C\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0926\u0930\u0935\u093E\u091C\u093C\u094B\u0902 \u0938\u0947 \u0905\u0902\u0926\u0930 \u091C\u093E\u090F\u0901!",
      "\u0906\u092A \u091C\u094B \u092D\u0940 \u0936\u092C\u094D\u0926 \u0938\u0940\u0916\u0924\u0947 \u0939\u0948\u0902, \u0935\u0939 \u090F\u0915 \u092C\u0921\u093C\u0947 \u0930\u094B\u092E\u093E\u0902\u091A \u0915\u0940 \u0913\u0930 \u0915\u0926\u092E \u0939\u0948\u0964",
      "\u091C\u093F\u0924\u0928\u093E \u091C\u093C\u094D\u092F\u093E\u0926\u093E \u0916\u094B\u091C\u0947\u0902\u0917\u0947, \u0909\u0924\u0928\u093E \u091C\u093C\u094D\u092F\u093E\u0926\u093E \u092A\u093E\u090F\u0901\u0917\u0947!",
      "\u0930\u093E\u091C\u093C: \u0915\u0941\u091B \u0930\u093E\u0938\u094D\u0924\u0947 \u091B\u093F\u092A\u0947 \u0916\u091C\u093C\u093E\u0928\u094B\u0902 \u0924\u0915 \u0932\u0947 \u091C\u093E\u0924\u0947 \u0939\u0948\u0902...",
      "\u0915\u094D\u092F\u093E \u0906\u092A \u091C\u093E\u0928\u0924\u0947 \u0939\u0948\u0902? \u0939\u0930 \u092C\u093E\u0930 \u0932\u094B\u0921 \u0939\u094B\u0928\u0947 \u092A\u0930 \u092F\u0939 \u0928\u0915\u094D\u0936\u093E \u092C\u0926\u0932 \u091C\u093E\u0924\u093E \u0939\u0948!",
      "\u092D\u093E\u0937\u093E\u090F\u0901 \u0928\u0908 \u0926\u0941\u0928\u093F\u092F\u093E\u0913\u0902 \u0915\u0947 \u0926\u0930\u0935\u093E\u091C\u093C\u0947 \u0916\u094B\u0932\u0924\u0940 \u0939\u0948\u0902\u0964 \u0938\u091A\u092E\u0941\u091A!",
      "\u0916\u094B\u091C \u091C\u093E\u0930\u0940 \u0930\u0916\u0947\u0902! \u0939\u092E\u0947\u0936\u093E \u0915\u0941\u091B \u0928\u092F\u093E \u092E\u093F\u0932\u0924\u093E \u0939\u0948\u0964"
    ]
  };
  var CHEST_MESSAGES = {
    en: [
      "You found a hidden treasure! ...it's knowledge!",
      "A scroll inside reads: 'Practice makes permanente'",
      "You discover a glowing rune... it says 'XP +100' (just kidding)",
      "Inside: a tiny map of all the worlds you'll explore!",
      "A golden coin! Wait... it's a vocabulary token.",
      "You found an ancient grammar scroll!",
      "The chest contains... motivation! +10 willpower.",
      "Inside you find a note: 'You're doing great!'"
    ],
    es: [
      "\xA1Encontraste un tesoro escondido! ...\xA1es conocimiento!",
      "Un pergamino dice: 'La pr\xE1ctica hace al maestro'",
      "Descubres una runa brillante... dice 'XP +100' (es broma)",
      "Dentro: \xA1un mapa peque\xF1o de todos los mundos que explorar\xE1s!",
      "\xA1Una moneda de oro! Espera... es un token de vocabulario.",
      "\xA1Encontraste un pergamino antiguo de gram\xE1tica!",
      "El cofre contiene... \xA1motivaci\xF3n! +10 voluntad.",
      "Dentro encuentras una nota: '\xA1Lo est\xE1s haciendo genial!'"
    ],
    pt: [
      "Voc\xEA encontrou um tesouro escondido!... \xE9 conhecimento!",
      "Um pergaminho diz: 'a pr\xE1tica leva \xE0 melhora'.",
      "Voc\xEA descobre uma runa brilhante... nela est\xE1 escrito 'XP +100' (brincadeira).",
      "Dentro: um mapinha de todos os mundos que voc\xEA vai explorar!",
      "Uma moeda de ouro! Espera... \xE9 um token de vocabul\xE1rio.",
      "Voc\xEA encontrou um pergaminho antigo de gram\xE1tica!",
      "O ba\xFA cont\xE9m... motiva\xE7\xE3o! +10 de for\xE7a de vontade.",
      "L\xE1 dentro h\xE1 um bilhete: 'Voc\xEA est\xE1 indo muito bem!'"
    ],
    it: [
      "Hai trovato un tesoro nascosto! ...\xE8 conoscenza.",
      "Una pergamena dice: 'La pratica rende perfetti'",
      "Scopri una runa luminosa... dice 'XP +100' (scherzo)",
      "Dentro c'\xE8 una piccola mappa di tutti i mondi che esplorerai.",
      "Una moneta d'oro! Aspetta... \xE8 un gettone di vocabolario.",
      "Hai trovato un'antica pergamena di grammatica.",
      "Il baule contiene... motivazione! +10 forza di volont\xE0.",
      "Dentro trovi una nota: 'Stai andando alla grande!'"
    ],
    fr: [
      "Tu as trouve un tresor cache ! ...c'est de la connaissance.",
      "Un parchemin indique : 'C'est en pratiquant qu'on progresse'",
      "Tu decouvres une rune brillante... elle dit 'XP +100' (je plaisante)",
      "Dedans : une petite carte de tous les mondes que tu exploreras.",
      "Une piece d'or ! Attends... c'est un jeton de vocabulaire.",
      "Tu as trouve un ancien parchemin de grammaire.",
      "Le coffre contient... de la motivation ! +10 volonte.",
      "Dedans tu trouves une note : 'Tu t'en sors tres bien !'"
    ],
    ja: [
      "\u96A0\u3055\u308C\u305F\u5B9D\u7269\u3092\u898B\u3064\u3051\u307E\u3057\u305F\uFF01\u305D\u308C\u306F\u77E5\u8B58\u3067\u3059\uFF01",
      "\u4E2D\u306E\u5DFB\u7269\u306B\u306F\u300C\u7DF4\u7FD2\u306F\u529B\u306A\u308A\u300D\u3068\u66F8\u304B\u308C\u3066\u3044\u307E\u3059\u3002",
      "\u5149\u308B\u30EB\u30FC\u30F3\u3092\u898B\u3064\u3051\u307E\u3057\u305F...\u300CXP +100\u300D\u3068\u66F8\u3044\u3066\u3042\u308A\u307E\u3059\uFF08\u5197\u8AC7\u3067\u3059\uFF09\u3002",
      "\u4E2D\u306B\u306F\u3001\u3053\u308C\u304B\u3089\u63A2\u7D22\u3059\u308B\u3059\u3079\u3066\u306E\u4E16\u754C\u306E\u5C0F\u3055\u306A\u5730\u56F3\u304C\u3042\u308A\u307E\u3059\uFF01",
      "\u91D1\u8CA8\u3067\u3059\uFF01\u5F85\u3063\u3066...\u8A9E\u5F59\u30C8\u30FC\u30AF\u30F3\u3067\u3057\u305F\u3002",
      "\u53E4\u4EE3\u306E\u6587\u6CD5\u306E\u5DFB\u7269\u3092\u898B\u3064\u3051\u307E\u3057\u305F\uFF01",
      "\u7BB1\u306E\u4E2D\u8EAB\u306F...\u3084\u308B\u6C17\u3067\u3059\uFF01\u610F\u5FD7\u529B+10\u3002",
      "\u4E2D\u306B\u30E1\u30E2\u304C\u3042\u308A\u307E\u3059\u3002\u300C\u3068\u3066\u3082\u3088\u304F\u3067\u304D\u3066\u3044\u307E\u3059\uFF01\u300D"
    ],
    hi: [
      "\u0906\u092A\u0915\u094B \u090F\u0915 \u091B\u093F\u092A\u093E \u0916\u091C\u093C\u093E\u0928\u093E \u092E\u093F\u0932\u093E! ...\u092F\u0939 \u091C\u094D\u091E\u093E\u0928 \u0939\u0948!",
      "\u0905\u0902\u0926\u0930 \u0915\u0940 \u092A\u0930\u094D\u091A\u0940 \u0915\u0939\u0924\u0940 \u0939\u0948: '\u0905\u092D\u094D\u092F\u093E\u0938 \u0938\u0947 \u0928\u093F\u092A\u0941\u0923\u0924\u093E \u0906\u0924\u0940 \u0939\u0948'",
      "\u0906\u092A\u0915\u094B \u091A\u092E\u0915\u0924\u093E \u0930\u0942\u0928 \u092E\u093F\u0932\u093E... \u0909\u0938 \u092A\u0930 'XP +100' \u0932\u093F\u0916\u093E \u0939\u0948 (\u092E\u091C\u093C\u093E\u0915 \u0915\u0930 \u0930\u0939\u0947 \u0939\u0948\u0902)",
      "\u0905\u0902\u0926\u0930: \u0909\u0928 \u0938\u092D\u0940 \u0926\u0941\u0928\u093F\u092F\u093E\u0913\u0902 \u0915\u093E \u091B\u094B\u091F\u093E \u0928\u0915\u094D\u0936\u093E \u091C\u093F\u0928\u094D\u0939\u0947\u0902 \u0906\u092A \u0916\u094B\u091C\u0947\u0902\u0917\u0947!",
      "\u090F\u0915 \u0938\u094B\u0928\u0947 \u0915\u093E \u0938\u093F\u0915\u094D\u0915\u093E! \u0920\u0939\u0930\u093F\u090F... \u092F\u0939 \u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u091F\u094B\u0915\u0928 \u0939\u0948\u0964",
      "\u0906\u092A\u0915\u094B \u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u0915\u093E \u090F\u0915 \u092A\u094D\u0930\u093E\u091A\u0940\u0928 \u0938\u094D\u0915\u094D\u0930\u0949\u0932 \u092E\u093F\u0932\u093E!",
      "\u0907\u0938 \u0938\u0902\u0926\u0942\u0915 \u092E\u0947\u0902 \u0939\u0948... \u092A\u094D\u0930\u0947\u0930\u0923\u093E! +10 \u0907\u091A\u094D\u091B\u093E\u0936\u0915\u094D\u0924\u093F\u0964",
      "\u0905\u0902\u0926\u0930 \u090F\u0915 \u0928\u094B\u091F \u0939\u0948: '\u0906\u092A \u092C\u0939\u0941\u0924 \u0905\u091A\u094D\u091B\u093E \u0915\u0930 \u0930\u0939\u0947 \u0939\u0948\u0902!'"
    ]
  };
  var LAMP_MESSAGES = {
    en: [
      "The lamp flickers warmly. It feels cozy here.",
      "A soft glow illuminates some ancient text... illegible.",
      "The light dances like tiny fireflies.",
      "You feel a warm glow of encouragement."
    ],
    es: [
      "La l\xE1mpara parpadea c\xE1lidamente. Se siente acogedor.",
      "Un brillo suave ilumina un texto antiguo... ilegible.",
      "La luz baila como peque\xF1as luci\xE9rnagas.",
      "Sientes un c\xE1lido resplandor de \xE1nimo."
    ],
    pt: [
      "A lumin\xE1ria pisca suavemente. O lugar parece aconchegante.",
      "Um brilho suave ilumina um texto antigo... ileg\xEDvel.",
      "A luz dan\xE7a como pequenas fa\xEDscas.",
      "Voc\xEA sente um brilho caloroso de encorajamento."
    ],
    it: [
      "La lampada tremola con calore. Qui si sta bene.",
      "Una luce soffusa illumina un testo antico... illeggibile.",
      "La luce danza come piccole scintille.",
      "Senti un caldo bagliore di incoraggiamento."
    ],
    fr: [
      "La lampe vacille doucement. L'endroit semble accueillant.",
      "Une lueur douce eclaire un texte ancien... illisible.",
      "La lumiere danse comme de petites etincelles.",
      "Tu ressens une douce lueur d'encouragement."
    ],
    ja: [
      "\u30E9\u30F3\u30D7\u304C\u6696\u304B\u304F\u3086\u3089\u3081\u3044\u3066\u3044\u307E\u3059\u3002\u3053\u3053\u306F\u5C45\u5FC3\u5730\u304C\u3088\u3055\u305D\u3046\u3067\u3059\u3002",
      "\u67D4\u3089\u304B\u306A\u5149\u304C\u53E4\u3044\u6587\u5B57\u3092\u7167\u3089\u3057\u3066\u3044\u307E\u3059...\u8AAD\u3081\u307E\u305B\u3093\u3002",
      "\u5149\u304C\u5C0F\u3055\u306A\u706B\u82B1\u306E\u3088\u3046\u306B\u8E0A\u3063\u3066\u3044\u307E\u3059\u3002",
      "\u52B1\u307E\u3057\u306E\u6696\u304B\u306A\u5149\u3092\u611F\u3058\u307E\u3059\u3002"
    ],
    hi: [
      "\u0926\u0940\u092A\u0915 \u0917\u0930\u092E\u093E\u0939\u091F \u0938\u0947 \u091F\u093F\u092E\u091F\u093F\u092E\u093E \u0930\u0939\u093E \u0939\u0948\u0964 \u092F\u0939\u093E\u0901 \u092C\u0939\u0941\u0924 \u0906\u0930\u093E\u092E\u0926\u093E\u092F\u0915 \u0932\u0917\u0924\u093E \u0939\u0948\u0964",
      "\u092E\u0941\u0932\u093E\u092F\u092E \u0930\u094B\u0936\u0928\u0940 \u0915\u093F\u0938\u0940 \u092A\u094D\u0930\u093E\u091A\u0940\u0928 \u0932\u0947\u0916 \u0915\u094B \u092A\u094D\u0930\u0915\u093E\u0936\u093F\u0924 \u0915\u0930 \u0930\u0939\u0940 \u0939\u0948... \u092A\u0922\u093C\u093E \u0928\u0939\u0940\u0902 \u091C\u093E \u0930\u0939\u093E\u0964",
      "\u0930\u094B\u0936\u0928\u0940 \u091B\u094B\u091F\u0940 \u091C\u0941\u0917\u0928\u0941\u0913\u0902 \u0915\u0940 \u0924\u0930\u0939 \u0928\u093E\u091A \u0930\u0939\u0940 \u0939\u0948\u0964",
      "\u0906\u092A\u0915\u094B \u0939\u094C\u0938\u0932\u0947 \u0915\u0940 \u090F\u0915 \u0917\u0930\u092E \u091A\u092E\u0915 \u092E\u0939\u0938\u0942\u0938 \u0939\u094B\u0924\u0940 \u0939\u0948\u0964"
    ]
  };
  var PLANT_MESSAGES = {
    en: [
      "A happy little plant. It seems to like this spot.",
      "The leaves rustle gently as you pass by.",
      "This plant has been here longer than anyone remembers.",
      "A small flower is blooming. How nice!"
    ],
    es: [
      "Una plantita feliz. Parece que le gusta este lugar.",
      "Las hojas se mueven suavemente cuando pasas.",
      "Esta planta lleva aqu\xED m\xE1s tiempo del que nadie recuerda.",
      "Una peque\xF1a flor est\xE1 floreciendo. \xA1Qu\xE9 bonito!"
    ],
    pt: [
      "Uma plantinha feliz. Parece gostar deste lugar.",
      "As folhas se mexem suavemente quando voc\xEA passa.",
      "Esta planta est\xE1 aqui h\xE1 mais tempo do que qualquer um lembra.",
      "Uma florzinha est\xE1 desabrochando. Que bonito!"
    ],
    it: [
      "Una piantina felice. Sembra che le piaccia questo posto.",
      "Le foglie frusciano dolcemente mentre passi.",
      "Questa pianta \xE8 qui da pi\xF9 tempo di quanto chiunque ricordi.",
      "Un piccolo fiore sta sbocciando. Che bello!"
    ],
    fr: [
      "Une petite plante heureuse. Elle semble aimer cet endroit.",
      "Les feuilles frissonnent doucement quand tu passes.",
      "Cette plante est ici depuis plus longtemps que personne ne s'en souvient.",
      "Une petite fleur est en train d'eclore. Comme c'est joli !"
    ],
    ja: [
      "\u5E78\u305B\u305D\u3046\u306A\u5C0F\u3055\u306A\u690D\u7269\u3067\u3059\u3002\u3053\u306E\u5834\u6240\u304C\u6C17\u306B\u5165\u3063\u3066\u3044\u308B\u3088\u3046\u3067\u3059\u3002",
      "\u901A\u308A\u904E\u304E\u308B\u3068\u8449\u304C\u3084\u3055\u3057\u304F\u63FA\u308C\u307E\u3059\u3002",
      "\u3053\u306E\u690D\u7269\u306F\u8AB0\u306E\u8A18\u61B6\u3088\u308A\u3082\u9577\u304F\u3053\u3053\u306B\u3042\u308A\u307E\u3059\u3002",
      "\u5C0F\u3055\u306A\u82B1\u304C\u54B2\u3044\u3066\u3044\u307E\u3059\u3002\u7D20\u6575\u3067\u3059\u306D\uFF01"
    ],
    hi: [
      "\u090F\u0915 \u0916\u0941\u0936 \u091B\u094B\u091F\u0940 \u092A\u094C\u0927\u0940\u0964 \u0932\u0917\u0924\u093E \u0939\u0948 \u0907\u0938\u0947 \u092F\u0939 \u091C\u0917\u0939 \u092A\u0938\u0902\u0926 \u0939\u0948\u0964",
      "\u0906\u092A\u0915\u0947 \u0917\u0941\u091C\u0930\u0924\u0947 \u0939\u0940 \u092A\u0924\u094D\u0924\u093F\u092F\u093E\u0901 \u0927\u0940\u0930\u0947-\u0927\u0940\u0930\u0947 \u0938\u0930\u0938\u0930\u093E\u0924\u0940 \u0939\u0948\u0902\u0964",
      "\u092F\u0939 \u092A\u094C\u0927\u093E \u092F\u0939\u093E\u0901 \u0909\u0924\u0928\u0947 \u0938\u092E\u092F \u0938\u0947 \u0939\u0948 \u091C\u093F\u0924\u0928\u093E \u0915\u093F\u0938\u0940 \u0915\u094B \u092F\u093E\u0926 \u092D\u0940 \u0928\u0939\u0940\u0902\u0964",
      "\u090F\u0915 \u091B\u094B\u091F\u093E \u092B\u0942\u0932 \u0916\u093F\u0932 \u0930\u0939\u093E \u0939\u0948\u0964 \u0915\u093F\u0924\u0928\u093E \u0938\u0941\u0902\u0926\u0930!"
    ]
  };
  var TABLE_MESSAGES = {
    en: [
      "A sturdy wooden table. Someone left notes about verb conjugations.",
      "The table has scratch marks from years of study sessions.",
      "Books and papers are scattered across the surface.",
      "A half-finished puzzle sits on the table."
    ],
    es: [
      "Una mesa resistente. Alguien dej\xF3 notas sobre conjugaciones.",
      "La mesa tiene marcas de a\xF1os de sesiones de estudio.",
      "Libros y papeles est\xE1n esparcidos por la superficie.",
      "Un rompecabezas a medio terminar est\xE1 sobre la mesa."
    ],
    pt: [
      "Uma mesa resistente. Algu\xE9m deixou anota\xE7\xF5es sobre conjuga\xE7\xF5es.",
      "A mesa tem marcas de muitos anos de estudo.",
      "Livros e pap\xE9is est\xE3o espalhados pela superf\xEDcie.",
      "H\xE1 um quebra-cabe\xE7a pela metade sobre a mesa."
    ],
    it: [
      "Un tavolo robusto. Qualcuno ha lasciato appunti sulle coniugazioni.",
      "Il tavolo porta i segni di anni di sessioni di studio.",
      "Libri e fogli sono sparsi sulla superficie.",
      "Un rompicapo a met\xE0 \xE8 appoggiato sul tavolo."
    ],
    fr: [
      "Une table robuste. Quelqu'un a laisse des notes sur les conjugaisons.",
      "La table porte des marques de nombreuses sessions d'etude.",
      "Des livres et papiers sont eparpilles sur la surface.",
      "Un puzzle a moitie termine est pose sur la table."
    ],
    ja: [
      "\u4E08\u592B\u306A\u6728\u306E\u30C6\u30FC\u30D6\u30EB\u3067\u3059\u3002\u8AB0\u304B\u304C\u52D5\u8A5E\u306E\u6D3B\u7528\u30E1\u30E2\u3092\u6B8B\u3057\u3066\u3044\u307E\u3059\u3002",
      "\u30C6\u30FC\u30D6\u30EB\u306B\u306F\u9577\u5E74\u306E\u52C9\u5F37\u4F1A\u3067\u3067\u304D\u305F\u50B7\u304C\u3042\u308A\u307E\u3059\u3002",
      "\u672C\u3084\u7D19\u304C\u8868\u9762\u306B\u6563\u3089\u3070\u3063\u3066\u3044\u307E\u3059\u3002",
      "\u9014\u4E2D\u307E\u3067\u89E3\u3044\u305F\u30D1\u30BA\u30EB\u304C\u30C6\u30FC\u30D6\u30EB\u306B\u7F6E\u304B\u308C\u3066\u3044\u307E\u3059\u3002"
    ],
    hi: [
      "\u092E\u091C\u092C\u0942\u0924 \u0932\u0915\u0921\u093C\u0940 \u0915\u0940 \u092E\u0947\u091C\u093C\u0964 \u0915\u093F\u0938\u0940 \u0928\u0947 \u0915\u094D\u0930\u093F\u092F\u093E-\u0930\u0942\u092A\u094B\u0902 \u092A\u0930 \u0928\u094B\u091F\u094D\u0938 \u091B\u094B\u0921\u093C \u0930\u0916\u0947 \u0939\u0948\u0902\u0964",
      "\u0907\u0938 \u092E\u0947\u091C\u093C \u092A\u0930 \u0935\u0930\u094D\u0937\u094B\u0902 \u0915\u0947 \u0905\u0927\u094D\u092F\u092F\u0928 \u0938\u0924\u094D\u0930\u094B\u0902 \u0915\u0947 \u0928\u093F\u0936\u093E\u0928 \u0939\u0948\u0902\u0964",
      "\u0938\u0924\u0939 \u092A\u0930 \u0915\u093F\u0924\u093E\u092C\u0947\u0902 \u0914\u0930 \u0915\u093E\u0917\u091C\u093C \u092C\u093F\u0916\u0930\u0947 \u0939\u0941\u090F \u0939\u0948\u0902\u0964",
      "\u092E\u0947\u091C\u093C \u092A\u0930 \u0906\u0927\u093E \u092A\u0942\u0930\u093E \u0939\u0941\u0906 \u090F\u0915 \u092A\u091C\u093C\u0932 \u0930\u0916\u093E \u0939\u0948\u0964"
    ]
  };
  var ALL_MESSAGES = {
    [SIGN]: SIGN_MESSAGES,
    [CHEST]: CHEST_MESSAGES,
    [LAMP]: LAMP_MESSAGES,
    [PLANT_POT]: PLANT_MESSAGES,
    [TABLE]: TABLE_MESSAGES
  };
  OUTDOOR_NAMES.ar = [
    "\u0645\u064A\u062F\u0627\u0646 \u0627\u0644\u0645\u062F\u064A\u0646\u0629",
    "\u0633\u0627\u062D\u0629 \u0627\u0644\u0642\u0631\u064A\u0629",
    "\u0641\u0633\u062D\u0629 \u0627\u0644\u063A\u0627\u0628\u0629",
    "\u062D\u062F\u064A\u0642\u0629 \u0636\u0641\u0629 \u0627\u0644\u0646\u0647\u0631",
    "\u0645\u0631\u062C \u0627\u0644\u063A\u0631\u0648\u0628",
    "\u062D\u062F\u064A\u0642\u0629 \u0636\u0648\u0621 \u0627\u0644\u0642\u0645\u0631",
    "\u0633\u0627\u062D\u0629 \u0627\u0644\u062D\u062C\u0627\u0631\u0629",
    "\u0627\u0644\u0628\u0633\u062A\u0627\u0646 \u0627\u0644\u0647\u0627\u0645\u0633",
    "\u0633\u0627\u062D\u0629 \u0627\u0644\u0641\u0648\u0627\u0646\u064A\u0633",
    "\u062D\u0642\u0644 \u0627\u0644\u0632\u0647\u0648\u0631 \u0627\u0644\u0628\u0631\u064A\u0629"
  ];
  OUTDOOR_NAMES.de = [
    "Stadtplatz",
    "Dorfanger",
    "Waldlichtung",
    "Park am Fluss",
    "Abendwiese",
    "Mondscheingarten",
    "Kopfsteinpflasterplatz",
    "Fl\xFCsterhain",
    "Laternenhof",
    "Wildblumenfeld"
  ];
  INDOOR_ROOM_TYPES[0].names.de = [
    "Alte Bibliothek",
    "Leseraum",
    "Studierzimmer",
    "B\xFCcherecke",
    "Staubiges Archiv"
  ];
  INDOOR_ROOM_TYPES[1].names.de = [
    "Gem\xFCtliche H\xFCtte",
    "Warmes H\xE4uschen",
    "Rast der Reisenden",
    "Kaminlodge",
    "Bergh\xFCtte"
  ];
  INDOOR_ROOM_TYPES[2].names.de = [
    "Handwerkswerkstatt",
    "Bastelraum",
    "Macherraum",
    "T\xFCftlerlabor",
    "Erfinderversteck"
  ];
  INDOOR_ROOM_TYPES[3].names.de = [
    "G\xE4stezimmer",
    "Gem\xFCtliches Schlafzimmer",
    "Traumzimmer",
    "Nickerchenraum",
    "Ruhehafen"
  ];
  INDOOR_ROOM_TYPES[4].names.de = [
    "Lounge",
    "Gemeinschaftsraum",
    "Versammlungssaal",
    "Soziale Ecke",
    "Teeraum"
  ];
  SIGN_MESSAGES.de = [
    "Willkommen, Abenteurer! Erkunde die Welt, w\xE4hrend dein Spiel l\xE4dt.",
    "Tipp: Sprich im echten Spiel mit NPCs, um Wortschatz zu \xFCben!",
    "Schon gewusst? Sprachenlernen ist wie ein Level-up f\xFCrs Gehirn.",
    "Profi-Tipp: Schlie\xDFe Quests ab, um XP zu verdienen und neue Lektionen freizuschalten!",
    "Die Br\xFCcke verbindet zwei Welten... genau wie Sprachen.",
    "Betritt die T\xFCren, um neue R\xE4ume zu entdecken!",
    "Jedes gelernte Wort ist ein Schritt in einem gro\xDFen Abenteuer.",
    "Je mehr du erkundest, desto mehr entdeckst du!",
    "Geheimnis: Manche Wege f\xFChren zu verborgenen Sch\xE4tzen...",
    "Wusstest du? Diese Karte \xE4ndert sich bei jedem Laden!",
    "Sprachen \xF6ffnen T\xFCren zu neuen Welten. Buchst\xE4blich!",
    "Erkunde weiter! Es gibt immer etwas Neues zu finden."
  ];
  CHEST_MESSAGES.de = [
    "Du hast einen verborgenen Schatz gefunden! ...es ist Wissen!",
    "In einer Schriftrolle steht: '\xDCbung macht den Meister'",
    "Du entdeckst eine leuchtende Rune... sie sagt 'XP +100' (nur Spa\xDF)",
    "Drinnen liegt eine kleine Karte aller Welten, die du erkunden wirst!",
    "Eine Goldm\xFCnze! Moment... es ist ein Wortschatz-Token.",
    "Du hast eine alte Grammatikrolle gefunden!",
    "Die Truhe enth\xE4lt... Motivation! +10 Willenskraft.",
    "Drinnen findest du eine Notiz: 'Du machst das gro\xDFartig!'"
  ];
  LAMP_MESSAGES.de = [
    "Die Lampe flackert warm. Hier f\xFChlt es sich gem\xFCtlich an.",
    "Ein sanftes Leuchten beleuchtet alten Text... unleserlich.",
    "Das Licht tanzt wie kleine Funken.",
    "Du sp\xFCrst ein warmes Leuchten der Ermutigung."
  ];
  PLANT_MESSAGES.de = [
    "Eine gl\xFCckliche kleine Pflanze. Sie scheint diesen Platz zu m\xF6gen.",
    "Die Bl\xE4tter rascheln sanft, als du vorbeigehst.",
    "Diese Pflanze ist l\xE4nger hier, als sich irgendjemand erinnert.",
    "Eine kleine Blume bl\xFCht. Wie sch\xF6n!"
  ];
  TABLE_MESSAGES.de = [
    "Ein stabiler Holztisch. Jemand hat Notizen zu Verbkonjugationen dagelassen.",
    "Der Tisch tr\xE4gt Kratzspuren von jahrelangen Lernsitzungen.",
    "B\xFCcher und Papiere liegen \xFCber die Oberfl\xE4che verstreut.",
    "Ein halb gel\xF6stes R\xE4tsel liegt auf dem Tisch."
  ];
  INDOOR_ROOM_TYPES[0].names.ar = [
    "\u0627\u0644\u0645\u0643\u062A\u0628\u0629 \u0627\u0644\u0642\u062F\u064A\u0645\u0629",
    "\u063A\u0631\u0641\u0629 \u0627\u0644\u0642\u0631\u0627\u0621\u0629",
    "\u0645\u0643\u062A\u0628 \u0627\u0644\u0628\u0627\u062D\u062B",
    "\u0631\u0643\u0646 \u0627\u0644\u0643\u062A\u0628",
    "\u0627\u0644\u0623\u0631\u0634\u064A\u0641 \u0627\u0644\u062A\u0631\u0627\u0628\u064A"
  ];
  INDOOR_ROOM_TYPES[1].names.ar = [
    "\u0627\u0644\u0643\u0648\u062E \u0627\u0644\u062F\u0627\u0641\u064A",
    "\u0627\u0644\u0628\u064A\u062A \u0627\u0644\u062F\u0627\u0641\u064A",
    "\u0627\u0633\u062A\u0631\u0627\u062D\u0629 \u0627\u0644\u0645\u0633\u0627\u0641\u0631",
    "\u0645\u0644\u062C\u0623 \u0627\u0644\u0645\u062F\u0641\u0623\u0629",
    "\u0643\u0648\u062E \u0627\u0644\u062C\u0628\u0644"
  ];
  INDOOR_ROOM_TYPES[2].names.ar = [
    "\u0627\u0644\u0648\u0631\u0634\u0629 \u0627\u0644\u062D\u0631\u0641\u064A\u0629",
    "\u063A\u0631\u0641\u0629 \u0627\u0644\u0623\u0634\u063A\u0627\u0644",
    "\u0645\u0633\u0627\u062D\u0629 \u0627\u0644\u0635\u0646\u0639",
    "\u0645\u0639\u0645\u0644 \u0627\u0644\u0645\u0635\u0644\u0651\u062D",
    "\u0645\u062E\u0628\u0623 \u0627\u0644\u0645\u062E\u062A\u0631\u0639"
  ];
  INDOOR_ROOM_TYPES[3].names.ar = [
    "\u063A\u0631\u0641\u0629 \u0627\u0644\u0636\u064A\u0648\u0641",
    "\u0623\u0648\u0636\u0629 \u0646\u0648\u0645 \u062F\u0627\u0641\u064A\u0629",
    "\u063A\u0631\u0641\u0629 \u0627\u0644\u062D\u0627\u0644\u0645",
    "\u063A\u0631\u0641\u0629 \u0627\u0644\u0642\u064A\u0644\u0648\u0644\u0629",
    "\u0645\u0644\u0627\u0630 \u0627\u0644\u0631\u0627\u062D\u0629"
  ];
  INDOOR_ROOM_TYPES[4].names.ar = [
    "\u0627\u0644\u0627\u0633\u062A\u0631\u0627\u062D\u0629",
    "\u0627\u0644\u063A\u0631\u0641\u0629 \u0627\u0644\u0645\u0634\u062A\u0631\u0643\u0629",
    "\u0642\u0627\u0639\u0629 \u0627\u0644\u062A\u062C\u0645\u0639",
    "\u0627\u0644\u0631\u0643\u0646 \u0627\u0644\u0627\u062C\u062A\u0645\u0627\u0639\u064A",
    "\u063A\u0631\u0641\u0629 \u0627\u0644\u0634\u0627\u064A"
  ];
  SIGN_MESSAGES.ar = [
    "\u0623\u0647\u0644\u0627 \u0628\u064A\u0643 \u064A\u0627 \u0645\u063A\u0627\u0645\u0631! \u0627\u0633\u062A\u0643\u0634\u0641 \u0644\u062D\u062F \u0645\u0627 \u0644\u0639\u0628\u062A\u0643 \u062A\u062C\u0647\u0632.",
    "\u062A\u0644\u0645\u064A\u062D: \u0643\u0644\u0645 \u0627\u0644\u0634\u062E\u0635\u064A\u0627\u062A \u0641\u064A \u0627\u0644\u0644\u0639\u0628\u0629 \u0627\u0644\u0623\u0635\u0644\u064A\u0629 \u0639\u0634\u0627\u0646 \u062A\u062A\u0645\u0631\u0646 \u0639\u0644\u0649 \u0627\u0644\u0645\u0641\u0631\u062F\u0627\u062A!",
    "\u0645\u0639\u0644\u0648\u0645\u0629 \u0644\u0637\u064A\u0641\u0629: \u062A\u0639\u0644\u0645 \u0627\u0644\u0644\u063A\u0629 \u0634\u0628\u0647 \u0625\u0646\u0643 \u0628\u062A\u0631\u0641\u0639 \u0645\u0633\u062A\u0648\u0649 \u0645\u062E\u0643.",
    "\u0646\u0635\u064A\u062D\u0629 \u0645\u062D\u062A\u0631\u0641\u064A\u0646: \u062E\u0644\u0635 \u0627\u0644\u0645\u0647\u0627\u0645 \u0639\u0634\u0627\u0646 \u062A\u0627\u062E\u062F XP \u0648\u062A\u0641\u062A\u062D \u062F\u0631\u0648\u0633 \u062C\u062F\u064A\u062F\u0629!",
    "\u0627\u0644\u0643\u0648\u0628\u0631\u064A \u0628\u064A\u0648\u0635\u0644 \u0628\u064A\u0646 \u0639\u0627\u0644\u0645\u064A\u0646... \u0632\u064A \u0627\u0644\u0644\u063A\u0627\u062A \u0628\u0627\u0644\u0638\u0628\u0637.",
    "\u062C\u0631\u0651\u0628 \u062A\u062F\u062E\u0644 \u0645\u0646 \u0627\u0644\u0645\u062F\u0627\u062E\u0644 \u0639\u0634\u0627\u0646 \u062A\u0643\u062A\u0634\u0641 \u0623\u0648\u0636 \u062C\u062F\u064A\u062F\u0629!",
    "\u0643\u0644 \u0643\u0644\u0645\u0629 \u0628\u062A\u062A\u0639\u0644\u0645\u0647\u0627 \u0647\u064A \u062E\u0637\u0648\u0629 \u0641\u064A \u0645\u063A\u0627\u0645\u0631\u0629 \u0643\u0628\u064A\u0631\u0629.",
    "\u0643\u0644 \u0645\u0627 \u062A\u0633\u062A\u0643\u0634\u0641 \u0623\u0643\u062A\u0631\u060C \u062A\u0643\u062A\u0634\u0641 \u0623\u0643\u062A\u0631!",
    "\u0633\u0631 \u0635\u063A\u064A\u0631: \u0628\u0639\u0636 \u0627\u0644\u0637\u0631\u0642 \u0628\u062A\u0648\u062F\u0651\u064A \u0644\u0643\u0646\u0648\u0632 \u0645\u062E\u0641\u064A\u0629...",
    "\u062A\u0639\u0631\u0641\u061F \u0627\u0644\u062E\u0631\u064A\u0637\u0629 \u062F\u064A \u0628\u062A\u062A\u063A\u064A\u0631 \u0643\u0644 \u0645\u0631\u0629 \u062A\u062A\u062D\u0645\u0644 \u0641\u064A\u0647\u0627!",
    "\u0627\u0644\u0644\u063A\u0627\u062A \u0628\u062A\u0641\u062A\u062D \u0623\u0628\u0648\u0627\u0628 \u0644\u0639\u0648\u0627\u0644\u0645 \u062C\u062F\u064A\u062F\u0629. \u062D\u0631\u0641\u064A\u064B\u0627!",
    "\u0643\u0645\u0651\u0644 \u0627\u0633\u062A\u0643\u0634\u0627\u0641! \u062F\u0627\u064A\u0645\u064B\u0627 \u0641\u064A\u0647 \u062D\u0627\u062C\u0629 \u062C\u062F\u064A\u062F\u0629 \u062A\u0644\u0627\u0642\u064A\u0647\u0627."
  ];
  CHEST_MESSAGES.ar = [
    "\u0644\u0642\u064A\u062A \u0643\u0646\u0632 \u0645\u062E\u0641\u064A!... \u0637\u0644\u0639 \u0645\u0639\u0631\u0641\u0629!",
    '\u062C\u0648\u0647 \u0648\u0631\u0642\u0629 \u0645\u0643\u062A\u0648\u0628: "\u0627\u0644\u062A\u0645\u0631\u064A\u0646 \u0628\u064A\u0639\u0645\u0644 \u0641\u0631\u0642"',
    '\u0627\u0643\u062A\u0634\u0641\u062A \u0631\u0648\u0646 \u0645\u0636\u064A\u0621... \u0645\u0643\u062A\u0648\u0628 \u0639\u0644\u064A\u0647 "XP +100" (\u0628\u0647\u0632\u0631)',
    "\u062C\u0648\u0627\u0647\u0627 \u062E\u0631\u064A\u0637\u0629 \u0635\u063A\u064A\u0631\u0629 \u0644\u0643\u0644 \u0627\u0644\u0639\u0648\u0627\u0644\u0645 \u0627\u0644\u0644\u064A \u0647\u062A\u0632\u0648\u0631\u0647\u0627!",
    "\u0639\u0645\u0644\u0629 \u062F\u0647\u0628! \u0627\u0633\u062A\u0646\u0649... \u062F\u0647 \u062A\u0648\u0643\u0646 \u0645\u0641\u0631\u062F\u0627\u062A.",
    "\u0644\u0642\u064A\u062A \u0645\u062E\u0637\u0648\u0637\u0629 \u0642\u062F\u064A\u0645\u0629 \u0641\u064A \u0627\u0644\u0642\u0648\u0627\u0639\u062F!",
    "\u0627\u0644\u0635\u0646\u062F\u0648\u0642 \u0641\u064A\u0647... \u062D\u0645\u0627\u0633! +10 \u0642\u0648\u0629 \u0625\u0631\u0627\u062F\u0629.",
    '\u062C\u0648\u0647 \u0644\u0642\u064A\u062A \u0645\u0644\u0627\u062D\u0638\u0629: "\u0625\u0646\u062A \u0645\u0627\u0634\u064A \u0643\u0648\u064A\u0633 \u062C\u062F\u064B\u0627!"'
  ];
  LAMP_MESSAGES.ar = [
    "\u0627\u0644\u0644\u0645\u0628\u0629 \u0628\u062A\u0646\u0648\u0631 \u0628\u0646\u0639\u0648\u0645\u0629. \u0627\u0644\u0645\u0643\u0627\u0646 \u0647\u0646\u0627 \u062F\u0627\u0641\u064A.",
    "\u0646\u0648\u0631 \u0647\u0627\u062F\u064A \u0628\u064A\u0646\u0648\u0651\u0631 \u0643\u062A\u0627\u0628\u0629 \u0642\u062F\u064A\u0645\u0629... \u0645\u0634 \u0645\u0642\u0631\u0648\u0621\u0629.",
    "\u0627\u0644\u0646\u0648\u0631 \u0628\u064A\u0631\u0642\u0635 \u0632\u064A \u0634\u0631\u0627\u0631\u0627\u062A \u0635\u063A\u064A\u0631\u0629.",
    "\u0628\u062A\u062D\u0633 \u0628\u062F\u0641\u0627 \u0648\u062A\u0634\u062C\u064A\u0639."
  ];
  PLANT_MESSAGES.ar = [
    "\u0646\u0628\u062A\u0629 \u0635\u063A\u064A\u0631\u0629 \u0633\u0639\u064A\u062F\u0629. \u0648\u0627\u0636\u062D \u0625\u0646 \u0627\u0644\u0645\u0643\u0627\u0646 \u062F\u0647 \u0639\u0627\u062C\u0628\u0647\u0627.",
    "\u0627\u0644\u0648\u0631\u0642 \u0628\u064A\u062A\u062D\u0631\u0643 \u0628\u0647\u062F\u0648\u0621 \u0648\u0625\u0646\u062A \u0645\u0627\u0634\u064A.",
    "\u0627\u0644\u0646\u0628\u062A\u0629 \u062F\u064A \u0645\u0648\u062C\u0648\u062F\u0629 \u0647\u0646\u0627 \u0645\u0646 \u0632\u0645\u0627\u0646 \u062C\u062F\u064B\u0627.",
    "\u0632\u0647\u0631\u0629 \u0635\u063A\u064A\u0631\u0629 \u0628\u062A\u062A\u0641\u062A\u062D. \u062C\u0645\u064A\u0644 \u0623\u0648\u064A!"
  ];
  TABLE_MESSAGES.ar = [
    "\u062A\u0631\u0627\u0628\u064A\u0632\u0629 \u062E\u0634\u0628 \u0645\u062A\u064A\u0646\u0629. \u062D\u062F \u0633\u0627\u064A\u0628 \u0645\u0644\u0627\u062D\u0638\u0627\u062A \u0639\u0646 \u062A\u0635\u0631\u064A\u0641 \u0627\u0644\u0623\u0641\u0639\u0627\u0644.",
    "\u0639\u0644\u0649 \u0627\u0644\u062A\u0631\u0627\u0628\u064A\u0632\u0629 \u0622\u062B\u0627\u0631 \u0633\u0646\u064A\u0646 \u0645\u0646 \u062C\u0644\u0633\u0627\u062A \u0627\u0644\u0645\u0630\u0627\u0643\u0631\u0629.",
    "\u0643\u062A\u0628 \u0648\u0648\u0631\u0642 \u0645\u062A\u0628\u0647\u062F\u0644\u064A\u0646 \u0639\u0644\u0649 \u0627\u0644\u0633\u0637\u062D.",
    "\u0641\u064A\u0647 \u0628\u0627\u0632\u0644 \u0644\u0633\u0647 \u0645\u062E\u0644\u0635\u0634 \u0639\u0644\u0649 \u0627\u0644\u062A\u0631\u0627\u0628\u064A\u0632\u0629."
  ];
  OUTDOOR_NAMES.zh = [
    "\u57CE\u9547\u5E7F\u573A",
    "\u6751\u5E84\u7EFF\u5730",
    "\u68EE\u6797\u7A7A\u5730",
    "\u6CB3\u7554\u516C\u56ED",
    "\u5915\u9633\u8349\u5730",
    "\u6708\u5149\u82B1\u56ED",
    "\u9E45\u5375\u77F3\u5E7F\u573A",
    "\u4F4E\u8BED\u6811\u6797",
    "\u706F\u7B3C\u5EAD\u9662",
    "\u91CE\u82B1\u7530\u91CE"
  ];
  INDOOR_ROOM_TYPES[0].names.zh = [
    "\u53E4\u8001\u56FE\u4E66\u9986",
    "\u9605\u8BFB\u5BA4",
    "\u5B66\u8005\u4E66\u623F",
    "\u4E66\u672C\u89D2\u843D",
    "\u5C18\u5C01\u6863\u6848\u5BA4"
  ];
  INDOOR_ROOM_TYPES[1].names.zh = [
    "\u6E29\u99A8\u6728\u5C4B",
    "\u6696\u548C\u5C0F\u5C4B",
    "\u65C5\u4EBA\u4F11\u606F\u5904",
    "\u7089\u8FB9\u5C0F\u5C4B",
    "\u5C71\u95F4\u5C0F\u5C4B"
  ];
  INDOOR_ROOM_TYPES[2].names.zh = [
    "\u5DE5\u5320\u4F5C\u574A",
    "\u624B\u5DE5\u5BA4",
    "\u521B\u4F5C\u8005\u7A7A\u95F4",
    "\u4FEE\u8865\u5B9E\u9A8C\u5BA4",
    "\u53D1\u660E\u8005\u5C0F\u5C4B"
  ];
  INDOOR_ROOM_TYPES[3].names.zh = [
    "\u5BA2\u623F",
    "\u6E29\u6696\u5367\u5BA4",
    "\u68A6\u8005\u623F\u95F4",
    "\u5348\u7761\u623F",
    "\u4F11\u606F\u907F\u98CE\u6E2F"
  ];
  INDOOR_ROOM_TYPES[4].names.zh = [
    "\u4F11\u606F\u5BA4",
    "\u516C\u5171\u623F\u95F4",
    "\u805A\u4F1A\u5927\u5385",
    "\u793E\u4EA4\u89D2\u843D",
    "\u8336\u5BA4"
  ];
  SIGN_MESSAGES.zh = [
    "\u6B22\u8FCE\u4F60\uFF0C\u5192\u9669\u8005\uFF01\u5728\u6E38\u620F\u51C6\u5907\u597D\u4E4B\u524D\u5148\u63A2\u7D22\u4E00\u4E0B\u5427\u3002",
    "\u63D0\u793A\uFF1A\u548C\u4E3B\u6E38\u620F\u91CC\u7684\u89D2\u8272\u5BF9\u8BDD\uFF0C\u53EF\u4EE5\u7EC3\u4E60\u8BCD\u6C47\uFF01",
    "\u6709\u8DA3\u4E8B\u5B9E\uFF1A\u5B66\u4E60\u8BED\u8A00\u5C31\u50CF\u7ED9\u5927\u8111\u5347\u7EA7\u3002",
    "\u9AD8\u624B\u63D0\u793A\uFF1A\u5B8C\u6210\u4EFB\u52A1\u53EF\u4EE5\u83B7\u5F97 XP \u5E76\u89E3\u9501\u65B0\u8BFE\u7A0B\uFF01",
    "\u6865\u8FDE\u63A5\u4E24\u4E2A\u4E16\u754C\uFF0C\u8BED\u8A00\u4E5F\u662F\u8FD9\u6837\u3002",
    "\u8BD5\u8BD5\u8D70\u8FDB\u95E8\u91CC\uFF0C\u53D1\u73B0\u65B0\u7684\u623F\u95F4\uFF01",
    "\u4F60\u5B66\u4F1A\u7684\u6BCF\u4E2A\u8BCD\uFF0C\u90FD\u662F\u5927\u5192\u9669\u7684\u4E00\u6B65\u3002",
    "\u63A2\u7D22\u8D8A\u591A\uFF0C\u53D1\u73B0\u8D8A\u591A\uFF01",
    "\u5C0F\u79D8\u5BC6\uFF1A\u6709\u4E9B\u8DEF\u901A\u5411\u9690\u85CF\u5B9D\u85CF...",
    "\u4F60\u77E5\u9053\u5417\uFF1F\u8FD9\u5F20\u5730\u56FE\u6BCF\u6B21\u52A0\u8F7D\u90FD\u4F1A\u53D8\u5316\uFF01",
    "\u8BED\u8A00\u4F1A\u6253\u5F00\u901A\u5F80\u65B0\u4E16\u754C\u7684\u5927\u95E8\u3002\u771F\u7684\uFF01",
    "\u7EE7\u7EED\u63A2\u7D22\uFF0C\u603B\u6709\u65B0\u4E1C\u897F\u7B49\u7740\u4F60\u3002"
  ];
  CHEST_MESSAGES.zh = [
    "\u4F60\u627E\u5230\u4E86\u9690\u85CF\u5B9D\u85CF\uFF01\u539F\u6765\u662F\u77E5\u8BC6\uFF01",
    "\u91CC\u9762\u6709\u5F20\u7EB8\u5199\u7740\uFF1A\u201C\u7EC3\u4E60\u771F\u7684\u6709\u7528\u3002\u201D",
    "\u4F60\u53D1\u73B0\u4E86\u53D1\u5149\u7B26\u6587\uFF0C\u4E0A\u9762\u5199\u7740\u201CXP +100\u201D\uFF08\u5F00\u73A9\u7B11\u7684\uFF09\u3002",
    "\u91CC\u9762\u6709\u4E00\u5F20\u5C0F\u5730\u56FE\uFF0C\u6807\u7740\u4F60\u5C06\u8BBF\u95EE\u7684\u6240\u6709\u4E16\u754C\uFF01",
    "\u4E00\u679A\u91D1\u5E01\uFF01\u7B49\u7B49...\u5176\u5B9E\u662F\u8BCD\u6C47\u4EE3\u5E01\u3002",
    "\u4F60\u627E\u5230\u4E86\u4E00\u5377\u53E4\u8001\u8BED\u6CD5\u5377\u8F74\uFF01",
    "\u7BB1\u5B50\u91CC\u88C5\u7740...\u52A8\u529B\uFF01+10 \u610F\u5FD7\u529B\u3002",
    "\u91CC\u9762\u6709\u5F20\u7EB8\u6761\uFF1A\u201C\u4F60\u505A\u5F97\u5F88\u68D2\uFF01\u201D"
  ];
  LAMP_MESSAGES.zh = [
    "\u706F\u67D4\u548C\u5730\u4EAE\u7740\u3002\u8FD9\u91CC\u5F88\u6E29\u6696\u3002",
    "\u67D4\u5149\u7167\u4EAE\u4E86\u53E4\u8001\u6587\u5B57...\u4F46\u770B\u4E0D\u6E05\u3002",
    "\u706F\u5149\u50CF\u5C0F\u706B\u82B1\u4E00\u6837\u8DF3\u52A8\u3002",
    "\u4F60\u611F\u5230\u4E00\u9635\u6E29\u6696\u548C\u9F13\u52B1\u3002"
  ];
  PLANT_MESSAGES.zh = [
    "\u4E00\u682A\u5FEB\u4E50\u7684\u5C0F\u690D\u7269\u3002\u5B83\u4F3C\u4E4E\u5F88\u559C\u6B22\u8FD9\u91CC\u3002",
    "\u4F60\u8D70\u8FC7\u65F6\uFF0C\u53F6\u5B50\u8F7B\u8F7B\u6446\u52A8\u3002",
    "\u8FD9\u682A\u690D\u7269\u5DF2\u7ECF\u5728\u8FD9\u91CC\u5F88\u4E45\u5F88\u4E45\u4E86\u3002",
    "\u4E00\u6735\u5C0F\u82B1\u6B63\u5728\u5F00\u653E\u3002\u771F\u6F02\u4EAE\uFF01"
  ];
  TABLE_MESSAGES.zh = [
    "\u4E00\u5F20\u7ED3\u5B9E\u7684\u6728\u684C\u3002\u6709\u4EBA\u7559\u4E0B\u4E86\u52A8\u8BCD\u53D8\u4F4D\u7B14\u8BB0\u3002",
    "\u684C\u9762\u4E0A\u7559\u4E0B\u4E86\u591A\u5E74\u5B66\u4E60\u65F6\u5149\u7684\u75D5\u8FF9\u3002",
    "\u4E66\u672C\u548C\u7EB8\u5F20\u6563\u843D\u5728\u684C\u9762\u4E0A\u3002",
    "\u684C\u4E0A\u8FD8\u6709\u4E00\u4E2A\u6CA1\u5B8C\u6210\u7684\u8C1C\u9898\u3002"
  ];
  var MAP_W = 18;
  var MAP_H = 12;
  var INDOOR_W = 18;
  var INDOOR_H_MIN = 8;
  var INDOOR_H_MAX = 10;
  function generateOutdoor(rng) {
    const map = Array.from({ length: MAP_H }, () => Array(MAP_W).fill(GRASS));
    for (let x = 0; x < MAP_W; x++) {
      map[0][x] = TREE;
      map[MAP_H - 1][x] = TREE;
    }
    for (let y = 0; y < MAP_H; y++) {
      map[y][0] = TREE;
      map[y][MAP_W - 1] = TREE;
    }
    const pathX = 4 + Math.floor(rng() * (MAP_W - 8));
    for (let y = 1; y < MAP_H - 1; y++) map[y][pathX] = PATH;
    const pathY = 3 + Math.floor(rng() * (MAP_H - 6));
    for (let x = 1; x < MAP_W - 1; x++) map[pathY][x] = PATH;
    const pathY2 = pathY + 2 + Math.floor(rng() * 3);
    if (pathY2 < MAP_H - 1) {
      for (let x = 1; x < MAP_W - 1; x++) map[pathY2][x] = PATH;
    }
    const pondW = 2 + Math.floor(rng() * 3);
    const pondH = 2;
    const pondX = 2 + Math.floor(rng() * (MAP_W - pondW - 4));
    const pondY = 2 + Math.floor(rng() * (MAP_H - pondH - 4));
    for (let py = pondY; py < pondY + pondH; py++) {
      for (let px = pondX; px < pondX + pondW; px++) {
        if (map[py][px] === GRASS) map[py][px] = WATER;
      }
    }
    for (let y = 0; y < MAP_H; y++) {
      for (let x = 0; x < MAP_W; x++) {
        if (map[y][x] === WATER) {
          if (x > 0 && map[y][x - 1] === PATH || x < MAP_W - 1 && map[y][x + 1] === PATH || y > 0 && map[y - 1][x] === PATH || y < MAP_H - 1 && map[y + 1][x] === PATH) {
            map[y][x] = BRIDGE;
          }
        }
      }
    }
    const grassTiles = [];
    for (let y = 1; y < MAP_H - 1; y++) {
      for (let x = 1; x < MAP_W - 1; x++) {
        if (map[y][x] === GRASS) grassTiles.push([x, y]);
      }
    }
    const shuffled = shuffle(rng, grassTiles);
    let idx = 0;
    const numTrees = 3 + Math.floor(rng() * 4);
    for (let i = 0; i < numTrees && idx < shuffled.length; i++, idx++) {
      map[shuffled[idx][1]][shuffled[idx][0]] = TREE;
    }
    const numRocks = 2 + Math.floor(rng() * 3);
    for (let i = 0; i < numRocks && idx < shuffled.length; i++, idx++) {
      map[shuffled[idx][1]][shuffled[idx][0]] = ROCK;
    }
    const numFlowers = 3 + Math.floor(rng() * 4);
    for (let i = 0; i < numFlowers && idx < shuffled.length; i++, idx++) {
      map[shuffled[idx][1]][shuffled[idx][0]] = FLOWER;
    }
    const numLamps = 1 + Math.floor(rng() * 3);
    for (let i = 0; i < numLamps && idx < shuffled.length; i++, idx++) {
      map[shuffled[idx][1]][shuffled[idx][0]] = LAMP;
    }
    const numSigns = 2 + Math.floor(rng() * 2);
    for (let i = 0; i < numSigns && idx < shuffled.length; i++, idx++) {
      map[shuffled[idx][1]][shuffled[idx][0]] = SIGN;
    }
    const numChests = 1 + Math.floor(rng() * 2);
    for (let i = 0; i < numChests && idx < shuffled.length; i++, idx++) {
      map[shuffled[idx][1]][shuffled[idx][0]] = CHEST;
    }
    const doorCandidates = shuffled.slice(idx).filter(([x, y]) => {
      if (map[y][x] !== GRASS) return false;
      return x > 0 && map[y][x - 1] === PATH || x < MAP_W - 1 && map[y][x + 1] === PATH || y > 0 && map[y - 1][x] === PATH || y < MAP_H - 1 && map[y + 1][x] === PATH;
    });
    const doorPositions = doorCandidates.slice(0, 2);
    for (const [dx, dy] of doorPositions) {
      map[dy][dx] = DOOR;
    }
    let startX = Math.floor(MAP_W / 2);
    let startY = Math.floor(MAP_H / 2);
    for (let r = 0; r < 5; r++) {
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          const sx = startX + dx;
          const sy = startY + dy;
          if (sx > 0 && sx < MAP_W - 1 && sy > 0 && sy < MAP_H - 1) {
            const tile = map[sy][sx];
            if (!SOLID_TILES.has(tile) && !INTERACT_TILES.has(tile) && tile !== WATER && tile !== DOOR) {
              startX = sx;
              startY = sy;
              r = 99;
              dy = 99;
              break;
            }
          }
        }
      }
    }
    return { map, startX, startY, doorPositions };
  }
  function generateIndoor(rng, roomType) {
    const h = INDOOR_H_MIN + Math.floor(rng() * (INDOOR_H_MAX - INDOOR_H_MIN + 1));
    const w = INDOOR_W;
    const map = Array.from({ length: h }, () => Array(w).fill(FLOOR));
    for (let x = 0; x < w; x++) {
      map[0][x] = WALL_TOP;
      map[h - 1][x] = WALL_TOP;
    }
    for (let y = 0; y < h; y++) {
      map[y][0] = WALL_TOP;
      map[y][w - 1] = WALL_TOP;
    }
    const topSlots = [];
    for (let x = 1; x < w - 1; x++) topSlots.push(x);
    const shuffledTop = shuffle(rng, topSlots);
    const wallItems = shuffle(rng, roomType.wallFurniture);
    const numWindows = 2 + Math.floor(rng() * 3);
    for (let i = 0; i < numWindows && i < shuffledTop.length; i++) {
      map[1][shuffledTop[i]] = WINDOW_TILE;
    }
    let wallIdx = numWindows;
    const numWallFurn = 3 + Math.floor(rng() * 3);
    for (let i = 0; i < numWallFurn && wallIdx < shuffledTop.length; i++, wallIdx++) {
      if (map[1][shuffledTop[wallIdx]] === FLOOR) {
        map[1][shuffledTop[wallIdx]] = pick(rng, wallItems);
      }
    }
    if (roomType.hasRug && rng() > 0.3) {
      const rugX = 3 + Math.floor(rng() * (w - 8));
      const rugY = 3 + Math.floor(rng() * (h - 6));
      const rugW = 2 + Math.floor(rng() * 3);
      const rugH = 2 + Math.floor(rng() * 2);
      for (let ry = rugY; ry < Math.min(rugY + rugH, h - 2); ry++) {
        for (let rx = rugX; rx < Math.min(rugX + rugW, w - 2); rx++) {
          if (map[ry][rx] === FLOOR) map[ry][rx] = RUG;
        }
      }
    }
    const interiorTiles = [];
    for (let y = 2; y < h - 2; y++) {
      for (let x = 2; x < w - 2; x++) {
        if (map[y][x] === FLOOR || map[y][x] === RUG) interiorTiles.push([x, y]);
      }
    }
    const shuffledInterior = shuffle(rng, interiorTiles);
    const centerItems = shuffle(rng, roomType.centerFurniture);
    let iIdx = 0;
    const numTables = 1 + Math.floor(rng() * 2);
    for (let i = 0; i < numTables && iIdx < shuffledInterior.length; i++, iIdx++) {
      const [x, y] = shuffledInterior[iIdx];
      if (map[y][x] === FLOOR || map[y][x] === RUG) {
        map[y][x] = pick(rng, centerItems);
      }
    }
    const numPlants = 1 + Math.floor(rng() * 2);
    for (let i = 0; i < numPlants && iIdx < shuffledInterior.length; i++, iIdx++) {
      map[shuffledInterior[iIdx][1]][shuffledInterior[iIdx][0]] = PLANT_POT;
    }
    if (iIdx < shuffledInterior.length) {
      map[shuffledInterior[iIdx][1]][shuffledInterior[iIdx][0]] = SIGN;
      iIdx++;
    }
    if (iIdx < shuffledInterior.length) {
      map[shuffledInterior[iIdx][1]][shuffledInterior[iIdx][0]] = CHEST;
      iIdx++;
    }
    if (rng() > 0.4 && iIdx < shuffledInterior.length) {
      map[shuffledInterior[iIdx][1]][shuffledInterior[iIdx][0]] = LAMP;
      iIdx++;
    }
    const doorX = Math.floor(w / 2);
    const doorY = h - 2;
    map[doorY][doorX] = DOOR;
    if (doorY - 1 > 0 && SOLID_TILES.has(map[doorY - 1][doorX])) map[doorY - 1][doorX] = FLOOR;
    const startX = doorX;
    const startY = doorY - 1;
    return { map, startX, startY, doorX, doorY };
  }
  function generateWorld(seed) {
    const rng = createRng(seed);
    const palette = {
      grass: pick(rng, GRASS_PALETTES),
      water: pick(rng, WATER_PALETTES),
      path: pick(rng, PATH_PALETTES),
      leaves: pick(rng, LEAF_PALETTES),
      trunk: pick(rng, TRUNK_COLORS)
    };
    const outdoor = generateOutdoor(rng);
    const outdoorName = {
      en: pick(rng, OUTDOOR_NAMES.en),
      es: pick(rng, OUTDOOR_NAMES.es),
      pt: pick(rng, OUTDOOR_NAMES.pt),
      it: pick(rng, OUTDOOR_NAMES.it),
      fr: pick(rng, OUTDOOR_NAMES.fr),
      de: pick(rng, OUTDOOR_NAMES.de),
      ja: pick(rng, OUTDOOR_NAMES.ja),
      hi: pick(rng, OUTDOOR_NAMES.hi),
      ar: pick(rng, OUTDOOR_NAMES.ar),
      zh: pick(rng, OUTDOOR_NAMES.zh)
    };
    const roomTypePool = shuffle(rng, INDOOR_ROOM_TYPES);
    const roomType1 = roomTypePool[0];
    const roomType2 = roomTypePool[1];
    const indoor1 = generateIndoor(rng, roomType1);
    const indoor1Name = {
      en: pick(rng, roomType1.names.en),
      es: pick(rng, roomType1.names.es),
      pt: pick(rng, roomType1.names.pt),
      it: pick(rng, roomType1.names.it),
      fr: pick(rng, roomType1.names.fr),
      de: pick(rng, roomType1.names.de),
      ja: pick(rng, roomType1.names.ja),
      hi: pick(rng, roomType1.names.hi),
      ar: pick(rng, roomType1.names.ar),
      zh: pick(rng, roomType1.names.zh)
    };
    const indoor2 = generateIndoor(rng, roomType2);
    const indoor2Name = {
      en: pick(rng, roomType2.names.en),
      es: pick(rng, roomType2.names.es),
      pt: pick(rng, roomType2.names.pt),
      it: pick(rng, roomType2.names.it),
      fr: pick(rng, roomType2.names.fr),
      de: pick(rng, roomType2.names.de),
      ja: pick(rng, roomType2.names.ja),
      hi: pick(rng, roomType2.names.hi),
      ar: pick(rng, roomType2.names.ar),
      zh: pick(rng, roomType2.names.zh)
    };
    const rooms = {
      outdoor: {
        name: outdoorName,
        map: outdoor.map,
        startX: outdoor.startX,
        startY: outdoor.startY,
        doors: []
      },
      room1: {
        name: indoor1Name,
        map: indoor1.map,
        startX: indoor1.startX,
        startY: indoor1.startY,
        doors: [
          { x: indoor1.doorX, y: indoor1.doorY, target: "outdoor", tx: 0, ty: 0 }
        ]
      },
      room2: {
        name: indoor2Name,
        map: indoor2.map,
        startX: indoor2.startX,
        startY: indoor2.startY,
        doors: [
          { x: indoor2.doorX, y: indoor2.doorY, target: "outdoor", tx: 0, ty: 0 }
        ]
      }
    };
    if (outdoor.doorPositions.length >= 1) {
      const [dx1, dy1] = outdoor.doorPositions[0];
      rooms.outdoor.doors.push({ x: dx1, y: dy1, target: "room1", tx: indoor1.startX, ty: indoor1.startY });
      rooms.room1.doors[0].tx = dx1;
      rooms.room1.doors[0].ty = Math.max(1, dy1 - 1);
    }
    if (outdoor.doorPositions.length >= 2) {
      const [dx2, dy2] = outdoor.doorPositions[1];
      rooms.outdoor.doors.push({ x: dx2, y: dy2, target: "room2", tx: indoor2.startX, ty: indoor2.startY });
      rooms.room2.doors[0].tx = dx2;
      rooms.room2.doors[0].ty = Math.max(1, dy2 - 1);
    }
    const messages = {};
    for (const [tile, msgs] of Object.entries(ALL_MESSAGES)) {
      messages[tile] = SUPPORT_LANGUAGE_CODES2.reduce((acc, lang) => {
        acc[lang] = shuffle(rng, msgs[lang] || msgs.en);
        return acc;
      }, {});
    }
    return { rooms, palette, messages };
  }
  function seededRng(x, y) {
    let h = x * 374761393 + y * 668265263 + 1013904223 | 0;
    h = (h ^ h >>> 13) * 1274126177 | 0;
    return ((h ^ h >>> 16) >>> 0) / 4294967296;
  }
  function drawGrass(ctx, x, y, palette) {
    const c = palette.grass;
    ctx.fillStyle = c[Math.floor(seededRng(x, y) * c.length)];
    ctx.fillRect(x * T2, y * T2, T2, T2);
    const rng = seededRng(x + 100, y + 100);
    if (rng > 0.5) {
      ctx.fillStyle = c[2] || c[0];
      ctx.globalAlpha = 0.6;
      ctx.fillRect(x * T2 + 6 + seededRng(x + 30, y) * (T2 - 12), y * T2 + 8 + seededRng(x, y + 30) * (T2 - 16), 3, 8);
      ctx.fillRect(x * T2 + 20 + seededRng(x + 40, y) * 8, y * T2 + 4 + seededRng(x, y + 40) * 8, 3, 8);
      ctx.globalAlpha = 1;
    }
  }
  function drawPath(ctx, x, y, palette) {
    const c = palette.path;
    ctx.fillStyle = c[Math.floor(seededRng(x, y) * c.length)];
    ctx.fillRect(x * T2, y * T2, T2, T2);
    if (seededRng(x + 50, y + 50) > 0.4) {
      ctx.fillStyle = c[0];
      ctx.globalAlpha = 0.5;
      ctx.fillRect(x * T2 + 12, y * T2 + 20, 6, 4);
      ctx.globalAlpha = 1;
    }
  }
  function drawWater(ctx, x, y, frame, palette) {
    ctx.fillStyle = palette.water.base;
    ctx.fillRect(x * T2, y * T2, T2, T2);
    const off = (frame * 0.025 + x * 0.5) % 1 * T2;
    ctx.fillStyle = palette.water.highlight;
    ctx.globalAlpha = 0.35;
    ctx.fillRect(x * T2 + off, y * T2 + 10, 12, 3);
    ctx.fillRect(x * T2 + (off + 20) % T2, y * T2 + 28, 10, 3);
    ctx.globalAlpha = 1;
  }
  function drawTree(ctx, x, y, palette) {
    drawGrass(ctx, x, y, palette);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 3;
    ctx.fillStyle = palette.trunk;
    ctx.fillRect(cx - 4, by - 24, 8, 18);
    const lc = palette.leaves;
    ctx.fillStyle = lc[0];
    ctx.beginPath();
    ctx.arc(cx, by - 30, 16, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = lc[1];
    ctx.beginPath();
    ctx.arc(cx - 6, by - 27, 10, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = lc[2];
    ctx.beginPath();
    ctx.arc(cx + 7, by - 26, 9, 0, Math.PI * 2);
    ctx.fill();
  }
  function drawFlower(ctx, x, y, palette) {
    drawGrass(ctx, x, y, palette);
    const flowerColors = ["#e85d9a", "#f0c040", "#ff6b6b", "#a06ef0", "#ff9050", "#60c0f0"];
    const count = seededRng(x + 200, y + 200) > 0.5 ? 3 : 2;
    for (let i = 0; i < count; i++) {
      const fx = x * T2 + 6 + seededRng(x + i * 13, y) * (T2 - 12);
      const fy = y * T2 + 6 + seededRng(x, y + i * 17) * (T2 - 12);
      const fc = flowerColors[Math.floor(seededRng(x + i, y + i) * flowerColors.length)];
      ctx.fillStyle = palette.grass[0];
      ctx.fillRect(fx, fy, 3, 9);
      ctx.fillStyle = fc;
      ctx.fillRect(fx - 3, fy - 3, 9, 6);
      ctx.fillRect(fx, fy - 6, 3, 3);
    }
  }
  function drawSign(ctx, x, y, palette, isIndoor) {
    if (isIndoor) drawFloor(ctx, x, y);
    else drawGrass(ctx, x, y, palette);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 3;
    ctx.fillStyle = "#6b4e1f";
    ctx.fillRect(cx - 3, by - 30, 6, 27);
    ctx.fillStyle = "#8b6914";
    ctx.fillRect(cx - 15, by - 38, 30, 14);
    ctx.fillStyle = "#a07a20";
    ctx.fillRect(cx - 13, by - 36, 26, 10);
    ctx.fillStyle = "#fff";
    ctx.fillRect(cx - 2, by - 35, 3, 6);
    ctx.fillRect(cx - 2, by - 28, 3, 2);
  }
  function drawChest(ctx, x, y, palette, isIndoor) {
    if (isIndoor) drawFloor(ctx, x, y);
    else drawGrass(ctx, x, y, palette);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 6;
    ctx.fillStyle = "#b8860b";
    ctx.fillRect(cx - 12, by - 16, 24, 14);
    ctx.fillStyle = "#c89620";
    ctx.fillRect(cx - 13, by - 22, 26, 8);
    ctx.fillStyle = "#ffd700";
    ctx.fillRect(cx - 3, by - 16, 6, 4);
    ctx.fillStyle = "#00000020";
    ctx.fillRect(cx - 12, by - 2, 24, 3);
  }
  function drawRock(ctx, x, y, palette) {
    drawGrass(ctx, x, y, palette);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 6;
    ctx.fillStyle = "#7a7a7a";
    ctx.beginPath();
    ctx.ellipse(cx, by - 8, 14, 10, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#8a8a8a";
    ctx.beginPath();
    ctx.ellipse(cx - 3, by - 11, 8, 6, -0.3, 0, Math.PI * 2);
    ctx.fill();
  }
  function drawBridge(ctx, x, y, palette) {
    ctx.fillStyle = palette.water.base;
    ctx.fillRect(x * T2, y * T2, T2, T2);
    ctx.fillStyle = "#8b6d4a";
    ctx.fillRect(x * T2 + 3, y * T2, T2 - 6, T2);
    ctx.fillStyle = "#9c7e5a";
    for (let i = 0; i < T2; i += 12) ctx.fillRect(x * T2 + 3, y * T2 + i, T2 - 6, 1);
    ctx.fillStyle = palette.trunk;
    ctx.fillRect(x * T2 + 1, y * T2, 3, T2);
    ctx.fillRect(x * T2 + T2 - 4, y * T2, 3, T2);
  }
  function drawLamp(ctx, x, y, frame, palette, isIndoor) {
    if (isIndoor) drawFloor(ctx, x, y);
    else drawGrass(ctx, x, y, palette);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 3;
    ctx.fillStyle = "#4a4a4a";
    ctx.fillRect(cx - 3, by - 36, 6, 33);
    ctx.fillStyle = "#3a3a3a";
    ctx.fillRect(cx - 7, by - 40, 14, 7);
    const ga = 0.25 + Math.sin(frame * 0.05) * 0.1;
    ctx.fillStyle = `rgba(255, 220, 100, ${ga})`;
    ctx.beginPath();
    ctx.arc(cx, by - 36, 18, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#ffe066";
    ctx.fillRect(cx - 4, by - 39, 8, 4);
  }
  function drawDoor(ctx, x, y, frame, palette, isIndoor) {
    if (isIndoor) {
      drawFloor(ctx, x, y);
      const cx = x * T2 + T2 / 2;
      const by = y * T2 + T2;
      ctx.fillStyle = "#8b5a2b";
      ctx.fillRect(cx - 14, by - 6, 28, 6);
      const ga = 0.25 + Math.sin(frame * 0.06) * 0.15;
      ctx.fillStyle = `rgba(100, 200, 255, ${ga})`;
      ctx.fillRect(cx - 12, by - 5, 24, 4);
      ctx.fillStyle = `rgba(255, 255, 255, ${0.5 + Math.sin(frame * 0.08) * 0.3})`;
      ctx.font = `bold ${Math.round(T2 * 0.4)}px monospace`;
      ctx.textAlign = "center";
      ctx.fillText("\u2193", cx, by - 10);
    } else {
      drawGrass(ctx, x, y, palette);
      const cx = x * T2 + T2 / 2;
      const by = y * T2 + T2 - 3;
      ctx.fillStyle = "#6b4226";
      ctx.fillRect(cx - 14, by - 36, 28, 36);
      ctx.fillStyle = "#8b5a2b";
      ctx.fillRect(cx - 11, by - 33, 22, 33);
      ctx.fillStyle = "#7a4a20";
      ctx.fillRect(cx - 8, by - 30, 7, 10);
      ctx.fillRect(cx + 1, by - 30, 7, 10);
      ctx.fillRect(cx - 8, by - 16, 7, 10);
      ctx.fillRect(cx + 1, by - 16, 7, 10);
      ctx.fillStyle = "#daa520";
      ctx.fillRect(cx + 6, by - 18, 3, 3);
      const ga = 0.3 + Math.sin(frame * 0.06) * 0.15;
      ctx.fillStyle = `rgba(255, 220, 100, ${ga})`;
      ctx.fillRect(cx - 11, by - 1, 22, 2);
    }
  }
  function drawFloor(ctx, x, y) {
    const floors = ["#b89a72", "#a88a62", "#c8aa82"];
    ctx.fillStyle = floors[Math.floor(seededRng(x, y) * floors.length)];
    ctx.fillRect(x * T2, y * T2, T2, T2);
    ctx.fillStyle = "#a08050";
    ctx.globalAlpha = 0.2;
    for (let i = 0; i < T2; i += 8) ctx.fillRect(x * T2, y * T2 + i, T2, 1);
    ctx.globalAlpha = 1;
  }
  function drawWallTop(ctx, x, y) {
    ctx.fillStyle = "#5a4a3a";
    ctx.fillRect(x * T2, y * T2, T2, T2);
    ctx.fillStyle = "#4a3a2a";
    ctx.fillRect(x * T2, y * T2 + T2 - 3, T2, 3);
    ctx.fillStyle = "#6a5a4a";
    ctx.globalAlpha = 0.3;
    const off = y % 2 * (T2 / 2);
    for (let bx = 0; bx < T2; bx += T2 / 2) ctx.fillRect(x * T2 + bx + off, y * T2, 1, T2);
    ctx.globalAlpha = 1;
  }
  function drawBookshelf(ctx, x, y) {
    drawWallTop(ctx, x, y);
    const bx = x * T2 + 4;
    const by = y * T2 + 4;
    const bw = T2 - 8;
    const bh = T2 - 6;
    ctx.fillStyle = "#6b4226";
    ctx.fillRect(bx, by, bw, bh);
    ctx.fillStyle = "#8b5a2b";
    ctx.fillRect(bx + 2, by + 2, bw - 4, bh - 4);
    ctx.fillStyle = "#6b4226";
    const shelfH = Math.floor(bh / 3);
    for (let i = 1; i < 3; i++) ctx.fillRect(bx + 2, by + shelfH * i, bw - 4, 2);
    const bookColors = ["#c0392b", "#2980b9", "#27ae60", "#8e44ad", "#f39c12", "#e74c3c"];
    for (let s = 0; s < 3; s++) {
      const sy = by + shelfH * s + 4;
      let bkx = bx + 4;
      for (let b = 0; b < 5; b++) {
        const w = 3 + seededRng(x + b, y + s) * 4;
        ctx.fillStyle = bookColors[Math.floor(seededRng(x * 7 + b, y * 3 + s) * bookColors.length)];
        ctx.fillRect(bkx, sy, w, shelfH - 6);
        bkx += w + 1;
        if (bkx > bx + bw - 6) break;
      }
    }
  }
  function drawTable(ctx, x, y) {
    drawFloor(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 8;
    ctx.fillStyle = "#5a3a1a";
    ctx.fillRect(cx - 14, by + 2, 4, 6);
    ctx.fillRect(cx + 10, by + 2, 4, 6);
    ctx.fillStyle = "#8b6d4a";
    ctx.fillRect(cx - 16, by - 6, 32, 8);
    ctx.fillStyle = "#9c7e5a";
    ctx.fillRect(cx - 14, by - 5, 28, 6);
  }
  function drawRug(ctx, x, y) {
    drawFloor(ctx, x, y);
    ctx.fillStyle = "#8b2252";
    ctx.globalAlpha = 0.6;
    ctx.fillRect(x * T2 + 2, y * T2 + 2, T2 - 4, T2 - 4);
    ctx.fillStyle = "#cd5c5c";
    ctx.globalAlpha = 0.5;
    ctx.fillRect(x * T2 + 6, y * T2 + 6, T2 - 12, T2 - 12);
    ctx.globalAlpha = 1;
    ctx.fillStyle = "#daa520";
    ctx.globalAlpha = 0.4;
    ctx.fillRect(x * T2 + 4, y * T2 + 4, T2 - 8, 2);
    ctx.fillRect(x * T2 + 4, y * T2 + T2 - 6, T2 - 8, 2);
    ctx.fillRect(x * T2 + 4, y * T2 + 4, 2, T2 - 8);
    ctx.fillRect(x * T2 + T2 - 6, y * T2 + 4, 2, T2 - 8);
    ctx.globalAlpha = 1;
  }
  function drawFireplace(ctx, x, y, frame) {
    drawWallTop(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 2;
    ctx.fillStyle = "#6a6a6a";
    ctx.fillRect(cx - 16, by - 34, 32, 34);
    ctx.fillStyle = "#5a5a5a";
    ctx.fillRect(cx - 12, by - 30, 24, 26);
    ctx.fillStyle = "#1a1a1a";
    ctx.fillRect(cx - 10, by - 24, 20, 20);
    const fl = Math.sin(frame * 0.12) * 3;
    ctx.fillStyle = "#ff4500";
    ctx.beginPath();
    ctx.ellipse(cx, by - 14 + fl, 7, 10, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#ff8c00";
    ctx.beginPath();
    ctx.ellipse(cx - 2, by - 12 - fl, 4, 7, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#ffd700";
    ctx.beginPath();
    ctx.ellipse(cx + 1, by - 10, 3, 5, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  function drawSofa(ctx, x, y) {
    drawFloor(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 6;
    ctx.fillStyle = "#6a3030";
    ctx.fillRect(cx - 16, by - 18, 32, 8);
    ctx.fillStyle = "#8b4040";
    ctx.fillRect(cx - 16, by - 10, 32, 12);
    ctx.fillStyle = "#7a3535";
    ctx.fillRect(cx, by - 10, 2, 12);
    ctx.fillStyle = "#6a3030";
    ctx.fillRect(cx - 18, by - 14, 4, 16);
    ctx.fillRect(cx + 14, by - 14, 4, 16);
  }
  function drawBed(ctx, x, y) {
    drawFloor(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 4;
    ctx.fillStyle = "#5a3a1a";
    ctx.fillRect(cx - 16, by - 28, 32, 28);
    ctx.fillStyle = "#e8e0d0";
    ctx.fillRect(cx - 14, by - 26, 28, 22);
    ctx.fillStyle = "#f0f0f0";
    ctx.fillRect(cx - 10, by - 24, 20, 8);
    ctx.fillStyle = "#4a7abc";
    ctx.fillRect(cx - 14, by - 12, 28, 10);
  }
  function drawWindowTile(ctx, x, y) {
    drawWallTop(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const cy = y * T2 + T2 / 2;
    ctx.fillStyle = "#8b6d4a";
    ctx.fillRect(cx - 12, cy - 14, 24, 22);
    ctx.fillStyle = "#87ceeb";
    ctx.fillRect(cx - 10, cy - 12, 20, 18);
    ctx.fillStyle = "#8b6d4a";
    ctx.fillRect(cx - 1, cy - 12, 2, 18);
    ctx.fillRect(cx - 10, cy - 1, 20, 2);
  }
  function drawDesk(ctx, x, y) {
    drawFloor(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 6;
    ctx.fillStyle = "#4a3020";
    ctx.fillRect(cx - 14, by, 4, 6);
    ctx.fillRect(cx + 10, by, 4, 6);
    ctx.fillStyle = "#6b4226";
    ctx.fillRect(cx - 16, by - 8, 32, 8);
    ctx.fillStyle = "#7a522e";
    ctx.fillRect(cx - 14, by - 7, 28, 6);
    ctx.fillStyle = "#f0f0e0";
    ctx.fillRect(cx - 8, by - 12, 10, 6);
    ctx.fillStyle = "#333";
    ctx.fillRect(cx + 6, by - 10, 2, 6);
  }
  function drawPlantPot(ctx, x, y) {
    drawFloor(ctx, x, y);
    const cx = x * T2 + T2 / 2;
    const by = y * T2 + T2 - 6;
    ctx.fillStyle = "#b05030";
    ctx.fillRect(cx - 8, by - 10, 16, 12);
    ctx.fillStyle = "#c06040";
    ctx.fillRect(cx - 6, by - 8, 12, 8);
    ctx.fillStyle = "#b05030";
    ctx.fillRect(cx - 9, by - 12, 18, 4);
    ctx.fillStyle = "#3a8a44";
    ctx.beginPath();
    ctx.arc(cx, by - 20, 10, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#4a9c54";
    ctx.beginPath();
    ctx.arc(cx - 4, by - 22, 7, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(cx + 5, by - 18, 6, 0, Math.PI * 2);
    ctx.fill();
  }
  function drawTile(ctx, x, y, tile, frame, palette, isIndoor) {
    switch (tile) {
      case GRASS:
        return drawGrass(ctx, x, y, palette);
      case PATH:
        return drawPath(ctx, x, y, palette);
      case WATER:
        return drawWater(ctx, x, y, frame, palette);
      case TREE:
        return drawTree(ctx, x, y, palette);
      case FLOWER:
        return drawFlower(ctx, x, y, palette);
      case SIGN:
        return drawSign(ctx, x, y, palette, isIndoor);
      case CHEST:
        return drawChest(ctx, x, y, palette, isIndoor);
      case ROCK:
        return drawRock(ctx, x, y, palette);
      case BRIDGE:
        return drawBridge(ctx, x, y, palette);
      case LAMP:
        return drawLamp(ctx, x, y, frame, palette, isIndoor);
      case DOOR:
        return drawDoor(ctx, x, y, frame, palette, isIndoor);
      case FLOOR:
        return drawFloor(ctx, x, y);
      case WALL_TOP:
        return drawWallTop(ctx, x, y);
      case BOOKSHELF:
        return drawBookshelf(ctx, x, y);
      case TABLE:
        return drawTable(ctx, x, y);
      case RUG:
        return drawRug(ctx, x, y);
      case FIREPLACE:
        return drawFireplace(ctx, x, y, frame);
      case SOFA:
        return drawSofa(ctx, x, y);
      case BED:
        return drawBed(ctx, x, y);
      case WINDOW_TILE:
        return drawWindowTile(ctx, x, y);
      case DESK:
        return drawDesk(ctx, x, y);
      case PLANT_POT:
        return drawPlantPot(ctx, x, y);
      default:
        return drawGrass(ctx, x, y, palette);
    }
  }
  function drawInteractHint(ctx, tileX, tileY, frame) {
    const cx = tileX * T2 + T2 / 2;
    const cy = tileY * T2 - 6;
    const bounce = Math.sin(frame * 0.08) * 4;
    ctx.save();
    ctx.globalAlpha = 0.6 + Math.sin(frame * 0.1) * 0.3;
    ctx.fillStyle = "#ffd700";
    ctx.font = `bold ${Math.round(T2 * 0.45)}px monospace`;
    ctx.textAlign = "center";
    ctx.fillText("!", cx, cy + bounce);
    ctx.restore();
  }
  function drawTransition(ctx, w, h, progress) {
    ctx.fillStyle = "#000";
    ctx.globalAlpha = progress < 0.5 ? progress * 2 : 2 - progress * 2;
    ctx.fillRect(0, 0, w, h);
    ctx.globalAlpha = 1;
  }
  var record = function recorder() {
    const ops = [], stack = [];
    let fillStyle = "#000", globalAlpha = 1, font = "10px sans-serif", textAlign = "start", shape = [];
    const ctx = { ops, clearRect() {
    }, save() {
      stack.push({ fillStyle, globalAlpha, font, textAlign });
      ops.push(["save"]);
    }, restore() {
      Object.assign(ctx, stack.pop());
      ops.push(["restore"]);
    }, translate(x, y) {
      ops.push(["translate", x, y]);
    }, scale(x, y) {
      ops.push(["scale", x, y]);
    }, fillRect(x, y, w, h) {
      ops.push(["rect", x, y, w, h, fillStyle, globalAlpha]);
    }, beginPath() {
      shape = [];
    }, arc(...args) {
      shape.push(["arc", ...args]);
    }, ellipse(...args) {
      shape.push(["ellipse", ...args]);
    }, fill() {
      ops.push(["path", shape, fillStyle, globalAlpha]);
    }, fillText(text, x, y) {
      ops.push(["text", text, x, y, font, textAlign, fillStyle, globalAlpha]);
    } };
    for (const key of ["fillStyle", "globalAlpha", "font", "textAlign"]) Object.defineProperty(ctx, key, { get() {
      return key === "fillStyle" ? fillStyle : key === "globalAlpha" ? globalAlpha : key === "font" ? font : textAlign;
    }, set(v) {
      if (key === "fillStyle") fillStyle = v;
      else if (key === "globalAlpha") globalAlpha = v;
      else if (key === "font") font = v;
      else textAlign = v;
    } });
    return ctx;
  };
  var GAME_LOADER_EXPLORATION_MIN_MS = 5e3;
  var GAME_LOADER_EXPLORATION_MAX_MS = 8e3;
  function getGameLoaderExplorationDelay(randomValue = Math.random()) {
    const normalized = Math.min(1, Math.max(0, Number(randomValue) || 0));
    return Math.floor(
      GAME_LOADER_EXPLORATION_MIN_MS + normalized * (GAME_LOADER_EXPLORATION_MAX_MS - GAME_LOADER_EXPLORATION_MIN_MS)
    );
  }
  function makeEngine(p) {
    let now = p.now ?? 1e6, nextTimer = 0, message = null, roomName = null, objects = /* @__PURE__ */ new Set(), sounds = [], timers = /* @__PURE__ */ new Map();
    const Date = { now: () => now }, setTimeout = (f, ms) => {
      const id = ++nextTimer;
      timers.set(id, { f, due: now + ms });
      return id;
    }, clearTimeout = (id) => timers.delete(id);
    const supportLang = p.support || "en", world = generateWorld(p.seed), stateRef = { current: {
      px: world.rooms.outdoor.startX,
      py: world.rooms.outdoor.startY,
      dir: "down",
      frame: 0,
      walkFrame: 0,
      lastMove: 0,
      keysDown: /* @__PURE__ */ new Set(),
      touchStart: null,
      currentRoom: "outdoor",
      msgIdx: {},
      transitioning: false,
      transitionProgress: 0,
      transitionTarget: null,
      moving: false
    } }, messageTimeoutRef = { current: null }, roomNameTimeoutRef = { current: null }, petTypeRef = { current: p.pet || "ghost" };
    const setMessage = (v) => message = v, setRoomName = (v) => roomName = v, setObjectsFound = (f) => objects = f(objects), playGameSound = (name) => sounds.push(name);
    let width = 402, height = 874, ctx;
    const containerRef = { current: { getBoundingClientRect: () => ({ width, height }) } }, canvas = { width, height, getBoundingClientRect: () => ({ left: 0, top: 0, width, height }) }, canvasRef = { current: canvas };
    const showMessage = (text) => {
      setMessage(text);
      if (messageTimeoutRef.current) clearTimeout(messageTimeoutRef.current);
      messageTimeoutRef.current = setTimeout(() => setMessage(null), 4e3);
    };
    const showRoomName = (name) => {
      setRoomName(name);
      if (roomNameTimeoutRef.current) clearTimeout(roomNameTimeoutRef.current);
      roomNameTimeoutRef.current = setTimeout(() => setRoomName(null), 2e3);
    };
    const handleInteract = (tileX, tileY) => {
      const s = stateRef.current;
      const room = world.rooms[s.currentRoom];
      const tile = room.map[tileY]?.[tileX];
      if (!tile || !world.messages[tile]) return;
      const lang = normalizeSupportLanguage(supportLang, DEFAULT_SUPPORT_LANGUAGE);
      const msgs = world.messages[tile][lang] || world.messages[tile].en || [];
      const key = `${s.currentRoom}:${tileX},${tileY}`;
      const idxKey = `${tile}`;
      if (!s.msgIdx[idxKey]) s.msgIdx[idxKey] = 0;
      showMessage(msgs[s.msgIdx[idxKey] % msgs.length]);
      s.msgIdx[idxKey]++;
      setObjectsFound((prev) => new Set(prev).add(key));
      playGameSound("rpgDialogueOpen");
    };
    const tryInteract = () => {
      const s = stateRef.current;
      if (s.transitioning) return;
      const dx = { left: -1, right: 1, up: 0, down: 0 }[s.dir];
      const dy = { left: 0, right: 0, up: -1, down: 1 }[s.dir];
      const tx = s.px + dx;
      const ty = s.py + dy;
      const room = world.rooms[s.currentRoom];
      if (tx >= 0 && tx < room.map[0].length && ty >= 0 && ty < room.map.length && INTERACT_TILES.has(room.map[ty][tx])) {
        handleInteract(tx, ty);
      }
    };
    const enterDoor = (door) => {
      const s = stateRef.current;
      if (s.transitioning) return;
      s.transitioning = true;
      s.transitionProgress = 0;
      s.transitionTarget = door;
      playGameSound("rpgDialogueSelect");
    };
    const tryMove = (dir) => {
      const now2 = Date.now();
      const s = stateRef.current;
      s.dir = dir;
      if (s.transitioning) return false;
      if (now2 - s.lastMove < MOVE_COOLDOWN) return false;
      const room = world.rooms[s.currentRoom];
      const mapW = room.map[0].length;
      const mapH = room.map.length;
      const dx = { left: -1, right: 1, up: 0, down: 0 }[dir];
      const dy = { left: 0, right: 0, up: -1, down: 1 }[dir];
      const nx = s.px + dx;
      const ny = s.py + dy;
      if (nx < 0 || nx >= mapW || ny < 0 || ny >= mapH) return false;
      const targetTile = room.map[ny][nx];
      if (targetTile === DOOR) {
        const door = room.doors.find((d) => d.x === nx && d.y === ny);
        if (door) {
          enterDoor(door);
          s.lastMove = now2;
          return true;
        }
      }
      if (SOLID_TILES.has(targetTile) || INTERACT_TILES.has(targetTile)) {
        return false;
      }
      s.px = nx;
      s.py = ny;
      s.lastMove = now2;
      s.walkFrame++;
      s.moving = true;
      playGameSound("rpgStep");
      return true;
    };
    const faceTowardTile = (tileX, tileY) => {
      const s = stateRef.current;
      const diffX = tileX - s.px;
      const diffY = tileY - s.py;
      if (Math.abs(diffX) > Math.abs(diffY)) {
        s.dir = diffX > 0 ? "right" : "left";
      } else if (diffY !== 0) {
        s.dir = diffY > 0 ? "down" : "up";
      }
    };
    const moveOneStepToward = (tileX, tileY) => {
      const s = stateRef.current;
      const diffX = tileX - s.px;
      const diffY = tileY - s.py;
      if (diffX === 0 && diffY === 0) return false;
      const primaryDir = Math.abs(diffX) >= Math.abs(diffY) ? diffX > 0 ? "right" : "left" : diffY > 0 ? "down" : "up";
      const secondaryDir = Math.abs(diffX) >= Math.abs(diffY) ? diffY === 0 ? null : diffY > 0 ? "down" : "up" : diffX === 0 ? null : diffX > 0 ? "right" : "left";
      if (tryMove(primaryDir)) return true;
      if (secondaryDir) return tryMove(secondaryDir);
      return false;
    };
    const resolveTileAtClientPoint = (clientX, clientY) => {
      const canvas2 = canvasRef.current;
      if (!canvas2) return null;
      const s = stateRef.current;
      const room = world.rooms[s.currentRoom];
      const rect = canvas2.getBoundingClientRect();
      const pixelX = (clientX - rect.left) * (canvas2.width / rect.width);
      const pixelY = (clientY - rect.top) * (canvas2.height / rect.height);
      const worldX = (pixelX - (s.camX || 0)) / (s.scaleVal || 1);
      const worldY = (pixelY - (s.camY || 0)) / (s.scaleVal || 1);
      const tileX = Math.floor(worldX / T2);
      const tileY = Math.floor(worldY / T2);
      const mapW = room.map[0].length;
      const mapH = room.map.length;
      if (tileX < 0 || tileX >= mapW || tileY < 0 || tileY >= mapH) return null;
      return { tileX, tileY, room };
    };
    const handleTileSelection = (tileX, tileY, room) => {
      const s = stateRef.current;
      if (s.transitioning) return;
      const targetRoom = room || world.rooms[s.currentRoom];
      const tile = targetRoom.map[tileY]?.[tileX];
      if (tile == null) return;
      const distance = Math.abs(tileX - s.px) + Math.abs(tileY - s.py);
      faceTowardTile(tileX, tileY);
      if (INTERACT_TILES.has(tile)) {
        if (distance === 1) {
          handleInteract(tileX, tileY);
        } else {
          moveOneStepToward(tileX, tileY);
        }
        return;
      }
      if (tile === DOOR) {
        const door = targetRoom.doors.find((entry) => entry.x === tileX && entry.y === tileY);
        if (!door) return;
        if (distance === 1) {
          enterDoor(door);
        } else {
          moveOneStepToward(tileX, tileY);
        }
        return;
      }
      moveOneStepToward(tileX, tileY);
    };
    function frame() {
      const s = stateRef.current;
      s.frame++;
      const container = containerRef.current;
      if (!container) {
        animId = requestAnimationFrame(loop);
        return;
      }
      const cRect = container.getBoundingClientRect();
      const cw = Math.round(cRect.width);
      const ch = Math.round(cRect.height);
      if (cw === 0 || ch === 0) {
        animId = requestAnimationFrame(loop);
        return;
      }
      if (canvas.width !== cw || canvas.height !== ch) {
        canvas.width = cw;
        canvas.height = ch;
        ctx.imageSmoothingEnabled = false;
      }
      if (s.transitioning) {
        s.transitionProgress += 0.04;
        if (s.transitionProgress >= 0.5 && s.transitionTarget) {
          const door = s.transitionTarget;
          s.currentRoom = door.target;
          s.px = door.tx;
          s.py = door.ty;
          s.transitionTarget = null;
          const lang = normalizeSupportLanguage(
            supportLang,
            DEFAULT_SUPPORT_LANGUAGE
          );
          const roomName2 = world.rooms[s.currentRoom].name[lang] || world.rooms[s.currentRoom].name.en;
          showRoomName(roomName2);
        }
        if (s.transitionProgress >= 1) {
          s.transitioning = false;
          s.transitionProgress = 0;
        }
      }
      const keys = s.keysDown;
      s.moving = false;
      if (keys.has("arrowup") || keys.has("w")) tryMove("up");
      else if (keys.has("arrowdown") || keys.has("s")) tryMove("down");
      else if (keys.has("arrowleft") || keys.has("a")) tryMove("left");
      else if (keys.has("arrowright") || keys.has("d")) tryMove("right");
      const room = world.rooms[s.currentRoom];
      const mapW = room.map[0].length;
      const mapH = room.map.length;
      const mapPixelW = mapW * T2;
      const mapPixelH = mapH * T2;
      const isIndoor = s.currentRoom !== "outdoor";
      const scaleVal = Math.max(cw / mapPixelW, ch / mapPixelH);
      const playerCenterX = (s.px + 0.5) * T2 * scaleVal;
      const playerCenterY = (s.py + 0.5) * T2 * scaleVal;
      const scaledMapW = mapPixelW * scaleVal;
      const scaledMapH = mapPixelH * scaleVal;
      let camX = Math.min(0, Math.max(cw - scaledMapW, cw / 2 - playerCenterX));
      let camY = Math.min(0, Math.max(ch - scaledMapH, ch / 2 - playerCenterY));
      s.camX = camX;
      s.camY = camY;
      s.scaleVal = scaleVal;
      ctx.clearRect(0, 0, cw, ch);
      ctx.fillStyle = isIndoor ? "#3a2a1a" : "#08142b";
      ctx.fillRect(0, 0, cw, ch);
      ctx.save();
      ctx.translate(camX, camY);
      ctx.scale(scaleVal, scaleVal);
      for (let y = 0; y < mapH; y++) {
        for (let x = 0; x < mapW; x++) drawTile(ctx, x, y, room.map[y][x], s.frame, world.palette, isIndoor);
      }
      const fdx = { left: -1, right: 1, up: 0, down: 0 }[s.dir];
      const fdy = { left: 0, right: 0, up: -1, down: 1 }[s.dir];
      const fx = s.px + fdx;
      const fy = s.py + fdy;
      if (fx >= 0 && fx < mapW && fy >= 0 && fy < mapH && INTERACT_TILES.has(room.map[fy][fx])) {
        drawInteractHint(ctx, fx, fy, s.frame);
      }
      const pt = petTypeRef.current;
      const drawCharacter = pt === "axolotl" ? drawAxolotlCharacter : pt === "alien" ? drawAlienCharacter : pt === "ghost" ? drawGhostCharacter : pt === "robot" ? drawRobotCharacter : pt === "slime" ? drawSlimeCharacter : drawDogCharacter;
      const charFrame = pt === "ghost" || pt === "robot" || pt === "slime" || pt === "axolotl" ? s.frame : s.moving ? s.walkFrame : 0;
      drawCharacter(ctx, s.px, s.py, s.dir, charFrame);
      ctx.restore();
      if (s.transitioning) drawTransition(ctx, cw, ch, s.transitionProgress);
    }
    function expire() {
      for (const [id, timer] of timers) if (timer.due <= now) {
        timers.delete(id);
        timer.f();
      }
    }
    function snapshot() {
      const s = stateRef.current;
      return { state: { ...s, keysDown: [...s.keysDown] }, message, roomName, objects: [...objects], sounds: sounds.splice(0) };
    }
    showRoomName(world.rooms.outdoor.name[normalizeSupportLanguage(supportLang, DEFAULT_SUPPORT_LANGUAGE)] || world.rooms.outdoor.name.en);
    return { world, run(op, p2) {
      now = p2.now ?? now;
      expire();
      if (op === "select") handleTileSelection(p2.x, p2.y);
      else if (op === "move") tryMove(p2.direction);
      else if (op === "interact") tryInteract();
      else if (op === "click") {
        const t = resolveTileAtClientPoint(p2.x, p2.y);
        if (t) handleTileSelection(t.tileX, t.tileY, t.room);
      } else if (op === "pet") petTypeRef.current = p2.pet;
      else if (op === "frame") {
        width = p2.width || width;
        height = p2.height || height;
        ctx = record();
        frame();
        return { ...snapshot(), ops: ctx.ops };
      } else if (op !== "state") throw Error("Unknown loader operation " + op);
      return snapshot();
    } };
  }
  var engine;
  var api = { run(op, json) {
    const p = JSON.parse(json);
    let result;
    if (op === "create") {
      engine = makeEngine(p);
      result = { world: engine.world, ...engine.run("state", {}) };
    } else if (op === "delay") result = getGameLoaderExplorationDelay(p.random);
    else if (op === "copy") result = GAME_LOADING_MESSAGES[p.language] || GAME_LOADING_MESSAGES.en;
    else {
      if (!engine) throw Error("Create loader first");
      result = engine.run(op, p);
    }
    return JSON.stringify(result);
  } };
  return __toCommonJS(stdin_exports);
})();

PiyaliGameLoader.api;
