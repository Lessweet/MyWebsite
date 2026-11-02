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
  /* 封面改成规整网格(2026-11-02 用户:改为网格布局;之前是倾斜 8° 错位铺满):
     不旋转、不错位,3 列 × 4 行 16:9,四周留边、格间同图缝,正好排满 4:3 */
  /* 网格占的面积 = 左图三屏手机那一组(左右各约 7.8%、上下各约 13.2%,2026-11-02 用户:面积和第一张一样);
     格子按这块面积均分,图居中裁切 */
  .sc-covers { transform: none !important; display: grid !important; inset: 13.2% 7.85% !important;
    grid-template-columns: repeat(3, minmax(0, 1fr)); grid-template-rows: repeat(4, minmax(0, 1fr)); gap: 0.45em !important; }
  .showcase .sc-cover { aspect-ratio: auto !important; width: 100% !important; height: 100% !important; min-height: 0; object-fit: cover; }
  .sc-row { display: contents !important; }
  .sc-row:first-child, .sc-row:nth-child(5) { display: none !important; }
  .sc-row:nth-child(4) .sc-cover:nth-child(n + 3) { display: none !important; }   /* 只放 12 张 */
  /* 摆放(2026-11-02 用户):浅色波点放中间;两张黑底按原来的位置(Codebase 第二行右、Design Signal 左下);SKILLS 不放左下。
     星座 / SKILLS / Claude Code ; Code added / 浅色波点 / Codebase ; AI Mode / 拼贴 / VIBEDESIGN ; Design Signal / 青色界面 / AI Slop */
  .sc-row:nth-child(2) .sc-cover:nth-child(2) { order: 1; }
  .sc-row:nth-child(2) .sc-cover:nth-child(3) { order: 2; }
  .sc-row:nth-child(2) .sc-cover:nth-child(4) { order: 3; }
  .sc-row:nth-child(3) .sc-cover:nth-child(4) { order: 4; }
  .sc-row:nth-child(2) .sc-cover:nth-child(1) { order: 5; }
  .sc-row:nth-child(3) .sc-cover:nth-child(1) { order: 6; }
  .sc-row:nth-child(2) .sc-cover:nth-child(5) { order: 7; }
  .sc-row:nth-child(3) .sc-cover:nth-child(3) { order: 8; }
  .sc-row:nth-child(3) .sc-cover:nth-child(2) { order: 9; }
  .sc-row:nth-child(3) .sc-cover:nth-child(5) { order: 10; }
  .sc-row:nth-child(4) .sc-cover:nth-child(1) { order: 11; }
  .sc-row:nth-child(4) .sc-cover:nth-child(2) { order: 12; }
  .sc-row:nth-child(even) { transform: none !important; }
  /* 封面网格的底和左图一样:柔和青绿渐变 + 白色小方点(2026-11-02 用户) */
  .sc-pane-covers { background: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='10'%3E%3Crect width='3' height='3' fill='white' fill-opacity='0.3'/%3E%3C/svg%3E") 0 0 / 0.26em 0.26em, radial-gradient(60% 70% at 12% 8%, #E5F2F3 0%, rgba(229, 242, 243, 0) 70%), radial-gradient(55% 65% at 85% 18%, #B3D1D7 0%, rgba(179, 209, 215, 0) 72%), radial-gradient(60% 70% at 18% 95%, #C4D5B4 0%, rgba(196, 213, 180, 0) 72%), radial-gradient(45% 55% at 96% 100%, #F0D5C2 0%, rgba(240, 213, 194, 0) 75%), linear-gradient(180deg, #CDE2E4 0%, #CEDCC0 100%); !important; }
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
