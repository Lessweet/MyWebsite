import { type CSSProperties, useEffect, useState } from 'react';
import { createPortal } from 'react-dom';

/* 测试版「调节」入口(2026-10-31 用户:右下角入口越来越多,合并成一个):
   右下角最下面一颗,点开小面板 ——
   - 封面圆角(--cover-radius)、悬停放大(--cover-zoom-scale)、文字占列(--text-cols,个人介绍和作品简介一起):拖滑杆实时改,不挡页面,边拖边看;
   - 文字颜色(主文字 / 灰色文字,只改浅色主题)、「编辑文字」开关(个人简介、日期、标题、作品简介直接点进去改,只改预览,刷新恢复);
   - 「入场动画…」打开原来的入场调参台(RevealTuner,它自己的按钮藏起来了)。
   值存在 localStorage,刷新保留;定下来后把数值告诉 Claude 写进 simple.css(默认值和 simple.css 一致) */
type Knob = { key: string; label: string; cssVar: string; min: number; max: number; step: number; def: number; unit: string; presets: number[] };
const KNOBS: Knob[] = [
  { key: 'dev-cover-radius', label: '封面圆角', cssVar: '--cover-radius', min: 0, max: 64, step: 1, def: 32, unit: 'px', presets: [8, 16, 24, 32, 48] },
  { key: 'dev-cover-zoom', label: '悬停放大', cssVar: '--cover-zoom-scale', min: 1, max: 1.1, step: 0.005, def: 1.02, unit: '×', presets: [1, 1.02, 1.03, 1.05, 1.08] },
  { key: 'dev-text-cols', label: '文字占列', cssVar: '--text-cols', min: 4, max: 13, step: 1, def: 10, unit: '列', presets: [6, 7, 8, 9, 10] },
];

/* 文字颜色(2026-11-01 用户:想直接调文字颜色):只改浅色主题的 --ink / --ink-2;深色主题保持 simple.css 原值 */
type Swatch = { key: string; label: string; cssVar: string; def: string };
const SWATCHES: Swatch[] = [
  { key: 'dev-ink-b', label: '主文字', cssVar: '--ink', def: '#3A3A3C' },
  { key: 'dev-ink-2b', label: '灰色文字', cssVar: '--ink-2', def: '#8E8E93' },
];
/* 「编辑文字」打开后能直接点进去改的文字(只改本页预览,刷新恢复) */
const EDITABLE = '.hero-intro > p:not(.hero-who), .work-year, .work-title, .work-summary';
const DRAFT_KEY = 'dev-text-drafts';

function readColor(c: Swatch) {
  try {
    return localStorage.getItem(c.key) || c.def;
  } catch {
    return c.def;
  }
}

function read(k: Knob) {
  try {
    const raw = localStorage.getItem(k.key);
    const v = Number(raw);
    return raw !== null && Number.isFinite(v) ? v : k.def;
  } catch {
    return k.def;
  }
}

export default function DevRadius() {
  const [open, setOpen] = useState(false);
  const [vals, setVals] = useState(() => KNOBS.map(read));
  useEffect(() => {
    KNOBS.forEach((k, i) => {
      const v = vals[i];
      document.documentElement.style.setProperty(k.cssVar, k.unit === 'px' ? `${v}px` : String(v));
      try {
        if (v === k.def) localStorage.removeItem(k.key);
        else localStorage.setItem(k.key, String(v));
      } catch {
        /* 存不了只是不记忆 */
      }
    });
  }, [vals]);
  const [colors, setColors] = useState(() => SWATCHES.map(readColor));
  useEffect(() => {
    const body = document.body;
    const apply = () => {
      const dark = body.classList.contains('theme-dark');
      SWATCHES.forEach((c, i) => {
        if (dark || colors[i].toLowerCase() === c.def.toLowerCase()) body.style.removeProperty(c.cssVar);
        else body.style.setProperty(c.cssVar, colors[i]);
      });
    };
    apply();
    const mo = new MutationObserver(apply);
    mo.observe(body, { attributes: true, attributeFilter: ['class'] });
    return () => mo.disconnect();
  }, [colors]);

  /* 只在用户自己动取色器 / 点恢复时写 localStorage;热更新改了默认色时不把旧值当成「调过」存下来(2026-11-01 bug) */
  const saveColors = (next: string[]) => {
    setColors(next);
    SWATCHES.forEach((c, i) => {
      try {
        if (next[i].toLowerCase() === c.def.toLowerCase()) localStorage.removeItem(c.key);
        else localStorage.setItem(c.key, next[i]);
      } catch {
        /* 存不了只是不记忆 */
      }
    });
  };

  /* 改过的文字存进 localStorage(按第几段记),刷新、页面热更新后自动填回(2026-11-01 用户:刷新后打的字没了) */
  const [drafts, setDrafts] = useState<Record<string, string>>(() => {
    try {
      return JSON.parse(localStorage.getItem(DRAFT_KEY) || '{}');
    } catch {
      return {};
    }
  });
  const [editing, setEditing] = useState(() => Object.keys(drafts).length > 0);
  useEffect(() => {
    const els = Array.from(document.querySelectorAll<HTMLElement>(EDITABLE));
    const onInput = (e: Event) => {
      const el = e.currentTarget as HTMLElement;
      const i = els.indexOf(el);
      setDrafts((d) => ({ ...d, [i]: el.innerHTML }));
    };
    els.forEach((el, i) => {
      if (drafts[i] !== undefined && el.innerHTML !== drafts[i]) el.innerHTML = drafts[i];   // 存整段 HTML,NetEase 字标、链接这类不是纯文字的也能留住
      if (editing) {
        el.contentEditable = 'plaintext-only';
        if (el.contentEditable !== 'plaintext-only') el.contentEditable = 'true';
        el.spellcheck = false;
        el.addEventListener('input', onInput);
      } else el.removeAttribute('contenteditable');
    });
    document.body.classList.toggle('dev-editing', editing);
    return () => els.forEach((el) => el.removeEventListener('input', onInput));
    // drafts 只在开关切换 / 首次加载时填回,打字时不重填(会把光标弄丢)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editing]);
  useEffect(() => {
    try {
      if (Object.keys(drafts).length) localStorage.setItem(DRAFT_KEY, JSON.stringify(drafts));
      else localStorage.removeItem(DRAFT_KEY);
    } catch {
      /* 存不了只是不记忆 */
    }
  }, [drafts]);

  const set = (i: number, v: number) => setVals((a) => a.map((x, j) => (j === i ? v : x)));
  const fmt = (k: Knob, v: number) => (k.unit === 'px' ? `${v}px` : k.unit === '列' ? `${v} 列` : `${v.toFixed(3).replace(/0+$/, '').replace(/\.$/, '')}×`);

  return createPortal(
    <div className="rd-wrap">
      {open && (
        <div className="rd-panel" role="dialog" aria-label="调节">
          {KNOBS.map((k, i) => (
            <div className="rd-knob" key={k.key}>
              <div className="rd-head">
                <span>{k.label}</span>
                <b>{fmt(k, vals[i])}</b>
              </div>
              <input
                aria-label={k.label}
                max={k.max}
                min={k.min}
                step={k.step}
                style={{ '--p': `${((vals[i] - k.min) / (k.max - k.min)) * 100}%` } as CSSProperties}
                type="range"
                value={vals[i]}
                onChange={(e) => set(i, Number(e.target.value))}
              />
              <div className="rd-presets">
                {k.presets.map((v) => (
                  <button aria-pressed={v === vals[i]} key={v} type="button" onClick={() => set(i, v)}>
                    {v}
                  </button>
                ))}
              </div>
            </div>
          ))}
          {SWATCHES.map((c, i) => (
            <label className="rd-color" key={c.key}>
              <span>{c.label}</span>
              <b>{colors[i].toUpperCase()}</b>
              <input
                aria-label={c.label}
                type="color"
                value={colors[i]}
                onChange={(e) => {
                  const v = e.target.value;
                  saveColors(colors.map((x, j) => (j === i ? v : x)));
                }}
              />
            </label>
          ))}
          {colors.some((v, i) => v.toLowerCase() !== SWATCHES[i].def.toLowerCase()) && (
            <button className="rd-reset" type="button" onClick={() => saveColors(SWATCHES.map((c) => c.def))}>
              颜色恢复默认
            </button>
          )}
          <button aria-pressed={editing} className="rd-edit" type="button" onClick={() => setEditing((e) => !e)}>
            <span>编辑文字</span>
            <i aria-hidden="true" />
          </button>
          {Object.keys(drafts).length > 0 && (
            <button
              className="rd-reset"
              type="button"
              onClick={() => {
                try {
                  localStorage.removeItem(DRAFT_KEY);
                } catch {
                  /* 忽略 */
                }
                location.reload();
              }}
            >
              文字恢复原文({Object.keys(drafts).length} 段改过)
            </button>
          )}
          <button
            className="rd-link"
            type="button"
            onClick={() => {
              setOpen(false);
              document.querySelector<HTMLButtonElement>('.rt-toggle')?.click();
            }}
          >
            入场动画…
          </button>
        </div>
      )}
      <button aria-expanded={open} aria-label="调节" className="rd-toggle" title="调节" type="button" onClick={() => setOpen((o) => !o)}>
        <svg aria-hidden="true" viewBox="0 0 24 24">
          <path d="M4 7h10M18 7h2M4 17h4M12 17h8" />
          <circle cx="16" cy="7" r="2" />
          <circle cx="10" cy="17" r="2" />
        </svg>
      </button>
    </div>,
    document.body,
  );
}
