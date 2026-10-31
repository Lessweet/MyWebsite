// 把「两图式」封面(代码拼的:手机截图 + 小封面网格)导出成整张 16:9 位图(2026-10-31 用户:
// 任何作品的加载态都是 16:9 整图,网站上用整张位图,加载时铺作品主题色、加载完整张淡入)。
// 用法:先开本地测试版(npm run dev -- --port 5175),再跑
//   node site/scripts/build-work-showcase-bitmap.mjs [http://localhost:5175]
// 产出:docs/writing/assets/works/gallery/wechat-ai-1.webp(左:三屏手机)、-2.webp(右:封面网格),1920×1080,
// 再自动出 -960 / -1280 小图(同 build-work-srcset.py)。改了拼图内容(HomePage Showcase / works.ts showcase)就重跑一次
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
const NAMES = ['wechat-ai-1', 'wechat-ai-2'];
const W = 1920;

const browser = await chromium.launch({ channel: 'chrome' });
const open = async (dsf) => {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: dsf, colorScheme: 'light' });
  await page.goto(`${BASE}/?render-showcase`, { waitUntil: 'load' });
  /* 去掉入场、圆角、悬停放大,只留画面本身 */
  await page.addStyleTag({ content: `*{animation:none!important;transition:none!important}
    .work-cover.showcase .sc-pane{border-radius:0!important;opacity:1!important}
    .work-cover img{opacity:1!important}
    .work-rail,.ol-toggle,.rt-toggle,.theme-toggle,.edge-blur,.page-reveal{display:none!important}` });
  /* 屏幕上下边缘的渐隐遮罩(.edge-blur)是盖在页面上的固定层,不藏会被一起截进图里(2026-10-31 修) */
  await page.evaluate(async () => {
    document.querySelector('.work-cover.showcase')?.scrollIntoView({ block: 'center' });
    await Promise.all([...document.querySelectorAll('.work-cover.showcase img')].map((i) => (i.loading = 'eager', i.complete ? 0 : new Promise((r) => (i.onload = i.onerror = r)))));
    await document.fonts.ready;
  });
  await page.waitForTimeout(500);
  return page;
};
const probe = await open(1);
const paneW = await probe.evaluate(() => document.querySelector('.work-cover.showcase .sc-pane').getBoundingClientRect().width);
await probe.close();
const page = await open(W / paneW);
const panes = await page.$$('.work-cover.showcase .sc-pane');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'showcase-'));
for (let i = 0; i < panes.length && i < NAMES.length; i++) await panes[i].screenshot({ path: path.join(tmp, `${NAMES[i]}.png`) });
await browser.close();

/* PNG → webp:1920×1080 原图 + 960 / 1280 小图 */
execFileSync('python3', ['-c', `
import sys
from PIL import Image, ImageFilter
tmp, out, *names = sys.argv[1:]
for n in names:
    im = Image.open(f'{tmp}/{n}.png').convert('RGB').resize((1920, 1080), Image.LANCZOS)
    # 封面集合整组旋转过,浏览器渲染时边缘会柔一层:轻微锐化找回清晰度(2026-10-31 用户:模糊、但别太大);
    # threshold 6 只锐化文字和边缘,不放大封面里的颗粒噪点(否则体积涨三成)
    if n.endswith('-2'):
        im = im.filter(ImageFilter.UnsharpMask(radius=1.4, percent=70, threshold=6))
    im.save(f'{out}/{n}.webp', 'WEBP', quality=86, method=6)
    for w in (960, 1280):
        sm = im.resize((w, round(1080 * w / 1920)), Image.LANCZOS)
        if n.endswith('-2'):
            sm = sm.filter(ImageFilter.UnsharpMask(radius=0.8, percent=50, threshold=6))   # 缩小后再补一点锐度
        sm.save(f'{out}/{n}-{w}.webp', 'WEBP', quality=82 if n.endswith('-2') else 84, method=6)
    print('gallery/' + n + '.webp')
`, tmp, OUT, ...NAMES], { stdio: 'inherit' });
