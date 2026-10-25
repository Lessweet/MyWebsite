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
  width: number; // % 过渡带宽度:分界线 → 纯空白
};

export const REVEAL_DEFAULTS: RevealParams = { dur: 3.6, ease: 'inout', angle: 135, blur: 18, width: 70 };

const EASES: Record<string, { label: string; css: string; pts: [number, number, number, number] }> = {
  inout: { label: '慢进慢出', css: 'cubic-bezier(0.45, 0, 0.2, 1)', pts: [0.45, 0, 0.2, 1] },
  linear: { label: '匀速', css: 'linear', pts: [0, 0, 1, 1] },
  out: { label: '先快后慢', css: 'cubic-bezier(0.22, 1, 0.36, 1)', pts: [0.22, 1, 0.36, 1] },
  in: { label: '先慢后快', css: 'cubic-bezier(0.55, 0, 0.9, 0.4)', pts: [0.55, 0, 0.9, 0.4] },
};

/* v3:模糊带 + 空白过渡合成一个过渡带宽度;v2 存的旧值换算过来(宽度 = 两段相加) */
const KEY = 'reveal-params-v3';
const OLD_KEY = 'reveal-params-v2';

export function loadRevealParams(): RevealParams {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return { ...REVEAL_DEFAULTS, ...JSON.parse(raw) };
    const old = localStorage.getItem(OLD_KEY);
    if (old) {
      const { band, fade, ...rest } = JSON.parse(old);
      const width = typeof band === 'number' && typeof fade === 'number' ? Math.min(100, Math.max(20, band + fade)) : REVEAL_DEFAULTS.width;
      return { ...REVEAL_DEFAULTS, ...rest, width };
    }
  } catch {
    /* 隐私模式等读不到就用默认 */
  }
  return REVEAL_DEFAULTS;
}

export function applyRevealParams(p: RevealParams, root: HTMLElement = document.documentElement) {
  const s = root.style;
  s.setProperty('--rv-dur', `${p.dur}s`);
  s.setProperty('--rv-ease', EASES[p.ease]?.css ?? EASES.inout.css);
  s.setProperty('--rv-angle', `${p.angle}deg`);
  s.setProperty('--rv-blur', `${p.blur}px`);
  s.setProperty('--rv-width', `${p.width}%`);
}

/* ── 各参数各自合适的操作方式(2026-10-25 用户:不要每个都是滑块和按钮)── */

/* 时长:− / + 步进(0.1s),可直接输入,下面几个常用时长快捷选 */
function DurationField({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  const clamp = (v: number) => Math.round(Math.min(10, Math.max(0.4, v)) * 10) / 10;
  return (
    <div className="rt-stepper-row">
      <div className="rt-stepper">
        <button aria-label="减 0.1 秒" type="button" onClick={() => onChange(clamp(value - 0.1))}>−</button>
        <input
          aria-label="时长(秒)"
          inputMode="decimal"
          value={value}
          onChange={(e) => {
            const v = Number(e.target.value);
            if (!Number.isNaN(v) && e.target.value !== '') onChange(clamp(v));
          }}
        />
        <span>s</span>
        <button aria-label="加 0.1 秒" type="button" onClick={() => onChange(clamp(value + 0.1))}>+</button>
      </div>
      <div className="rt-chips">
        {[1.6, 2.6, 3.6, 5, 8].map((v) => (
          <button aria-pressed={value === v} className="rt-chip" key={v} type="button" onClick={() => onChange(v)}>
            {v}s
          </button>
        ))}
      </div>
    </div>
  );
}

/* 角度:圆形方向盘,指针指向扫光前进的方向;拖动或点击设置,吸附到 5° */
function AngleDial({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  const ref = useRef<SVGSVGElement>(null);
  const set = (clientX: number, clientY: number) => {
    const r = ref.current!.getBoundingClientRect();
    const dx = clientX - (r.left + r.width / 2);
    const dy = clientY - (r.top + r.height / 2);
    let deg = (Math.atan2(dx, -dy) * 180) / Math.PI;
    if (deg < 0) deg += 360;
    onChange((Math.round(deg / 5) * 5) % 360);
  };
  const rad = (value * Math.PI) / 180;
  const x = 40 + Math.sin(rad) * 28;
  const y = 40 - Math.cos(rad) * 28;
  const names: Record<number, string> = { 90: '往右', 135: '往右下', 180: '往下', 45: '往右上', 225: '往左下', 270: '往左', 315: '往左上', 0: '往上' };
  return (
    <div className="rt-dial-row">
      <svg
        aria-label="扫光方向"
        className="rt-dial"
        ref={ref}
        role="slider"
        aria-valuenow={value}
        viewBox="0 0 80 80"
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          set(e.clientX, e.clientY);
        }}
        onPointerMove={(e) => e.buttons & 1 && set(e.clientX, e.clientY)}
      >
        <circle cx="40" cy="40" r="36" className="rt-dial-ring" />
        {[0, 45, 90, 135, 180, 225, 270, 315].map((d) => (
          <line
            className="rt-dial-tick"
            key={d}
            x1={40 + Math.sin((d * Math.PI) / 180) * 32}
            x2={40 + Math.sin((d * Math.PI) / 180) * 36}
            y1={40 - Math.cos((d * Math.PI) / 180) * 32}
            y2={40 - Math.cos((d * Math.PI) / 180) * 36}
          />
        ))}
        <line className="rt-dial-needle" x1="40" x2={x} y1="40" y2={y} />
        <circle cx={x} cy={y} r="5" className="rt-dial-knob" />
        <circle cx="40" cy="40" r="2.5" className="rt-dial-knob" />
      </svg>
      <div className="rt-dial-val">
        <b>{value}°</b>
        <span>{names[value] ?? '斜向'}</span>
      </div>
    </div>
  );
}

/* 模糊强度:一排样张,每张是被模糊过的「Aa 字」,看着选 */
function BlurSwatches({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  const opts = [0, 6, 12, 18, 28, 40];
  return (
    <div className="rt-swatches">
      {opts.map((v) => (
        <button aria-pressed={value === v} className="rt-swatch" key={v} type="button" onClick={() => onChange(v)}>
          <span style={{ filter: `blur(${v / 8}px)` }}>Aa 字</span>
          <small>{v}px</small>
        </button>
      ))}
    </div>
  );
}

/* 过渡带宽度(2026-10-25 用户:两个把手的过渡带怎么调都有分割感)——
   模糊和空白现在是一整段渐进过渡,只剩一个量:从分界线到纯空白有多宽。一个把手,拖它定终点;
   条本身画出过渡的样子(内容色 → 底色,缓入缓出),越宽越柔,越窄越利落 */
function WidthBar({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const set = (clientX: number) => {
    const r = ref.current!.getBoundingClientRect();
    onChange(Math.round(Math.min(100, Math.max(20, ((clientX - r.left) / r.width) * 100))));
  };
  const w = value;
  return (
    <div className="rt-tbar-wrap">
      <div
        aria-label="过渡带宽度"
        aria-valuemax={100}
        aria-valuemin={20}
        aria-valuenow={value}
        className="rt-tbar"
        ref={ref}
        role="slider"
        style={{
          background: `linear-gradient(90deg, var(--rt-blur-start) 0%, var(--rt-blur-start) ${w * 0.04}%, var(--rt-blur-end) ${w * 0.5}%, var(--site-bg) ${w}%, var(--site-bg) 100%)`,
        }}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          set(e.clientX);
        }}
        onPointerMove={(e) => e.buttons & 1 && set(e.clientX)}
      >
        <i className="rt-tbar-h" style={{ left: `${value}%` }} />
      </div>
      <div className="rt-tbar-legend">
        <span>分界线</span>
        <span className="rt-tbar-at" style={{ left: `${Math.min(value, 82)}%` }}>{value}% 处纯空白</span>
      </div>
    </div>
  );
}

/* 速度曲线:卡片里画出曲线形状 */
function EaseCards({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="rt-eases">
      {Object.entries(EASES).map(([k, v]) => {
        const [x1, y1, x2, y2] = v.pts;
        const W = 56;
        const H = 36;
        const d = `M0 ${H} C ${x1 * W} ${H - y1 * H}, ${x2 * W} ${H - y2 * H}, ${W} 0`;
        return (
          <button aria-pressed={value === k} className="rt-ease" key={k} type="button" onClick={() => onChange(k)}>
            <svg aria-hidden="true" viewBox={`-2 -2 ${W + 4} ${H + 4}`}>
              <path className="rt-ease-axis" d={`M0 ${H} H ${W}`} />
              <path className="rt-ease-curve" d={d} />
            </svg>
            <span>{v.label}</span>
          </button>
        );
      })}
    </div>
  );
}

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
  /* 播放进度(2026-10-25 用户:预览下方加进度条,支持拖动):直接读写预览页里扫光动画(.page-reveal)的时间点。
     预览页在嵌入模式下扫光播完不移除那层,所以播完也能往回拖 */
  const frameRef = useRef<HTMLIFrameElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);
  const scrubbing = useRef(false);
  const downOnBackdrop = useRef(false);
  const [elapsed, setElapsed] = useState(0);
  const [playing, setPlaying] = useState(false);
  const getAnim = (): Animation | undefined => {
    try {
      return frameRef.current?.contentDocument?.querySelector('.page-reveal')?.getAnimations()[0];
    } catch {
      return undefined;
    }
  };
  useEffect(() => {
    if (!open) return;
    let raf = 0;
    const tick = () => {
      const a = getAnim();
      if (a && !scrubbing.current) {
        setElapsed(Math.min(Number(a.currentTime ?? 0) / 1000, p.dur));
        setPlaying(a.playState === 'running');
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [open, p.dur]);
  useEffect(() => setElapsed(0), [nonce]);
  /* 拖动 / 点击进度条:暂停在对应的那一帧 */
  const seek = (clientX: number) => {
    const track = trackRef.current;
    const a = getAnim();
    if (!track || !a) return;
    const r = track.getBoundingClientRect();
    const ratio = Math.min(1, Math.max(0, (clientX - r.left) / r.width));
    a.pause();
    a.currentTime = ratio * p.dur * 1000;
    setElapsed(ratio * p.dur);
    setPlaying(false);
  };
  const togglePlay = () => {
    const a = getAnim();
    if (!a) return;
    if (a.playState === 'running') {
      a.pause();
    } else {
      if (Number(a.currentTime ?? 0) >= p.dur * 1000 - 1) a.currentTime = 0;   /* 播完了就从头 */
      a.play();
    }
  };

  /* 参数变了:写 localStorage + 本页 <html> 变量,同时直接改预览页的变量,不重新加载预览
     (2026-10-25 用户:暂停之后调参要直接看暂停那一帧,不要从头开始)。
     - 暂停着(含拖到某一帧):停在原地,只是这一帧换成新参数的样子;时长变了按进度比例换算,画面位置不跳;
     - 正在播:接着播;
     - 已播完:改了参数看不出效果,从头播一遍 */
  const prevDur = useRef(p.dur);
  useEffect(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(p));
    } catch {
      /* 存不了也不影响预览 */
    }
    applyRevealParams(p);
    const oldDur = prevDur.current;
    prevDur.current = p.dur;
    if (!open) return;
    const root = frameRef.current?.contentDocument?.documentElement;
    const a = getAnim();
    if (!root || !a) return;
    const t = Number(a.currentTime ?? 0);
    const finished = a.playState === 'finished' || t >= oldDur * 1000 - 1;
    applyRevealParams(p, root);
    if (finished) {
      a.currentTime = 0;
      a.play();
    } else if (oldDur !== p.dur) {
      a.currentTime = (t / oldDur) * p.dur;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [p, open]);
  /* 重播:原地从头播,不重新加载预览 */
  const replay = () => {
    const a = getAnim();
    if (!a) return setNonce((n) => n + 1);
    a.currentTime = 0;
    a.play();
  };

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
    const text = `入场扫光参数:时长 ${p.dur}s,曲线 ${EASES[p.ease].label}(${EASES[p.ease].css}),角度 ${p.angle}°,模糊 ${p.blur}px,过渡带 ${p.width}%`;
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
            onPointerDown={(e) => {
              downOnBackdrop.current = e.target === e.currentTarget;
            }}
            onClick={(e) => {
              // 按下和松开都在蒙层上才关;从卡片里拖出来松手不算
              if (e.target === e.currentTarget && downOnBackdrop.current) setOpen(false);
            }}
          >
           <div aria-label="入场扫光参数" aria-modal="true" className="rt-panel" role="dialog">
            <div className="rt-head">
              <h2>入场扫光</h2>
              <button aria-label="关闭" className="rt-close" title="关闭(Esc)" type="button" onClick={() => setOpen(false)}>
                <svg aria-hidden="true" viewBox="0 0 24 24">
                  <path d="M6 6l12 12M18 6L6 18" />
                </svg>
              </button>
            </div>
            <div className="rt-body">
              <div className="rt-preview" ref={boxRef}>
                <iframe
                  key={nonce}
                  src={`./?embed=1&r=${nonce}`}
                  style={{ width: PREVIEW_W, height: PREVIEW_H, transform: `translate(-50%, -50%) scale(${scale})` }}
                  ref={frameRef}
                  title="入场动画预览"
                />
                <div className="rt-progress">
                  <button aria-label={playing ? '暂停' : '播放'} className="rt-play" type="button" onClick={togglePlay}>
                    <svg aria-hidden="true" viewBox="0 0 16 16">
                      {playing ? <path d="M5 3.5v9M11 3.5v9" /> : <path d="M5 3.2v9.6L12.5 8Z" />}
                    </svg>
                  </button>
                  <div
                    aria-label="播放进度"
                    aria-valuemax={p.dur}
                    aria-valuemin={0}
                    aria-valuenow={Number(elapsed.toFixed(1))}
                    className="rt-track"
                    ref={trackRef}
                    role="slider"
                    tabIndex={0}
                    onPointerDown={(e) => {
                      scrubbing.current = true;
                      e.currentTarget.setPointerCapture(e.pointerId);
                      seek(e.clientX);
                    }}
                    /* 只有按住鼠标才算拖动:松手事件偶尔丢失时,鼠标经过不会再把进度拉走 */
                    onPointerMove={(e) => {
                      if (!(e.buttons & 1)) scrubbing.current = false;
                      else if (scrubbing.current) seek(e.clientX);
                    }}
                    onPointerUp={() => {
                      scrubbing.current = false;
                    }}
                    onPointerCancel={() => {
                      scrubbing.current = false;
                    }}
                    onLostPointerCapture={() => {
                      scrubbing.current = false;
                    }}
                  >
                    <span style={{ width: `${(elapsed / p.dur) * 100}%` }} />
                    <i style={{ left: `${(elapsed / p.dur) * 100}%` }} />
                  </div>
                  <span className="rt-time">
                    {elapsed.toFixed(1)} / {p.dur.toFixed(1)}s
                  </span>
                </div>
              </div>
              <div className="rt-controls">
                <div className="rt-field">
                  <span className="rt-label">时长</span>
                  <DurationField value={p.dur} onChange={(v) => setP({ ...p, dur: v })} />
                  <span className="rt-hint">扫光从开始到全部清楚用多久</span>
                </div>
                <div className="rt-field">
                  <span className="rt-label">方向</span>
                  <AngleDial value={p.angle} onChange={(v) => setP({ ...p, angle: v })} />
                  <span className="rt-hint">拖动指针,指向扫光前进的方向</span>
                </div>
                <div className="rt-field">
                  <span className="rt-label">模糊强度</span>
                  <BlurSwatches value={p.blur} onChange={(v) => setP({ ...p, blur: v })} />
                  <span className="rt-hint">过渡带里最糊的地方有多糊</span>
                </div>
                <div className="rt-field">
                  <span className="rt-label">过渡带</span>
                  <WidthBar value={p.width} onChange={(v) => setP({ ...p, width: v })} />
                  <span className="rt-hint">从分界线到纯空白有多宽:越宽越柔,越窄越利落</span>
                </div>
                <div className="rt-field">
                  <span className="rt-label">速度曲线</span>
                  <EaseCards value={p.ease} onChange={(v) => setP({ ...p, ease: v })} />
                </div>
                <div className="rt-actions">
                  <button className="rt-btn rt-primary" type="button" onClick={replay}>
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
