/* 1000 Nights — launch film composition.
 *
 * One deterministic function of time:  window.renderFrame(t)  draws frame at t seconds.
 * No wall clock, no Math.random — every random choice comes from a seeded PRNG,
 * so frame N is pixel-identical on every render.
 *
 * Query params:  ?fmt=9x16 | 16x9 | 1x1   (1x1 is the 7 s looping teaser)
 *                ?t=12.3  (preview a single time)   ?play=1 (realtime preview with scrubber)
 */
'use strict';

// ------------------------------------------------------------------ setup
const Q = new URLSearchParams(location.search);
const FMT = Q.get('fmt') || '9x16';
const SIZES = { '9x16': [1080, 1920], '16x9': [1920, 1080], '1x1': [1080, 1080] };
const [W, H] = SIZES[FMT];
const V = FMT === '9x16', L = FMT === '16x9', SQ = FMT === '1x1';
const ROOT = '../../../';                       // repo root, relative to this file
const canvas = document.getElementById('c');
canvas.width = W; canvas.height = H;
const ctx = canvas.getContext('2d');

const DURATION = SQ ? 7.0 : 39.5;
window.DURATION = DURATION;
window.FPS = 30;

// brand palette
const C = {
  navy: '#12151F', navyRGB: [18, 21, 31],
  amber: '#E8B76A', amberRGB: [232, 183, 106],
  parch: '#EFE6D6', parchRGB: [239, 230, 214],
  mute: 'rgba(239,230,214,0.62)',
  deep: '#0A0C13',
};
const rgba = (rgb, a) => `rgba(${rgb[0]},${rgb[1]},${rgb[2]},${a})`;

// ------------------------------------------------------------------ math
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const lerp = (a, b, t) => a + (b - a) * t;
const seg = (t, a, b) => clamp((t - a) / (b - a));
const smooth = (x) => x * x * (3 - 2 * x);

// CSS-style cubic-bezier easing (same solver browsers use)
function bezier(x1, y1, x2, y2) {
  const cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx;
  const cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by;
  const sx = (t) => ((ax * t + bx) * t + cx) * t;
  const sy = (t) => ((ay * t + by) * t + cy) * t;
  const dx = (t) => (3 * ax * t + 2 * bx) * t + cx;
  return (x) => {
    if (x <= 0) return 0; if (x >= 1) return 1;
    let t = x;
    for (let i = 0; i < 8; i++) { const e = sx(t) - x; const d = dx(t); if (Math.abs(e) < 1e-6 || Math.abs(d) < 1e-6) break; t -= e / d; }
    let lo = 0, hi = 1;
    for (let i = 0; i < 30 && Math.abs(sx(t) - x) > 1e-6; i++) { if (sx(t) < x) lo = t; else hi = t; t = (lo + hi) / 2; }
    return sy(t);
  };
}
// The easing vocabulary of the film (see STORYBOARD.md §4)
const E = {
  dissolve: bezier(0.45, 0, 0.55, 1),   // symmetric slow-in/slow-out for cross-dissolves
  bloom: bezier(0.16, 1, 0.3, 1),       // expo-out: light arrives fast, settles long
  out: bezier(0.33, 1, 0.68, 1),        // cubic-out: type and UI arrivals
  settle: bezier(0.22, 1, 0.36, 1.012), // quint-out with a ~1% overshoot, for UI settles
  move: bezier(0.65, 0, 0.35, 1),       // camera/object repositioning, slow in & out
  anticip: bezier(0.55, 0, 0.9, 0.35),  // slow ease-in for the ember "breath" before the strike
  exit: bezier(0.5, 0, 0.75, 0),        // ease-in for departures
  drift: bezier(0.3, 0.1, 0.7, 0.9),    // near-linear with soft ends, for Ken Burns
  light: bezier(0.3, 0.55, 0.4, 1),     // candle light spreading: soft start, long ease-out
};

// seeded PRNG (mulberry32)
function rng(seed) {
  let a = seed >>> 0;
  return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
}
// 1-D value noise, smooth, seeded; optional wrap for perfect loops
const NOISE_TAB = (() => { const r = rng(1001); return Array.from({ length: 512 }, () => r() * 2 - 1); })();
function noise(x, seed = 0, wrap = 0) {
  const i = Math.floor(x), f = x - i;
  let i0 = i, i1 = i + 1;
  if (wrap) { i0 = ((i0 % wrap) + wrap) % wrap; i1 = ((i1 % wrap) + wrap) % wrap; }
  const a = NOISE_TAB[(i0 + seed * 37) & 511], b = NOISE_TAB[(i1 + seed * 37) & 511];
  return lerp(a, b, smooth(f));
}
// candle flicker: three octaves of slow noise; wrapLen (seconds) makes it loop exactly
function flicker(t, seed = 0, wrapLen = 0) {
  const o = (f, s) => noise(t * f, seed + s, wrapLen ? Math.round(wrapLen * f) : 0);
  // frequencies chosen so f*wrapLen is an integer for the 7 s teaser
  return o(2 / 1, 1) * 0.55 + o(37 / 7, 2) * 0.3 + o(78 / 7, 3) * 0.15;
}

// ------------------------------------------------------------------ assets
const IMG = {};
function loadImage(key, src) {
  return new Promise((res, rej) => { const i = new Image(); i.onload = () => { IMG[key] = i; res(); }; i.onerror = () => rej(new Error('img ' + src)); i.src = src; });
}
async function loadFonts() {
  const F = ROOT + 'assets/fonts/';
  const faces = [
    new FontFace('NR', `url(${F}Newsreader-Regular.ttf)`, { weight: '400', style: 'normal' }),
    new FontFace('NR', `url(${F}Newsreader-Medium.ttf)`, { weight: '500', style: 'normal' }),
    new FontFace('NR', `url(${F}Newsreader-Italic.ttf)`, { weight: '400', style: 'italic' }),
    new FontFace('NRD', `url(${F}NewsreaderDisplay-Light.ttf)`, { weight: '300', style: 'normal' }),
    new FontFace('NRD', `url(${F}NewsreaderDisplay-Regular.ttf)`, { weight: '400', style: 'normal' }),
  ];
  for (const f of faces) { await f.load(); document.fonts.add(f); }
}
let PACK = null;
const ENGR = ROOT + 'assets/packs/pack-001/images/2.0x/';
const SHOT = ROOT + 'docs/screenshots/';
const DER = '../derived/';

window.ready = (async () => {
  await loadFonts();
  PACK = await (await fetch(ROOT + 'assets/packs/pack-001.json')).json();
  await Promise.all([
    loadImage('iconUnlit', DER + 'icon-unlit.png'),
    loadImage('iconFlame', DER + 'icon-flame.png'),
    loadImage('ncUnlit', DER + 'nc-unlit.png'),
    loadImage('ncFlame', DER + 'nc-flame.png'),
    loadImage('ncDots', DER + 'nc-dots-unlit.png'),
    loadImage('journeyUnlit', DER + 'journey-unlit.png'),
    loadImage('readerNR', DER + 'reader-noribbon.png'),
    loadImage('tonight', SHOT + 'tonight.png'),
    loadImage('reader', SHOT + 'reader.png'),
    loadImage('complete', SHOT + 'night-complete.png'),
    loadImage('journey', SHOT + 'journey.png'),
    loadImage('shareHL', SHOT + 'share-highlight.png'),
    loadImage('p1', ENGR + 'henry-the-gift-of-the-magi.webp'),
    loadImage('p2', ENGR + 'whitman-when-i-heard-the-learnd-astronomer.webp'),
    loadImage('p3', ENGR + 'stevenson-el-dorado.webp'),
  ]);
  buildStatic();
  return true;
})();

// ------------------------------------------------------------------ static layers
let VIGNETTE, GRAIN = [], ICON_MASK, PLATE_MASK, PHONE_SHADOW;
let iconCanvas, iconCtx, plateCanvas, plateCtx, readerCont = null;
const work = (key) => PACK.works.find((w) => w.id === key);

function makeCanvas(w, h) { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; }

function buildStatic() {
  // vignette
  VIGNETTE = makeCanvas(W, H);
  const v = VIGNETTE.getContext('2d');
  const g = v.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.25, W / 2, H / 2, Math.hypot(W, H) * 0.56);
  g.addColorStop(0, 'rgba(5,6,10,0)'); g.addColorStop(1, 'rgba(5,6,10,0.62)');
  v.fillStyle = g; v.fillRect(0, 0, W, H);
  // film grain tiles (seeded); low amplitude, also dithers gradients against banding
  const r = rng(77);
  for (let k = 0; k < 4; k++) {
    const c = makeCanvas(256, 256), cx = c.getContext('2d');
    const id = cx.createImageData(256, 256);
    for (let i = 0; i < id.data.length; i += 4) { const n = (r() + r() + r()) / 3; const val = Math.round(n * 255); id.data[i] = id.data[i + 1] = id.data[i + 2] = val; id.data[i + 3] = 255; }
    cx.putImageData(id, 0, 0); GRAIN.push(ctx.createPattern(c, 'repeat'));
  }
  // icon feather mask (soft rectangle; keeps the book's corners)
  ICON_MASK = makeCanvas(1024, 1024);
  const m = ICON_MASK.getContext('2d');
  m.filter = 'blur(46px)'; m.fillStyle = '#fff'; m.fillRect(90, 90, 844, 844);
  iconCanvas = makeCanvas(1024, 1024); iconCtx = iconCanvas.getContext('2d');
  // plate canvas + feather mask
  const PR = plateRect(0);
  plateCanvas = makeCanvas(Math.ceil(PR.w), Math.ceil(PR.h)); plateCtx = plateCanvas.getContext('2d');
  PLATE_MASK = makeCanvas(plateCanvas.width, plateCanvas.height);
  const pm = PLATE_MASK.getContext('2d');
  const fe = V ? 64 : 70;
  pm.filter = `blur(${fe * 0.55}px)`; pm.fillStyle = '#fff';
  pm.fillRect(V ? fe * 0.5 : fe, fe, plateCanvas.width - (V ? fe : fe * 2), plateCanvas.height - fe * 2);
  // reader continuation text (laid out once)
  layoutReaderContinuation();
}

// ------------------------------------------------------------------ particles
function starfield(seed, n) {
  const r = rng(seed);
  return Array.from({ length: n }, () => ({
    x: r() * W, y: r() * H, s: 0.5 + r() * r() * 1.9, b: 0.25 + r() * 0.75,
    ph: r() * Math.PI * 2, fr: 0.25 + r() * 0.9, on: r(), depth: 0.2 + r() * 0.5,
  }));
}
const STARS = starfield(11, V ? 170 : L ? 190 : 120);
const DUST = (() => { const r = rng(23); return Array.from({ length: 46 }, () => ({ x: r(), y: r(), vx: (r() - 0.5) * 6, vy: -2 - r() * 6, s: 0.6 + r() * 1.8, a: 0.05 + r() * 0.16, ph: r() * 6.28, depth: 0.6 + r() * 1.2 })); })();

// ------------------------------------------------------------------ text helpers
function font(kind, px) {
  switch (kind) {
    case 'display': return `300 ${px}px NRD`;
    case 'displayR': return `400 ${px}px NRD`;
    case 'italic': return `italic 400 ${px}px NR`;
    case 'caps': return `500 ${px}px NR`;
    default: return `400 ${px}px NR`;
  }
}
function setText(f, spacing = 0) { ctx.font = f; ctx.letterSpacing = spacing + 'px'; ctx.textBaseline = 'alphabetic'; ctx.textAlign = 'left'; }
function textW(s) { return ctx.measureText(s).width; }
function greedy(words, maxW) {
  const lines = []; let cur = '';
  for (const w of words) { const t = cur ? cur + ' ' + w : w; if (textW(t) > maxW && cur) { lines.push(cur); cur = w; } else cur = t; }
  if (cur) lines.push(cur); return lines;
}
// balanced: same line count as greedy, but the narrowest measure that keeps it (no orphans)
function wrap(text, maxW, balance = false) {
  const words = text.split(' ');
  const g = greedy(words, maxW);
  if (!balance || g.length < 2) return g;
  let lo = maxW * 0.4, hi = maxW;
  for (let i = 0; i < 18; i++) { const mid = (lo + hi) / 2; if (greedy(words, mid).length > g.length) lo = mid; else hi = mid; }
  return greedy(words, hi);
}
/* Reveal a line unit-by-unit (chars or words): each unit goes blur→sharp, drifts up, fades in.
 * Overlapping action: units start `stagger` apart but each takes `dur`, so several move at once. */
function revealLine(str, x, y, opt) {
  const { t, t0, stagger = 0.04, dur = 0.9, unit = 'char', color = C.parch, align = 'left', blur = 12, rise = 18, spacing = 0, alpha = 1, colors = null } = opt;
  const units = unit === 'char' ? [...str] : str.split(/(?<= )/);
  const full = textW(str) - (spacing || 0);
  let ox = align === 'center' ? x - full / 2 : align === 'right' ? x - full : x;
  let prefix = '';
  units.forEach((u, i) => {
    const px = ox + (prefix ? textW(prefix) : 0);
    prefix += u;
    const p = seg(t, t0 + i * stagger, t0 + i * stagger + dur);
    if (p <= 0 || !u.trim()) return;
    const e = E.out(p);
    ctx.save();
    ctx.globalAlpha = alpha * smooth(clamp(p * 1.6));
    const b = (1 - e) * blur;
    if (b > 0.15) ctx.filter = `blur(${b.toFixed(2)}px)`;
    ctx.fillStyle = colors ? colors[i] || color : color;
    ctx.fillText(u, px, y + (1 - e) * rise);
    ctx.restore();
  });
}
function drawLineStatic(str, x, y, color, align = 'left', alpha = 1, spacing = 0) {
  const w = textW(str) - spacing;
  const ox = align === 'center' ? x - w / 2 : align === 'right' ? x - w : x;
  ctx.save(); ctx.globalAlpha = alpha; ctx.fillStyle = color; ctx.fillText(str, ox, y); ctx.restore();
}

// ------------------------------------------------------------------ background
function drawBackground(t, starAlpha, parX = 0, parY = 0) {
  ctx.fillStyle = C.navy; ctx.fillRect(0, 0, W, H);
  // faint cool sky gradient
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, 'rgba(26,31,48,0.55)'); g.addColorStop(0.6, 'rgba(18,21,31,0)'); g.addColorStop(1, 'rgba(8,9,14,0.5)');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  if (starAlpha > 0.003) drawStars(t, starAlpha, parX, parY);
}
// stars "light" one by one: each has an on-time inside the lighting window
function drawStars(t, alpha, parX, parY) {
  const lightA = SQ ? 0 : 2.3, lightB = SQ ? 0 : 7.5;
  for (const s of STARS) {
    const on = SQ ? 1 : E.out(seg(t, lerp(lightA, lightB, s.on), lerp(lightA, lightB, s.on) + 1.2));
    if (on <= 0) continue;
    const tw = SQ ? 0.75 + 0.25 * Math.sin((2 * Math.PI * Math.round(s.fr * 3)) * t / DURATION + s.ph)
      : 0.75 + 0.25 * Math.sin(t * s.fr * 2.2 + s.ph);
    const a = alpha * on * s.b * tw * 0.8;
    const x = ((s.x + parX * s.depth) % W + W) % W, y = ((s.y + parY * s.depth) % H + H) % H;
    ctx.fillStyle = `rgba(236,228,214,${a.toFixed(3)})`;
    ctx.beginPath(); ctx.arc(x, y, s.s, 0, 7); ctx.fill();
    if (s.s > 1.7) { ctx.fillStyle = `rgba(232,183,106,${(a * 0.12).toFixed(3)})`; ctx.beginPath(); ctx.arc(x, y, s.s * 4, 0, 7); ctx.fill(); }
  }
}
function drawDust(t, alpha, parX = 0, parY = 0, warm = 0) {
  if (alpha <= 0.003) return;
  for (const d of DUST) {
    // teaser: closed orbits so the 7 s loop is seamless; film: slow drift
    const lx = SQ ? 26 * Math.sin(2 * Math.PI * t / DURATION + d.ph) : d.vx * t + 8 * Math.sin(t * 0.4 + d.ph);
    const ly = SQ ? 18 * Math.cos(2 * Math.PI * t / DURATION + d.ph * 1.3) : d.vy * t;
    const x = (((d.x * W + lx + parX * d.depth) % W) + W) % W;
    const y = (((d.y * H + ly + parY * d.depth) % H) + H) % H;
    const a = alpha * d.a * (0.6 + 0.4 * Math.sin((SQ ? 2 * Math.PI * 6 / DURATION : 0.9) * t + d.ph));
    const col = warm ? [lerp(239, 232, warm), lerp(230, 183, warm), lerp(214, 106, warm)] : C.parchRGB;
    ctx.fillStyle = rgba(col, a.toFixed(3));
    ctx.beginPath(); ctx.arc(x, y, d.s, 0, 7); ctx.fill();
  }
}
function finish(t) {
  ctx.drawImage(VIGNETTE, 0, 0);
  // grain: changes every 2 frames, offset seeded by frame index
  const fi = Math.floor(t * 15 + 1e-6) % (SQ ? Math.round(DURATION * 15) : 1e9);
  const r = rng(900 + fi);
  ctx.save();
  ctx.globalCompositeOperation = 'overlay'; ctx.globalAlpha = 0.07;
  ctx.translate(Math.floor(r() * 256), Math.floor(r() * 256));
  ctx.fillStyle = GRAIN[fi % GRAIN.length]; ctx.fillRect(-256, -256, W + 512, H + 512);
  ctx.restore();
}

// ------------------------------------------------------------------ the hero candle (app icon)
// icon-space anchors (1024 px icon)
const WICK = { x: 510, y: 312 }, FLAME_ORIGIN = { x: 370, y: 105 }, FLAME_BASE = { x: 510, y: 334 };

/* draw the icon lit by its own candle.
 * light: 0..1 (how far the light has spread), lum: overall brightness, fl: flicker */
function drawIcon(cx, cy, size, st) {
  const { light, flame, fl, alpha = 1, skew = 0, stretch = 0 } = st;
  const k = size / 1024;
  // 1) unlit icon into offscreen, feathered, then darkness shaped by the light radius
  iconCtx.globalCompositeOperation = 'source-over';
  iconCtx.clearRect(0, 0, 1024, 1024);
  iconCtx.drawImage(IMG.iconUnlit, 0, 0);
  iconCtx.globalCompositeOperation = 'destination-in';
  iconCtx.drawImage(ICON_MASK, 0, 0);
  iconCtx.globalCompositeOperation = 'source-atop';
  const R = lerp(30, 1350, light);
  const lv = clamp(light * 1.4) * (0.94 + 0.06 * fl);
  const g = iconCtx.createRadialGradient(WICK.x, WICK.y + 40, 0, WICK.x, WICK.y + 40, R);
  g.addColorStop(0, rgba(C.navyRGB, 1 - lv));
  g.addColorStop(0.45, rgba(C.navyRGB, 1 - lv * 0.92));
  g.addColorStop(1, rgba(C.navyRGB, 1));
  iconCtx.fillStyle = g; iconCtx.fillRect(0, 0, 1024, 1024);
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.drawImage(iconCanvas, cx - size / 2, cy - size / 2, size, size);
  // 2) warm ambient glow from the flame
  const fx = cx + (WICK.x - 512) * k, fy = cy + (WICK.y - 512 - 50) * k;
  if (flame > 0.001) {
    ctx.globalCompositeOperation = 'lighter';
    const gr = ctx.createRadialGradient(fx, fy, 0, fx, fy, size * 0.75);
    const ga = 0.16 * flame * (0.9 + 0.1 * fl) * alpha;
    gr.addColorStop(0, rgba([232, 160, 80], ga)); gr.addColorStop(0.35, rgba([232, 150, 70], ga * 0.35)); gr.addColorStop(1, 'rgba(232,150,70,0)');
    ctx.fillStyle = gr; ctx.fillRect(fx - size, fy - size, size * 2, size * 2);
    // 3) the flame sprite itself, additive, flickering about the wick base
    const bx = cx + (FLAME_BASE.x - 512) * k, by = cy + (FLAME_BASE.y - 512) * k;
    ctx.translate(bx, by);
    const sy = flame * (1 + 0.07 * fl) * (1 + stretch);
    const sx = Math.max(0.05, flame * (1 - 0.035 * fl) * (1 - stretch * 0.5));
    ctx.transform(1, 0, skew + 0.035 * noise(fl * 3 + 9, 4), 1, 0, 0);
    ctx.scale(sx * k, sy * k);
    ctx.globalAlpha = alpha * clamp(flame * 1.3);
    ctx.drawImage(IMG.iconFlame, FLAME_ORIGIN.x - FLAME_BASE.x, FLAME_ORIGIN.y - FLAME_BASE.y);
  }
  ctx.restore();
  return { fx: cx + (WICK.x - 512) * k, fy: cy + (WICK.y - 512 - 60) * k, wx: cx + (WICK.x - 512) * k, wy: cy + (WICK.y - 512) * k, k };
}
// the match-strike: an ember breathes at the wick (anticipation), then sparks fly on ballistic arcs
function drawStrike(t, t0, wx, wy, k, alpha = 1) {
  // ember breath (t0-0.55 .. t0): slow ease-in brightening
  const pre = E.anticip(seg(t, t0 - 0.6, t0));
  const post = 1 - E.out(seg(t, t0, t0 + 0.5));
  const em = pre * post;
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  if (em > 0.002) {
    const r = (6 + 10 * em) * k * 2.2;
    const g = ctx.createRadialGradient(wx, wy, 0, wx, wy, r);
    g.addColorStop(0, `rgba(255,214,150,${0.9 * em * alpha})`); g.addColorStop(0.3, `rgba(240,140,60,${0.45 * em * alpha})`); g.addColorStop(1, 'rgba(200,90,30,0)');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(wx, wy, r, 0, 7); ctx.fill();
  }
  // sparks
  const r = rng(314);
  for (let i = 0; i < 18; i++) {
    const ang = -Math.PI / 2 + (r() - 0.5) * 2.4, sp = (180 + r() * 380) * k * 1.6, life = 0.35 + r() * 0.55, d = r() * 0.08;
    const tau = t - t0 - d;
    if (tau <= 0 || tau > life) continue;
    const g = 900 * k * 1.6;
    const px = (tt) => wx + Math.cos(ang) * sp * tt;
    const py = (tt) => wy + Math.sin(ang) * sp * tt + 0.5 * g * tt * tt;
    const a = (1 - tau / life) * alpha;
    ctx.strokeStyle = `rgba(255,${200 - 60 * (tau / life)},${130 - 70 * (tau / life)},${a.toFixed(3)})`;
    ctx.lineWidth = Math.max(1, 2.2 * k * 1.6 * (1 - tau / life * 0.5)); ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(px(Math.max(0, tau - 0.045)), py(Math.max(0, tau - 0.045))); ctx.lineTo(px(tau), py(tau)); ctx.stroke();
  }
  ctx.restore();
}
/* embers: born at the flame tip, rise and sway on sine arcs, cool from gold to red and fade.
 * emitAt(time) returns the flame tip in screen space at the moment of birth (world-space trails). */
function drawEmbers(t, from, to, emitAt, opts = {}) {
  const { n = 26, seed = 5, scale = 1, alpha = 1, loop = 0 } = opts;
  const r = rng(seed);
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  for (let i = 0; i < n; i++) {
    const life = 2.6 + r() * 2.2, rise = (55 + r() * 70) * scale, amp = (8 + r() * 26) * scale, w = 0.8 + r() * 1.4, ph = r() * 6.28, drift = (r() - 0.5) * 30 * scale, sz = (1.1 + r() * 1.6) * scale, off = r();
    let birth, tau;
    if (loop) { tau = (((t / loop + off) % 1) + 1) % 1 * loop; birth = t - tau; if (tau > life) continue; }
    else { birth = from + (i / n) * (to - from) + off * 0.3; tau = t - birth; if (tau < 0 || tau > life || birth > to) continue; }
    const o = emitAt(birth);
    if (!o) continue;
    const x = o.x + drift * tau + amp * Math.sin(w * tau + ph) - amp * Math.sin(ph);
    const y = o.y - rise * tau - 6 * scale * tau * tau;
    const fade = Math.sin(Math.PI * clamp(tau / life)) * (0.75 + 0.25 * Math.sin(tau * 13 + ph));
    const cool = tau / life;
    const a = fade * alpha * (o.a ?? 1);
    if (a < 0.004) continue;
    const g = ctx.createRadialGradient(x, y, 0, x, y, sz * 3.2);
    g.addColorStop(0, `rgba(255,${Math.round(lerp(214, 150, cool))},${Math.round(lerp(140, 70, cool))},${(0.85 * a).toFixed(3)})`);
    g.addColorStop(1, 'rgba(200,90,30,0)');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, sz * 3.2, 0, 7); ctx.fill();
  }
  ctx.restore();
}

// ------------------------------------------------------------------ timeline
const T = {
  strike: 1.3, igniteA: 1.36, igniteB: 2.5, lightA: 1.4, lightB: 3.8,
  moveA: 3.3, moveB: 4.6,
  title1: 4.05, title2: 5.55, titleOut: 8.9,
  plates: [9.3, 12.75, 16.2], plateDur: [4.2, 4.2, 4.6],
  phoneIn: 20.45,
  rdA: 23.0, cmpA: 26.0, jrnA: 29.0, shrA: 31.8, appOut: 34.2,
  end: 34.55, endStrike: 34.95, fadeOut: 39.0,
};
window.TIMELINE = T;
// audio cue points (read by tools/synth_audio.py via render.mjs)
window.CUES = SQ ? [] : [
  { t: T.strike, kind: 'strike' },
  { t: T.igniteA, kind: 'ignite' },
  { t: T.title1, kind: 'chime', note: 0 },
  { t: T.plates[0], kind: 'page' }, { t: T.plates[1], kind: 'page' }, { t: T.plates[2], kind: 'page' },
  { t: T.phoneIn + 0.3, kind: 'chime', note: 1 },
  { t: T.cmpA + 0.7, kind: 'ignite_small' },
  ...Array.from({ length: 7 }, (_, i) => ({ t: T.jrnA + 0.55 + i * 0.3, kind: 'star', note: i })),
  { t: T.endStrike, kind: 'ignite' },
  { t: T.end + 0.9, kind: 'chime', note: 2 },
];

// hero candle placement over S1–S2
function heroState(t) {
  const a = V ? { x: 540, y: 900, s: 860 } : L ? { x: 960, y: 540, s: 760 } : { x: 540, y: 400, s: 600 };
  const b = V ? { x: 540, y: 640, s: 640 } : L ? { x: 540, y: 540, s: 700 } : a;
  const m = E.move(seg(t, T.moveA, T.moveB));
  const push = 1 + 0.03 * E.drift(seg(t, 0, T.moveA)); // slow push-in during the ignition
  return { x: lerp(a.x, b.x, m), y: lerp(a.y, b.y, m), s: lerp(a.s * push, b.s, m) };
}
function heroFlame(t) {
  // ignition: flame grows from a bead to full with expo-out, plus a gentle 6% flare that relaxes
  const g = seg(t, T.igniteA, T.igniteB);
  const base = lerp(0.12, 1, E.bloom(g));
  const flare = 0.06 * Math.sin(Math.PI * seg(t, T.igniteA + 0.15, T.igniteA + 0.9));
  return g <= 0 ? 0 : base + flare;
}

// ------------------------------------------------------------------ S1 + S2: ignition and title
function shotCandle(t) {
  const alphaOut = 1 - E.exit(seg(t, T.titleOut, T.titleOut + 0.7));
  if (alphaOut <= 0) return;
  const hs = heroState(t);
  // follow-through: flame lags the move — skew against horizontal velocity, squash on vertical (delayed 0.12 s)
  const dt = 1 / 30, td = t - 0.12;
  const h0 = heroState(td - dt), h1 = heroState(td + dt);
  const vx = (h1.x - h0.x) / (2 * dt), vy = (h1.y - h0.y) / (2 * dt);
  const fl = flicker(t, 0);
  const light = E.light(seg(t, T.lightA, T.lightB)) * 0.98 + 0.02 * seg(t, T.lightA - 0.4, T.lightA);
  const p = drawIcon(hs.x, hs.y, hs.s, {
    light, flame: heroFlame(t), fl, alpha: alphaOut,
    skew: clamp(-vx / 1400, -0.25, 0.25), stretch: clamp(vy / 2600, -0.12, 0.12),
  });
  drawStrike(t, T.strike, p.wx, p.wy, p.k, alphaOut);
  drawEmbers(t, T.igniteA + 0.4, T.titleOut, (b) => {
    if (b < T.igniteA + 0.3) return null;
    const s = heroState(b); const k = s.s / 1024;
    return { x: s.x + (WICK.x - 512) * k, y: s.y + (WICK.y - 512 - 120) * k };
  }, { n: 22, seed: 7, scale: hs.s / 860, alpha: alphaOut });
}
function shotTitle(t) {
  if (t < T.title1 - 0.1 || t > T.titleOut + 1) return;
  const out = E.exit(seg(t, T.titleOut, T.titleOut + 0.6));
  const a = 1 - out, lift = -26 * out;
  ctx.save(); ctx.translate(0, lift);
  if (V) {
    setText(font('display', 116));
    revealLine('A thousand nights.', 540, 1135, { t, t0: T.title1, stagger: 0.05, dur: 1.0, align: 'center', alpha: a, blur: 14, rise: 22 });
    const lines = [['One ', 'story,'], ['one ', 'poem,'], ['one ', 'essay.']];
    setText(font('italic', 68));
    lines.forEach((ln, i) => {
      revealLine(ln.join(''), 540, 1262 + i * 88, { t, t0: T.title2 + i * 0.38, unit: 'word', stagger: 0.16, dur: 0.95, align: 'center', alpha: a, colors: [C.parch, C.amber], blur: 10, rise: 16 });
    });
  } else {
    const x = 980;
    setText(font('display', 92));
    revealLine('A thousand nights.', x, 470, { t, t0: T.title1, stagger: 0.05, dur: 1.0, alpha: a, blur: 14, rise: 20 });
    setText(font('italic', 60));
    [['One ', 'story,'], ['one ', 'poem,'], ['one ', 'essay.']].forEach((ln, i) => {
      revealLine(ln.join(''), x + 4, 590 + i * 76, { t, t0: T.title2 + i * 0.38, unit: 'word', stagger: 0.16, dur: 0.95, alpha: a, colors: [C.parch, C.amber], blur: 10, rise: 14 });
    });
  }
  ctx.restore();
}

// ------------------------------------------------------------------ S3: engraving plates
const PLATES = [
  { img: 'p1', id: 'henry-the-gift-of-the-magi', kind: 'A STORY', f0: [0.62, 0.38], f1: [0.46, 0.62], arc: [0.62, 0.62], z: [1.0, 1.1] },
  { img: 'p2', id: 'whitman-when-i-heard-the-learnd-astronomer', kind: 'A POEM', f0: [0.66, 0.66], f1: [0.52, 0.34], arc: [0.7, 0.42], z: [1.08, 1.0] },
  { img: 'p3', id: 'stevenson-el-dorado', kind: 'AN ESSAY', author: 'R. L. Stevenson', quote: 'To travel hopefully is a better thing than to arrive.', f0: [0.4, 0.66], f1: [0.66, 0.36], arc: [0.48, 0.42], z: [1.0, 1.1] },
];
function plateRect(i) {
  if (V) return { x: 0, y: 290, w: 1080, h: 740 };
  return i % 2 === 0 ? { x: 30, y: 120, w: 1260, h: 840 } : { x: 630, y: 120, w: 1260, h: 840 };
}
function quadBez(p0, p1, p2, u) { const a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u; return [a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1]]; }
function shotPlates(t) {
  PLATES.forEach((P, i) => {
    const s = T.plates[i], d = T.plateDur[i], u = t - s;
    if (u < 0 || u > d) return;
    const aIn = E.dissolve(seg(u, 0, 0.9)), aOut = 1 - E.dissolve(seg(u, d - 0.85, d));
    const a = aIn * aOut;
    const R = plateRect(i);
    // Ken Burns on an arc: focus point travels a quadratic Bezier, zoom eases
    const k = E.drift(seg(u, 0, d));
    const [fx, fy] = quadBez(P.f0, P.arc, P.f1, k);
    const z = lerp(P.z[0], P.z[1], k);
    const img = IMG[P.img];
    const base = Math.max(R.w / img.width, R.h / img.height) * 1.04;
    const sc = base * z;
    // keep the crop inside the image
    const vw = R.w / sc, vh = R.h / sc;
    const cxp = clamp(fx * img.width, vw / 2, img.width - vw / 2), cyp = clamp(fy * img.height, vh / 2, img.height - vh / 2);
    plateCtx.globalCompositeOperation = 'source-over';
    plateCtx.clearRect(0, 0, plateCanvas.width, plateCanvas.height);
    plateCtx.drawImage(img, cxp - vw / 2, cyp - vh / 2, vw, vh, 0, 0, R.w, R.h);
    plateCtx.globalCompositeOperation = 'destination-in';
    plateCtx.drawImage(PLATE_MASK, 0, 0);
    ctx.save(); ctx.globalAlpha = a;
    // tiny parallax drift of the plate itself vs. the type (overlapping action)
    const drift = (k - 0.5) * (V ? -14 : -18);
    ctx.drawImage(plateCanvas, R.x + (L ? drift : 0), R.y + (V ? drift : 0));
    ctx.restore();
    // foreground dust in front of the plate moves faster (parallax)
    // type leaves a beat before its picture (overlapping action)
    drawPlateText(P, i, u, d, 1 - E.dissolve(seg(u, d - 1.15, d - 0.4)));
  });
}
function drawPlateText(P, i, u, d, aOut) {
  const w = work(P.id);
  const quote = '“' + (P.quote || w.pull_quote) + '”';
  const label = `${P.kind}  ·  ${(P.author || w.author).toUpperCase()}`;
  const t0 = 0.45;
  if (V) {
    setText(font('caps', 28), 6.5);
    revealLine(label, 540 + 3, 1112, { t: u, t0, unit: 'word', stagger: 0.06, dur: 0.8, color: C.amber, align: 'center', alpha: aOut, blur: 6, rise: 8, spacing: 6.5 });
    setText(font('italic', 62));
    const lines = wrap(quote, 900, true);
    lines.forEach((ln, j) => revealLine(ln, 540, 1205 + j * 84, { t: u, t0: t0 + 0.2 + j * 0.14, unit: 'word', stagger: 0.07, dur: 0.9, align: 'center', alpha: aOut, blur: 10, rise: 14 }));
    setText(font('italic', 34));
    revealLine(w.title, 540, 1205 + lines.length * 84 + 34, { t: u, t0: t0 + 0.7, unit: 'word', stagger: 0.05, dur: 0.8, color: C.mute, align: 'center', alpha: aOut, blur: 6, rise: 8 });
  } else {
    const left = i % 2 === 0;
    const x = left ? 1360 : 120, maxW = 470;
    setText(font('italic', 54));
    const lines = wrap(quote, maxW, true);
    const blockH = 50 + lines.length * 72 + 60;
    const y0 = 540 - blockH / 2 + 20;
    setText(font('caps', 24), 5);
    revealLine(label, x, y0, { t: u, t0, unit: 'word', stagger: 0.06, dur: 0.8, color: C.amber, alpha: aOut, blur: 6, rise: 8 });
    setText(font('italic', 54));
    lines.forEach((ln, j) => revealLine(ln, x, y0 + 82 + j * 72, { t: u, t0: t0 + 0.2 + j * 0.14, unit: 'word', stagger: 0.07, dur: 0.9, alpha: aOut, blur: 10, rise: 12 }));
    setText(font('italic', 30));
    revealLine(w.title, x, y0 + 82 + lines.length * 72 + 22, { t: u, t0: t0 + 0.7, unit: 'word', stagger: 0.05, dur: 0.8, color: C.mute, alpha: aOut, blur: 6, rise: 8 });
  }
}

// ------------------------------------------------------------------ S4: the app in a phone
const SCR = { w: 1179, h: 2556 };
const BEZEL = 44, R_OUT = 190, R_IN = 148;
function rrect(c, x, y, w, h, r) { c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); }
function phoneBase() { return V ? { x: 540, y: 1012, s: 0.42 } : { x: 1330, y: 540, s: 0.345 }; }
/* Draw a phone at (cx,cy) scale s; drawScreen(ctx) paints in 1179×2556 screen space */
function drawPhone(cx, cy, s, alpha, dim, drawScreen) {
  const fw = SCR.w + BEZEL * 2, fh = SCR.h + BEZEL * 2;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(cx, cy); ctx.scale(s, s); ctx.translate(-fw / 2, -fh / 2);
  // shadow + body
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,0.55)'; ctx.shadowBlur = 140; ctx.shadowOffsetY = 50;
  rrect(ctx, 0, 0, fw, fh, R_OUT); ctx.fillStyle = '#0C0C0E'; ctx.fill(); ctx.restore();
  rrect(ctx, 1.5, 1.5, fw - 3, fh - 3, R_OUT); ctx.lineWidth = 6; ctx.strokeStyle = '#46464C'; ctx.stroke();
  // warm rim light on the left edge — the candle is "off-screen left"
  const rim = ctx.createLinearGradient(0, 0, fw, 0);
  rim.addColorStop(0, 'rgba(232,183,106,0.30)'); rim.addColorStop(0.2, 'rgba(232,183,106,0)');
  rrect(ctx, 1.5, 1.5, fw - 3, fh - 3, R_OUT); ctx.strokeStyle = rim; ctx.lineWidth = 6; ctx.stroke();
  // screen
  ctx.save();
  ctx.translate(BEZEL, BEZEL);
  rrect(ctx, 0, 0, SCR.w, SCR.h, R_IN); ctx.clip();
  drawScreen();
  drawStatusBar();
  if (dim > 0) { ctx.fillStyle = rgba([8, 9, 14], dim); ctx.fillRect(0, 0, SCR.w, SCR.h); }
  ctx.restore();
  ctx.restore();
}
function drawStatusBar() {
  const fg = C.parch;
  ctx.save();
  ctx.fillStyle = fg; ctx.font = '500 46px NR'; ctx.letterSpacing = '0px'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText('9:41', 150, 84);
  ctx.fillStyle = '#000'; rrect(ctx, SCR.w / 2 - 190, 36, 380, 104, 52); ctx.fill();
  const x = SCR.w - 300; ctx.fillStyle = fg;
  [14, 20, 26, 32].forEach((h, i) => { rrect(ctx, x + i * 14, 100 - h, 9, h, 2); ctx.fill(); });
  ctx.beginPath(); ctx.moveTo(SCR.w - 195, 108); ctx.arc(SCR.w - 195, 108, 34, Math.PI * 1.25, Math.PI * 1.75); ctx.closePath(); ctx.fill();
  ctx.strokeStyle = fg; ctx.lineWidth = 3; rrect(ctx, SCR.w - 150, 70, 74, 34, 9); ctx.stroke();
  rrect(ctx, SCR.w - 145, 75, 64, 24, 6); ctx.fill();
  ctx.globalAlpha *= 0.9; rrect(ctx, SCR.w / 2 - 210, SCR.h - 32, 420, 12, 6); ctx.fill();
  ctx.restore();
}
function appBG() { ctx.fillStyle = C.navy; ctx.fillRect(0, 0, SCR.w, SCR.h); }
// slice a screenshot into horizontal bands that settle in, staggered
function drawBands(img, bands, t) {
  for (const b of bands) {
    const p = seg(t, b.t, b.t + (b.d || 1.0));
    if (p <= 0) continue;
    const e = E.settle(p), a = E.dissolve(clamp(p * 1.7));
    const dy = (1 - e) * (b.dy ?? 90);
    ctx.save(); ctx.globalAlpha *= a;
    ctx.drawImage(img, 0, b.y0, SCR.w, b.y1 - b.y0, 0, b.y0 + dy, SCR.w, b.y1 - b.y0);
    ctx.restore();
  }
}
function scrTonight(t) {
  appBG();
  const A = T.phoneIn + 0.2;
  drawBands(IMG.tonight, [
    { y0: 220, y1: 400, t: A },
    { y0: 460, y1: 650, t: A + 0.12 },
    { y0: 670, y1: 1275, t: A + 0.3, dy: 140 },
    { y0: 1275, y1: 1880, t: A + 0.46, dy: 140 },
    { y0: 1880, y1: 2261, t: A + 0.62, dy: 140 },
    { y0: 2261, y1: 2556, t: A + 0.05, dy: 0, d: 0.7 },
  ], t);
}
// ---- reader: real screenshot + continuation set in the same face/size, scrolled under a fixed header
const RD = { left: 79, maxW: 1022, size: 54, lead: 90, para: 62, ribbonX: 1130.5, ribbonY0: 349, ribbonY1: 2381, scroll: 760 };
function layoutReaderContinuation() {
  const w = work('wilde-the-nightingale-and-the-rose');
  const paras = w.text_md.split(/\n\n+/);
  const start = paras.findIndex((p) => p.startsWith('“Here at last is a true lover'));
  ctx.save(); setText(`400 ${RD.size}px NR`);
  const out = [];
  for (let k = start; k < start + 3; k++) out.push(wrap(paras[k].replace(/\s+/g, ' '), RD.maxW));
  ctx.restore();
  readerCont = out; // [ [lines of para], ... ]
}
function scrReader(t) {
  appBG();
  const A = T.rdA;
  const sp = E.move(seg(t, A + 0.4, A + 3.0));
  const S = sp * RD.scroll;
  ctx.save();
  ctx.beginPath(); ctx.rect(0, 300, SCR.w, SCR.h - 300); ctx.clip();
  ctx.translate(0, -S);
  ctx.drawImage(IMG.readerNR, 0, 300, SCR.w, SCR.h - 300, 0, 300, SCR.w, SCR.h - 300);
  // highlight pulse on the passage that becomes the share card
  const hp = Math.sin(Math.PI * seg(t, A + 0.7, A + 2.4));
  if (hp > 0) {
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = `rgba(232,183,106,${(0.13 * hp).toFixed(3)})`;
    ctx.fillRect(74, 1656, 986, 89); ctx.fillRect(74, 1748, 198, 85);
    ctx.restore();
  }
  // continuation (first two lines of the paragraph are already in the screenshot)
  setText(`400 ${RD.size}px NR`); ctx.fillStyle = C.parch;
  let y = 2413 + RD.lead; // baseline of the line after "sung of him, though I knew him not:"
  readerCont.forEach((lines, pi) => {
    lines.forEach((ln, li) => {
      if (pi === 0 && li < 3) return;
      ctx.fillText(ln, RD.left, y); y += RD.lead;
    });
    y += RD.para;
  });
  ctx.restore();
  // bottom safe-area fade (home indicator)
  const gb = ctx.createLinearGradient(0, SCR.h - 190, 0, SCR.h - 40);
  gb.addColorStop(0, 'rgba(18,21,31,0)'); gb.addColorStop(1, C.navy);
  ctx.fillStyle = gb; ctx.fillRect(0, SCR.h - 190, SCR.w, 190);
  // fixed header with a soft fade where text slides under it
  const g = ctx.createLinearGradient(0, 300, 0, 400);
  g.addColorStop(0, C.navy); g.addColorStop(1, 'rgba(18,21,31,0)');
  ctx.fillStyle = g; ctx.fillRect(0, 300, SCR.w, 100);
  ctx.drawImage(IMG.reader, 0, 0, SCR.w, 300, 0, 0, SCR.w, 300);
  // amber ribbon: track + progress + bead (time-lapse: a whole story's progress in 3 s)
  const rp = E.move(seg(t, A + 0.3, A + 3.1));
  const y1 = lerp(RD.ribbonY0, RD.ribbonY1, rp);
  ctx.fillStyle = 'rgba(232,183,106,0.24)'; ctx.fillRect(RD.ribbonX - 2, RD.ribbonY0, 4, RD.ribbonY1 - RD.ribbonY0);
  ctx.fillStyle = C.amber; ctx.fillRect(RD.ribbonX - 2, RD.ribbonY0, 4, y1 - RD.ribbonY0);
  const gl = ctx.createRadialGradient(RD.ribbonX, y1, 0, RD.ribbonX, y1, 40);
  gl.addColorStop(0, 'rgba(232,183,106,0.45)'); gl.addColorStop(1, 'rgba(232,183,106,0)');
  ctx.fillStyle = gl; ctx.fillRect(RD.ribbonX - 40, y1 - 40, 80, 80);
  ctx.fillStyle = C.amber; ctx.beginPath(); ctx.arc(RD.ribbonX, y1, 10, 0, 7); ctx.fill();
}
// ---- night complete: candle lights (same ember→flame language as the opening), then type and dots
const NC = { ox: 290, oy: 330, base: { x: 590, y: 694 }, dots: [204, 333, 462, 590, 718, 846, 973], dotY: 1746 };
function scrComplete(t) {
  appBG();
  const A = T.cmpA;
  ctx.drawImage(IMG.ncUnlit, NC.ox, NC.oy);
  const strike = A + 0.75;
  const fl = flicker(t, 3);
  const f = seg(t, strike, strike + 0.8);
  if (f > 0) {
    const s = lerp(0.15, 1, E.bloom(f)) * (1 + 0.04 * fl);
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = clamp(f * 2.5);
    ctx.translate(NC.base.x, NC.base.y);
    ctx.transform(1, 0, 0.03 * fl, 1, 0, 0);
    ctx.scale(lerp(0.4, 1, E.bloom(f)) * (1 - 0.02 * fl), s);
    ctx.drawImage(IMG.ncFlame, NC.ox - NC.base.x, NC.oy - NC.base.y);
    ctx.restore();
  }
  // ember breath before the light
  const pre = E.anticip(seg(t, strike - 0.45, strike)) * (1 - seg(t, strike, strike + 0.25));
  if (pre > 0) {
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    const g = ctx.createRadialGradient(590, 680, 0, 590, 680, 40);
    g.addColorStop(0, `rgba(255,214,150,${0.9 * pre})`); g.addColorStop(1, 'rgba(240,140,60,0)');
    ctx.fillStyle = g; ctx.fillRect(540, 630, 100, 100); ctx.restore();
  }
  drawBands(IMG.complete, [
    { y0: 990, y1: 1170, t: strike + 0.35, dy: 50 },
    { y0: 1220, y1: 1410, t: strike + 0.55, dy: 40 },
    { y0: 1430, y1: 1495, t: strike + 0.7, dy: 30 },
    { y0: 2120, y1: 2345, t: strike + 0.95, dy: 30 },
  ], t);
  // week dots: grey row appears, then each lights in turn
  const rowA = E.dissolve(seg(t, strike + 0.6, strike + 1.0));
  if (rowA > 0) {
    ctx.save(); ctx.globalAlpha = rowA;
    ctx.drawImage(IMG.ncDots, 150, 1720);
    ctx.drawImage(IMG.complete, 150, 1785, 880, 60, 150, 1785, 880, 60); // S M T W T F S
    NC.dots.forEach((x, i) => {
      const p = E.out(seg(t, strike + 0.9 + i * 0.09, strike + 1.25 + i * 0.09));
      if (p <= 0) return;
      ctx.save(); ctx.beginPath(); ctx.arc(x, NC.dotY, 26 * p, 0, 7); ctx.clip();
      ctx.drawImage(IMG.complete, x - 30, NC.dotY - 30, 60, 60, x - 30, NC.dotY - 30, 60, 60); ctx.restore();
      const gp = Math.sin(Math.PI * p);
      ctx.save(); ctx.globalCompositeOperation = 'lighter';
      const g = ctx.createRadialGradient(x, NC.dotY, 0, x, NC.dotY, 60); g.addColorStop(0, `rgba(232,183,106,${0.35 * gp})`); g.addColorStop(1, 'rgba(232,183,106,0)');
      ctx.fillStyle = g; ctx.fillRect(x - 60, NC.dotY - 60, 120, 120); ctx.restore();
    });
    ctx.restore();
  }
}
// ---- journey: stars light one by one along the constellation
const JR = { ox: 100, oy: 860, stars: [[236, 918], [236, 1027], [163, 1115], [153, 1180], [215, 1235], [298, 1257], [340, 1333]], label: [380, 1310, 250, 40] };
function scrJourney(t) {
  ctx.drawImage(IMG.journey, 0, 0);
  ctx.drawImage(IMG.journeyUnlit, JR.ox, JR.oy);
  const A = T.jrnA + 0.55;
  const st = JR.stars;
  ctx.save();
  ctx.beginPath();
  st.forEach(([x, y], i) => {
    const p = E.bloom(seg(t, A + i * 0.3, A + i * 0.3 + 0.5));
    if (p > 0) { ctx.moveTo(x + 64 * p, y); ctx.arc(x, y, 64 * p, 0, Math.PI * 2); }
  });
  // segments draw from star i to i+1 between their lightings (slow in/out along the line)
  for (let i = 0; i < st.length - 1; i++) {
    const p = E.move(seg(t, A + i * 0.3 + 0.05, A + (i + 1) * 0.3 + 0.02));
    if (p <= 0) continue;
    const [x0, y0] = st[i], [x1, y1] = st[i + 1];
    const xe = lerp(x0, x1, p), ye = lerp(y0, y1, p);
    const nx = -(y1 - y0), ny = x1 - x0, nl = Math.hypot(nx, ny), hw = 12;
    ctx.moveTo(x0 + nx / nl * hw, y0 + ny / nl * hw); ctx.lineTo(xe + nx / nl * hw, ye + ny / nl * hw);
    ctx.lineTo(xe - nx / nl * hw, ye - ny / nl * hw); ctx.lineTo(x0 - nx / nl * hw, y0 - ny / nl * hw); ctx.closePath();
  }
  const lp = E.out(seg(t, A + 6 * 0.3 + 0.35, A + 6 * 0.3 + 1.0));
  if (lp > 0) { const [lx, ly, lw, lh] = JR.label; ctx.rect(lx, ly, lw * lp, lh); }
  ctx.clip();
  ctx.drawImage(IMG.journey, JR.ox, JR.oy, 600, 540, JR.ox, JR.oy, 600, 540);
  ctx.restore();
  // a soft bloom as each star catches
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  st.forEach(([x, y], i) => {
    const p = seg(t, A + i * 0.3, A + i * 0.3 + 0.9);
    if (p <= 0 || p >= 1) return;
    const a = Math.sin(Math.PI * Math.sqrt(p)) * (i === 6 ? 0.6 : 0.42);
    const r = (i === 6 ? 120 : 80) * (0.6 + 0.4 * E.out(p));
    const g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, `rgba(255,220,160,${a})`); g.addColorStop(1, 'rgba(232,183,106,0)');
    ctx.fillStyle = g; ctx.fillRect(x - r, y - r, 2 * r, 2 * r);
  });
  ctx.restore();
}

// captions beside/above the phone
const CAPS = [
  { t0: T.phoneIn + 0.45, t1: T.rdA + 0.2, label: 'TONIGHT', text: 'Every night, three short readings.' },
  { t0: T.rdA + 0.4, t1: T.cmpA + 0.15, label: 'THE READER', text: 'Read by candlelight.' },
  { t0: T.cmpA + 0.4, t1: T.jrnA + 0.15, label: 'NIGHT COMPLETE', text: 'Finish, and light a candle.' },
  { t0: T.jrnA + 0.4, t1: T.shrA + 0.25, label: 'YOUR JOURNEY', text: 'Watch your nights become a constellation.' },
  { t0: T.shrA + 0.45, t1: T.appOut + 0.35, label: 'SHARE', text: 'Keep the lines that stay with you.' },
];
function drawCaptions(t) {
  for (const c of CAPS) {
    if (t < c.t0 - 0.05 || t > c.t1 + 0.6) continue;
    const out = E.exit(seg(t, c.t1, c.t1 + 0.45));
    const a = 1 - out;
    ctx.save(); ctx.translate(0, -14 * out);
    if (V) {
      setText(font('caps', 26), 6);
      revealLine(c.label, 543, 262, { t, t0: c.t0, unit: 'word', stagger: 0.06, dur: 0.7, color: C.amber, align: 'center', alpha: a, blur: 6, rise: 8, spacing: 6 });
      setText(font('display', 56));
      const lines = wrap(c.text, 960, true);
      lines.forEach((ln, j) => revealLine(ln, 540, 338 + j * 64, { t, t0: c.t0 + 0.12 + j * 0.12, unit: 'word', stagger: 0.07, dur: 0.85, align: 'center', alpha: a, blur: 10, rise: 12 }));
    } else {
      const x = 360;
      setText(font('display', 76));
      const lines = wrap(c.text, 640, true);
      const y0 = 540 - (lines.length * 84) / 2 + 30;
      setText(font('caps', 24), 5);
      revealLine(c.label, x, y0 - 34, { t, t0: c.t0, unit: 'word', stagger: 0.06, dur: 0.7, color: C.amber, alpha: a, blur: 6, rise: 8 });
      setText(font('display', 76));
      lines.forEach((ln, j) => revealLine(ln, x, y0 + 54 + j * 84, { t, t0: c.t0 + 0.12 + j * 0.12, unit: 'word', stagger: 0.07, dur: 0.85, alpha: a, blur: 10, rise: 12 }));
    }
    ctx.restore();
  }
}
function shotApp(t) {
  if (t < T.phoneIn || t > T.appOut + 1.0) return;
  const pb = phoneBase();
  const pin = E.settle(seg(t, T.phoneIn, T.phoneIn + 1.2));
  const pa = E.dissolve(seg(t, T.phoneIn, T.phoneIn + 0.6));
  const out = E.exit(seg(t, T.appOut, T.appOut + 0.7));
  // share beat: phone recedes and (landscape) steps aside for the card
  const rec = E.move(seg(t, T.shrA, T.shrA + 0.9));
  const push = 1 + 0.035 * E.drift(seg(t, T.rdA, T.cmpA + 0.3)) - 0.035 * E.move(seg(t, T.cmpA, T.cmpA + 0.8));
  const s = pb.s * push * lerp(1, 0.93, rec);
  const x = pb.x + (L ? lerp(0, -70, rec) : 0);
  const y = pb.y + (1 - pin) * (V ? 340 : 260) - 30 * out + (V ? lerp(0, -40, rec) : 0);
  drawPhone(x, y, s, pa * (1 - out), 0.55 * rec, () => {
    const x1 = E.dissolve(seg(t, T.rdA, T.rdA + 0.45));
    const x2 = E.dissolve(seg(t, T.cmpA, T.cmpA + 0.45));
    const x3 = E.dissolve(seg(t, T.jrnA, T.jrnA + 0.45));
    if (x1 < 1) scrTonight(t);
    if (x1 > 0 && x2 < 1) { ctx.save(); ctx.globalAlpha *= x1; scrReader(t); ctx.restore(); }
    if (x2 > 0 && x3 < 1) { ctx.save(); ctx.globalAlpha *= x2; scrComplete(t); ctx.restore(); }
    if (x3 > 0) { ctx.save(); ctx.globalAlpha *= x3; scrJourney(t); ctx.restore(); }
  });
  drawShareCard(t, out);
  drawCaptions(t);
}
function drawShareCard(t, out) {
  const p = seg(t, T.shrA + 0.1, T.shrA + 1.25);
  if (p <= 0) return;
  const e = E.settle(p);
  const rot = (1 - E.settle(seg(t, T.shrA + 0.1, T.shrA + 1.6))) * -2.4 * Math.PI / 180; // rotation settles later: follow-through
  const img = IMG.shareHL;
  const s = V ? 0.7 : 0.53;
  const cx = V ? 540 : 1560, cy = (V ? 1010 : 540) + (1 - e) * (V ? 760 : 620) - 30 * out;
  const w = img.width * s, h = img.height * s;
  ctx.save();
  ctx.globalAlpha = E.dissolve(clamp(p * 2.2)) * (1 - out);
  ctx.translate(cx, cy); ctx.rotate(rot);
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 80; ctx.shadowOffsetY = 30 + 20 * (1 - e);
  rrect(ctx, -w / 2, -h / 2, w, h, 26); ctx.fillStyle = C.navy; ctx.fill(); ctx.restore();
  ctx.save(); rrect(ctx, -w / 2, -h / 2, w, h, 26); ctx.clip(); ctx.drawImage(img, -w / 2, -h / 2, w, h); ctx.restore();
  rrect(ctx, -w / 2 + 1, -h / 2 + 1, w - 2, h - 2, 26); ctx.strokeStyle = 'rgba(232,183,106,0.22)'; ctx.lineWidth = 2; ctx.stroke();
  ctx.restore();
}

// ------------------------------------------------------------------ S5: end card
function endLayout() {
  if (V) return { icon: { x: 540, y: 690, s: 720 }, word: [543, 1088, 'center'], l1: [540, 1206], l2: [540, 1286], cs: [543, 1418], align: 'center' };
  if (L) return { icon: { x: 600, y: 540, s: 700 }, word: [1010, 402, 'left'], l1: [1006, 520], l2: [1010, 596], cs: [1010, 712], align: 'left' };
  return { icon: { x: 540, y: 372, s: 580 }, word: [543, 735, 'center'], l1: [540, 852], l2: [540, 922], cs: [543, 1000], align: 'center' };
}
function shotEnd(t) {
  if (!SQ && t < T.end) return;
  const A = SQ ? -100 : T.end, S = SQ ? -100 : T.endStrike;
  const Lo = endLayout();
  const fl = flicker(t, 9, SQ ? DURATION : 0);
  const appear = SQ ? 1 : E.dissolve(seg(t, A, A + 0.6));
  const light = SQ ? 1 : E.bloom(seg(t, S + 0.05, S + 1.6));
  const flame = SQ ? 1 : (seg(t, S, S + 0.9) > 0 ? lerp(0.12, 1, E.bloom(seg(t, S, S + 0.9))) : 0);
  const push = SQ ? 1 : 1 + 0.025 * E.drift(seg(t, A, DURATION));
  const p = drawIcon(Lo.icon.x, Lo.icon.y, Lo.icon.s * push, { light: 0.06 + 0.94 * light, flame, fl, alpha: appear });
  if (!SQ) drawStrike(t, S, p.wx, p.wy, p.k, appear);
  drawEmbers(t, S + 0.5, DURATION, (b) => (SQ || b > S + 0.4) ? { x: p.wx, y: p.wy - 120 * p.k } : null,
    { n: SQ ? 14 : 18, seed: 19, scale: Lo.icon.s / 860, loop: SQ ? DURATION : 0 });
  const tt = SQ ? 99 : t;
  // wordmark: letters arrive with tracking that settles inwards (spacing eases from wide to final)
  const tr = SQ ? 1 : E.out(seg(t, A + 0.8, A + 2.2));
  const wsz = V ? 58 : L ? 54 : 50;
  const spacing = wsz * lerp(0.62, 0.34, tr);
  setText(font('caps', wsz), spacing);
  const [wx, wy, wal] = Lo.word;
  const wa = SQ ? 1 : E.dissolve(seg(t, A + 0.8, A + 1.6));
  ctx.save(); ctx.globalAlpha = wa;
  const ww = textW('1000 NIGHTS') - spacing;
  ctx.fillStyle = C.amber; ctx.fillText('1000 NIGHTS', wal === 'center' ? wx - ww / 2 : wx, wy);
  ctx.restore();
  // hairline rule under the wordmark draws out from the centre
  const rl = SQ ? 1 : E.move(seg(t, A + 1.3, A + 2.2));
  if (rl > 0) {
    ctx.fillStyle = 'rgba(232,183,106,0.55)';
    const rw = 90 * rl;
    if (wal === 'center') ctx.fillRect(wx - rw / 2, wy + (V ? 40 : 34), rw, 2); else ctx.fillRect(wx, wy + 32, rw, 2);
  }
  const al = Lo.align;
  setText(font('display', V ? 78 : L ? 76 : 64));
  if (SQ) drawLineStatic('A thousand nights.', Lo.l1[0], Lo.l1[1], C.parch, al);
  else revealLine('A thousand nights.', Lo.l1[0], Lo.l1[1] + (V ? 14 : 0), { t: tt, t0: A + 1.35, unit: 'word', stagger: 0.12, dur: 0.95, align: al, blur: 10, rise: 14 });
  setText(font('italic', V ? 50 : L ? 48 : 44));
  const l2 = ['One ', 'story, ', 'one ', 'poem, ', 'one ', 'essay.'];
  if (SQ) {
    // teaser: the three nouns glow amber in turn, one per third of the loop (seamless)
    let x = Lo.l2[0] - textW(l2.join('')) / 2;
    l2.forEach((w, i) => {
      const n = Math.floor(i / 2);
      const ph = (t / DURATION) * 3 - n;               // which third we're in
      const glow = i % 2 ? Math.max(0, Math.sin(Math.PI * clamp(ph))) : 0;
      const col = [lerp(239, 232, glow), lerp(230, 183, glow), lerp(214, 106, glow)];
      ctx.fillStyle = rgba(col, 1); ctx.fillText(w, x, Lo.l2[1]); x += textW(w);
    });
  } else {
    revealLine(l2.join(''), Lo.l2[0], Lo.l2[1] + (V ? 14 : 0), { t: tt, t0: A + 1.75, unit: 'word', stagger: 0.12, dur: 0.95, align: al, colors: [C.parch, C.amber, C.parch, C.amber, C.parch, C.amber], blur: 10, rise: 12 });
  }
  setText(font('caps', V ? 28 : L ? 24 : 24), V ? 6.5 : 5.5);
  if (!SQ) revealLine('COMING SOON TO IPHONE', Lo.cs[0], Lo.cs[1] + (V ? 14 : 0), { t: tt, t0: A + 2.5, unit: 'word', stagger: 0.1, dur: 0.9, color: 'rgba(239,230,214,0.7)', align: al, blur: 6, rise: 8, spacing: V ? 6.5 : 5.5 });
  else revealLine('COMING SOON TO IPHONE', Lo.cs[0], Lo.cs[1], { t: 99, t0: 0, unit: 'word', color: 'rgba(239,230,214,0.7)', align: al, spacing: 5.5 });
}

// ------------------------------------------------------------------ frame
function starAlphaAt(t) {
  if (SQ) return 0.7;
  let a = 0.75;
  a *= 1 - 0.55 * E.dissolve(seg(t, T.plates[0], T.plates[0] + 1)) * (1 - E.dissolve(seg(t, T.phoneIn, T.phoneIn + 1)));
  return a;
}
window.renderFrame = function (t) {
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over'; ctx.filter = 'none';
  // slow global parallax drift for stars/dust
  const parX = SQ ? 0 : -t * (L ? 6 : 3), parY = SQ ? 0 : t * 2;
  drawBackground(t, starAlphaAt(t), parX, parY);
  if (SQ) {
    shotEnd(t);
  } else {
    shotCandle(t);
    shotTitle(t);
    shotPlates(t);
    shotApp(t);
    shotEnd(t);
  }
  // foreground dust: a touch faster than the stars (parallax), warmer near candle shots
  const inPlates = !SQ && t > T.plates[0] && t < T.phoneIn + 0.5;
  drawDust(t, inPlates ? 1.0 : 0.7, parX * 3 + (inPlates ? -t * 10 : 0), parY * 2, 0.4);
  // fade to night at the very end (loops back into the dark opening)
  if (!SQ) {
    const fo = E.dissolve(seg(t, T.fadeOut, DURATION));
    const fi = 1 - seg(t, 0, 0.4);
    const a = Math.max(fo, fi);
    if (a > 0) { ctx.fillStyle = rgba(C.navyRGB, a); ctx.fillRect(0, 0, W, H); }
  }
  finish(t);
};

// ------------------------------------------------------------------ preview
window.ready.then(() => {
  const t0 = parseFloat(Q.get('t') || '0');
  window.renderFrame(t0);
  if (Q.get('play')) {
    const sc = document.getElementById('scrub'); sc.style.display = 'block'; sc.max = DURATION;
    let start = null;
    const loop = (now) => { if (start === null) start = now; const t = ((now - start) / 1000) % DURATION; sc.value = t; window.renderFrame(t); requestAnimationFrame(loop); };
    requestAnimationFrame(loop);
  }
}).catch((e) => { document.title = 'ERROR ' + e.message; console.error(e); });
