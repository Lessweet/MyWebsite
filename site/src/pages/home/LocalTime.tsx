/* 介绍段最后一行灰字:城市 + 作者这边的时间 + 时段状态小图标(📍 图钉 2026-10-23 删除)。
   2026-10-23:参考 benji.org 页尾「本地时间 + 城市 + 会睡觉/醒着的小兔」。不照搬兔子,
   换成按时段切换的状态图标(睡觉 / 电脑配咖啡 / 拉面 / 画图 / 写文章),各带一个小循环动效。
   预览某个时段:地址栏加 ?hour=13(0–23)。
   2026-10-23 用户:右边的图标改为天气 —— 取北京实时天气(Open-Meteo,免 key),
   按天气码显示 晴 / 多云 / 阴 / 雾 / 雨 / 雪 / 雷雨(晴和多云分白天黑夜);
   取不到天气时不显示图标。时段图标(SLEEP…WRITE)先留着不用。
   预览某种天气:地址栏加 ?wx=rain(clear / partly / cloudy / fog / rain / snow / storm)。 */
import { useEffect, useState } from 'react';
import type { ReactNode } from 'react';

/* 作者所在时区 UTC+8,无夏令时 */
const MY_TZ = 'Asia/Shanghai';
const MY_CITY = '北京';

type Status = { period: string; label: string; icon: ReactNode };

/* 图标统一 24 viewBox、灰色 1.5px 描边(currentColor)、几何线条(2026-10-23 用户:手绘感
   显粗糙,改回干净线条)。动效类见 simple.css 的 st-* */
const SLEEP: ReactNode = (
  <>
    <path d="M15.5 4.5a7.5 7.5 0 1 0 4.5 13.4 6 6 0 0 1-4.5-13.4Z" />
    <path className="st-z st-z1" d="M17 3.5h2.5L17 6h2.5" />
    <path className="st-z st-z2" d="M20.5 1h1.6l-1.6 1.6h1.6" />
  </>
);
const COFFEE: ReactNode = (
  <>
    <rect x="2" y="6" width="11" height="8" rx="1.2" />
    <path d="M1 17h13" />
    <path d="M15.5 11h5v3.5a2.5 2.5 0 0 1-5 0Z" />
    <path d="M20.5 12h.75a1.6 1.6 0 0 1 0 3.2h-.75" />
    <path className="st-steam st-steam1" d="M17 9.2c-.7-.9.7-1.5 0-2.4" />
    <path className="st-steam st-steam2" d="M19 9.2c-.7-.9.7-1.5 0-2.4" />
  </>
);
const RAMEN: ReactNode = (
  <>
    <path d="M3 11h18a9 8.5 0 0 1-18 0Z" />
    <path d="M9.5 21h5" />
    <path d="M14 2.5 10.5 11M18.5 3.5 13 11" />
    <path className="st-steam st-steam1" d="M5.5 8.6c-.7-.9.7-1.5 0-2.4" />
    <path className="st-steam st-steam2" d="M8 8.2c-.7-.9.7-1.5 0-2.4" />
  </>
);
/* 下午「在画图」:铅笔、钢笔笔尖都不要(2026-10-23 用户),改成电脑 ——
   台式显示器(上午是笔记本配咖啡,区分开),屏幕里循环描一条曲线 */
const DRAW: ReactNode = (
  <>
    <rect height="13" rx="1.5" width="19" x="2.5" y="3.5" />
    <path d="M12 16.5v4M8.5 20.5h7" />
    <path className="st-squiggle" pathLength={1} d="M6 13c2-3.4 3.8-1 5.8-3.4S15 7.8 18 7" />
  </>
);
const WRITE: ReactNode = (
  <>
    <rect x="5" y="3" width="14" height="18" rx="2" />
    <path className="st-line st-line1" pathLength={1} d="M8.5 8h7" />
    <path className="st-line st-line2" pathLength={1} d="M8.5 12h7" />
    <path className="st-line st-line3" pathLength={1} d="M8.5 16h4" />
  </>
);

/* ── 天气 ── */
const LAT = 39.9042;
const LON = 116.4074;
const WX_URL = `https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=weather_code,is_day&timezone=Asia%2FShanghai`;
const WX_TTL = 30 * 60 * 1000;   /* 30 分钟刷新一次;同一会话内用 sessionStorage 缓存,刷新页面不重复请求 */

type WxKind = 'clear' | 'partly' | 'cloudy' | 'fog' | 'rain' | 'snow' | 'storm';
const WX_LABEL: Record<WxKind, string> = {
  clear: '晴', partly: '多云', cloudy: '阴', fog: '雾', rain: '雨', snow: '雪', storm: '雷雨',
};
/* WMO 天气码 → 图标类型 */
function wxKind(code: number): WxKind {
  if (code === 0) return 'clear';
  if (code <= 2) return 'partly';
  if (code === 3) return 'cloudy';
  if (code === 45 || code === 48) return 'fog';
  if (code >= 95) return 'storm';
  if ((code >= 71 && code <= 77) || code === 85 || code === 86) return 'snow';
  return 'rain';   /* 51–67 毛毛雨 / 雨 / 冻雨,80–82 阵雨 */
}

const CLOUD = 'M7.5 18.5h9a3.75 3.75 0 0 0 .5-7.47 5.25 5.25 0 0 0-10.1 1.2 3.15 3.15 0 0 0 .6 6.27Z';
function wxIcon(kind: WxKind, day: boolean): ReactNode {
  switch (kind) {
    case 'clear':
      return day ? (
        <g className="wx-spin">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M18.7 5.3l-1.4 1.4M6.7 17.3l-1.4 1.4" />
        </g>
      ) : (
        <path d="M15.5 4.5a7.5 7.5 0 1 0 4.5 13.4 6 6 0 0 1-4.5-13.4Z" />
      );
    case 'partly':
      return (
        <>
          {day ? (
            <path d="M8.5 3v1.2M3.5 8.5h1.2M5 5l.9.9M12 5l-.9.9M5.6 11a3.2 3.2 0 1 1 6.1-1.6" />
          ) : (
            <path d="M10.8 4.2a4.2 4.2 0 1 0 1.6 5.6 3.3 3.3 0 0 1-1.6-5.6Z" />
          )}
          <path className="wx-drift" d="M9 20h8a3.3 3.3 0 0 0 .45-6.57 4.6 4.6 0 0 0-8.85 1.05A2.8 2.8 0 0 0 9 20Z" />
        </>
      );
    case 'cloudy':
      return <path className="wx-drift" d={CLOUD} />;
    case 'fog':
      return <path className="wx-drift" d="M4 9h16M6 13h12M4 17h16" />;
    case 'rain':
      return (
        <>
          <path d={CLOUD} transform="translate(0 -3)" />
          <path className="wx-fall wx-fall1" d="M9 18l-.8 2" />
          <path className="wx-fall wx-fall2" d="M12.5 18l-.8 2" />
          <path className="wx-fall wx-fall3" d="M16 18l-.8 2" />
        </>
      );
    case 'snow':
      return (
        <>
          <path d={CLOUD} transform="translate(0 -3)" />
          <circle className="wx-fall wx-fall1" cx="9" cy="19" r="0.6" />
          <circle className="wx-fall wx-fall2" cx="12.5" cy="20" r="0.6" />
          <circle className="wx-fall wx-fall3" cx="16" cy="19" r="0.6" />
        </>
      );
    case 'storm':
      return (
        <>
          <path d={CLOUD} transform="translate(0 -3)" />
          <path className="wx-flash" d="M12.8 15.5l-2 3h3l-2 3" />
        </>
      );
  }
}

type Wx = { kind: WxKind; day: boolean };
function readCache(): Wx | null {
  try {
    const raw = sessionStorage.getItem('wx-beijing');
    if (!raw) return null;
    const v = JSON.parse(raw);
    return Date.now() - v.t < WX_TTL ? v.wx : null;
  } catch {
    return null;
  }
}
function useBeijingWeather(): Wx | null {
  const force = new URLSearchParams(location.search).get('wx') as WxKind | null;
  const [wx, setWx] = useState<Wx | null>(() =>
    force && force in WX_LABEL ? { kind: force, day: true } : readCache(),
  );
  useEffect(() => {
    if (force && force in WX_LABEL) return;
    let alive = true;
    const load = () =>
      fetch(WX_URL)
        .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
        .then((d) => {
          const v: Wx = { kind: wxKind(d.current.weather_code), day: d.current.is_day === 1 };
          if (!alive) return;
          setWx(v);
          try {
            sessionStorage.setItem('wx-beijing', JSON.stringify({ t: Date.now(), wx: v }));
          } catch {
            /* 隐私模式等写不进就算了 */
          }
        })
        .catch(() => {});
    if (!readCache()) load();
    const id = window.setInterval(load, WX_TTL);
    return () => {
      alive = false;
      clearInterval(id);
    };
  }, [force]);
  return wx;
}

function statusOf(h: number): Status {
  if (h < 5) return { period: '凌晨', label: '在睡觉', icon: SLEEP };
  if (h < 11) return { period: '上午', label: '电脑和咖啡', icon: COFFEE };
  if (h < 13) return { period: '中午', label: '吃拉面', icon: RAMEN };
  if (h < 18) return { period: '下午', label: '在画图', icon: DRAW };
  return { period: '晚上', label: '在写文章', icon: WRITE };
}

function myTime(now: Date) {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: MY_TZ,
    hour: 'numeric',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(now);
  let h = Number(parts.find((p) => p.type === 'hour')?.value ?? 0);
  const m = parts.find((p) => p.type === 'minute')?.value ?? '00';
  const force = new URLSearchParams(location.search).get('hour');
  if (force !== null && /^\d{1,2}$/.test(force) && Number(force) < 24) h = Number(force);
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return { status: statusOf(h), text: `${h12}:${m}` };
}

export default function LocalTime() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = window.setInterval(() => {
      const d = new Date();
      if (d.getMinutes() !== now.getMinutes()) setNow(d);
    }, 1000);
    return () => clearInterval(id);
  }, [now]);

  const t = myTime(now);
  const wx = useBeijingWeather();
  return (
    <p className="hero-loc">
      {/* 整行一个入场单元,排在介绍段 / 联系方式之后(HomePage 下发 --d) */}
      <span className="hero-ch">
        {MY_CITY} {t.status.period}
        <span className="loc-time">
          {t.text}
        </span>
        {wx && (
          <svg
            key={`${wx.kind}-${wx.day}`}
            aria-label={`北京天气:${WX_LABEL[wx.kind]}`}
            className="loc-status"
            role="img"
            viewBox="0 0 24 24"
          >
            <title>{WX_LABEL[wx.kind]}</title>
            {wxIcon(wx.kind, wx.day)}
          </svg>
        )}
      </span>
    </p>
  );
}
