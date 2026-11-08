import { useEffect } from 'react';

/* 单栏 ⇄ 双栏切换时的过渡(2026-11-08 用户:拖窗口跨过断点时要有移动、保持连续,不要直接切)。
   FLIP:每次 resize 记下这些块在屏幕上的位置;跨过断点的那一次,用上一次记的位置当起点、新布局里的位置当终点,
   先把块平移回起点,再滑到终点。只平移不缩放(文字不变形);栏宽变了文字会重新折行,那一下是即时的,但整块是滑过去的。
   只动起点或终点在屏幕里的块;系统「减少动态效果」时直接切。断点和 simple.css 双栏的媒体查询是同一条 */
const TWO_COL = '(min-width: 1280px) and (orientation: landscape)';
const BLOCKS = '.hero-intro > p, .hero-loc, .works > .work';
const DURATION = 560;
const EASE = 'cubic-bezier(0.2, 0.8, 0.2, 1)';

type Box = { x: number; y: number; h: number };

export function useLayoutMorph() {
  useEffect(() => {
    const mq = window.matchMedia(TWO_COL);
    const still = window.matchMedia('(prefers-reduced-motion: reduce)');
    let two = mq.matches;
    let last = new Map<Element, Box>();
    const measure = () => {
      const m = new Map<Element, Box>();
      document.querySelectorAll(BLOCKS).forEach((el) => {
        const r = el.getBoundingClientRect();
        m.set(el, { x: r.left, y: r.top, h: r.height });
      });
      return m;
    };
    const onScreen = (b: Box) => b.y + b.h > 0 && b.y < window.innerHeight;
    const onResize = () => {
      const now = measure();
      const flipped = mq.matches !== two;
      two = mq.matches;
      if (flipped && !still.matches) {
        now.forEach((to, el) => {
          const from = last.get(el);
          if (!from || !(onScreen(from) || onScreen(to))) return;
          const dx = from.x - to.x, dy = from.y - to.y;
          if (Math.abs(dx) < 1 && Math.abs(dy) < 1) return;
          /* composite: add —— 叠在块自己的入场 / 悬停变换上,不把它们冲掉 */
          el.animate([{ transform: `translate(${dx}px, ${dy}px)` }, { transform: 'translate(0, 0)' }], { duration: DURATION, easing: EASE, composite: 'add' });
        });
      }
      last = now;
    };
    last = measure();
    /* 滚动也会改位置:滚动时更新起点,否则滚过以后再拖窗口,起点是旧的 */
    let raf = 0;
    const onScroll = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => (last = measure()));
    };
    window.addEventListener('resize', onResize);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => {
      window.removeEventListener('resize', onResize);
      window.removeEventListener('scroll', onScroll);
      cancelAnimationFrame(raf);
    };
  }, []);
}
