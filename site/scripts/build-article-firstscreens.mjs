#!/usr/bin/env node
// 作品集「公众号 AI 设计内容」:几篇排版风格不同的原创文章手机首屏(2026-10-24 用户:再放几篇样式不同的文章首屏)。
// 做法同 build-work-showcase.mjs 的第 1 屏:375×812 @2x 打开 aiadong_mp 里排好版的 article_styled.html,
// 顶部补微信标题 + 作者行(原创 · AI设计师阿东 · 日期),GIF 钉在第 0 帧、SVG 动画停在 0 秒。
// 输出:site/assets/portfolio-deck/phones/<key>.png(作品集素材,不上线)
// 运行:node site/scripts/build-article-firstscreens.mjs

import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const MP = '/Users/chentongrong/Documents/projects/aiadong_mp';
const OUT = path.join(ROOT, 'site/assets/portfolio-deck/phones');

export const ARTICLES = [
  { key: 'skills', dir: '20260705 Figma Skills', title: '设计师的新资产，是 Skills', date: '2026-07-05' },   // 日期按文件夹,发布日没有记录
  { key: 'astra', dir: '20260907 Astra出图路径', title: 'Astra 三个设计实测，People Use 和 Computer Use 共存', date: '2026-09-08' },
  { key: 'long-chat', dir: '20260811 AI长对话导航设计', title: 'AI 产品设计｜长对话导航机制', date: '2026-08-12' },
  { key: 'selection', dir: '20260804 AI浏览器划词上下文', title: 'AI 产品设计｜选中即上下文', date: '2026-08-06' },
  { key: 'genui', dir: '20260801 GenUI建站实录', title: '跳过 Figma 直接用 GenUI 做设计，踩了一路坑，也跑通了上线', date: '2026-08-03' },
  { key: 'review', dir: '20260627 审查 AI 产物', title: '设计师的新工作，审查 AI 产物', date: '2026-07-05' },
  { key: 'shader', dir: '20260626 Figma config/ShaderMotion我的实操', title: '在设计系统里，Figma Shader 和 Motion ，正从效果变成可复用元素', date: '2026-07-02' },
];

const CSS = `
  html, body { background: #fff !important; margin: 0; }
  .note { display: none !important; }
  body { -webkit-font-smoothing: antialiased; }
  #wx-head { padding: 20px 16px 6px; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif; background: #fff; }
  #wx-head h1 { font-size: 22px; line-height: 1.4; font-weight: 500; color: rgba(0,0,0,.9); margin: 0 0 14px; letter-spacing: 0; }
  #wx-head .meta { font-size: 15px; line-height: 20px; color: rgba(0,0,0,.3); }
  #wx-head .meta span { margin-right: 8px; }
  #wx-head .orig { display: inline-block; font-size: 12px; line-height: 18px; padding: 0 4px; border-radius: 2px;
                   background: rgba(0,0,0,.05); color: rgba(0,0,0,.3); vertical-align: 1px; }
  #wx-head .nick { color: #576b95; }
`;

const head = ({ title, date }) => {
  const [y, m, d] = date.split('-').map(Number);
  return `<div id="wx-head"><h1>${title}</h1><div class="meta"><span class="orig">原创</span>`
    + `<span class="nick">AI设计师阿东</span><span>${y}年${m}月${d}日</span></div></div>`;
};

fs.mkdirSync(OUT, { recursive: true });
const browser = await chromium.launch({ channel: 'chrome' });
for (const a of ARTICLES) {
  const file = path.join(MP, a.dir, 'article_styled.html');
  const page = await browser.newPage({ viewport: { width: 375, height: 812 }, deviceScaleFactor: 2 });
  await page.goto(pathToFileURL(file).href, { waitUntil: 'load' });
  await page.addStyleTag({ content: CSS });
  await page.evaluate((h) => document.body.insertAdjacentHTML('afterbegin', h), head(a));
  // 排版稿里「[视频位置：…发布时在编辑器手动插入]」这类占位说明,换成视频里的一帧(2026-10-24 用户:这句 bug)。
  // 帧图:ffmpeg -ss 2 从同文件夹的录屏里截,存在 OUT/<key>-video-frame.png;没有帧图就直接去掉这行
  const frame = path.join(OUT, `${a.key}-video-frame.png`);
  const frameUrl = fs.existsSync(frame) ? 'data:image/png;base64,' + fs.readFileSync(frame).toString('base64') : null;
  await page.evaluate((url) => {
    const ps = [...document.querySelectorAll('p, div, section')].filter((el) => /^\s*!?\[?视频位置/.test(el.textContent) && el.children.length === 0);
    for (const el of ps) {
      if (url) el.outerHTML = `<img src="${url}" style="display:block;width:100%;height:auto;border-radius:4px;margin:16px 0">`;
      else el.remove();
    }
  }, frameUrl);
  // GIF 钉第 0 帧
  await page.evaluate(async () => {
    for (const img of [...document.images].filter((i) => /\.gif(\?|$)/i.test(i.src))) {
      try {
        const data = new Uint8Array(await (await fetch(img.src)).arrayBuffer());
        const dec = new ImageDecoder({ data, type: 'image/gif' });
        const { image } = await dec.decode({ frameIndex: 0 });
        const cv = Object.assign(document.createElement('canvas'), { width: image.displayWidth, height: image.displayHeight });
        cv.getContext('2d').drawImage(image, 0, 0); image.close();
        img.src = cv.toDataURL('image/png');
      } catch {}
    }
  });
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.images].map((i) => (i.complete ? 0 : new Promise((r) => { i.onload = i.onerror = r; }))));
    document.querySelectorAll('svg').forEach((s) => { s.pauseAnimations?.(); s.setCurrentTime?.(0); });
  });
  await page.waitForTimeout(400);
  const out = path.join(OUT, `${a.key}.png`);
  await page.screenshot({ path: out, clip: { x: 0, y: 0, width: 375, height: 812 } });
  console.log('saved', out);
  await page.close();
}
await browser.close();
