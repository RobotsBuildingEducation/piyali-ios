// The source terrain and sprite functions draw directly into RGB(A) canvas
// pixels. JavaScriptCore has no browser Canvas.
class PixelCanvas {
  width = 0;
  height = 0;
  getContext() {
    this.pixels = new Uint8ClampedArray(this.width * this.height * 4);
    let color = [0, 0, 0, 255];
    const composite = (offset, r, g, b, opacity) => {
      if (!opacity) return;
      const oldOpacity = this.pixels[offset + 3] * (255 - opacity) / 255;
      const alpha = opacity + oldOpacity;
      this.pixels[offset] = (r * opacity + this.pixels[offset] * oldOpacity) / alpha;
      this.pixels[offset + 1] = (g * opacity + this.pixels[offset + 1] * oldOpacity) / alpha;
      this.pixels[offset + 2] = (b * opacity + this.pixels[offset + 2] * oldOpacity) / alpha;
      this.pixels[offset + 3] = alpha;
    };
    return {
      set fillStyle(value) {
        const [r, g, b, a = 1] = value.match(/[\d.]+/g).map(Number);
        color = [r, g, b, Math.round(a * 255)];
      },
      fillRect: (x, y, width, height) => {
        for (let row = Math.max(0, y); row < Math.min(y + height, this.height); row++) {
          for (let col = Math.max(0, x); col < Math.min(x + width, this.width); col++) {
            composite((row * this.width + col) * 4, ...color);
          }
        }
      },
      clearRect: (x, y, width, height) => {
        for (let row = Math.max(0, y); row < Math.min(y + height, this.height); row++) {
          const start = (row * this.width + Math.max(0, x)) * 4;
          const end = (row * this.width + Math.min(x + width, this.width)) * 4;
          this.pixels.fill(0, start, end);
        }
      },
      drawImage: (image, x, y) => {
        for (let row = 0; row < image.height; row++) {
          for (let col = 0; col < image.width; col++) {
            const src = (row * image.width + col) * 4, dst = ((y + row) * this.width + x + col) * 4;
            composite(dst, image.pixels[src], image.pixels[src + 1], image.pixels[src + 2], image.pixels[src + 3]);
          }
        }
      },
    };
  }
}

function encodePixels(bytes) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let result = "";
  for (let at = 0; at < bytes.length; at += 3) {
    const a = bytes[at], b = bytes[at + 1] || 0, c = bytes[at + 2] || 0;
    result += alphabet[a >> 2] + alphabet[((a & 3) << 4) | (b >> 4)] +
      (at + 1 < bytes.length ? alphabet[((b & 15) << 2) | (c >> 6)] : "=") +
      (at + 2 < bytes.length ? alphabet[c & 63] : "=");
  }
  return result;
}

export function terrain(input) {
  const { width: mapWidth, height: mapHeight, tiles: mapData, definitions: tiles, seed } = JSON.parse(input);
  globalThis.document = { createElement: () => new PixelCanvas() };
  const ground = createGroundLayerCanvas({ mapData, tiles, mapWidth, mapHeight, seed });
  const tile = (x, y) => x >= 0 && y >= 0 && x < mapWidth && y < mapHeight ? mapData[y * mapWidth + x] : undefined;
  const interior = (x, y) => !!tiles[tile(x, y)] && !tiles[tile(x, y)].void;
  const open = (x, y) => interior(x, y) && !tiles[tile(x, y)].solid;
  const pixels = ground.pixels;
  const context = ground.getContext("2d");
  ground.pixels.set(pixels);
  for (let y = 0; y < mapHeight; y++) for (let x = 0; x < mapWidth; x++) {
    const type = tile(x,y), definition = tiles[type];
    if (!definition || !definition.solid || definition.sprite) continue;
    const edges = {
      exposedUp: open(x, y - 1), exposedDown: open(x, y + 1),
      exposedLeft: open(x - 1, y), exposedRight: open(x + 1, y),
      faceDown: interior(x, y + 1), linkedUp: tile(x, y - 1) === type,
      linkedDown: tile(x, y + 1) === type, linkedLeft: tile(x - 1, y) === type,
      linkedRight: tile(x + 1, y) === type,
    };
    const texture = createTileTexture(definition, x, y, seed, edges);
    context.drawImage(texture.image, x * 16, y * 16);
  }
  return encodePixels(ground.pixels);
}


// Greeting Plaza draws generated props above the terrain, with the source
// sprite dimensions, depth order, per-tile seed and ambient tree phases.
export function decoration(input) {
  const { width, height, tiles, definitions, seed, id } = JSON.parse(input);
  globalThis.document = { createElement: () => new PixelCanvas() };
  let ambientSeed = 2166136261;
  for (const character of id + ":" + id + ":") {
    ambientSeed = Math.imul(ambientSeed ^ character.charCodeAt(0), 16777619);
  }
  const ambientRandom = mulberry32(ambientSeed);
  const layers = [];
  const add = (texture, kind, x, y, width, height, z, phase = null) => {
    const image = texture.image;
    layers.push({ kind, x, y, width, height, z, phase,
      pixelWidth: image.width, pixelHeight: image.height, rgba: encodePixels(image.pixels) });
  };
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const sprite = definitions[tiles[y * width + x]]?.sprite;
    if (!["tree", "bench", "counter"].includes(sprite)) continue;
    const tree = sprite === "tree";
    add(createSpriteTexture(sprite, seed + x * 7 + y * 13), sprite, x + 0.5,
      height - 1 - y + (tree ? 0.6 : 0.5), tree ? 1.3 : 1, tree ? 1.6 : 1,
      1000 + y * 10, tree ? ambientRandom() * 2 * Math.PI : null);
  }
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const definition = definitions[tiles[y * width + x]];
    if (!definition || definition.solid || definition.sprite) continue;
    const decSeed = (seed + x * 73856093 + y * 19349663) >>> 0;
    if ((decSeed % 1000) / 1000 > 0.09) continue;
    const kind = ["paper_bits", "stones"][decSeed % 2];
    add(createGroundDecalTexture(kind, seed + x * 113 + y * 197), kind,
      x + 0.5 + (((decSeed >>> 8) % 100) / 100 - 0.5) * 0.2,
      height - 1 - y + 0.5 + (((decSeed >>> 16) % 100) / 100 - 0.5) * 0.15, 0.72, 0.72, 0.8);
  }
  return JSON.stringify(layers);
}
