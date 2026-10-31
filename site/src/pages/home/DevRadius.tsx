import { type CSSProperties, useEffect, useState } from 'react';
import { createPortal } from 'react-dom';

/* 测试版「调节」入口(2026-10-31 用户:右下角入口越来越多,合并成一个):
   右下角最下面一颗,点开小面板 ——
   - 封面圆角(--cover-radius)、悬停放大(--cover-zoom-scale):拖滑杆实时改,不挡页面,边拖边看;
   - 「入场动画…」打开原来的入场调参台(RevealTuner,它自己的按钮藏起来了)。
   值存在 localStorage,刷新保留;定下来后把数值告诉 Claude 写进 simple.css(默认值和 simple.css 一致) */
type Knob = { key: string; label: string; cssVar: string; min: number; max: number; step: number; def: number; unit: string; presets: number[] };
const KNOBS: Knob[] = [
  { key: 'dev-cover-radius', label: '封面圆角', cssVar: '--cover-radius', min: 0, max: 64, step: 1, def: 32, unit: 'px', presets: [8, 16, 24, 32, 48] },
  { key: 'dev-cover-zoom', label: '悬停放大', cssVar: '--cover-zoom-scale', min: 1, max: 1.1, step: 0.005, def: 1.02, unit: '×', presets: [1, 1.02, 1.03, 1.05, 1.08] },
];

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
  const set = (i: number, v: number) => setVals((a) => a.map((x, j) => (j === i ? v : x)));
  const fmt = (k: Knob, v: number) => (k.unit === 'px' ? `${v}px` : `${v.toFixed(3).replace(/0+$/, '').replace(/\.$/, '')}×`);

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
