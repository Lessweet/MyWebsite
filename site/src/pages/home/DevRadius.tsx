import { type CSSProperties, useEffect, useState } from 'react';
import { createPortal } from 'react-dom';

/* 测试版「调节」入口(2026-10-31 用户:右下角入口越来越多,合并成一个):
   右下角最下面一颗,点开小面板 ——
   - 封面圆角(--cover-radius)、悬停放大(--cover-zoom-scale)、文字占列(--text-cols,个人介绍和作品简介一起)、网格槽 = 封面图缝(--grid-gap)、字重(--fw,重点字 = 正文 + 100):拖滑杆实时改,不挡页面,边拖边看;
   - 文字颜色(主文字 / 灰色文字,只改浅色主题)、「编辑文字」开关(个人简介、日期、标题、作品简介直接点进去改,只改预览,刷新恢复);
   - 「入场动画…」打开原来的入场调参台(RevealTuner,它自己的按钮藏起来了)。
   值存在 localStorage,刷新保留;定下来后把数值告诉 Claude 写进 simple.css(默认值和 simple.css 一致) */
type Knob = { key: string; label: string; cssVar: string; min: number; max: number; step: number; def: number; unit: string; presets: number[] };
const KNOBS: Knob[] = [
  { key: 'dev-cover-radius-b', label: '封面圆角', cssVar: '--cover-radius', min: 0, max: 64, step: 1, def: 8, unit: 'px', presets: [8, 16, 24, 32, 48] },
  { key: 'dev-cover-zoom', label: '悬停放大', cssVar: '--cover-zoom-scale', min: 1, max: 1.1, step: 0.005, def: 1.02, unit: '×', presets: [1, 1.02, 1.03, 1.05, 1.08] },
  { key: 'dev-work-pad', label: '卡片内边距', cssVar: '--work-pad', min: 0, max: 48, step: 1, def: 20, unit: 'px', presets: [8, 12, 16, 20, 24] },   /* 卡片模式的作品底卡;圆角自动 = 封面圆角 + 内边距(2026-11-03 用户) */
  { key: 'dev-grid-gap-b', label: '网格槽 / 图缝', cssVar: '--grid-gap', min: 0, max: 32, step: 1, def: 16, unit: 'px', presets: [4, 8, 12, 16, 24] },
  { key: 'dev-fw-b', label: '字重(正文)', cssVar: '--fw', min: 200, max: 500, step: 100, def: 400, unit: '', presets: [200, 300, 400, 500] },
  { key: 'dev-text-cols', label: '文字占列', cssVar: '--text-cols', min: 4, max: 13, step: 1, def: 8, unit: '列', presets: [6, 7, 8, 9, 10] },
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

/* 刻度样式:线 / 圆点 / 手绘墨线(2026-11-02 用户:试过胶囊、空心环、菱形、竖条,都不要) */
const RAIL_STYLES = [
  { key: 'line', short: '线', label: '刻度线' },
  { key: 'dot', short: '点', label: '圆点' },
  { key: 'ink', short: '墨线', label: '手绘墨线' },
] as const;
type RailStyle = (typeof RAIL_STYLES)[number]['key'];

/* 作品排版:Feed(线上默认,index.html 写死 data-mode="feed")/ 卡片(2026-11-03 新样式)。写在 <html data-mode> 上,CSS 按它切换 */
const LAYOUT_MODES = [
  { key: 'card', short: '卡片', label: '卡片模式' },
  { key: 'feed', short: 'Feed', label: 'Feed 模式' },
] as const;
type LayoutMode = (typeof LAYOUT_MODES)[number]['key'];

/* 天气图标风格:2.5D 线条(线上,2026-11-08 用户换成图标实验页那套)/ 手绘墨线。
   写在 <html data-wx="ink"> 上(LocalTime 两套都渲染、CSS 按它显示一套);favicon 不跟着切,线上仍是墨线 */
const WX_STYLES = [
  { key: 'ink', short: '墨线', label: '手绘墨线' },
  { key: 'iso', short: '2.5D', label: '2.5D 线条' },
] as const;
type WxStyle = (typeof WX_STYLES)[number]['key'];

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
    /* 超出滑杆范围的值当成坏值丢掉(2026-11-03:加滑杆时数组顺序变了,热更新把字重 400 存进了网格槽) */
    return raw !== null && Number.isFinite(v) && v >= k.min && v <= k.max ? v : k.def;
  } catch {
    return k.def;
  }
}

export default function DevRadius() {
  const [open, setOpen] = useState(false);
  /* 点页面空白处关掉面板(2026-11-08 用户);点面板里面、调节按钮自己不算 */
  useEffect(() => {
    if (!open) return;
    const onDown = (e: PointerEvent) => {
      if (!(e.target as Element).closest?.('.rd-wrap')) setOpen(false);
    };
    document.addEventListener('pointerdown', onDown);
    return () => document.removeEventListener('pointerdown', onDown);
  }, [open]);
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
  /* 作品刻度样式:线 / 点(2026-11-02 用户:试一版圆点,加个调节器选)。写在 <html data-rail> 上,CSS 按它切换 */
  const [rail, setRail] = useState<RailStyle>(() => {
    try {
      const v = localStorage.getItem('dev-rail-style') as RailStyle | null;
      return v && RAIL_STYLES.some((r) => r.key === v) ? v : 'ink';   /* 本地测试版默认墨线;线上没有这个面板,默认刻度线(2026-11-02 用户) */
    } catch {
      return 'line';
    }
  });
  useEffect(() => {
    document.documentElement.dataset.rail = rail;
    try {
      if (rail === 'ink') localStorage.removeItem('dev-rail-style');
      else localStorage.setItem('dev-rail-style', rail);
    } catch {
      /* 存不了只是不记忆 */
    }
  }, [rail]);
  const [mode, setMode] = useState<LayoutMode>(() => {
    try {
      /* 线上是 Feed(site/index.html 的 data-mode="feed");本地没存过就跟线上一样(2026-11-08 用户:线上默认不是卡片式) */
      return localStorage.getItem('dev-layout-mode') === 'card' ? 'card' : 'feed';
    } catch {
      return 'feed';
    }
  });
  useEffect(() => {
    const root = document.documentElement;
    if (mode === 'feed') root.dataset.mode = 'feed';
    else delete root.dataset.mode;
    try {
      if (mode === 'feed') localStorage.removeItem('dev-layout-mode');
      else localStorage.setItem('dev-layout-mode', mode);
    } catch {
      /* 存不了只是不记忆 */
    }
  }, [mode]);
  const [wxStyle, setWxStyle] = useState<WxStyle>(() => {
    try {
      return localStorage.getItem('dev-wx-style') === 'ink' ? 'ink' : 'iso';
    } catch {
      return 'iso';
    }
  });
  useEffect(() => {
    const root = document.documentElement;
    if (wxStyle === 'ink') root.dataset.wx = 'ink';
    else delete root.dataset.wx;
    try {
      if (wxStyle === 'iso') localStorage.removeItem('dev-wx-style');
      else localStorage.setItem('dev-wx-style', wxStyle);
    } catch {
      /* 存不了只是不记忆 */
    }
  }, [wxStyle]);
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
  const fmt = (k: Knob, v: number) => (k.unit === 'px' ? `${v}px` : k.unit === '列' ? `${v} 列` : k.unit === '' ? `${v} / 重点 ${v + 100}` : `${v.toFixed(3).replace(/0+$/, '').replace(/\.$/, '')}×`);

  /* 一个滑杆:标题 + 当前值,细轨道;常用值是轨道上的小刻度点,点一下跳过去(2026-11-08 用户:面板密密麻麻一堆堆 → 去掉下面整排按钮) */
  const knob = (i: number) => {
    const k = KNOBS[i];
    const pct = (v: number) => ((v - k.min) / (k.max - k.min)) * 100;
    return (
      <div className="rd-knob" key={k.key}>
        <div className="rd-head">
          <span>{k.label}</span>
          <b>{fmt(k, vals[i])}</b>
        </div>
        <div className="rd-track">
          <input
            aria-label={k.label}
            max={k.max}
            min={k.min}
            step={k.step}
            style={{ '--p': `${pct(vals[i])}%` } as CSSProperties}
            type="range"
            value={vals[i]}
            onChange={(e) => {
              /* 吸附(2026-11-08 用户:默认点不好滑到):拖到常用值附近(整条的 4% 以内)就吸到那个值上 */
              const raw = Number(e.target.value);
              const near = k.presets.find((v) => Math.abs(v - raw) <= (k.max - k.min) * 0.04);
              set(i, near ?? raw);
            }}
          />
          {k.presets.map((v) => (
            <button
              aria-label={`${k.label} ${v}`}
              aria-pressed={v === vals[i]}
              className="rd-tick"
              key={v}
              style={{ left: `calc(6px + (100% - 12px) * ${pct(v) / 100})` }}   /* 手柄 12px 只在「轨道宽 − 12」里走,刻度点按同样的范围放,才和手柄中心对齐 */
              title={String(v)}
              type="button"
              onClick={() => set(i, v)}
            >
              <span>{v}</span>
            </button>
          ))}
        </div>
      </div>
    );
  };
  /* 分段选择:一行,左名称、右一组紧凑按钮,选中 = 白底黑字 */
  const seg = <K extends string>(label: string, opts: readonly { key: K; short: string }[], cur: K, pick: (k: K) => void) => (
    <div className="rd-row">
      <span>{label}</span>
      <div className="rd-seg" role="group" aria-label={label}>
        {opts.map((m) => (
          <button aria-pressed={cur === m.key} key={m.key} type="button" onClick={() => pick(m.key)}>
            {m.short}
          </button>
        ))}
      </div>
    </div>
  );

  /* 恢复默认 = 线上参数(2026-11-08 用户):滑杆、颜色回 simple.css 的值;Feed 模式(index.html 写死的)、墨线天气图标、刻度线(线上没有 data-rail,就是刻度线;
     本地测试版默认的是墨线刻度,这里要明确切回「线」);编辑文字关掉。改过的文字草稿不动(那是内容不是参数) */
  const isLive =
    KNOBS.every((k, i) => vals[i] === k.def) &&
    mode === 'feed' &&
    wxStyle === 'iso' &&
    rail === 'line' &&
    !editing &&
    colors.every((v, i) => v.toLowerCase() === SWATCHES[i].def.toLowerCase());
  /* 和线上不一样的参数,一项一行(2026-11-08 用户:底部加「确认修改(n)」)。
     点确认不直接改代码:把清单复制下来,粘贴给 Claude,由它写进 simple.css / 代码里的默认值再提交(同面板顶部的约定) */
  const changes: string[] = [
    ...KNOBS.flatMap((k, i) => (vals[i] === k.def ? [] : [`${k.label}:${fmt(k, k.def)} → ${fmt(k, vals[i])}`])),
    ...(mode === 'feed' ? [] : [`作品排版:Feed 模式 → ${LAYOUT_MODES.find((m) => m.key === mode)?.label}`]),
    ...(wxStyle === 'iso' ? [] : [`图标风格:2.5D 线条 → ${WX_STYLES.find((m) => m.key === wxStyle)?.label}`]),
    ...(rail === 'line' ? [] : [`刻度样式:刻度线 → ${RAIL_STYLES.find((r) => r.key === rail)?.label}`]),
    ...SWATCHES.flatMap((c, i) => (colors[i].toLowerCase() === c.def.toLowerCase() ? [] : [`${c.label}:${c.def} → ${colors[i].toUpperCase()}`])),
  ];
  const [copied, setCopied] = useState(false);
  const confirm = async () => {
    const text = `把调节面板里这些改动写进线上默认:\n${changes.map((c) => `- ${c}`).join('\n')}`;
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      window.prompt('复制下面这段发给 Claude', text);   /* 剪贴板不让写时兜底 */
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  const resetAll = () => {
    setVals(KNOBS.map((k) => k.def));
    setMode('feed');
    setWxStyle('ink');
    setRail('line');
    setEditing(false);
    saveColors(SWATCHES.map((c) => c.def));
  };

  return createPortal(
    <div className="rd-wrap">
      {open && (
        <div className="rd-panel" role="dialog" aria-label="调节">
          <section className="rd-sec">
            <h4>卡片</h4>
            {[0, 1, 2].map(knob)}
          </section>
          <section className="rd-sec">
            <h4>排版</h4>
            {[3, 4, 5].map(knob)}
          </section>
          <section className="rd-sec">
            <h4>样式</h4>
            {seg('作品排版', LAYOUT_MODES, mode, setMode)}
            {seg('图标风格', WX_STYLES, wxStyle, setWxStyle)}
            {seg('刻度样式', RAIL_STYLES, rail, setRail)}
          </section>
          <section className="rd-sec">
            <h4>颜色</h4>
            {SWATCHES.map((c, i) => (
              <label className="rd-row rd-color" key={c.key}>
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
          </section>
          <section className="rd-sec rd-foot">
            <button aria-pressed={editing} className="rd-row rd-edit" type="button" onClick={() => setEditing((e) => !e)}>
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
              className="rd-row rd-link"
              type="button"
              onClick={() => {
                setOpen(false);
                document.querySelector<HTMLButtonElement>('.rt-toggle')?.click();
              }}
            >
              <span>入场动画</span>
              <i aria-hidden="true">→</i>
            </button>
            <div className="rd-actions">
              <button className="rd-restore" disabled={isLive} type="button" onClick={resetAll}>
                恢复默认
              </button>
              <button className="rd-confirm" disabled={!changes.length} title={changes.join('\n')} type="button" onClick={confirm}>
                {copied ? '已复制,发给 Claude' : '确认修改'}
                {!copied && changes.length > 0 && <i>{changes.length}</i>}
              </button>
            </div>
          </section>
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
