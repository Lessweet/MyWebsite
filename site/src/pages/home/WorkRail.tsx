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

type Item = {
  date: string;
  title: string;
  cover?: string;
  showcase?: { covers: { src: string }[] };
  gallery?: { src: string; tint?: string }[];
};

/* 预览卡缩略图(2026-10-31 用户:去掉简介,试一张很小的封面):四图式取第一张(用 960 宽那档,页面上多半已加载过),
   两图式取右侧第一张文章封面,单图取封面本身 */
function thumbOf(w: Item): { src: string; tint?: string } | null {
  const g = w.gallery?.find((it) => it.src);
  if (g) return { src: g.src.replace(/\.webp(\?|$)/, '-960.webp$1'), tint: g.tint };
  const c = w.showcase?.covers.find((it) => it.src);
  if (c) return { src: c.src };
  return w.cover ? { src: w.cover } : null;
}
type Block = { el: HTMLElement; work: number };

/* 所有宽度、所有设备都显示(2026-10-31 用户:边距统一 32 后右边有位置放刻度,手机上也要);
   原来手机、平板和 < 640 的窗口不显示。名字沿用 WIDE */
const WIDE = 'all';

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
  /* 单栏(竖排、手机)时第一条作品滑到顶部才出现(2026-10-25 用户;10-31 试过一直显示,用户:小屏和手机还是要原来的出现时机);
     双栏一打开就在 */
  const [away, setAway] = useState(() => !window.matchMedia('(min-width: 1280px)').matches);
  /* 出现过一次以后再藏起来,刻度要一根根往右滑出去(2026-10-31 用户);从没出现过时直接是藏着的 */
  const [shownOnce, setShownOnce] = useState(false);
  useEffect(() => {
    if (!away) setShownOnce(true);
  }, [away]);
  const [hover, setHover] = useState<number | null>(null);
  const [cardY, setCardY] = useState(0);
  /* 双栏时刻度放在左栏介绍区下面(2026-10-31 用户:右上角不容易察觉);top 跟着介绍区底边算 */
  const [railTop, setRailTop] = useState<number | null>(null);
  const railRef = useRef<HTMLElement>(null);
  /* 手指按在刻度区上拖动中(触屏):焦点跟手指走,松手跳过去 */
  const touching = useRef(false);
  const hoverRef = useRef<number | null>(null);
  /* 触屏松手已经跳过去了,紧跟着的 click 不再跳第二次 */
  const lastTouchUp = useRef(0);
  const tickRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const cardInner = useRef<HTMLDivElement>(null);
  const [cardH, setCardH] = useState(0);
  /* 卡片固定宽度 = 所有作品里最长那行文字(日期或标题)+ 图 + 间距(2026-10-31 用户:不要换行、切换不跳) */
  const measureRef = useRef<HTMLDivElement>(null);
  const [textW, setTextW] = useState(0);

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
      const twoCol = window.matchMedia('(min-width: 1280px)').matches;
      const firstHead = blocks[0].el.querySelector('.work-head') ?? blocks[0].el;
      setAway(!twoCol && firstHead.getBoundingClientRect().top > 60);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    return () => window.removeEventListener('scroll', update);
  }, [wide, blocks]);

  useEffect(() => {
    if (!wide || !blocks.length) return;
    const intro = document.querySelector<HTMLElement>('.intro-col');
    const place = () => {
      const railH = railRef.current?.offsetHeight ?? 0;
      /* 单列(竖排):贴页面右缘、窗口竖直正中(2026-10-31 用户:不放右上角) */
      if (!intro || !window.matchMedia('(min-width: 1280px)').matches) {
        return setRailTop(Math.round((window.innerHeight - railH) / 2));
      }
      /* 放在介绍区底边到窗口底这块空白的正中(2026-10-31 用户:左下空白区域的一半位置);
         窗口矮、空白不够时至少离介绍区 48 */
      const introBottom = intro.getBoundingClientRect().bottom;
      const top = Math.max(introBottom + 48, introBottom + (window.innerHeight - introBottom - railH) / 2);
      setRailTop(Math.round(top));
    };
    place();
    const ro = new ResizeObserver(place);
    if (intro) ro.observe(intro);
    window.addEventListener('resize', place);
    return () => {
      ro.disconnect();
      window.removeEventListener('resize', place);
    };
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

  /* 预览卡高度跟内容走,用过渡从上一张的高度变过去;宽度固定(2026-10-31 用户:按内容变宽窄,切换时跳) */
  useLayoutEffect(() => {
    const el = cardInner.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setCardH(el.offsetHeight));
    ro.observe(el);
    setCardH(el.offsetHeight);
    return () => ro.disconnect();
  }, [hover, wide, blocks.length]);

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
      setCardY(r.top + r.height / 2 - rail.top);
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
    window.scrollTo({ top: target, behavior: reduce ? 'auto' : 'smooth' });
    let done = false;
    const arrive = () => {
      if (done) return;
      done = true;
      window.removeEventListener('scrollend', arrive);
      root.classList.remove('feed-jumping');
      window.dispatchEvent(new Event('feed-jump-end'));
    };
    /* 能报「滚动结束」的浏览器就等它;不支持的(旧 Safari)按距离估一个时间 —— 固定 900ms 时,
       从页底滚回第一条这种长距离还没到就开始排入场 */
    const from = window.scrollY;
    const hasScrollEnd = 'onscrollend' in document.documentElement;
    if (hasScrollEnd) window.addEventListener('scrollend', arrive, { once: true });
    else setTimeout(arrive, Math.min(1600, 400 + Math.abs(from - target) * 0.4));
  };

  if (!wide || blocks.length < 2) return null;

  const hb = hover != null ? blocks[hover] : null;
  const focus = hover ?? current;
  const hw = hb ? items[hb.work] : null;
  const thumb = hw ? thumbOf(hw) : null;

  return (
    <nav
      aria-label="作品导航"
      aria-hidden={away || undefined}
      className={`work-rail${hb ? ' is-hover' : ''}${away ? (shownOnce ? ' is-leaving' : ' is-away') : ''}`}
      ref={railRef}
      style={{ ...(railTop != null ? { top: railTop } : {}), '--n': blocks.length } as CSSProperties}
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
      {/* 只有一张预览卡:跟着悬停的那根线上下滑,内容换时高度平滑过渡 */}
      <div aria-hidden="true" className="wr-pop" style={{ top: cardY }} onClick={() => hover != null && go(hover)}>
        <div
          className="wr-card"
          style={{ height: cardH || undefined, ...(textW ? { '--wr-text-w': `${textW}px` } : {}) } as CSSProperties}
        >
        <div className="wr-card-inner" key={hover ?? -1} ref={cardInner}>
          {hw && (
            <>
              {thumb && (
                <span className="wr-thumb" style={thumb.tint ? { background: thumb.tint } : undefined}>
                  <img alt="" decoding="async" src={thumb.src} />
                </span>
              )}
              <span className="wr-text">
                <small>{hw.date}</small>
                <b>{hw.title}</b>
              </span>
            </>
          )}
        </div>
        </div>
        {/* 量宽度用:所有作品的日期、标题各一行,不显示 */}
        <div className="wr-measure" ref={measureRef}>
          {items.flatMap((w, i) => [<span key={`d${i}`}>{w.date}</span>, <span key={`t${i}`}>{w.title}</span>])}
        </div>
      </div>
    </nav>
  );
}
