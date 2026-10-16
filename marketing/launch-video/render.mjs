#!/usr/bin/env node
/* Render the 1000 Nights launch film frame by frame.
 *
 *   node marketing/launch-video/render.mjs                 # everything: 9x16, 16x9, 1x1 + posters
 *   node marketing/launch-video/render.mjs --fmt 16x9      # one cut
 *   node marketing/launch-video/render.mjs --fmt 9x16 --stills 1.2,4.5,30   # PNG stills only
 *   node marketing/launch-video/render.mjs --contact        # 12-frame contact sheets per cut
 *
 * Frames go to $FRAMES_DIR (default: the session scratchpad below), never into the repo.
 * Time is stepped as t = frame / 30 and handed to window.renderFrame(t): no wall clock.
 */
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); } catch { ({ chromium } = require('/opt/node22/lib/node_modules/playwright')); }

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '../..');
const FRAMES_DIR = process.env.FRAMES_DIR || '/tmp/claude-0/-home-user-reading-1000-nights/cb96545e-a1a1-5d9b-9bac-1f2f794dcc8c/scratchpad/video-frames';
const FPS = 30;
const OUT = {
  '9x16': { file: '1000-nights-launch-9x16.mp4', poster: 'poster-9x16.png', posterT: 38.4 },
  '16x9': { file: '1000-nights-launch-16x9.mp4', poster: 'poster-16x9.png', posterT: 38.4 },
  '1x1': { file: '1000-nights-teaser-1x1.mp4', poster: null },
};
const SIZES = { '9x16': [1080, 1920], '16x9': [1920, 1080], '1x1': [1080, 1080] };

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? (args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true) : d; };
const fmts = opt('fmt', 'all') === 'all' ? ['9x16', '16x9', '1x1'] : String(opt('fmt')).split(',');
const workers = parseInt(opt('workers', '4'), 10);
const stills = opt('stills', null);
const contact = opt('contact', false);
const noAudio = opt('no-audio', false);

// ---- tiny static server rooted at the repo (read-only)
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.png': 'image/png', '.webp': 'image/webp', '.ttf': 'font/ttf' };
const server = http.createServer((req, res) => {
  const p = path.join(REPO, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  if (!p.startsWith(REPO) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(p)] || 'application/octet-stream' });
  fs.createReadStream(p).pipe(res);
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const PORT = server.address().port;

const browser = await chromium.launch({ args: ['--disable-gpu', '--font-render-hinting=none', '--force-color-profile=srgb'] });

async function openPage(fmt) {
  const [w, h] = SIZES[fmt];
  const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
  page.on('pageerror', (e) => console.error('[page]', e.message));
  await page.goto(`http://127.0.0.1:${PORT}/marketing/launch-video/src/index.html?fmt=${fmt}`);
  await page.evaluate(() => window.ready);
  return page;
}
// Lossless PNG straight from the compositor; optimizeForSpeed uses fast zlib (about 6x faster than page.screenshot)
async function shoot(page, t, file) {
  await page.evaluate((tt) => window.renderFrame(tt), t);
  if (!page.__cdp) page.__cdp = await page.context().newCDPSession(page);
  const { data } = await page.__cdp.send('Page.captureScreenshot', { format: 'png', optimizeForSpeed: true });
  fs.writeFileSync(file, Buffer.from(data, 'base64'));
}

function sh(cmd, a) {
  const r = spawnSync(cmd, a, { stdio: 'inherit' });
  if (r.status !== 0) throw new Error(`${cmd} failed`);
}

async function renderStills(fmt, times, dir) {
  fs.mkdirSync(dir, { recursive: true });
  const page = await openPage(fmt);
  const files = [];
  for (const t of times) { const f = path.join(dir, `${fmt}_t${t.toFixed(2)}.png`); await shoot(page, t, f); files.push(f); }
  await page.close();
  return files;
}

async function renderCut(fmt) {
  const dir = path.join(FRAMES_DIR, fmt);
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  const probe = await openPage(fmt);
  const duration = await probe.evaluate(() => window.DURATION);
  const cues = await probe.evaluate(() => window.CUES);
  await probe.close();
  const N = Math.round(duration * FPS);
  console.log(`[${fmt}] ${N} frames @ ${FPS} fps → ${dir}`);
  const t0 = Date.now();
  let done = 0;
  await Promise.all(Array.from({ length: workers }, async (_, w) => {
    const page = await openPage(fmt);
    for (let i = w; i < N; i += workers) {
      await shoot(page, i / FPS, path.join(dir, `f_${String(i).padStart(5, '0')}.png`));
      if (++done % 100 === 0) console.log(`  ${done}/${N}  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
    }
    await page.close();
  }));
  // ambient bed (synthesised, see tools/synth_audio.py)
  let audio = null;
  if (!noAudio && cues.length) {
    audio = path.join(FRAMES_DIR, `${fmt}-ambient.wav`);
    fs.writeFileSync(path.join(FRAMES_DIR, `${fmt}-cues.json`), JSON.stringify({ duration, cues }));
    sh('python3', [path.join(HERE, 'tools/synth_audio.py'), path.join(FRAMES_DIR, `${fmt}-cues.json`), audio]);
  }
  const out = path.join(HERE, OUT[fmt].file);
  const a = ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', path.join(dir, 'f_%05d.png')];
  if (audio) a.push('-i', audio);
  a.push('-vf', 'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', fmt === '1x1' ? '17' : '18', '-tune', 'film',
    '-profile:v', 'high', '-level', '4.2', '-pix_fmt', 'yuv420p',
    '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv',
    '-r', String(FPS), '-g', String(FPS * 2));
  if (audio) a.push('-c:a', 'aac', '-b:a', '160k', '-shortest');
  a.push('-movflags', '+faststart', out);
  sh('ffmpeg', a);
  console.log(`[${fmt}] wrote ${out}`);
  if (OUT[fmt].poster) {
    const fi = Math.round(OUT[fmt].posterT * FPS);
    fs.copyFileSync(path.join(dir, `f_${String(fi).padStart(5, '0')}.png`), path.join(HERE, OUT[fmt].poster));
    console.log(`[${fmt}] wrote ${OUT[fmt].poster}`);
  }
}

try {
  if (stills) {
    for (const fmt of fmts) {
      const times = String(stills).split(',').map(Number);
      const files = await renderStills(fmt, times, path.join(FRAMES_DIR, '..', 'stills'));
      console.log(files.join('\n'));
    }
  } else if (contact) {
    for (const fmt of fmts) {
      const dur = fmt === '1x1' ? 7 : 39.5;
      const times = fmt === '1x1' ? [0, 0.6, 1.2, 1.8, 2.4, 3, 3.6, 4.2, 4.8, 5.4, 6, 6.6]
        : [1.0, 2.6, 7.6, 11.6, 15.0, 19.0, 22.2, 25.0, 28.2, 31.2, 33.6, 38.0];
      const dir = path.join(FRAMES_DIR, '..', 'contact', fmt);
      fs.rmSync(dir, { recursive: true, force: true });
      const files = await renderStills(fmt, times, dir);
      const sheet = path.join(FRAMES_DIR, '..', `contact-${fmt}.png`);
      sh('python3', [path.join(HERE, 'tools/contact_sheet.py'), sheet, ...files]);
      console.log('contact sheet', sheet, 'duration', dur);
    }
  } else {
    for (const fmt of fmts) await renderCut(fmt);
  }
} finally {
  await browser.close();
  server.close();
}
