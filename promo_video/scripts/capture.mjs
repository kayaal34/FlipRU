// FlipRU web sürümünden telefon boyutunda ekran görüntüsü alır.
//
//   node scripts/capture.mjs steps.json
//
// steps.json: [{"click":[x,y]}, {"wait":800}, {"shot":"ad"},
//              {"wheel":[x,y,dy]}, {"key":"Escape"}, {"move":[x,y]},
//              {"semantics":true}, {"clickText":"н"}]
// Koordinatlar CSS pikseli (412x892 görünüm).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const ROOT = 'C:/FlipRU/build/web';
const OUT = path.resolve('public/shots');
const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.ttf': 'font/ttf', '.otf': 'font/otf', '.css': 'text/css', '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
};

const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const f = path.join(ROOT, p);
  if (!f.startsWith(path.normalize(ROOT)) || !fs.existsSync(f)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
});
await new Promise((r) => server.listen(8765, r));

// PowerShell'in yazdığı dosyalar BOM ile başlayabiliyor.
const steps = JSON.parse(fs.readFileSync(process.argv[2], 'utf8').replace(/^\uFEFF/, ''));
fs.mkdirSync(OUT, { recursive: true });

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: true,
  args: ['--lang=tr-TR', '--font-render-hinting=none'],
});
const page = await browser.newPage();
await page.setViewport({ width: 412, height: 892, deviceScaleFactor: 3, isMobile: false, hasTouch: false });
await page.goto('http://localhost:8765/', { waitUntil: 'networkidle0', timeout: 120000 });
await new Promise((r) => setTimeout(r, 6000));

for (const s of steps) {
  if (s.click) await page.mouse.click(s.click[0], s.click[1]);
  if (s.wheel) { await page.mouse.move(s.wheel[0], s.wheel[1]); await page.mouse.wheel({ deltaY: s.wheel[2] }); }
  if (s.move) await page.mouse.move(s.move[0], s.move[1]);
  if (s.key) await page.keyboard.press(s.key);
  // Flutter erişilebilirlik ağacını açar; ardından metinle tıklanabilir.
  if (s.semantics) await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  if (s.clickText) {
    const box = await page.evaluate((txt) => {
      const els = [...document.querySelectorAll('flt-semantics, [role]')];
      const el = els.find((e) => (e.getAttribute('aria-label') || e.textContent || '').trim() === txt);
      if (!el) return null;
      const r = el.getBoundingClientRect();
      return [r.x + r.width / 2, r.y + r.height / 2];
    }, s.clickText);
    if (!box) throw new Error('bulunamadı: ' + s.clickText);
    await page.mouse.click(box[0], box[1]);
    console.log('tap', s.clickText, box.map(Math.round).join(','));
  }
  if (s.wait) await new Promise((r) => setTimeout(r, s.wait));
  if (s.shot) {
    await new Promise((r) => setTimeout(r, 700));
    await page.screenshot({ path: path.join(OUT, s.shot + '.png') });
    console.log('shot', s.shot);
  }
}
await browser.close();
server.close();
