// Render the learner-deck figures (hand signs and treble staff) to transparent PNGs.
//
// Usage (from the repository root, after `npm ci`):
//   node curriculum/content/first-notes/tools/build-figures.mjs <Bravura.otf>
//
// The staff uses Bravura (SIL Open Font License 1.1, https://github.com/steinbergmedia/bravura)
// for the treble clef and whole notes, so the deck shows engraved symbols without depending on
// the viewer's fonts. The hands are original line-art drawn here. Output:
// slides/figures/*.png, read by build-slides.py.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outDir = path.join(root, 'slides/figures');
const bravura = process.argv[2];
if (!bravura || !fs.existsSync(bravura)) {
  console.error('usage: build-figures.mjs <Bravura.otf>');
  process.exit(1);
}

const VIOLET = '#6D28E0';
const INK = '#1A1633';
const TINT = '#EFE8FF';
const RULE = '#8E86A6';

// ------------------------------------------------------------------ hands
// Palm faces the viewer; the thumb is on the left (a right hand seen from the front).
// Finger proportions: middle longest, little finger shortest and narrowest.
const FINGERS = {
  index: { x: 38, w: 27, top: 38, splay: -5 },
  middle: { x: 68, w: 28, top: 18, splay: -1 },
  ring: { x: 99, w: 27, top: 32, splay: 3 },
  pinky: { x: 129, w: 23, top: 66, splay: 9 },
};
const FINGER_BASE = 150;

const PALM = 'M50 122 H146 Q160 122 160 140 V196 Q160 238 116 244 H82 Q36 238 36 196 V140 Q36 122 50 122 Z';
// The thumb's root sits in the mound at the lower left of the palm (thenar).
const THUMB_ROOT = { x: 54, y: 196 };
const TUCKED_ROOT = { x: 22, y: 216 };

function capsule(x, y, w, h, extra = '') {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${Math.min(w, h) / 2}" ${extra}/>`;
}

const pt = (p) => `${p.x.toFixed(1)} ${p.y.toFixed(1)}`;

// A tapered limb from root to tip with a rounded tip. `closed` adds the root edge; an open
// outline lets the root blend into the palm it grows from.
function limb(root, tip, rootW, tipW, closed) {
  const len = Math.hypot(tip.x - root.x, tip.y - root.y);
  const u = { x: (tip.x - root.x) / len, y: (tip.y - root.y) / len };
  const n = { x: -u.y, y: u.x };
  const at = (p, s) => ({ x: p.x + n.x * s, y: p.y + n.y * s });
  const r = tipW / 2;
  const d = `M${pt(at(root, rootW / 2))} L${pt(at(tip, r))} A${r} ${r} 0 0 0 ${pt(at(tip, -r))} L${pt(at(root, -rootW / 2))}`;
  return closed ? `${d} Z` : d;
}

function silhouette(raised) {
  const parts = [];
  for (const [name, f] of Object.entries(FINGERS)) {
    if (!raised.has(name)) continue;
    const pivot = `rotate(${f.splay} ${f.x + f.w / 2} ${FINGER_BASE})`;
    parts.push(capsule(f.x, f.top, f.w, FINGER_BASE + 10 - f.top, `transform="${pivot}"`));
  }
  if (raised.has('thumb')) parts.push(`<path d="${limb(THUMB_ROOT, { x: -4, y: 126 }, 46, 28, true)}"/>`);
  parts.push(`<path d="${PALM}"/>`);
  return parts.join('');
}

// Fingers curled onto the palm: seen from the palm side, the bent segments lie over its upper part.
function foldedFingers(raised) {
  return Object.entries(FINGERS).filter(([name]) => !raised.has(name)).map(([, f]) =>
    capsule(f.x + 1, 112, f.w - 2, 58, `fill="${TINT}" stroke="${VIOLET}" stroke-width="6"`)).join('');
}

// The folded thumb crosses the palm and rests on the curled fingertips; its lower edge sweeps
// down into the thumb mound so it grows from the palm instead of lying on it.
function foldedThumb(raised) {
  const curled = Object.entries(FINGERS).filter(([name]) => !raised.has(name)).map(([, f]) => f.x + f.w / 2);
  const tipX = curled.length ? curled.reduce((a, b) => a + b, 0) / curled.length : 112;
  const tip = { x: tipX, y: 166 };
  // Rooted outside the palm and masked to its inside, so the thumb leaves the palm's own outline.
  const thumb = limb(TUCKED_ROOT, tip, 46, 28, true);
  return `<mask id="palm-inside" maskUnits="userSpaceOnUse" x="-40" y="0" width="230" height="262">
    <path d="${PALM}" fill="white"/>
  </mask>
  <g mask="url(#palm-inside)">
    <path d="${thumb}" fill="${TINT}" stroke="${VIOLET}" stroke-width="6" stroke-linejoin="round"/>
  </g>`;
}

// Palm creases mark that the palm faces the viewer.
function creases(raised) {
  const line = `fill="none" stroke="${VIOLET}" stroke-width="3.5" stroke-linecap="round" opacity="0.55"`;
  const life = `<path d="M54 152 Q80 186 84 232" ${line}/>`;
  const heart = `<path d="M152 168 Q122 162 96 176" ${line}/>`;
  // A curled little finger covers the end of the heart line.
  return (raised.has('thumb') ? life : '') + (raised.has('pinky') ? heart : '');
}

function handSvg(raised) {
  const set = new Set(raised);
  const parts = silhouette(set);
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-40 0 230 262" width="230" height="262">
  <g fill="${VIOLET}" stroke="${VIOLET}" stroke-width="14" stroke-linejoin="round">${parts}</g>
  <g fill="${TINT}">${parts}</g>
  ${creases(set)}
  ${foldedFingers(set)}
  ${set.has('thumb') ? '' : foldedThumb(set)}
</svg>`;
}

const SIGNS = {
  do: ['index'],
  re: ['index', 'middle'],
  mi: ['index', 'middle', 'ring'],
  fa: ['index', 'middle', 'ring', 'pinky'],
  sol: ['thumb', 'index', 'middle', 'ring', 'pinky'],
  la: ['thumb', 'pinky'],
  si: ['pinky'],
};

// ------------------------------------------------------------------ staff
// Notes sit under the name chips of slide 3: the image starts at slide x=64 and each chip
// centre is at 249.5 + 147·i. Bravura's em is four staff spaces (SMuFL).
const SPACE = 22;
const STAFF_W = 1152;
const STAFF_H = 230;
const BOTTOM = 160;
const STEPS = { C4: -2, D4: -1, E4: 0, F4: 1, G4: 2, A4: 3, B4: 4 };

function staffSvg() {
  const em = SPACE * 4;
  const lines = [0, 1, 2, 3, 4].map((k) =>
    `<line x1="0" x2="${STAFF_W}" y1="${BOTTOM - k * SPACE}" y2="${BOTTOM - k * SPACE}" stroke="${INK}" stroke-width="2.2"/>`).join('');
  const notes = Object.entries(STEPS).map(([pitch, step], i) => {
    const x = 249.5 + 147 * i - 64;
    const y = BOTTOM - (step * SPACE) / 2;
    const ledger = step <= -2
      ? `<line x1="${x - 30}" x2="${x + 30}" y1="${BOTTOM + SPACE}" y2="${BOTTOM + SPACE}" stroke="${INK}" stroke-width="2.6"/>` : '';
    return `${ledger}<text x="${x}" y="${y}" font-size="${em}" text-anchor="middle" fill="${VIOLET}" aria-label="${pitch}"></text>`;
  }).join('');
  const clef = `<text x="14" y="${BOTTOM - SPACE}" font-size="${em}" fill="${INK}"></text>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${STAFF_W} ${STAFF_H}" width="${STAFF_W}" height="${STAFF_H}"
  style="font-family: Bravura">${lines}${clef}${notes}</svg>`;
}

// ------------------------------------------------------------------ render
async function render(page, file, svg) {
  const font = fs.readFileSync(bravura).toString('base64');
  await page.setContent(`<!doctype html><html><head><style>
    @font-face { font-family: Bravura; src: url(data:font/otf;base64,${font}); }
    html, body { margin: 0; background: transparent; }
  </style></head><body>${svg}</body></html>`);
  await page.evaluate(() => document.fonts.ready);
  await page.locator('svg').screenshot({ path: path.join(outDir, file), omitBackground: true });
  // Hands are self-contained SVG sources; the staff needs Bravura, so only its PNG is kept.
  if (file.startsWith('hand-')) fs.writeFileSync(path.join(outDir, file.replace(/\.png$/, '.svg')), svg + '\n');
}

fs.mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 3 });
for (const [key, raised] of Object.entries(SIGNS)) await render(page, `hand-${key}.png`, handSvg(raised));
await render(page, 'staff-treble.png', staffSvg());
await browser.close();
console.log('Rendered', fs.readdirSync(outDir).filter((f) => f.endsWith('.png')).join(', '));
