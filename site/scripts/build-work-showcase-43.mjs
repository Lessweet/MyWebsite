// 「AI design 内容写作」两张 4:3 封面(2026-11-02 用户:两张图各自正方形 → 改 4:3,里面的元素也要适配好):
// 用同一套代码拼图(Showcase),把容器改成 4:3 后重新排版、导出,不是把 16:9 图裁出来。
// 用法:先开本地测试版(localhost:5175),再跑 node site/scripts/build-work-showcase-square.mjs [url]
// 产出:docs/writing/assets/works/gallery/wechat-ai-1-43.webp、wechat-ai-2-43.webp(1920×1440)+ -960 / -1280
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const OUT = path.join(ROOT, 'docs/writing/assets/works/gallery');
const BASE = process.argv[2] || 'http://localhost:5175';
const NAMES = ['wechat-ai-1-43', 'wechat-ai-2-43'];
const W = 1920;
/* 4:3 里的排版:三屏手机按宽度放到最大(1.1,左右各留一点);封面网格放大到铺满方形(旋转后四角不露底) */
const SQUARE = `
  .work-cover.showcase .sc-pane { aspect-ratio: 4 / 3 !important; }
  .sc-pane-article .sc-phones { scale: 1.16 !important; gap: 0.9em !important; }   /* 三页间距 1.6 → 0.9em(2026-11-02 用户:再小),整组略放大 */
  .sc-covers { transform: rotate(8deg) scale(1.45) !important; }   /* 1.8 → 1.45(2026-11-02 用户:缩小一点、看到更多) */
`;

const browser = await chromium.launch({ channel: 'chrome' });
const open = async (dsf) => {
  const page = await browser.newPage({ viewport: { width: 1440, height: 1400 }, deviceScaleFactor: dsf, colorScheme: 'light' });
  await page.goto(`${BASE}/?render-showcase`, { waitUntil: 'load' });
  await page.addStyleTag({ content: `*{animation:none!important;transition:none!important}
    .work-cover.showcase .sc-pane{border-radius:0!important;opacity:1!important}
    .work-cover img{opacity:1!important}
    .work-rail,.ol-toggle,.rt-toggle,.rd-wrap,.theme-toggle,.edge-blur,.page-reveal{display:none!important}${SQUARE}` });
  await page.evaluate(async () => {
    document.querySelector('.work-cover.showcase')?.scrollIntoView({ block: 'center' });
    await Promise.all([...document.querySelectorAll('.work-cover.showcase img')].map((i) => (i.loading = 'eager', i.complete ? 0 : new Promise((r) => (i.onload = i.onerror = r)))));
    await document.fonts.ready;
  });
  await page.waitForTimeout(600);
  return page;
};
const probe = await open(1);
const paneW = await probe.evaluate(() => document.querySelector('.work-cover.showcase .sc-pane').getBoundingClientRect().width);
await probe.close();
const page = await open(W / paneW);
const panes = await page.$$('.work-cover.showcase .sc-pane');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'showcase-sq-'));
for (let i = 0; i < panes.length && i < NAMES.length; i++) await panes[i].screenshot({ path: path.join(tmp, `${NAMES[i]}.png`) });
await browser.close();

execFileSync('python3', ['-c', `
import sys
from PIL import Image, ImageFilter
tmp, out, *names = sys.argv[1:]
for n in names:
    im = Image.open(f'{tmp}/{n}.png').convert('RGB').resize((1920, 1440), Image.LANCZOS)
    if n.startswith('wechat-ai-2'):
        im = im.filter(ImageFilter.UnsharpMask(radius=1.4, percent=70, threshold=6))
    im.save(f'{out}/{n}.webp', 'WEBP', quality=84, method=6)
    for w in (960, 1280):
        im.resize((w, w * 3 // 4), Image.LANCZOS).save(f'{out}/{n}-{w}.webp', 'WEBP', quality=82, method=6)
    print('gallery/' + n + '.webp')
`, tmp, OUT, ...NAMES], { stdio: 'inherit' });
