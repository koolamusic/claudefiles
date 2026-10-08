// Local patch (not upstream): the typefaces the page uses, read from
// assets/fonts and inlined as @font-face data URIs so a generated page or
// SVG never fetches from Google Fonts. The files are OFL-licensed; see
// assets/fonts/manifest.json for family, weight, source URL and license.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const DIR = fileURLToPath(new URL('../../assets/fonts/', import.meta.url));
const MANIFEST = JSON.parse(readFileSync(`${DIR}manifest.json`, 'utf8'));
const faces = new Map();

function face(f) {
  if (!faces.has(f.file)) {
    const b64 = readFileSync(DIR + f.file).toString('base64');
    faces.set(f.file, `@font-face{font-family:'${f.family}';font-style:${f.style};font-weight:${f.weight};${f.stretch ? `font-stretch:${f.stretch};` : ''}font-display:swap;src:url(data:font/woff2;base64,${b64}) format('woff2');unicode-range:${f.unicodeRange}}`);
  }
  return faces.get(f.file);
}

// Kalam is only drawn by the sketchy look, so it is only embedded then.
export function localFontCss({ sketchy = false } = {}) {
  return MANIFEST.filter((f) => sketchy || f.family !== 'Kalam').map(face).join('');
}

// The bundled encoders, carried in the page as inert text so the Export menu
// works offline; viewer.client.js evaluates one on first use.
const VENDOR = fileURLToPath(new URL('../vendor/', import.meta.url));
export const ENCODER_BLOCKS = { gifenc: 'gifenc.js', mp4: 'mp4-muxer.js', webm: 'webm-muxer.js' };
export function encoderScripts() {
  return Object.entries(ENCODER_BLOCKS)
    .map(([name, file]) => `<script type="text/plain" id="sc-lib-${name}">${readFileSync(VENDOR + file, 'utf8').replace(/<\/script/gi, '<\\/script')}</script>`)
    .join('\n');
}
