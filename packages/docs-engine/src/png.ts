// Minimal RGB PNG encoder. The cards are rectangles and bitmap glyphs, so this
// beats pulling in sharp/resvg/satori and making them build on every host.
import { deflateSync } from "node:zlib";

const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(bytes: Uint8Array): number {
  let c = 0xffffffff;
  for (let i = 0; i < bytes.length; i++) {
    c = (CRC_TABLE[(c ^ bytes[i]!) & 0xff] as number) ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type: string, data: Uint8Array): Uint8Array {
  const out = new Uint8Array(12 + data.length);
  const view = new DataView(out.buffer);
  view.setUint32(0, data.length);
  for (let i = 0; i < 4; i++) out[4 + i] = type.charCodeAt(i);
  out.set(data, 8);
  view.setUint32(8 + data.length, crc32(out.subarray(4, 8 + data.length)));
  return out;
}

export interface Rgb {
  r: number;
  g: number;
  b: number;
}

export function hex(color: string): Rgb {
  const n = parseInt(color.replace("#", ""), 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

export class Canvas {
  readonly width: number;
  readonly height: number;
  private readonly px: Uint8Array;

  constructor(width: number, height: number, fill: Rgb) {
    this.width = width;
    this.height = height;
    this.px = new Uint8Array(width * height * 3);
    this.fill(0, 0, width, height, fill);
  }

  fill(x: number, y: number, w: number, h: number, color: Rgb): void {
    const x0 = Math.max(0, Math.round(x));
    const y0 = Math.max(0, Math.round(y));
    const x1 = Math.min(this.width, Math.round(x + w));
    const y1 = Math.min(this.height, Math.round(y + h));
    for (let py = y0; py < y1; py++) {
      let i = (py * this.width + x0) * 3;
      for (let px = x0; px < x1; px++) {
        this.px[i++] = color.r;
        this.px[i++] = color.g;
        this.px[i++] = color.b;
      }
    }
  }

  stroke(x: number, y: number, w: number, h: number, weight: number, color: Rgb): void {
    this.fill(x, y, w, weight, color);
    this.fill(x, y + h - weight, w, weight, color);
    this.fill(x, y, weight, h, color);
    this.fill(x + w - weight, y, weight, h, color);
  }

  encode(): Uint8Array {
    const ihdr = new Uint8Array(13);
    const view = new DataView(ihdr.buffer);
    view.setUint32(0, this.width);
    view.setUint32(4, this.height);
    ihdr[8] = 8;
    ihdr[9] = 2;

    const stride = this.width * 3;
    const raw = new Uint8Array((stride + 1) * this.height);
    for (let y = 0; y < this.height; y++) {
      raw.set(this.px.subarray(y * stride, (y + 1) * stride), y * (stride + 1) + 1);
    }

    // IDAT is a zlib stream, not raw deflate. Bun.deflateSync gives raw, which
    // produces a file that passes `file` and then fails in every real decoder.
    const idat = new Uint8Array(deflateSync(raw));

    const parts = [
      new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      chunk("IHDR", ihdr),
      chunk("IDAT", idat),
      chunk("IEND", new Uint8Array(0)),
    ];
    const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
    let at = 0;
    for (const p of parts) {
      out.set(p, at);
      at += p.length;
    }
    return out;
  }
}
