/* 入场动画调参面板(2026-10-25 用户:主题键旁边加一个调节器,蒙层 + 居中卡片,左预览右参数;
   能选入场用哪一种,每一种各自调参数)。只在本地开发(import.meta.env.DEV)出现,线上访客看不到。
   配置存在本浏览器 localStorage(见 entrance.ts),首页按它来;「复制参数」把数值给 Claude 写成线上默认。 */
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import {
  EASES,
  ENTRANCE_DEFAULTS,
  ENTRANCE_MODES,
  applyEntrance,
  describeEntrance,
  loadEntrance,
  saveEntrance,
} from './entrance';
import type { BlocksParams, EntranceConfig, EntranceMode, StaggerParams, SweepParams } from './entrance';

/* ── 各参数各自合适的操作方式(2026-10-25 用户:不要每个都是滑块和按钮)──
   控件下面不放解释文字、入场方式卡片不放说明(2026-10-25 用户:删除) */

/* 数值:− / + 步进,可直接输入,下面一排常用值 */
function Stepper({
  value,
  onChange,
  step,
  min,
  max,
  unit,
  chips,
  label,
}: {
  value: number;
  onChange: (v: number) => void;
  step: number;
  min: number;
  max: number;
  unit: string;
  chips: number[];
  label: string;
}) {
  const digits = step < 1 ? 1 : 0;
  const clamp = (v: number) => Number(Math.min(max, Math.max(min, v)).toFixed(digits));
  return (
    <div className="rt-stepper-row">
      <div className="rt-stepper">
        <button aria-label={`减 ${step}${unit}`} type="button" onClick={() => onChange(clamp(value - step))}>−</button>
        <input
          aria-label={label}
          inputMode="decimal"
          value={value}
          onChange={(e) => {
            const v = Number(e.target.value);
            if (!Number.isNaN(v) && e.target.value !== '') onChange(clamp(v));
          }}
        />
        <span>{unit}</span>
        <button aria-label={`加 ${step}${unit}`} type="button" onClick={() => onChange(clamp(value + step))}>+</button>
      </div>
      <div className="rt-chips">
        {chips.map((v) => (
          <button aria-pressed={value === v} className="rt-chip" key={v} type="button" onClick={() => onChange(v)}>
            {v}
            {unit}
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

/* 模糊:一排样张,每张是被模糊过的「Aa 字」,看着选。scale = 样张上的模糊 / 实际模糊 */
function BlurSwatches({ value, onChange, opts, scale }: { value: number; onChange: (v: number) => void; opts: number[]; scale: number }) {
  return (
    <div className="rt-swatches" style={{ gridTemplateColumns: `repeat(${opts.length}, 1fr)` }}>
      {opts.map((v) => (
        <button aria-pressed={value === v} className="rt-swatch" key={v} type="button" onClick={() => onChange(v)}>
          <span style={{ filter: `blur(${v * scale}px)` }}>Aa 字</span>
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

/* 节奏(依次出现):一行 9 个字,每个点是一个字开始浮现的时刻;刻度固定(最慢 30ms/字 正好铺满),
   左右拖 = 改字间隔,点排得越密越快;换行停顿用下面一排选 */
const RHYTHM_CHARS = 9;
const RHYTHM_MAX = 30;
function Rhythm({ charStep, lineStep, onChange }: { charStep: number; lineStep: number; onChange: (charStep: number, lineStep: number) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const span = (RHYTHM_CHARS - 1) * RHYTHM_MAX;
  const set = (clientX: number) => {
    const r = ref.current!.getBoundingClientRect();
    const t = Math.min(1, Math.max(0, (clientX - r.left - 12) / (r.width - 24))) * span;
    onChange(Math.round(t / (RHYTHM_CHARS - 1)), lineStep);
  };
  const pos = (t: number) => `calc(12px + (100% - 24px) * ${t / span})`;
  const end = (RHYTHM_CHARS - 1) * charStep;
  /* 介绍段大约 120 个字、9 行:给一个整段走完要多久的直观数字 */
  const intro = 120 * charStep + 8 * lineStep;
  return (
    <div className="rt-rhythm-wrap">
      <div
        aria-label="字间隔"
        aria-valuemax={RHYTHM_MAX}
        aria-valuemin={0}
        aria-valuenow={charStep}
        className="rt-rhythm"
        ref={ref}
        role="slider"
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          set(e.clientX);
        }}
        onPointerMove={(e) => e.buttons & 1 && set(e.clientX)}
      >
        {Array.from({ length: RHYTHM_CHARS }, (_, k) => (
          <i className="rt-rhythm-dot" key={k} style={{ left: pos(k * charStep) }} />
        ))}
        <b className="rt-rhythm-h" style={{ left: pos(end) }} />
      </div>
      <div className="rt-rhythm-legend">
        <span>
          每字隔 <b>{charStep}ms</b>
        </span>
        <span>介绍段走完约 {(intro / 1000).toFixed(1)}s</span>
      </div>
      <div className="rt-seg-row">
        <span>换行停顿</span>
        <div className="rt-chips">
          {[0, 30, 60, 120, 200].map((v) => (
            <button aria-pressed={lineStep === v} className="rt-chip" key={v} type="button" onClick={() => onChange(charStep, v)}>
              {v}ms
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/* 上浮距离:每张卡片画一个字从虚影的位置浮到实字的位置,箭头长短就是距离 */
function RiseCards({ value, onChange, opts }: { value: number; onChange: (v: number) => void; opts: number[] }) {
  return (
    <div className="rt-rises">
      {opts.map((v) => (
        <button aria-pressed={value === v} className="rt-rise" key={v} type="button" onClick={() => onChange(v)}>
          <svg aria-hidden="true" viewBox="0 0 40 56">
            <text className="rt-rise-ghost" x="20" y={28 + v} textAnchor="middle">字</text>
            {v > 0 && <path className="rt-rise-arrow" d={`M33 ${24 + v} V 22 M30.5 24.5 L33 22 L35.5 24.5`} />}
            <text className="rt-rise-char" x="20" y="28" textAnchor="middle">字</text>
          </svg>
          <small>{v}px</small>
        </button>
      ))}
    </div>
  );
}

/* 逐段浮现的节奏:一张小甘特图,每行一段(字标、介绍各段、时间、作品),横条从开始浮现画到浮现完。
   左右拖 = 改段间隔(拖的是「时间」那行的起点);条的长短跟着每段时长变,作品区前的停顿在下面选 */
const CASCADE_ROWS = ['字标', '介绍 1', '介绍 2', '介绍 3', '联系', '时间', '作品 1', '作品 2'];
const CASCADE_SPAN = 2000;
function Cascade({ p, onChange }: { p: BlocksParams; onChange: (step: number, sectionGap: number) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const starts = CASCADE_ROWS.map((_, i) => (i <= 5 ? i * p.step : 5 * p.step + p.sectionGap + (i - 6) * 2 * p.step));
  const end = starts[starts.length - 1] + p.dur;
  const set = (clientX: number) => {
    const r = ref.current!.getBoundingClientRect();
    const t = Math.min(1, Math.max(0, (clientX - r.left) / r.width)) * CASCADE_SPAN;
    onChange(Math.round(Math.min(150, t / 5) / 5) * 5, p.sectionGap);
  };
  const pct = (t: number) => `${(t / CASCADE_SPAN) * 100}%`;
  return (
    <div className="rt-cascade-wrap">
      <div className="rt-cascade">
        <div className="rt-cascade-labels" aria-hidden="true">
          {CASCADE_ROWS.map((l) => (
            <span key={l}>{l}</span>
          ))}
        </div>
        <div
          aria-label="段间隔"
          aria-valuemax={150}
          aria-valuemin={0}
          aria-valuenow={p.step}
          className="rt-cascade-rows"
          ref={ref}
          role="slider"
          onPointerDown={(e) => {
            e.currentTarget.setPointerCapture(e.pointerId);
            set(e.clientX);
          }}
          onPointerMove={(e) => e.buttons & 1 && set(e.clientX)}
        >
          {starts.map((t, i) => (
            <div className={`rt-cascade-row${i >= 6 ? ' is-work' : ''}`} key={i}>
              <i style={{ left: pct(t), width: pct(p.dur) }} />
            </div>
          ))}
          <b className="rt-cascade-h" style={{ left: pct(starts[5]) }} />
        </div>
      </div>
      <div className="rt-rhythm-legend">
        <span>
          每段隔 <b>{p.step}ms</b>
        </span>
        <span>全部到位约 {(end / 1000).toFixed(2)}s</span>
      </div>
      <div className="rt-seg-row">
        <span>作品区前停顿</span>
        <div className="rt-chips">
          {[0, 100, 200, 400].map((v) => (
            <button aria-pressed={p.sectionGap === v} className="rt-chip" key={v} type="button" onClick={() => onChange(p.step, v)}>
              {v}ms
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/* 入场方式:三张卡片,各画一个小示意 */
function ModeCards({ value, onChange }: { value: EntranceMode; onChange: (v: EntranceMode) => void }) {
  return (
    <div className="rt-modes">
      {(Object.keys(ENTRANCE_MODES) as EntranceMode[]).map((k) => (
        <button aria-pressed={value === k} className="rt-mode" key={k} type="button" onClick={() => onChange(k)}>
          <svg aria-hidden="true" viewBox="0 0 64 40">
            {k === 'blocks' ? (
              [0, 1, 2, 3].map((row) => (
                <rect
                  fill="currentColor"
                  height={row === 3 ? 8 : 5}
                  key={row}
                  opacity={0.7 - row * 0.17}
                  rx="1.5"
                  width={row === 3 ? 56 : [40, 56, 48][row]}
                  x="4"
                  y={4 + row * 9}
                />
              ))
            ) : k === 'sweep' ? (
              <>
                <defs>
                  <linearGradient id="rt-mode-sweep" x1="0" x2="1" y1="0" y2="1">
                    <stop offset="0.25" stopColor="currentColor" stopOpacity="0.55" />
                    <stop offset="0.75" stopColor="currentColor" stopOpacity="0.04" />
                  </linearGradient>
                </defs>
                <rect fill="url(#rt-mode-sweep)" height="40" rx="6" width="64" />
              </>
            ) : (
              [0, 1, 2].map((row) =>
                Array.from({ length: row === 2 ? 4 : 7 }, (_, c) => (
                  <rect
                    fill="currentColor"
                    height="5"
                    key={`${row}-${c}`}
                    opacity={Math.max(0.08, 0.7 - (row * 7 + c) * 0.04)}
                    rx="1.5"
                    width="6"
                    x={4 + c * 8.5}
                    y={8 + row * 11}
                  />
                )),
              )
            )}
          </svg>
          <b>{ENTRANCE_MODES[k].label}</b>
        </button>
      ))}
    </div>
  );
}

/* 预览尺寸(2026-10-25 用户:预览加横版 / 竖版切换) */
type Orient = 'landscape' | 'portrait';
const PREVIEWS: Record<Orient, { w: number; h: number; label: string }> = {
  landscape: { w: 1440, h: 900, label: '横版' },
  portrait: { w: 390, h: 844, label: '竖版' },
};
const ORIENT_KEY = 'entrance-preview-orient';
function loadOrient(): Orient {
  try {
    return localStorage.getItem(ORIENT_KEY) === 'portrait' ? 'portrait' : 'landscape';
  } catch {
    return 'landscape';
  }
}

/* 预览页的入场时间轴:把预览页里所有一次性的动画(扫光、逐字、作品浮现)当成一条时间轴来控制。
   offset = 每个动画相对时间轴起点晚开始多久;拖到 T = 每个动画都暂停在 T - offset。
   无限循环的(天气图标等)不算 */
type Timeline = {
  doc: Document | null;
  offsets: Map<Animation, number>;
  base: number; // 播放时:时间轴 0 点对应预览页的哪个时刻
  paused: boolean;
  T: number;
  total: number;
  seenAt: number; // 第一次看到这一页的时刻(等首屏动画都建好)
  restore: { T: number } | null; // 重新加载后要回到的暂停帧
};

export default function RevealTuner() {
  const [slot] = useState<HTMLElement | null>(() => document.querySelector<HTMLElement>('.head-right'));
  const [open, setOpen] = useState(false);
  const [cfg, setCfgState] = useState<EntranceConfig>(loadEntrance);
  /* 只在用户改参数时存档:放在 effect 里存的话,本地改代码热更新时旧组件会把旧参数写回去,把刚调好的冲掉 */
  const setCfg = (next: EntranceConfig) => {
    saveEntrance(next);
    setCfgState(next);
  };
  const [orient, setOrient] = useState<Orient>(loadOrient);
  const [nonce, setNonce] = useState(0);
  const [copied, setCopied] = useState(false);
  const [masked, setMasked] = useState(false);
  const boxRef = useRef<HTMLDivElement>(null);
  /* 参数区上下边缘渐隐(2026-10-25 用户:底部渐进过渡,顶部也要):上面滚过才淡、下面到底就不淡 */
  const controlsRef = useRef<HTMLDivElement>(null);
  const updateFade = () => {
    const el = controlsRef.current;
    if (!el) return;
    el.toggleAttribute('data-fade-top', el.scrollTop > 1);
    el.toggleAttribute('data-fade-bottom', el.scrollTop + el.clientHeight < el.scrollHeight - 1);
  };
  const [scale, setScale] = useState(0.5);
  const frameRef = useRef<HTMLIFrameElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);
  const scrubbing = useRef(false);
  const downOnBackdrop = useRef(false);
  const [elapsed, setElapsed] = useState(0);
  const [total, setTotal] = useState(0);
  const [playing, setPlaying] = useState(false);
  const tl = useRef<Timeline>({ doc: null, offsets: new Map(), base: 0, paused: false, T: 0, total: 0, seenAt: 0, restore: null });
  const view = PREVIEWS[orient];

  const frameDoc = (): Document | null => {
    try {
      return frameRef.current?.contentDocument ?? null;
    } catch {
      return null;
    }
  };
  const now = (doc: Document) => Number(doc.timeline.currentTime ?? 0);

  /* 收集预览页里新出现的动画,记下它比时间轴起点晚多久 */
  const collect = (doc: Document) => {
    const t = tl.current;
    const fresh = doc.getAnimations().filter((a) => {
      if (t.offsets.has(a) || a.startTime == null) return false;
      return a.effect?.getComputedTiming().iterations !== Infinity;
    });
    if (fresh.length) {
      if (t.offsets.size === 0) t.base = Math.min(...fresh.map((a) => Number(a.startTime)));
      for (const a of fresh) {
        const off = Number(a.startTime) - t.base;
        t.offsets.set(a, off);
        if (t.paused) {
          a.pause();
          a.currentTime = t.T - off;
        }
      }
    }
    let end = 0;
    t.offsets.forEach((off, a) => {
      end = Math.max(end, off + Number(a.effect?.getComputedTiming().endTime ?? 0));
    });
    t.total = end;
  };
  /* 停在时间轴的 T 毫秒处 */
  const seekTo = (T: number) => {
    const t = tl.current;
    t.paused = true;
    t.T = Math.max(0, Math.min(T, t.total));
    t.offsets.forEach((off, a) => {
      a.pause();
      a.currentTime = t.T - off;
    });
    setElapsed(t.T);
    setPlaying(false);
  };
  const playFrom = (T: number) => {
    const t = tl.current;
    const doc = frameDoc();
    if (!doc) return;
    seekTo(T);
    t.offsets.forEach((off, a) => {
      /* 已经播完的停在结尾不动:对播完的动画 play() 会从头再来 */
      if (t.T - off < Number(a.effect?.getComputedTiming().endTime ?? 0)) a.play();
    });
    t.base = now(doc) - t.T;
    t.paused = false;
    setPlaying(true);
  };
  const isFinished = () => tl.current.total > 0 && tl.current.T >= tl.current.total - 1;

  /* 每帧:发现新页面就重置时间轴;收集动画;更新进度 */
  useEffect(() => {
    if (!open) return;
    let raf = 0;
    const tick = () => {
      raf = requestAnimationFrame(tick);
      const doc = frameDoc();
      const t = tl.current;
      if (!doc || !doc.body) return;
      if (t.doc !== doc) {
        t.doc = doc;
        t.offsets = new Map();
        t.paused = false;
        t.T = 0;
        t.total = 0;
        t.seenAt = now(doc);
      }
      collect(doc);
      /* 重新加载后回到原来那一帧:等首屏的动画都建好(作品区要等一下),再停过去、露出预览 */
      if (t.restore && now(doc) - t.seenAt > 500 && t.offsets.size) {
        seekTo(t.restore.T);
        t.restore = null;
        setMasked(false);
      }
      if (scrubbing.current || t.paused) {
        setTotal(t.total);
        return;
      }
      t.T = Math.min(Math.max(0, now(doc) - t.base), t.total);
      setElapsed(t.T);
      setTotal(t.total);
      setPlaying(t.offsets.size > 0 && t.T < t.total);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  /* 重新加载预览;暂停着的话加载完回到同一帧(先遮住,免得看到从头播的那一下) */
  const reload = (keepFrame: boolean) => {
    const t = tl.current;
    if (keepFrame && t.paused && !isFinished()) {
      t.restore = { T: t.T };
      setMasked(true);
    } else {
      t.restore = null;
    }
    setNonce((n) => n + 1);
  };

  /* 拖动 / 点击进度条:暂停在对应的那一帧 */
  const seek = (clientX: number) => {
    const track = trackRef.current;
    if (!track || !tl.current.total) return;
    const r = track.getBoundingClientRect();
    seekTo(Math.min(1, Math.max(0, (clientX - r.left) / r.width)) * tl.current.total);
  };
  const togglePlay = () => {
    const t = tl.current;
    if (!t.offsets.size) return;
    if (!t.paused && !isFinished()) {
      const doc = frameDoc();
      if (doc) seekTo(Math.min(now(doc) - t.base, t.total));
    } else {
      playFrom(isFinished() ? 0 : t.T);
    }
  };

  /* 参数变了:存起来 + 写本页变量;预览页能直接改的(CSS 变量)直接改,不重新加载
     (2026-10-25 用户:暂停之后调参要直接看暂停那一帧,不要从头开始)。
     - 暂停着:停在原地,这一帧换成新参数的样子;扫光时长变了按比例换算,画面位置不跳;
     - 正在播:接着播;已播完:从头播一遍,不然看不出改了什么;
     - 换入场方式、改字间隔 / 换行停顿 / 作品间隔(首页脚本加载时才读)要重新加载预览,暂停着的话回到同一帧 */
  const prev = useRef(cfg);
  useEffect(() => {
    applyEntrance(cfg);
    const old = prev.current;
    prev.current = cfg;
    if (!open || old === cfg) return;
    const needsReload =
      old.mode !== cfg.mode ||
      (cfg.mode === 'stagger' &&
        (old.stagger.charStep !== cfg.stagger.charStep ||
          old.stagger.lineStep !== cfg.stagger.lineStep ||
          old.stagger.workGap !== cfg.stagger.workGap)) ||
      (cfg.mode === 'blocks' && (old.blocks.step !== cfg.blocks.step || old.blocks.sectionGap !== cfg.blocks.sectionGap));
    if (needsReload) return reload(old.mode === cfg.mode);
    const doc = frameDoc();
    if (!doc) return;
    const t = tl.current;
    const finished = isFinished();
    const wasT = t.T;
    applyEntrance(cfg, doc.documentElement);
    /* 改了时长,结束时刻跟着变:下一帧重新算一遍再定位 */
    requestAnimationFrame(() => {
      collect(doc);
      if (finished) return playFrom(0);
      if (t.paused) {
        const k = cfg.mode === 'sweep' ? cfg.sweep.dur / old.sweep.dur : 1;
        seekTo(wasT * k);
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cfg, open]);

  /* 换横版 / 竖版:重新加载,暂停着的话回到同一帧 */
  const switchOrient = (o: Orient) => {
    if (o === orient) return;
    try {
      localStorage.setItem(ORIENT_KEY, o);
    } catch {
      /* 记不住也没关系 */
    }
    setOrient(o);
    reload(true);
  };

  /* 预览框按预览尺寸等比缩放(上面留出横竖切换、下面留出进度条) */
  useLayoutEffect(() => {
    if (!open || !boxRef.current) return;
    const box = boxRef.current;
    const fit = () => setScale(Math.min((box.clientWidth - 32) / view.w, (box.clientHeight - 136) / view.h));
    fit();
    const ro = new ResizeObserver(fit);
    ro.observe(box);
    return () => ro.disconnect();
  }, [open, view.w, view.h]);

  /* 打开、换入场方式(内容高度变了)、窗口尺寸变化时重算一次渐隐 */
  useLayoutEffect(() => {
    if (!open || !controlsRef.current) return;
    updateFade();
    const ro = new ResizeObserver(updateFade);
    ro.observe(controlsRef.current);
    return () => ro.disconnect();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, cfg.mode]);

  /* 打开时锁住页面滚动,Esc 关闭 */
  useEffect(() => {
    if (!open) return;
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    window.addEventListener('keydown', onKey);
    return () => {
      document.body.style.overflow = prevOverflow;
      window.removeEventListener('keydown', onKey);
    };
  }, [open]);

  if (!slot) return null;

  const setSweep = (patch: Partial<SweepParams>) => setCfg({ ...cfg, sweep: { ...cfg.sweep, ...patch } });
  const setStagger = (patch: Partial<StaggerParams>) => setCfg({ ...cfg, stagger: { ...cfg.stagger, ...patch } });
  const setBlocks = (patch: Partial<BlocksParams>) => setCfg({ ...cfg, blocks: { ...cfg.blocks, ...patch } });
  const resetMode = () => setCfg({ ...cfg, [cfg.mode]: ENTRANCE_DEFAULTS[cfg.mode] });

  const copy = async () => {
    const text = describeEntrance(cfg);
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    } catch {
      window.prompt('复制下面这段:', text);
    }
  };

  const sw = cfg.sweep;
  const st = cfg.stagger;
  const bk = cfg.blocks;
  const pct = total ? (elapsed / total) * 100 : 0;

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
            <div aria-label="入场动画参数" aria-modal="true" className="rt-panel" role="dialog">
              <div className="rt-head">
                <h2>入场动画</h2>
                <button aria-label="关闭" className="rt-close" title="关闭(Esc)" type="button" onClick={() => setOpen(false)}>
                  <svg aria-hidden="true" viewBox="0 0 24 24">
                    <path d="M6 6l12 12M18 6L6 18" />
                  </svg>
                </button>
              </div>
              <div className="rt-body">
                <div className="rt-preview" ref={boxRef}>
                  <div aria-label="预览尺寸" className="rt-orient" role="group">
                    {(Object.keys(PREVIEWS) as Orient[]).map((o) => (
                      <button aria-pressed={orient === o} key={o} type="button" onClick={() => switchOrient(o)}>
                        <svg aria-hidden="true" viewBox="0 0 20 20">
                          {o === 'landscape' ? <rect height="10" rx="2" width="16" x="2" y="5" /> : <rect height="16" rx="2" width="10" x="5" y="2" />}
                        </svg>
                        {PREVIEWS[o].label}
                      </button>
                    ))}
                  </div>
                  <iframe
                    key={nonce}
                    src={`./?embed=1&r=${nonce}`}
                    style={{
                      width: view.w,
                      height: view.h,
                      transform: `translate(-50%, -50%) scale(${scale})`,
                      opacity: masked ? 0 : 1,
                    }}
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
                      aria-valuemax={Number((total / 1000).toFixed(1))}
                      aria-valuemin={0}
                      aria-valuenow={Number((elapsed / 1000).toFixed(1))}
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
                      <span style={{ width: `${pct}%` }} />
                      <i style={{ left: `${pct}%` }} />
                    </div>
                    <span className="rt-time">
                      {(elapsed / 1000).toFixed(1)} / {(total / 1000).toFixed(1)}s
                    </span>
                  </div>
                </div>
                <div className="rt-side">
                <div className="rt-controls" ref={controlsRef} onScroll={updateFade}>
                  <div className="rt-field">
                    <span className="rt-label">入场方式</span>
                    <ModeCards value={cfg.mode} onChange={(mode) => setCfg({ ...cfg, mode })} />
                  </div>
                  {cfg.mode === 'sweep' ? (
                    <>
                      <div className="rt-field">
                        <span className="rt-label">时长</span>
                        <Stepper chips={[1.6, 2.6, 3.6, 5, 8]} label="时长(秒)" max={10} min={0.4} step={0.1} unit="s" value={sw.dur} onChange={(dur) => setSweep({ dur })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">方向</span>
                        <AngleDial value={sw.angle} onChange={(angle) => setSweep({ angle })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">模糊强度</span>
                        <BlurSwatches opts={[0, 6, 12, 18, 28, 40]} scale={1 / 8} value={sw.blur} onChange={(blur) => setSweep({ blur })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">过渡带</span>
                        <WidthBar value={sw.width} onChange={(width) => setSweep({ width })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">速度曲线</span>
                        <EaseCards value={sw.ease} onChange={(ease) => setSweep({ ease })} />
                      </div>
                    </>
                  ) : cfg.mode === 'blocks' ? (
                    <>
                      <div className="rt-field">
                        <span className="rt-label">节奏</span>
                        <Cascade p={bk} onChange={(step, sectionGap) => setBlocks({ step, sectionGap })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">每段时长</span>
                        <Stepper chips={[300, 500, 700, 1000]} label="每段时长(毫秒)" max={2000} min={100} step={50} unit="ms" value={bk.dur} onChange={(dur) => setBlocks({ dur })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">上浮距离</span>
                        <RiseCards opts={[0, 4, 8, 16, 24]} value={bk.rise} onChange={(rise) => setBlocks({ rise })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">起始模糊</span>
                        <BlurSwatches opts={[0, 2, 4, 8]} scale={0.85} value={bk.blur} onChange={(blur) => setBlocks({ blur })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">速度曲线</span>
                        <EaseCards value={bk.ease} onChange={(ease) => setBlocks({ ease })} />
                      </div>
                    </>
                  ) : (
                    <>
                      <div className="rt-field">
                        <span className="rt-label">节奏</span>
                        <Rhythm charStep={st.charStep} lineStep={st.lineStep} onChange={(charStep, lineStep) => setStagger({ charStep, lineStep })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">单字时长</span>
                        <Stepper chips={[300, 560, 900, 1200]} label="单字时长(毫秒)" max={3000} min={100} step={20} unit="ms" value={st.dur} onChange={(dur) => setStagger({ dur })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">起始模糊</span>
                        <BlurSwatches opts={[0, 2, 4, 8, 12]} scale={0.85} value={st.blur} onChange={(blur) => setStagger({ blur })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">上浮距离</span>
                        <RiseCards opts={[0, 3, 6.2, 12, 20]} value={st.rise} onChange={(rise) => setStagger({ rise })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">速度曲线</span>
                        <EaseCards value={st.ease} onChange={(ease) => setStagger({ ease })} />
                      </div>
                      <div className="rt-field">
                        <span className="rt-label">作品间隔</span>
                        <Stepper chips={[0, 200, 400, 800]} label="作品间隔(毫秒)" max={2000} min={0} step={50} unit="ms" value={st.workGap} onChange={(workGap) => setStagger({ workGap })} />
                      </div>
                    </>
                  )}
                </div>
                {/* 底栏固定在面板底部,参数区单独滚动(2026-10-25 用户:固定在底部、要有主次):
                    复制参数是主操作(实心),恢复默认最轻(灰色文字,放最左)。
                    重播按钮去掉了(用户:多余,左边播放键播完再点就是从头播) */}
                <div className="rt-actions">
                  <button className="rt-link" type="button" onClick={resetMode}>
                    恢复默认
                  </button>
                  <button className="rt-btn rt-primary" type="button" onClick={copy}>
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
