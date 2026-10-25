/* 入场扫光(.page-reveal)调参面板(2026-10-25 用户:主题键旁边加一个调节器,点开全屏模态,预览 + 参数)。
   只在本地开发(import.meta.env.DEV)出现,线上访客看不到。
   参数写到 <html> 的 --rv-* 变量,并存在本浏览器 localStorage;预览是缩小的 1440 × 900 首页(?embed=1),
   改参数自动重播。「复制参数」把数值给 Claude 写进 simple.css 当正式默认值。 */
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

export type RevealParams = {
  dur: number; // 秒
  ease: string; // EASES 的 key
  angle: number; // 度
  blur: number; // px
  band: number; // % 模糊带
  fade: number; // % 空白过渡
};

export const REVEAL_DEFAULTS: RevealParams = { dur: 3.6, ease: 'inout', angle: 135, blur: 18, band: 10, fade: 20 };

const EASES: Record<string, { label: string; css: string }> = {
  inout: { label: '慢进慢出', css: 'cubic-bezier(0.45, 0, 0.2, 1)' },
  linear: { label: '匀速', css: 'linear' },
  out: { label: '先快后慢', css: 'cubic-bezier(0.22, 1, 0.36, 1)' },
  in: { label: '先慢后快', css: 'cubic-bezier(0.55, 0, 0.9, 0.4)' },
};

const KEY = 'reveal-params-v1';

export function loadRevealParams(): RevealParams {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return { ...REVEAL_DEFAULTS, ...JSON.parse(raw) };
  } catch {
    /* 隐私模式等读不到就用默认 */
  }
  return REVEAL_DEFAULTS;
}

export function applyRevealParams(p: RevealParams) {
  const s = document.documentElement.style;
  s.setProperty('--rv-dur', `${p.dur}s`);
  s.setProperty('--rv-ease', EASES[p.ease]?.css ?? EASES.inout.css);
  s.setProperty('--rv-angle', `${p.angle}deg`);
  s.setProperty('--rv-blur', `${p.blur}px`);
  s.setProperty('--rv-band', `${p.band}%`);
  s.setProperty('--rv-fade', `${p.fade}%`);
}

const SLIDERS: { key: keyof RevealParams; label: string; min: number; max: number; step: number; unit: string; hint: string }[] = [
  { key: 'dur', label: '时长', min: 0.6, max: 8, step: 0.1, unit: 's', hint: '扫光从左上走到右下用多久' },
  { key: 'angle', label: '角度', min: 90, max: 180, step: 5, unit: '°', hint: '90 从左往右,135 斜向,180 从上往下' },
  { key: 'blur', label: '模糊强度', min: 0, max: 40, step: 1, unit: 'px', hint: '分界线附近内容有多糊' },
  { key: 'band', label: '模糊带宽度', min: 2, max: 40, step: 1, unit: '%', hint: '越小分界越硬,越大越柔' },
  { key: 'fade', label: '空白过渡', min: 0, max: 60, step: 1, unit: '%', hint: '模糊之后多远变成纯空白' },
];

const PREVIEW_W = 1440;
const PREVIEW_H = 900;

export default function RevealTuner() {
  const [slot] = useState<HTMLElement | null>(() => document.querySelector<HTMLElement>('.head-right'));
  const [open, setOpen] = useState(false);
  const [p, setP] = useState<RevealParams>(loadRevealParams);
  const [nonce, setNonce] = useState(0);
  const [copied, setCopied] = useState(false);
  const boxRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.5);

  /* 参数变了:写 localStorage + <html> 变量,稍等一下自动重播预览 */
  useEffect(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(p));
    } catch {
      /* 存不了也不影响预览 */
    }
    applyRevealParams(p);
    if (!open) return;
    const t = window.setTimeout(() => setNonce((n) => n + 1), 350);
    return () => clearTimeout(t);
  }, [p, open]);

  /* 预览框按 1440 × 900 等比缩放 */
  useLayoutEffect(() => {
    if (!open || !boxRef.current) return;
    const box = boxRef.current;
    const fit = () => setScale(Math.min(box.clientWidth / PREVIEW_W, box.clientHeight / PREVIEW_H));
    fit();
    const ro = new ResizeObserver(fit);
    ro.observe(box);
    return () => ro.disconnect();
  }, [open]);

  /* 打开时锁住页面滚动,Esc 关闭 */
  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    window.addEventListener('keydown', onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener('keydown', onKey);
    };
  }, [open]);

  if (!slot) return null;

  const copy = async () => {
    const text = `入场扫光参数:时长 ${p.dur}s,曲线 ${EASES[p.ease].label}(${EASES[p.ease].css}),角度 ${p.angle}°,模糊 ${p.blur}px,模糊带 ${p.band}%,空白过渡 ${p.fade}%`;
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    } catch {
      window.prompt('复制下面这段:', text);
    }
  };

  return (
    <>
      {createPortal(
        <button aria-label="调节入场动画" className="rt-toggle" title="调节入场动画" type="button" onClick={() => setOpen(true)}>
          <svg aria-hidden="true" viewBox="0 0 24 24">
            <path d="M4 7h10M18 7h2M4 17h4M12 17h8" />
            <circle cx="16" cy="7" r="2" />
            <circle cx="10" cy="17" r="2" />
          </svg>
        </button>,
        slot,
      )}
      {open &&
        createPortal(
          /* 蒙层把背后的页面模糊掉,中间一张卡片放调参台;点卡片外面关闭(2026-10-25 用户:不要全屏页) */
          <div
            className="rt-modal"
            onClick={(e) => {
              if (e.target === e.currentTarget) setOpen(false);
            }}
          >
           <div aria-label="入场扫光参数" aria-modal="true" className="rt-panel" role="dialog">
            <div className="rt-head">
              <h2>入场扫光</h2>
              <button className="rt-btn" type="button" onClick={() => setOpen(false)}>
                关闭
              </button>
            </div>
            <div className="rt-body">
              <div className="rt-preview" ref={boxRef}>
                <iframe
                  key={nonce}
                  src={`./?embed=1&r=${nonce}`}
                  style={{ width: PREVIEW_W, height: PREVIEW_H, transform: `translate(-50%, -50%) scale(${scale})` }}
                  title="入场动画预览"
                />
              </div>
              <div className="rt-controls">
                {SLIDERS.map((s) => (
                  <label className="rt-field" key={s.key}>
                    <span className="rt-label">
                      {s.label}
                      <b>
                        {p[s.key]}
                        {s.unit}
                      </b>
                    </span>
                    <input
                      max={s.max}
                      min={s.min}
                      step={s.step}
                      type="range"
                      value={p[s.key] as number}
                      onChange={(e) => setP({ ...p, [s.key]: Number(e.target.value) })}
                    />
                    <span className="rt-hint">{s.hint}</span>
                  </label>
                ))}
                <div className="rt-field">
                  <span className="rt-label">速度曲线</span>
                  <div className="rt-seg">
                    {Object.entries(EASES).map(([k, v]) => (
                      <button
                        aria-pressed={p.ease === k}
                        className="rt-btn"
                        key={k}
                        type="button"
                        onClick={() => setP({ ...p, ease: k })}
                      >
                        {v.label}
                      </button>
                    ))}
                  </div>
                </div>
                <div className="rt-actions">
                  <button className="rt-btn rt-primary" type="button" onClick={() => setNonce((n) => n + 1)}>
                    重播
                  </button>
                  <button className="rt-btn" type="button" onClick={() => setP(REVEAL_DEFAULTS)}>
                    恢复默认
                  </button>
                  <button className="rt-btn" type="button" onClick={copy}>
                    {copied ? '已复制' : '复制参数'}
                  </button>
                </div>
              </div>
            </div>
           </div>
          </div>,
          document.body,
        )}
    </>
  );
}
