// The source terrain functions use Canvas only for RGB(A) fills and compositing
// their own 16-pixel tile textures. JavaScriptCore has no browser Canvas.
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
