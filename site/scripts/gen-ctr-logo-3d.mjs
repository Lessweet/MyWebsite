/**
 * CTR 字标(线框 + 挤出立体)生成器,2026-10-23。
 *
 * 视觉语言(参考用户给的「Insights on Business」图):
 *   实线 = 正面轮廓;
 *   虚线 = 整个挤出体积的外沿里没被正面挡住的部分 —— 背面露出的边 + 转角处的结构棱都在其中,
 *          被侧壁挡住的背面边不画(之前整圈画背面轮廓,虚线穿过斜线区,显得重叠杂乱);
 *   斜线 = 看得见的侧壁 = 挤出体积 − 正面。
 * 挤出体积 = 正面 ⊕ 线段(0→d) 的闵可夫斯基和 = 正面 ∪ 背面 ∪ 每条边扫过的四边形,精确求并。
 *
 * 字形几何来自 gen-ctr-logo.py 的 json 模式(C 的圆 / T、R 的 Figma 路径,已在最终坐标)。
 * 用法:
 *   node site/scripts/gen-ctr-logo-3d.mjs file   > docs/logo-ctr-v4.svg
 *   node site/scripts/gen-ctr-logo-3d.mjs inline → 贴进 site/index.html 顶栏(颜色走 simple.css)
 *   node site/scripts/gen-ctr-logo-3d.mjs inline --svg site/assets/logo/mark-source.svg → 换成单个图形的站点 logo
 */
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pc from 'polygon-clipping';

const here = dirname(fileURLToPath(import.meta.url));

/* --svg <文件>:不画 CTR,改把这个 SVG 里的单个图形(只支持绝对坐标 M/L/C/Z,多子路径按奇偶规则)
   做成同一套线框立体字标(2026-10-23 用户:站点 logo 换成「站点 logo/字体/材质/Vector.svg」那个图形)。
   图形先等比缩放到与 CTR 字母同高(GLYPH_H),这样线宽、斜线间距、挤出深度在屏幕上和原字标一致 */
const svgArg = process.argv.indexOf('--svg');
const SVG_FILE = svgArg > 0 ? process.argv[svgArg + 1] : null;
const GLYPH_H = 292;

const DX = 26;
const DY = 22;
const PAD = 4;

/* ---- 字形 → 多边形 ---- */
const circlePoly = ([cx, cy, r], n = 96) => {
  const ring = [];
  for (let k = 0; k < n; k++) {
    const t = (k / n) * Math.PI * 2;
    ring.push([cx + r * Math.cos(t), cy + r * Math.sin(t)]);
  }
  ring.push(ring[0]);
  return [ring];
};
function samplePath(d, n = 40) {
  const toks = d.match(/[MLCZ]|-?\d*\.?\d+/g);
  const rings = [];
  let i = 0;
  let cur = null;
  let ring = null;
  const num = () => parseFloat(toks[i++]);
  while (i < toks.length) {
    const c = toks[i++];
    if (c === 'M') {
      if (ring) rings.push(ring);
      cur = [num(), num()];
      ring = [cur];
    } else if (c === 'L') {
      cur = [num(), num()];
      ring.push(cur);
    } else if (c === 'C') {
      const p1 = [num(), num()];
      const p2 = [num(), num()];
      const p3 = [num(), num()];
      for (let k = 1; k <= n; k++) {
        const t = k / n;
        const mt = 1 - t;
        ring.push([
          mt ** 3 * cur[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0],
          mt ** 3 * cur[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1],
        ]);
      }
      cur = p3;
    }
  }
  if (ring) rings.push(ring);
  return rings.map((r) => [...r, r[0]]);
}
/* 多个子路径按奇偶规则合成(R 的内腔是第二个子路径) */
const evenOdd = (rings) => rings.slice(1).reduce((acc, r) => pc.xor(acc, [r]), [[rings[0]]]);

let fronts;
let glyphW;
if (SVG_FILE) {
  const src = readFileSync(SVG_FILE, 'utf8');
  const d = src.match(/\sd="([^"]+)"/)[1];
  const rings = samplePath(d);
  const ys = rings.flat().map((p) => p[1]);
  const xs = rings.flat().map((p) => p[0]);
  const [x0, y0] = [Math.min(...xs), Math.min(...ys)];
  const k = GLYPH_H / (Math.max(...ys) - y0);
  const scaled = rings.map((r) => r.map(([x, y]) => [(x - x0) * k, (y - y0) * k]));
  fronts = [evenOdd(scaled)];
  glyphW = (Math.max(...xs) - x0) * k;
} else {
  const G = JSON.parse(execFileSync('python3', [join(here, 'gen-ctr-logo.py'), 'json'], { encoding: 'utf8' }));
  fronts = [
    pc.union(...G.circles.map((c) => circlePoly(c))),
    evenOdd(samplePath(G.T)),
    evenOdd(samplePath(G.R)),
  ];
  glyphW = G.W;
}
const VBW = glyphW + DX + PAD * 2;
const VBH = GLYPH_H + DY + PAD * 2;

const shift = (mp, dx, dy) => mp.map((poly) => poly.map((ring) => ring.map(([x, y]) => [x + dx, y + dy])));
function extrude(F) {
  const quads = [];
  for (const poly of F)
    for (const ring of poly)
      for (let k = 0; k < ring.length - 1; k++) {
        const [a, b] = [ring[k], ring[k + 1]];
        quads.push([[a, b, [b[0] + DX, b[1] + DY], [a[0] + DX, a[1] + DY], a]]);
      }
  return pc.union(F, shift(F, DX, DY), ...quads);
}

/* 点在多边形内 / 到边界距离:用来筛掉挤出体积外沿上与正面重合或被正面盖住的段 */
function inside(mp, [x, y]) {
  let c = false;
  for (const poly of mp)
    for (const ring of poly)
      for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        const [xi, yi] = ring[i];
        const [xj, yj] = ring[j];
        if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
      }
  return c;
}
function distToBoundary(mp, [x, y]) {
  let m = Infinity;
  for (const poly of mp)
    for (const ring of poly)
      for (let k = 0; k < ring.length - 1; k++) {
        const [ax, ay] = ring[k];
        const [bx, by] = ring[k + 1];
        const vx = bx - ax;
        const vy = by - ay;
        const t = Math.max(0, Math.min(1, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy || 1)));
        m = Math.min(m, Math.hypot(x - ax - t * vx, y - ay - t * vy));
      }
  return m;
}
function visibleSilhouette(S, F) {
  const runs = [];
  for (const poly of S)
    for (const ring of poly) {
      let run = null;
      for (let k = 0; k < ring.length - 1; k++) {
        const a = ring[k];
        const b = ring[k + 1];
        const mid = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2];
        const hidden = inside(F, mid) || distToBoundary(F, mid) < 0.8;
        if (hidden) {
          if (run) runs.push(run), (run = null);
        } else {
          if (!run) run = [a];
          run.push(b);
        }
      }
      if (run) runs.push(run);
    }
  return runs;
}

/* Douglas–Peucker 简化:采样折线很密,去掉几乎共线的点(误差 ≤ EPS 用户单位,屏幕上不可见),体积减到几分之一 */
const EPS = 0.3;
function simplify(pts) {
  if (pts.length < 3) return pts;
  const [a, b] = [pts[0], pts[pts.length - 1]];
  let idx = -1;
  let dmax = 0;
  for (let k = 1; k < pts.length - 1; k++) {
    const [x, y] = pts[k];
    const vx = b[0] - a[0];
    const vy = b[1] - a[1];
    const len = Math.hypot(vx, vy) || 1;
    const d = Math.abs(vy * x - vx * y + b[0] * a[1] - b[1] * a[0]) / len;
    if (d > dmax) (dmax = d), (idx = k);
  }
  if (dmax <= EPS) return [a, b];
  return [...simplify(pts.slice(0, idx + 1)).slice(0, -1), ...simplify(pts.slice(idx))];
}
/* 闭合环首尾同点,直接简化会塌成一个点:先在离起点最远处切成两段,各自简化再拼回 */
function simplifyRing(ring) {
  let m = 1;
  let dm = 0;
  for (let k = 1; k < ring.length - 1; k++) {
    const d = Math.hypot(ring[k][0] - ring[0][0], ring[k][1] - ring[0][1]);
    if (d > dm) (dm = d), (m = k);
  }
  return [...simplify(ring.slice(0, m + 1)).slice(0, -1), ...simplify(ring.slice(m))];
}
const f = (v) => (Math.round(v * 10) / 10).toString();
const ringsToD = (mp) =>
  mp.flatMap((poly) => poly.map((ring) => 'M' + simplifyRing(ring).slice(0, -1).map(([x, y]) => `${f(x)} ${f(y)}`).join('L') + 'Z')).join('');
const runsToD = (runs) => runs.map((r) => 'M' + simplify(r).map(([x, y]) => `${f(x)} ${f(y)}`).join('L')).join('');

let letters = '';
const stats = [];
for (const F of fronts) {
  const S = extrude(F);
  const side = pc.difference(S, F);
  const runs = visibleSilhouette(S, F);
  stats.push(runs.length);
  /* hover 区 = 字母连同挤出部分的外接矩形(透明填充也算「已绘制」,能接鼠标),
     C 的开口这类空白处也能触发(2026-10-23 用户) */
  const xs = S.flat(2).map((p) => p[0]);
  const ys = S.flat(2).map((p) => p[1]);
  const [x0, x1, y0, y1] = [Math.min(...xs), Math.max(...xs), Math.min(...ys), Math.max(...ys)];
  letters +=
    `<g class="logo-letter">` +
    `<rect fill="transparent" x="${f(x0)}" y="${f(y0)}" width="${f(x1 - x0)}" height="${f(y1 - y0)}"/>` +
    `<path class="logo-hatch-fill" fill-rule="evenodd" d="${ringsToD(side)}"/>` +
    `<path class="logo-back-line" d="${runsToD(runs)}"/>` +
    `<path class="logo-fill logo-front-line" fill-rule="evenodd" d="${ringsToD(F)}"/>` +
    `</g>`;
}
process.stderr.write(`W=${glyphW.toFixed(1)} VB=${VBW.toFixed(1)}x${VBH} silhouette runs=${stats.join(',')}\n`);

const pat = (id, cls) =>
  `<pattern id="${id}" patternUnits="userSpaceOnUse" width="14" height="14" patternTransform="rotate(45)">` +
  `<line class="${cls}" x1="0" y1="0" x2="0" y2="14"/></pattern>`;
const defs = `<defs>${pat('ctr-hatch', 'logo-hatch')}${pat('ctr-hatch-dark', 'logo-hatch-dark')}</defs>`;
const body = `<g transform="translate(${PAD} ${PAD})">${letters}</g>`;
const vb = `0 0 ${VBW.toFixed(1)} ${VBH}`;

if (process.argv[2] === 'inline') {
  process.stdout.write(`<svg class="site-logo" viewBox="${vb}" role="img" aria-label="CTR">${defs}${body}</svg>\n`);
} else {
  const style =
    '<style>.logo-fill{fill:#FDFDFC}.logo-hatch-fill{fill:url(#ctr-hatch)}' +
    '.logo-hatch{stroke:#aeaeb2;stroke-width:3}.logo-hatch-dark{stroke:#636366;stroke-width:3}' +
    '.logo-back-line{fill:none;stroke:#8e8e93;stroke-width:1.25;stroke-dasharray:4 3}' +
    '.logo-front-line{stroke:#141414;stroke-width:1.5}</style>';
  process.stdout.write(
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="CTR">${style}${defs}${body}</svg>\n`,
  );
}
