#!/usr/bin/env node
// 首页「公众号 AI 设计内容」作品卡片素材：一张手机文章页截图 + 3 个排版组件小图。
//
// 文章：aiadong_mp「20260928 设计师工作方式」《今年的 AI 设计工作流：进代码、做工具、用多个 agent、多做判断》
//   —— 首页封面 site/assets/work-collage/08-ai-design-workflow-2026.webp 就是这篇的 封面/cover.png
//   （全库 2.35:1 图片按 216×92 缩略图 RGB 均方根误差比对：0.005，次近的别篇 0.28）。
//   这篇是单独排的「报告体」，没有 article_styled.html，排版页在 样张-报告体/article_report.html
//   （.wxsim 外壳已按微信正文区 375 宽、左右 16px 模拟；比 article_publish.html 新，内容一致、带 class 好取元素）。
// 输出：docs/writing/assets/works/showcase/
//   article-phone.webp  第 1 屏：手机文章页首屏 375×812 @2x（上面补一段微信的标题 + 作者行「原创 · AI设计师阿东 · 日期」）
//   article-phone-2/3.webp  第 2、3 屏：同宽往下滚的两屏（首页左侧「三屏」并排用），不加标题 / 作者行
//   comp-1..3.webp      3 个排版组件，按元素包围盒截，四周 8px（@2x 16px）白边
//   manifest.json       文件尺寸 + 中文说明 + 来源
//
// 依赖：仓库里的 playwright + 本机 Google Chrome（channel: 'chrome'）、系统 cwebp（brew install webp）
// 运行：node site/scripts/build-work-showcase.mjs

import { chromium } from 'playwright';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const OUT = path.join(ROOT, 'docs/writing/assets/works/showcase');
const MP = '/Users/chentongrong/Documents/projects/aiadong_mp';
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'work-showcase-'));
const Q = 85;
const PAD = 8; // CSS px，@2x 即 16px
// 组件按 360 宽渲染：正文区 328 + 两侧白边 16 = 344 → @2x 688，落在 400–700 内（375 宽会到 718）
const COMP_VW = 360;

const ARTICLE = {
  dir: '20260928 设计师工作方式',
  file: '样张-报告体/article_report.html',
  title: '今年的 AI 设计工作流：进代码、做工具、用多个 agent、多做判断',
  date: '2026-09-28', // 文件夹日期；库里没有单独记发布日期
};

// 页面清理：灰底改白；.note 是排版时的黄色说明条，不是正文
const PAGE_CSS = `
  html, body { background: #fff !important; }
  .note { display: none !important; }
  body { -webkit-font-smoothing: antialiased; }
`;

// 第 2、3 屏：anchor 返回这一屏顶边的文档 y（CSS px，375 宽、不插标题的页面），截 375×812
const SCREENS = [
  {
    file: 'article-phone-2.webp',
    desc: '第 2 屏：四行带像素图标的章节目录（1~5 月 / 6~7 月 / 8~9 月 / 7 月起）+ 第一章珊瑚色章首卡',
    // 从目录第一行上方开始（行自带 16px 上内边距，再留 16px）
    anchor: () => {
      const p = [...document.querySelectorAll('.article p')].find((el) => el.innerText.includes('设计师开始直接在'));
      return p.parentElement.parentElement.getBoundingClientRect().top + scrollY - 16;
    },
  },
  {
    file: 'article-phone-3.webp',
    desc: '第 3 屏：时间线「02-23」条目 + 大数字卡「5–10%」（Brian Lovin 花在 Figma 上的时间）+ 「03-01」条目',
    // 从「02-23」条目上方 24px 的条目间空白开始，屏底正好落在「03-01」正文末行之后
    anchor: () => {
      const p = [...document.querySelectorAll('p.tl-txt')].find((el) => el.innerText.includes('Prototype Playground'));
      return p.parentElement.getBoundingClientRect().top + scrollY - 24;
    },
  },
];

// 3 个组件：pick 在页面里找元素，返回 {x,y,w,h}（CSS px，视口坐标）
const COMPS = [
  {
    file: 'comp-1.webp',
    desc: '带像素图标的章节小标题（目录第一行：「1~5 月 · 设计师开始直接在代码里做设计」+ 像素笔记本图标）',
    pick: () => {
      const p = [...document.querySelectorAll('.article p')].find((el) => el.innerText.includes('设计师开始直接在'));
      // 左文字块 + 右 80px 图标的并集；不取整行，避开行上下的留白和分隔线
      const text = p.parentElement.getBoundingClientRect();
      const icon = p.parentElement.parentElement.lastElementChild.getBoundingClientRect(); // 「1~5」本身也是行内 svg，别用 querySelector('svg')
      const x0 = Math.min(text.left, icon.left), x1 = Math.max(text.right, icon.right);
      const y0 = Math.min(text.top, icon.top), y1 = Math.max(text.bottom, icon.bottom);
      return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
    },
  },
  {
    file: 'comp-2.webp',
    desc: '带头像署名的引用卡（浅珊瑚底、像素引号，Perplexity 设计经理 Sebastian Speier 的原话）',
    pick: () => {
      const cards = [...document.querySelectorAll('.article div')].filter((el) =>
        el.innerText.includes('不再把它当主文档') && getComputedStyle(el).backgroundColor !== 'rgba(0, 0, 0, 0)');
      const r = cards.at(-1).getBoundingClientRect(); // 最内层的有底色块 = 卡片本体
      return { x: r.left, y: r.top, w: r.width, h: r.height };
    },
  },
  {
    file: 'comp-3.webp',
    desc: '时间线条目（「02-02」日期 + 虚线 + 嵌品牌小图标和头像的正文：OpenAI 发布 Codex 桌面版）',
    pick: () => {
      const p = [...document.querySelectorAll('p.tl-txt')].find((el) => el.innerText.includes('Codex 桌面版'));
      const r = p.parentElement.getBoundingClientRect(); // 日期行 + 虚线 + 正文，不含下面的截图
      return { x: r.left, y: r.top, w: r.width, h: r.height };
    },
  },
];

// 微信文章页顶部：标题 + 作者行（原创 · 公众号名 · 日期），插在 .wxsim 里、正文之前
const WX_CSS = `
  #wx-head { padding: 20px 0 6px; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif; }
  #wx-head h1 { font-size: 22px; line-height: 1.4; font-weight: 500; color: rgba(0,0,0,.9); margin: 0 0 14px; letter-spacing: 0; }
  #wx-head .meta { font-size: 15px; line-height: 20px; color: rgba(0,0,0,.3); }
  #wx-head .meta span { margin-right: 8px; }
  #wx-head .orig { display: inline-block; font-size: 12px; line-height: 18px; padding: 0 4px; border-radius: 2px;
                   background: rgba(0,0,0,.05); color: rgba(0,0,0,.3); vertical-align: 1px; }
  #wx-head .nick { color: #576b95; }
`;

function wxHead({ title, date }) {
  const [y, m, d] = date.split('-').map(Number);
  return `<div id="wx-head"><h1>${title}</h1><div class="meta"><span class="orig">原创</span>`
    + `<span class="nick">AI设计师阿东</span><span>${y}年${m}月${d}日</span></div></div>`;
}

async function open(browser, width, { head } = {}) {
  const page = await browser.newPage({ viewport: { width, height: 812 }, deviceScaleFactor: 2 });
  await page.goto(pathToFileURL(path.join(MP, ARTICLE.dir, ARTICLE.file)).href, { waitUntil: 'load' });
  await page.addStyleTag({ content: PAGE_CSS + WX_CSS });
  if (head) await page.evaluate((h) => document.querySelector('.wxsim').insertAdjacentHTML('afterbegin', h), head);
  // GIF 钉在第 0 帧：动图按加载时刻播放，不钉的话每次重跑截到的帧都不一样（首屏大图 hero-dmsans.gif 就是动图）
  const gifs = await page.evaluate(() => [...document.images].map((i) => i.getAttribute('src')).filter((s) => /\.gif(\?|$)/i.test(s)));
  for (const src of new Set(gifs)) {
    const file = path.join(MP, ARTICLE.dir, path.dirname(ARTICLE.file), src.split('?')[0]);
    const b64 = fs.readFileSync(file).toString('base64');
    await page.evaluate(async ({ src, b64 }) => {
      const data = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
      const dec = new ImageDecoder({ data, type: 'image/gif' });
      const { image } = await dec.decode({ frameIndex: 0 });
      const cv = Object.assign(document.createElement('canvas'), { width: image.displayWidth, height: image.displayHeight });
      cv.getContext('2d').drawImage(image, 0, 0);
      image.close();
      const url = cv.toDataURL('image/png');
      document.querySelectorAll('img').forEach((i) => { if (i.getAttribute('src') === src) i.src = url; });
    }, { src, b64 });
  }
  // 等字体和图片都就绪
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.images].map((i) => (i.complete ? 0 : new Promise((r) => { i.onload = i.onerror = r; }))));
  });
  // SMIL 动画停在 0 秒（静止帧）
  await page.evaluate(() => document.querySelectorAll('svg').forEach((s) => { s.pauseAnimations?.(); s.setCurrentTime?.(0); }));
  return page;
}

function toWebp(png, name) {
  const out = path.join(OUT, name);
  execFileSync('cwebp', ['-quiet', '-q', String(Q), '-m', '6', png, '-o', out]);
  return out;
}

function size(file) {
  const b = fs.readFileSync(file);
  // WebP VP8/VP8L/VP8X 头里读宽高
  const fourcc = b.toString('ascii', 12, 16);
  if (fourcc === 'VP8 ') return { width: b.readUInt16LE(26) & 0x3fff, height: b.readUInt16LE(28) & 0x3fff };
  if (fourcc === 'VP8L') { const v = b.readUInt32LE(21); return { width: (v & 0x3fff) + 1, height: ((v >> 14) & 0x3fff) + 1 }; }
  return { width: 1 + b.readUIntLE(24, 3), height: 1 + b.readUIntLE(27, 3) };
}

fs.mkdirSync(OUT, { recursive: true });
// 用系统 Chrome（channel），免得 playwright 升级后要另下 headless shell
const browser = await chromium.launch({ channel: 'chrome' });
const files = [];
const source = { title: ARTICLE.title, dir: ARTICLE.dir, file: ARTICLE.file };

// 1. 手机文章页首屏（完整一屏 375×812）
{
  const page = await open(browser, 375, { head: wxHead(ARTICLE) });
  const png = path.join(TMP, 'phone.png');
  await page.screenshot({ path: png, clip: { x: 0, y: 0, width: 375, height: 812 } });
  const f = toWebp(png, 'article-phone.webp');
  files.push({ file: 'article-phone.webp', ...size(f), desc: `第 1 屏：手机上的公众号文章页首屏（375×812 @2x，模拟微信标题和作者行 + 首屏大图），《${ARTICLE.title}》`, scrollY: 0, source });
  await page.close();
}

// 2. 第 2、3 屏
for (const sc of SCREENS) {
  const page = await open(browser, 375);
  const y = Math.round(await page.evaluate(`(${sc.anchor})()`));
  const png = path.join(TMP, sc.file.replace('.webp', '.png'));
  await page.screenshot({ path: png, clip: { x: 0, y, width: 375, height: 812 }, fullPage: true });
  const f = toWebp(png, sc.file);
  files.push({ file: sc.file, ...size(f), desc: `${sc.desc}，《${ARTICLE.title}》`, scrollY: y, source });
  await page.close();
}

// 3. 三个组件（浮动组件版用；三屏版不用，保留）
for (const c of COMPS) {
  const page = await open(browser, COMP_VW);
  const box = await page.evaluate(`(${c.pick})()`);
  const scrollY = await page.evaluate(() => window.scrollY);
  const clip = {
    x: Math.max(0, Math.floor(box.x - PAD)),
    y: Math.floor(box.y + scrollY - PAD),
    width: Math.ceil(box.w + PAD * 2),
    height: Math.ceil(box.h + PAD * 2),
  };
  const png = path.join(TMP, c.file.replace('.webp', '.png'));
  await page.screenshot({ path: png, clip, fullPage: true });
  const f = toWebp(png, c.file);
  files.push({ file: c.file, ...size(f), desc: `${c.desc}，来自《${ARTICLE.title}》`, source });
  await page.close();
}

await browser.close();

const manifest = {
  article: { title: ARTICLE.title, date: ARTICLE.date, account: 'AI设计师阿东', dir: ARTICLE.dir, file: ARTICLE.file },
  files,
};
fs.writeFileSync(path.join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');

let total = 0;
for (const f of files) {
  const kb = fs.statSync(path.join(OUT, f.file)).size / 1024;
  total += kb;
  console.log(`${f.file}  ${f.width}×${f.height}  ${kb.toFixed(1)} KB`);
}
console.log(`total ${total.toFixed(1)} KB → ${path.relative(ROOT, OUT)}`);
