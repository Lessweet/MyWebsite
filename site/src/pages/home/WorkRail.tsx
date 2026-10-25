/* 作品导航刻度(2026-10-25 用户:参考 Codex 对话导航栏的「消息摘要刻度」,照文章里的录屏做)。
   只在宽屏双栏出现,竖排在页面最右边,第一根线和 Feed 第一条日期顶对齐(试过两栏之间、垂直居中)。
   - 一排短细线,一条作品一根(2026-10-25 用户:一个作品一个节点;试过每张封面图也各一根);
   - 一套样式(2026-10-25 用户:用一套样式,适配用户自动互动、hover 选择):整列只有一个「焦点」——
     悬停时是鼠标指着的那条,其余时候是正在看的那条(随滚动自动走);焦点那根最长、纯黑,紧挨着的上下各一根稍长,其余短的浅灰;
   - 预览卡只有一张,跟着光标上下滑,内容换时高度平滑过渡(文章作者嫌 Codex 的卡片尺寸硬切);
   - 点刻度或点预览卡(2026-10-25 用户:每个节点的小片可以点击直接定位)都滚到那块内容,到了以后那块轻轻闪一下(文章作者:目标已在屏幕内时点了没反应,缺个「你已经在这里了」);
   - 鼠标离开,焦点回到正在看的那条。
   单栏没有悬停、也没地方放,不显示。样式见 simple.css .work-rail */
import { useEffect, useLayoutEffect, useRef, useState } from 'react';

type Item = { date: string; title: string; summary?: string };
type Block = { el: HTMLElement; work: number };

const WIDE = '(min-width: 1152px)';

/* 从页面上收集每条作品:滚动定位按它的文字块(.work-head)算,屏幕里有没有按整条作品算 */
function collectBlocks(): Block[] {
  return [...document.querySelectorAll<HTMLElement>('.works > .work')].map((el, work) => ({ el, work }));
}

export default function WorkRail({ items }: { items: Item[] }) {
  const [wide, setWide] = useState(() => window.matchMedia(WIDE).matches);
  const [blocks, setBlocks] = useState<Block[]>([]);
  /* 正在看的那条(随滚动自动走) */
  const [current, setCurrent] = useState(0);
  const [hover, setHover] = useState<number | null>(null);
  const [cardY, setCardY] = useState(0);
  const railRef = useRef<HTMLElement>(null);
  const tickRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const cardInner = useRef<HTMLDivElement>(null);
  const [cardH, setCardH] = useState(0);

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
      /* 正在看的那条:顶边过了视口 40% 那条线的最后一条;滚到底就是最后一条 */
      let c = 0;
      blocks.forEach((b, i) => {
        if (b.el.getBoundingClientRect().top <= vh * 0.4) c = i;
      });
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) c = blocks.length - 1;
      setCurrent(c);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    return () => window.removeEventListener('scroll', update);
  }, [wide, blocks]);

  /* 预览卡高度跟内容走,用过渡从上一张的高度变过去 */
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
      setHover(best);
    }
  };
  const onLeave = () => setHover(null);

  /* 点击:滚到那块(文字块让日期落在第一条刚打开时的高度,图片块放到视口中间),到了以后那块闪一下 */
  const go = (i: number) => {
    const b = blocks[i];
    if (!b) return;
    const head = (el: HTMLElement) => el.querySelector<HTMLElement>('.work-head') ?? el;
    const docTop = (el: HTMLElement) => el.getBoundingClientRect().top + window.scrollY;
    /* 让这条的日期落在第一条刚打开页面时的高度 */
    const top = docTop(head(b.el)) - docTop(head(blocks[0].el));
    const target = Math.max(0, Math.min(top, document.documentElement.scrollHeight - window.innerHeight));
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    /* 闪一下:在那块内容上临时盖一个圆角框做动画,不碰内容自己的入场动画 */
    const ping = () => {
      /* 闪日期 + 标题 + 简介那一段 */
      const h = head(b.el).getBoundingClientRect();
      const summary = b.el.querySelector('.work-summary')?.getBoundingClientRect();
      const r = { left: h.left, top: h.top, width: Math.max(h.width, summary?.width ?? 0), height: (summary?.bottom ?? h.bottom) - h.top };
      const ring = document.createElement('div');
      ring.className = 'wr-ping';
      const pad = 12;
      Object.assign(ring.style, {
        left: `${r.left + window.scrollX - pad}px`,
        top: `${r.top + window.scrollY - pad}px`,
        width: `${r.width + pad * 2}px`,
        height: `${r.height + pad * 2}px`,
        borderRadius: '12px',
      });
      document.body.appendChild(ring);
      window.setTimeout(() => ring.remove(), 1300);
    };
    if (Math.abs(window.scrollY - target) < 2) return ping();   /* 已经在这儿了:原地闪一下 */
    window.scrollTo({ top: target, behavior: reduce ? 'auto' : 'smooth' });
    let done = false;
    const arrive = () => {
      if (done) return;
      done = true;
      window.removeEventListener('scrollend', arrive);
      ping();
    };
    window.addEventListener('scrollend', arrive, { once: true });
    window.setTimeout(arrive, 900);   /* 不支持 scrollend 的浏览器 */
  };

  if (!wide || blocks.length < 2) return null;

  const hb = hover != null ? blocks[hover] : null;
  const focus = hover ?? current;
  const hw = hb ? items[hb.work] : null;

  return (
    <nav
      aria-label="作品导航"
      className={`work-rail${hb ? ' is-hover' : ''}`}
      ref={railRef}
      onPointerLeave={onLeave}
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
          className={`wr-tick${i === focus ? ' is-focus' : ''}${Math.abs(i - focus) === 1 ? ' is-near' : ''}`}
          key={i}
          ref={(el) => {
            tickRefs.current[i] = el;
          }}
          type="button"
          onBlur={onLeave}
          onClick={() => go(i)}
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
        <div className="wr-card" style={{ height: cardH || undefined }}>
        <div className="wr-card-inner" key={hover ?? -1} ref={cardInner}>
          {hw && (
            <>
              <small>{hw.date}</small>
              <b>{hw.title}</b>
              {hw.summary && <span>{hw.summary}</span>}
            </>
          )}
        </div>
        </div>
      </div>
    </nav>
  );
}
