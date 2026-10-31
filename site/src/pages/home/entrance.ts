/* 首页入场动画的配置(2026-10-25 用户:调参台里能选用哪一种入场,每一种各自调参数)。
   两种:
   - sweep   斜向扫光:一开始整屏空白,一道渐进模糊从左上往右下揭开(index.html 的 .page-reveal);
   - stagger 依次出现:介绍段逐字浮现 → 联系方式 → 首屏作品一条一条浮现(原来的入场);
   - blocks  逐段浮现:照 benji.org 的节奏,一整段一整段轻轻浮上来(字标 → 每段介绍 → 时间 → 作品),
             0.5s、ease、上浮 8px,段与段隔 50ms,作品区前多停 200ms;一秒左右全部到位,察觉不到动画、但有先后。
   参数只有一套,存在 entrance.json(2026-10-31 用户:各种宽度、各种设备的入场参数要一致,只维护一套):
   线上、本地电脑、手机都读它;本地调参面板(RevealTuner)保存时经开发服务器写回这个文件(vite.config.ts entranceStore)。
   原来调参存在各自浏览器的 localStorage,手机和电脑各是一套、线上又是代码里的默认值 —— 三套不一致。
   ENTRANCE_DEFAULTS 只是「恢复默认」用的出厂值 */
import SAVED from './entrance.json';

export type EntranceMode = 'sweep' | 'stagger' | 'blocks';

export type SweepParams = {
  dur: number; // 秒
  ease: string; // EASES 的 key
  angle: number; // 度
  blur: number; // px,过渡带里最糊处
  width: number; // %,分界线 → 纯空白
};

export type StaggerParams = {
  charStep: number; // ms,相邻两个字开始浮现的间隔
  lineStep: number; // ms,换行 / 换段多停的时间
  dur: number; // ms,每个字浮现用多久(作品区按 1.6 倍)
  blur: number; // px,字刚出现时的模糊(作品区 3 倍)
  rise: number; // px,字从多低浮上来(作品区 1.5 倍)
  ease: string; // EASES 的 key
  workGap: number; // ms,上一条作品封面开始浮现后,下一条再等多久
};

export type BlocksParams = {
  step: number; // ms,相邻两段开始浮现的间隔(作品之间是它的 2 倍)
  sectionGap: number; // ms,介绍区走完到作品区开始多停的时间
  dur: number; // ms,每段浮现用多久
  rise: number; // px,从多低浮上来
  blur: number; // px,刚出现时的模糊
  ease: string; // EASES 的 key
};

export type EntranceConfig = { mode: EntranceMode; sweep: SweepParams; stagger: StaggerParams; blocks: BlocksParams };

export const EASES: Record<string, { label: string; css: string; pts: [number, number, number, number] }> = {
  ease: { label: '标准', css: 'ease', pts: [0.25, 0.1, 0.25, 1] },
  inout: { label: '慢进慢出', css: 'cubic-bezier(0.45, 0, 0.2, 1)', pts: [0.45, 0, 0.2, 1] },
  linear: { label: '匀速', css: 'linear', pts: [0, 0, 1, 1] },
  out: { label: '先快后慢', css: 'cubic-bezier(0.22, 1, 0.36, 1)', pts: [0.22, 1, 0.36, 1] },
  in: { label: '先慢后快', css: 'cubic-bezier(0.55, 0, 0.9, 0.4)', pts: [0.55, 0, 0.9, 0.4] },
};

/* 线上默认用逐段浮现(2026-10-25 用户) */
export const ENTRANCE_DEFAULTS: EntranceConfig = {
  mode: 'blocks',
  sweep: { dur: 3.6, ease: 'inout', angle: 135, blur: 18, width: 70 },
  stagger: { charStep: 6, lineStep: 60, dur: 560, blur: 4, rise: 6.2, ease: 'out', workGap: 400 },
  blocks: { step: 50, sectionGap: 200, dur: 500, rise: 8, blur: 0, ease: 'ease' },
};

export const ENTRANCE_MODES: Record<EntranceMode, { label: string; hint: string }> = {
  sweep: { label: '斜向扫光', hint: '整屏空白,一道渐进模糊斜着揭开' },
  stagger: { label: '逐字出现', hint: '介绍逐字浮现,作品一条接一条' },
  blocks: { label: '逐段浮现', hint: '一段一段轻轻浮上来,一秒到位' },
};

const KEY = 'entrance-v1';   /* 旧的浏览器本地存档:读到一次就搬进 entrance.json,然后删掉 */

function normalize(c: Partial<EntranceConfig> & Record<string, any>): EntranceConfig {
  const d = ENTRANCE_DEFAULTS;
  return {
    mode: c.mode === 'stagger' || c.mode === 'blocks' || c.mode === 'sweep' ? c.mode : d.mode,
    sweep: { ...d.sweep, ...c.sweep },
    stagger: { ...d.stagger, ...c.stagger },
    blocks: { ...d.blocks, ...c.blocks },
  };
}

/* 首页、调参面板实际用的配置:entrance.json。
   本地开发时,如果这台浏览器还留着以前存在 localStorage 的调参,先用它、并写回 entrance.json(只搬一次) */
let loaded: EntranceConfig | null = null;
export function loadEntrance(): EntranceConfig {
  if (loaded) return loaded;
  loaded = readEntrance();
  return loaded;
}
function readEntrance(): EntranceConfig {
  if (import.meta.env.DEV) {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) {
        const c = normalize(JSON.parse(raw));
        localStorage.removeItem(KEY);
        saveEntrance(c);
        return c;
      }
    } catch {
      /* 读不到就用文件里的 */
    }
  }
  return normalize(SAVED as Partial<EntranceConfig>);
}

/* 调参面板改了就写回 entrance.json(只在本地开发服务器上有这个接口) */
export function saveEntrance(c: EntranceConfig) {
  if (!import.meta.env.DEV) return;
  loaded = c;
  fetch('/__entrance', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(c) }).catch(() => {});
}

export function currentEntrance(): EntranceConfig {
  return loadEntrance();
}

/* 写进 <html> 的 CSS 变量(只是 CSS 能管的那部分;字间隔、换行停顿、作品间隔由首页脚本在加载时读) */
export function applyEntrance(c: EntranceConfig, root: HTMLElement = document.documentElement) {
  const s = root.style;
  const sw = c.sweep;
  s.setProperty('--rv-dur', `${sw.dur}s`);
  s.setProperty('--rv-ease', EASES[sw.ease]?.css ?? EASES.inout.css);
  s.setProperty('--rv-angle', `${sw.angle}deg`);
  s.setProperty('--rv-blur', `${sw.blur}px`);
  s.setProperty('--rv-width', `${sw.width}%`);
  const st = c.stagger;
  s.setProperty('--st-dur', `${st.dur}ms`);
  s.setProperty('--st-blur', `${st.blur}px`);
  s.setProperty('--st-rise', `${st.rise}px`);
  s.setProperty('--st-ease', EASES[st.ease]?.css ?? EASES.out.css);
  const bk = c.blocks;
  s.setProperty('--bk-dur', `${bk.dur}ms`);
  s.setProperty('--bk-rise', `${bk.rise}px`);
  s.setProperty('--bk-blur', `${bk.blur}px`);
  s.setProperty('--bk-ease', EASES[bk.ease]?.css ?? 'ease');
}

/* 「复制参数」的文字 */
export function describeEntrance(c: EntranceConfig) {
  if (c.mode === 'sweep') {
    const p = c.sweep;
    return `入场:斜向扫光。时长 ${p.dur}s,曲线 ${EASES[p.ease].label}(${EASES[p.ease].css}),角度 ${p.angle}°,模糊 ${p.blur}px,过渡带 ${p.width}%`;
  }
  if (c.mode === 'blocks') {
    const p = c.blocks;
    return `入场:逐段浮现。段间隔 ${p.step}ms,作品区前停顿 ${p.sectionGap}ms,每段时长 ${p.dur}ms,上浮 ${p.rise}px,起始模糊 ${p.blur}px,曲线 ${EASES[p.ease].label}(${EASES[p.ease].css})`;
  }
  const p = c.stagger;
  return `入场:逐字出现。字间隔 ${p.charStep}ms,换行停顿 ${p.lineStep}ms,单字时长 ${p.dur}ms,起始模糊 ${p.blur}px,上浮 ${p.rise}px,曲线 ${EASES[p.ease].label}(${EASES[p.ease].css}),作品间隔 ${p.workGap}ms`;
}
