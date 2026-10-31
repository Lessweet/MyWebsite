import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';

/* 大纲模式(2026-10-31 用户:V4 也要,按 V4 自己的断点和栏位标注):只在本地测试版出现,右下角一颗开关。
   打开后叠一层紫红色的栏位(单列一栏;宽屏左栏 440 + 栏距 120 + 右栏 Feed),每个元素描一圈紫红边,
   并标出边距、栏宽、关键间距和窗口宽度(从页面实际位置量,窗口变化时重算)。
   开关状态存 sessionStorage,刷新后保持。样式见 simple.css .ol-* */
const KEY = 'dev-outline';

/* V4 的断点 = Tailwind(sm 640 / md 768 / xl 1280 / 2xl 1536;和 simple.css 一一对应,改断点时这里同步改)。
   悬停大纲按钮时显示,当前档高亮。封面并排看的是卡片宽(@container ≥ 766),折算成窗口宽:单列 = 窗口 − 64,宽屏右栏 = 窗口 − 624 */
const BREAKPOINTS: { min: number; name: string; rule: string }[] = [
  { min: 0, name: '< 640', rule: '单列 · 边距 32 · 列宽 ≥ 60 均分铺满 · 文字铺满 · 封面上下排' },
  { min: 640, name: 'sm 640', rule: '单列 · 边距 32 · 文字铺满 · 封面上下排' },
  { min: 768, name: 'md 768', rule: '单列 · 介绍、简介都 8 列 · 窗口 ≥ 830 封面并排' },
  { min: 1280, name: 'xl 1280', rule: '两栏 · 左栏 440 = 介绍 6 列 · 栏距 120 · 简介 8 列 · 窗口 ≥ 1390 封面并排' },
  { min: 1536, name: '2xl 1536', rule: '整页封顶 1536 居中 · 右栏 912 = 12 列 · 两侧留白' },
];

/* 一条标注:竖向(v)或横向(h)的尺寸线,label 写数值 */
/* fixed:标在宽屏钉住的左栏上,跟着视口走、不随页面滚 */
type Mark = { dir: 'v' | 'h'; x: number; y: number; len: number; label: string; fixed?: boolean };

function measure(): Mark[] {
  const marks: Mark[] = [];
  const sy = window.scrollY;
  const box = (el: Element | null) => (el ? el.getBoundingClientRect() : null);
  const v = (x: number, top: number, bottom: number, name: string, fixed = false) => {
    const len = Math.round(bottom - top);
    if (len > 0) marks.push({ dir: 'v', x, y: top + (fixed ? 0 : sy), len, label: `${name} ${len}`, fixed });
  };
  const h = (y: number, left: number, right: number, name: string) => {
    const len = Math.round(right - left);
    if (len > 0) marks.push({ dir: 'h', x: left, y: y + sy, len, label: `${name} ${len}` });
  };

  /* 栏位:页面边距 + 各栏宽 + 栏距,放在页面最顶上一行;下面一行是窗口宽度 + 所在断点 */
  const shown = (el: Element) => getComputedStyle(el).display !== 'none';
  const regions = [...document.querySelectorAll('.ol-region')].filter(shown).map((r) => r.getBoundingClientRect());
  const cols = [...document.querySelectorAll('.ol-region i')].filter(shown).map((i) => i.getBoundingClientRect());
  const vw = document.documentElement.clientWidth;
  const bp = BREAKPOINTS.filter((b) => window.innerWidth >= b.min).pop()!;
  if (regions.length) {
    h(10 - sy, 0, regions[0].left, '边距');
    if (regions.length > 1) {
      h(10 - sy, regions[0].left, regions[0].right, '左栏');
      h(10 - sy, regions[0].right, regions[1].left, '栏距');
      h(10 - sy, regions[1].left, regions[1].right, '右栏');
    } else {
      h(10 - sy, regions[0].left, regions[0].right, '内容宽');
    }
  }
  /* 第二行:列宽 + 槽(量第一栏的第 1、2 列) */
  if (cols.length > 1) {
    h(52 - sy, cols[0].left, cols[0].right, '列宽');
    h(52 - sy, cols[0].right, cols[1].left, '槽');
  }
  marks.push({ dir: 'h', x: 0, y: 30, len: vw, label: `窗口 ${window.innerWidth} · ${bp.name}` });

  const wide = regions.length > 1;
  const intro = box(document.querySelector('.hero-intro > p'));   /* 量文字本身(介绍区是网格,整块比文字宽) */
  const works = [...document.querySelectorAll<HTMLElement>('.works > .work')];
  /* 单列:介绍段的行宽、介绍区 → 第一条作品。宽屏左栏是钉住的,不随页面滚,不标 */
  if (!wide && intro) {
    h(intro.bottom + 10, intro.left, intro.right, '介绍行宽');
    const introCol = box(document.querySelector('.intro-col'));
    if (introCol && works[0]) v(intro.left + 6, introCol.bottom, works[0].getBoundingClientRect().top, '介绍→作品');
  }
  /* 介绍区各段之间、最后一段 → 城市时间的间距(2026-10-31 用户);宽屏左栏钉住,标注也钉住 */
  const paras = [...document.querySelectorAll('.hero-intro > p'), document.querySelector('.hero-loc')]
    .filter((e): e is Element => !!e)
    .map((e) => e.getBoundingClientRect());
  paras.slice(1).forEach((b, i) => {
    const a = paras[i];
    v(a.left + 200, a.bottom, b.top, i === paras.length - 2 ? '段→时间' : '段距', wide);
  });
  works.slice(0, 2).forEach((w, i) => {
    const wb = w.getBoundingClientRect();
    const year = box(w.querySelector('.work-year'));
    const title = box(w.querySelector('.work-title'));
    const sum = box(w.querySelector('.work-summary'));
    const cover = box(w.querySelector('.work-cover'));
    if (!year || !title) return;
    const lx = wb.left + 6;
    if (i > 0) {
      v(lx, box(works[0])!.bottom, wb.top, '作品间距');
      return;
    }
    /* 宽屏:页面顶 → 第一条日期(与左上角字标顶对齐) */
    if (wide) v(lx, -sy, year.top, '顶→日期');
    v(lx + 70, year.bottom, title.top, '日期→标题');
    if (sum) v(lx + 160, title.bottom, sum.top, '标题→简介');
    if (sum) h(sum.bottom + 10, sum.left, sum.right, '简介行宽');
    if (cover) {
      v(lx + 260, (sum ?? title).bottom, cover.top, sum ? '简介→封面' : '标题→封面');
      h(cover.bottom + 10, cover.left, cover.right, '卡片宽');
      const items = [...w.querySelectorAll('.work-cover > .sc-pane, .work-cover > .gl-item')].map((e) => e.getBoundingClientRect());
      if (items.length > 1) {
        const a = items[0];
        const b = items[1];
        if (Math.abs(a.top - b.top) < 2) h(a.top + 20, a.right, b.left, '图缝');
        else v(a.left + 40, a.bottom, b.top, '图缝');
      }
    }
  });
  return marks;
}

export default function DevOutline() {
  const [on, setOn] = useState(() => {
    try {
      return sessionStorage.getItem(KEY) === '1';
    } catch {
      return false;
    }
  });
  const [marks, setMarks] = useState<Mark[]>([]);
  const [vw, setVw] = useState(() => window.innerWidth);
  useEffect(() => {
    const on = () => setVw(window.innerWidth);
    window.addEventListener('resize', on);
    return () => window.removeEventListener('resize', on);
  }, []);
  const current = BREAKPOINTS.filter((b) => vw >= b.min).pop()!;

  useEffect(() => {
    document.documentElement.classList.toggle('outline-mode', on);
    try {
      sessionStorage.setItem(KEY, on ? '1' : '0');
    } catch {
      /* 取不到 storage 时只是不记忆 */
    }
    if (!on) {
      setMarks([]);
      return;
    }
    /* 网格层先渲染出来再量;入场动画会让元素上浮几像素,稍后再量一次;窗口 / 内容尺寸变化时重量 */
    let raf = 0;
    const update = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => setMarks(measure()));
    };
    update();
    const late = window.setTimeout(update, 2500);
    const ro = new ResizeObserver(update);
    ro.observe(document.body);
    window.addEventListener('resize', update);
    return () => {
      cancelAnimationFrame(raf);
      window.clearTimeout(late);
      ro.disconnect();
      window.removeEventListener('resize', update);
    };
  }, [on]);

  return createPortal(
    <>
      {on && (
        <div aria-hidden="true" className="ol-grid">
          {[24, 24].map((n, k) => (
            <div className="ol-region" key={k}>
              {Array.from({ length: n }, (_, i) => (
                <i key={i} />
              ))}
            </div>
          ))}
        </div>
      )}
      {on && (
        <div aria-hidden="true" className="ol-marks">
          {marks.map((m, i) => (
            <div
              className={`ol-mark ol-mark-${m.dir}${m.len < 60 ? ' ol-mark-short' : ''}`}
              key={i}
              style={{ ...(m.dir === 'v' ? { left: m.x, top: m.y, height: m.len } : { left: m.x, top: m.y, width: m.len }), ...(m.fixed ? { position: 'fixed' as const } : {}) }}
            >
              <span>{m.label}</span>
            </div>
          ))}
        </div>
      )}
      <button
        aria-label="大纲模式:显示网格、元素边框和关键间距"
        aria-pressed={on}
        className="ol-toggle"
        onClick={() => setOn((v) => !v)}
        title="大纲模式"
        type="button"
      >
        <svg aria-hidden="true" viewBox="0 0 24 24">
          <rect height="16" rx="1.5" width="16" x="4" y="4" />
          <path d="M9.3 4v16M14.7 4v16" />
        </svg>
        {/* 悬停提示:当前窗口宽度落在哪个断点、各断点下的布局 */}
        <span className="ol-tip" role="tooltip">
          <b>
            窗口 {vw}px · {current.name}
          </b>
          {BREAKPOINTS.map((b) => (
            <span className={b === current ? 'is-on' : undefined} key={b.min}>
              <i>{b.name}</i>
              {b.rule}
            </span>
          ))}
        </span>
      </button>
    </>,
    document.body,
  );
}
