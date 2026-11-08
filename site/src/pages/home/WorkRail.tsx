/* 作品导航刻度(2026-10-25 用户:参考 Codex 对话导航栏的「消息摘要刻度」,照文章里的录屏做)。
   只在宽屏双栏出现,竖排在页面最右边,第一根线和 Feed 第一条日期顶对齐(试过两栏之间、垂直居中)。
   - 一排短细线,一条作品一根(2026-10-25 用户:一个作品一个节点;试过每张封面图也各一根);
   - 一套样式(2026-10-25 用户:用一套样式,适配用户自动互动、hover 选择):整列只有一个「焦点」——
     悬停时是鼠标指着的那条,其余时候是正在看的那条(随滚动自动走);焦点那根最长、纯黑,紧挨着的上下各一根稍长,其余短的浅灰;
   - 预览卡只有一张,跟着光标上下滑,内容换时高度平滑过渡(文章作者嫌 Codex 的卡片尺寸硬切);
   - 点刻度或点预览卡(2026-10-25 用户:每个节点的小片可以点击直接定位)都滚到那块内容;到了以后文字不再闪(2026-10-31 用户);
   - 鼠标离开,焦点回到正在看的那条。
   所有宽度都显示:双栏在左栏介绍区下面,单栏贴页面右缘、窗口竖直正中;手机上点刻度直接跳过去。样式见 simple.css .work-rail */
import { type CSSProperties, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

/* 刻度不分单栏 / 双栏,只有一套:贴右边、窗口竖直正中,第一条作品滑到窗口中间才出现(2026-11-08 用户:不管几列都在右边,不要两套) */

type Item = {
  date: string;
  title: string;
  cover?: string;
  showcase?: { covers: { src: string }[] };
  gallery?: { src: string }[];
  thumb?: string;
  thumbTint?: string;
};

/* 预览卡缩略图(2026-10-31 用户:去掉简介,试一张很小的封面):四图式取第一张(用 960 宽那档,页面上多半已加载过),
   两图式取右侧第一张文章封面,单图取封面本身 */
function thumbOf(w: Item): { src: string } | null {
  if (w.thumb) return { src: w.thumb };   /* 作品单独指定的预览图优先 */
  const g = w.gallery?.find((it) => it.src);
  if (g) return { src: g.src.replace(/\.webp(\?|$)/, '-960.webp$1') };
  const c = w.showcase?.covers.find((it) => it.src);
  if (c) return { src: c.src };
  return w.cover ? { src: w.cover } : null;
}
/* 预览卡底色取封面主色(2026-11-01 用户):缩略图缩到 24×24,按饱和度加权求平均(灰黑白的像素权重低),
   结果缓存;同源图片才能读像素,读不了就不加色 */
const tintCache = new Map<string, string>();
function coverTint(src: string): Promise<string | null> {
  const hit = tintCache.get(src);
  if (hit) return Promise.resolve(hit);
  return new Promise((resolve) => {
    const img = new Image();
    img.decoding = 'async';
    img.onload = () => {
      try {
        const n = 24;
        const cv = document.createElement('canvas');
        cv.width = n;
        cv.height = n;
        const ctx = cv.getContext('2d', { willReadFrequently: true });
        if (!ctx) return resolve(null);
        ctx.drawImage(img, 0, 0, n, n);
        /* 看整张图取色相(按饱和度加权的向量平均),饱和度、明度统一定死,8 张卡色调协调、不发浑(2026-11-01 用户:背景色不好看) */
        const d = ctx.getImageData(0, 0, n, n).data;
        let x = 0, y = 0, wsum = 0, ssum = 0, cnt = 0;
        for (let i = 0; i < d.length; i += 4) {
          const R = d[i] / 255, G = d[i + 1] / 255, B = d[i + 2] / 255;
          const mx = Math.max(R, G, B), mn = Math.min(R, G, B), ch = mx - mn;
          cnt++;
          if (ch < 0.08) continue;
          let h = mx === R ? ((G - B) / ch) % 6 : mx === G ? (B - R) / ch + 2 : (R - G) / ch + 4;
          h *= Math.PI / 3;
          const w = ch * ch;
          x += Math.cos(h) * w;
          y += Math.sin(h) * w;
          wsum += w;
          ssum += ch;
        }
        const chroma = ssum / cnt;   // 平均彩度:太低说明以黑白灰为主
        const hue = ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
        const c = wsum === 0 || chroma < 0.04 ? 'hsl(240, 3%, 22%)' : `hsl(${Math.round(hue)}, 38%, 36%)`;
        tintCache.set(src, c);
        resolve(c);
      } catch {
        resolve(null);
      }
    };
    img.onerror = () => resolve(null);
    img.src = src;
  });
}
type Block = { el: HTMLElement; work: number };

/* 所有宽度、所有设备都显示(2026-10-31 用户:边距统一 32 后右边有位置放刻度,手机上也要);
   原来手机、平板和 < 640 的窗口不显示。名字沿用 WIDE */
const WIDE = 'all';
/* 点刻度跳转的滚动时长(所有设备同一套):基础 450ms + 每像素 0.12ms,最长 1200ms */
const JUMP_BASE = 450;
const JUMP_PER_PX = 0.12;
const JUMP_MAX = 1200;

/* 轻触感(2026-10-31 用户:手机上划刻度要有 iOS 闹钟滚轮那种震动、机械感)。
   安卓 Chrome 有 navigator.vibrate;iOS Safari 没有,借 iOS 18 起「开关」复选框被点时自带的触感:
   页面外藏一个 <input switch>,每过一根刻度点一下它的 label。都不支持就静默 */
let hapticLabel: HTMLLabelElement | null = null;
function haptic() {
  if (typeof navigator.vibrate === 'function') {
    navigator.vibrate(8);
    return;
  }
  if (!hapticLabel) {
    hapticLabel = document.createElement('label');
    hapticLabel.setAttribute('aria-hidden', 'true');
    hapticLabel.style.cssText = 'position:fixed;left:-9999px;top:0;opacity:0;pointer-events:none';
    const input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    input.tabIndex = -1;
    hapticLabel.appendChild(input);
    document.body.appendChild(hapticLabel);
  }
  hapticLabel.click();
}

/* 从页面上收集每条作品:滚动定位按它的文字块(.work-head)算,屏幕里有没有按整条作品算 */
function collectBlocks(): Block[] {
  return [...document.querySelectorAll<HTMLElement>('.works > .work')].map((el, work) => ({ el, work }));
}

export default function WorkRail({ items }: { items: Item[] }) {
  const [wide, setWide] = useState(() => window.matchMedia(WIDE).matches);
  const [blocks, setBlocks] = useState<Block[]>([]);
  /* 正在看的那条(随滚动自动走) */
  const [current, setCurrent] = useState(-1);
  /* 第一条作品滑到窗口中间才出现(2026-10-25 用户;10-31 试过一直显示,用户:小屏和手机还是要原来的出现时机) */
  const [away, setAway] = useState(true);
  /* 出现过一次以后再藏起来,刻度要一根根往右滑出去(2026-10-31 用户);从没出现过时直接是藏着的 */
  const [shownOnce, setShownOnce] = useState(false);
  useEffect(() => {
    if (!away) setShownOnce(true);
  }, [away]);
  const [hover, setHover] = useState<number | null>(null);
  const [cardY, setCardY] = useState(0);
  const railRef = useRef<HTMLElement>(null);
  /* 手指按在刻度区上拖动中(触屏):焦点跟手指走,松手跳过去 */
  const touching = useRef(false);
  const hoverRef = useRef<number | null>(null);
  /* 触屏松手已经跳过去了,紧跟着的 click 不再跳第二次 */
  const lastTouchUp = useRef(0);
  const tickRefs = useRef<(HTMLButtonElement | null)[]>([]);
  /* 卡片显示第几件:鼠标离开后保持不变,卡片淡出时内容不跳 */
  const [reel, setReel] = useState(0);
  /* 卡片从隐藏到出现那一下不做位移过渡(直接落到位),出现以后上下换作品才跟着刻度滑 */
  const [jump, setJump] = useState(false);
  /* 卡片固定宽度 = 所有作品里最长那行文字(日期或标题)+ 图 + 间距(2026-10-31 用户:不要换行、切换不跳) */
  const measureRef = useRef<HTMLDivElement>(null);
  const [textW, setTextW] = useState(0);
  const [tints, setTints] = useState<Record<string, string>>({});
  useEffect(() => {
    let alive = true;
    items.forEach((w) => {
      const t = thumbOf(w);
      if (t)
        coverTint(t.src).then((c) => {
          if (alive && c) setTints((m) => (m[t.src] === c ? m : { ...m, [t.src]: c }));
        });
    });
    return () => {
      alive = false;
    };
  }, [items]);

  useEffect(() => {
    const mq = window.matchMedia(WIDE);
    const on = () => setWide(mq.matches);
    mq.addEventListener('change', on);
    return () => mq.removeEventListener('change', on);
  }, []);

  /* 页面渲染完再收集(图片的 currentSrc 要等加载挑好尺寸,窗口变化时重收) */
  useEffect(() => {
    if (!wide) return;
    const run = () => setBlocks(collectBlocks());
    run();
    const t = window.setTimeout(run, 1500);
    window.addEventListener('resize', run);
    return () => {
      clearTimeout(t);
      window.removeEventListener('resize', run);
    };
  }, [wide]);

  useEffect(() => {
    if (!wide || !blocks.length) return;
    const update = () => {
      const vh = window.innerHeight;
      /* 正在看的那条:顶边过了视口 40% 那条线的最后一条;滚到底就是最后一条。
         还没滑到第一条(单栏在看介绍)时是 -1:不高亮任何一根(2026-10-31 用户:刻度一直显示) */
      let c = -1;
      blocks.forEach((b, i) => {
        if (b.el.getBoundingClientRect().top <= vh * 0.4) c = i;
      });
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) c = blocks.length - 1;
      setCurrent(c);
      const firstHead = blocks[0].el.querySelector('.work-head') ?? blocks[0].el;
      /* 单栏:第一条作品的日期滑到窗口竖直中间就出现(2026-10-31 用户:原来要滑到顶部才出现,太晚) */
      setAway(firstHead.getBoundingClientRect().top > window.innerHeight / 2);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    return () => window.removeEventListener('scroll', update);
  }, [wide, blocks]);



  /* 刻度藏起来时(单栏滑回介绍区)清掉悬停:藏起来后收不到鼠标离开,再出现时会带着上一张预览卡 */
  useEffect(() => {
    if (away) setHover(null);
  }, [away]);

  useLayoutEffect(() => {
    const box = measureRef.current;
    if (!box) return;
    const fit = () => setTextW(Math.ceil(Math.max(0, ...[...box.children].map((c) => c.getBoundingClientRect().width))));
    fit();
    document.fonts?.ready.then(fit);
  }, [items, wide, blocks.length]);

  /* 鼠标在刻度列上移动:离光标最近的那根当作悬停的那根(成为焦点),预览卡跟着它 */
  const onMove = (clientY: number) => {
    let best = -1;
    let bestD = Infinity;
    tickRefs.current.forEach((t, i) => {
      if (!t) return;
      const r = t.getBoundingClientRect();
      const d = Math.abs(clientY - (r.top + r.height / 2));
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    });
    if (best >= 0) {
      const t = tickRefs.current[best]!;
      const rail = railRef.current!.getBoundingClientRect();
      const r = t.getBoundingClientRect();
      if (hoverRef.current == null) {
        setJump(true);
        requestAnimationFrame(() => requestAnimationFrame(() => setJump(false)));
      }
      setCardY(r.top + r.height / 2 - rail.top);
      setReel(best);
      if (touching.current && hoverRef.current !== best) haptic();
      hoverRef.current = best;
      setHover(best);
    }
  };
  const onLeave = () => {
    if (touching.current) return;
    hoverRef.current = null;
    setHover(null);
  };

  /* 点击:滚到那条作品(日期落在离窗口顶 57 处) */
  const go = (i: number) => {
    const b = blocks[i];
    if (!b) return;
    const head = (el: HTMLElement) => el.querySelector<HTMLElement>('.work-head') ?? el;
    const docTop = (el: HTMLElement) => el.getBoundingClientRect().top + window.scrollY;
    /* 让这条的日期落在离窗口顶 57 处:和双栏时第一条刚打开页面的位置一样,单列时也照这个 */
    const top = docTop(head(b.el)) - 57;
    const target = Math.max(0, Math.min(top, document.documentElement.scrollHeight - window.innerHeight));
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    /* 到了以后不再让文字闪一下(2026-10-31 用户:为什么要闪 —— 原地点、滚过去都不闪) */
    if (Math.abs(window.scrollY - target) < 2) return;   /* 已经在这儿了 */
    /* 滚过去的路上不排入场,到了再从上到下排(HomePage 的 feed-jump-end) */
    const root = document.documentElement;
    root.classList.add('feed-jumping');
    let done = false;
    let raf = 0;
    const stopEvents = ['wheel', 'touchstart', 'keydown'] as const;
    const arrive = () => {
      if (done) return;
      done = true;
      cancelAnimationFrame(raf);
      stopEvents.forEach((ev) => window.removeEventListener(ev, arrive));
      root.classList.remove('feed-jumping');
      window.dispatchEvent(new Event('feed-jump-end'));
    };
    /* 自己控制滚动(2026-10-31 用户:手机上定位过去特别快 —— 浏览器自带的平滑滚动各家速度不同,
       电脑 Chrome 长距离约 1.3s,iPhone 只要 0.3s)。所有设备同一套:时长按距离算、最长 JUMP_MAX,先加速后减速。
       途中滚轮 / 手指 / 键盘一动就停在原地,不和人抢 */
    const from = window.scrollY;
    const dist = target - from;
    const dur = reduce ? 0 : Math.min(JUMP_MAX, JUMP_BASE + Math.abs(dist) * JUMP_PER_PX);
    if (!dur) {
      window.scrollTo(0, target);
      return arrive();
    }
    stopEvents.forEach((ev) => window.addEventListener(ev, arrive, { passive: true }));
    const t0 = performance.now();
    const step = (now: number) => {
      const t = Math.min(1, (now - t0) / dur);
      const e = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;   /* 慢进慢出 */
      window.scrollTo(0, from + dist * e);
      if (t < 1) raf = requestAnimationFrame(step);
      else arrive();
    };
    raf = requestAnimationFrame(step);
  };

  if (!wide || blocks.length < 2) return null;

  const hb = hover != null ? blocks[hover] : null;
  const focus = hover ?? current;

  return (
    <>
    {/* 手机:选作品时全屏模糊层盖住页面,刻度和卡片浮在上面(2026-11-01 用户);电脑上不显示(CSS 控制)。
        刻度容器有 transform,fixed 子元素会跟着它走,所以挂到 body 上 */}
    {createPortal(<div aria-hidden="true" className={`wr-scrim${hb ? ' is-on' : ''}`} />, document.body)}
    {/* 手绘墨线刻度用的滤镜(2026-11-02 用户:刻度试手绘墨线,和天气图标、icon 页 Organic 同一套):
        线条边缘抖一下 + 每 0.56s 轻轻「沸腾」,颜色保持原来的深浅;只在 data-rail="ink" 时用上 */}
    <svg aria-hidden="true" className="wr-ink-defs" height="0" width="0">
      <filter colorInterpolationFilters="sRGB" height="500%" id="wr-ink" width="160%" x="-30%" y="-200%">
        <feTurbulence baseFrequency="0.22" numOctaves={2} result="wob" seed={9} type="fractalNoise" />
        <feDisplacementMap in="SourceGraphic" in2="wob" result="bent" scale={1.5} xChannelSelector="R" yChannelSelector="G" />
        <feTurbulence baseFrequency="0.3" numOctaves={1} result="boil" seed={41} type="fractalNoise">
          <animate attributeName="seed" calcMode="discrete" dur="0.56s" repeatCount="indefinite" values="41;44;47;50" />
        </feTurbulence>
        <feDisplacementMap in="bent" in2="boil" result="alive" scale={1.1} xChannelSelector="G" yChannelSelector="R" />
        <feGaussianBlur in="alive" result="soft" stdDeviation={0.25} />
        <feComponentTransfer in="soft">
          <feFuncA intercept={-0.6} slope={3} type="linear" />
        </feComponentTransfer>
      </filter>
    </svg>
    <nav
      aria-label="作品导航"
      aria-hidden={away || undefined}
      className={`work-rail${hb ? ' is-hover' : ''}${jump ? ' is-jump' : ''}${away ? (shownOnce ? ' is-leaving' : ' is-away') : ''}`}
      ref={railRef}
      style={{ '--n': blocks.length } as CSSProperties}
      onPointerLeave={onLeave}
      onPointerDown={(e) => {
        /* 触屏:按下就进入「划刻度」,手指上下滑焦点跟着走(同电脑悬停),每过一根震一下 */
        if (e.pointerType === 'mouse') return;
        if ((e.target as HTMLElement).closest('.wr-pop')) return;
        touching.current = true;
        hoverRef.current = null;
        e.currentTarget.setPointerCapture(e.pointerId);
        onMove(e.clientY);
      }}
      onPointerUp={(e) => {
        if (!touching.current) return;
        touching.current = false;
        e.currentTarget.releasePointerCapture?.(e.pointerId);
        const target = hoverRef.current;
        lastTouchUp.current = performance.now();
        hoverRef.current = null;
        setHover(null);
        if (target != null) go(target);
      }}
      onPointerCancel={() => {
        touching.current = false;
        hoverRef.current = null;
        setHover(null);
      }}
      onPointerMove={(e) => {
        /* 鼠标在预览卡上时卡片停住,不跟着换内容,方便点它 */
        if ((e.target as HTMLElement).closest('.wr-pop')) return;
        onMove(e.clientY);
      }}
    >
      {blocks.map((b, i) => (
        <button
          aria-current={i === current ? 'true' : undefined}
          aria-label={`${items[b.work]?.date ?? ''} ${items[b.work]?.title ?? ''}`}
          className={`wr-tick${i === focus ? ' is-focus' : ''}${focus >= 0 && Math.abs(i - focus) === 1 ? ' is-near' : ''}`}
          key={i}
          style={{ '--i': i } as CSSProperties}
          ref={(el) => {
            tickRefs.current[i] = el;
          }}
          type="button"
          onBlur={onLeave}
          onClick={() => {
            if (performance.now() - lastTouchUp.current < 600) return;
            go(i);
          }}
          onFocus={(e) => {
            const r = e.currentTarget.getBoundingClientRect();
            onMove(r.top + r.height / 2);
          }}
        >
          <i />
        </button>
      ))}
      {/* 只有一张预览卡(2026-10-31 用户:极简容器):白色卡片跟着刻度上下移,里面的内容直接换成那一件,
          不滚动、不淡入(试过转轮式整列跟着滚,用户:动静更大) */}
      <div aria-hidden="true" className="wr-pop" style={{ top: cardY }} onClick={() => hover != null && go(hover)}>
        {(() => {
          const w = blocks[reel] ? items[blocks[reel].work] : null;
          const thumb = w ? thumbOf(w) : null;
          const tint = thumb ? tints[thumb.src] : undefined;
          return (
        <div className="wr-card" key={reel} style={{ ...(textW ? { '--wr-text-w': `${textW}px` } : {}), ...(tint ? { '--wr-tint': tint } : {}), ...(w?.thumbTint ? { '--wr-top': w.thumbTint } : {}) } as CSSProperties}>
          {(() => {
            return (
              <div className="wr-row">
                {/* 底:同一张图放大 + 高斯模糊铺满卡片,图片上沿淡出时接的是它自己的模糊版,过渡天然连续(2026-11-01 用户:过渡不柔和) */}
                {thumb && <span aria-hidden="true" className="wr-bg" style={{ backgroundImage: `url(${thumb.src})` }} />}
                {thumb && (
                  <span className="wr-thumb">
                    <img alt="" decoding="async" src={thumb.src} />
                  </span>
                )}
                <span className="wr-text">
                  <small>{w?.date}</small>
                  <b>{w?.title}</b>
                </span>
              </div>
            );
          })()}
        </div>
          );
        })()}
        {/* 量宽度用:所有作品的日期、标题各一行,不显示 */}
        <div className="wr-measure" ref={measureRef}>
          {items.flatMap((w, i) => [<span key={`d${i}`}>{w.date}</span>, <span key={`t${i}`}>{w.title}</span>])}
        </div>
      </div>
    </nav>
    </>
  );
}
