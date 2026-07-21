/**
 * 站点行为 hooks —— 从 docs/script.js / docs/writing/writing.js 近乎逐行移植。
 * 移植纪律:选择器、常量、时序与旧实现保持一致;头部(#site-nav)由 nav-boot.js
 * 原生层负责,这些 hooks 只在 React 挂载后接管头部以下的行为。
 */
import { useEffect } from 'react';

/* ── writing.js: initStickyMenu ──
   移动端:把胶囊分类条的 sticky top 设为顶栏实际高度(入口内联脚本已同步设过一次,
   这里补 resize / load 监听) */
export function useStickyMenu() {
  useEffect(() => {
    const menu = document.querySelector('.design-menu');
    const header = document.querySelector('.header');
    if (!menu || !header) return;
    const set = () =>
      document.documentElement.style.setProperty(
        '--design-menu-top',
        (header as HTMLElement).offsetHeight + 'px',
      );
    set();
    window.addEventListener('resize', set);
    window.addEventListener('load', set);
    return () => {
      window.removeEventListener('resize', set);
      window.removeEventListener('load', set);
    };
  }, []);
}

/* ── writing.js: initScrollProgress ──
   顶栏底部滚动进度条:进度写到 .header 的 --scroll-progress */
export function useScrollProgress() {
  useEffect(() => {
    const header = document.querySelector('.header') as HTMLElement | null;
    if (!header) return;
    const doc = document.documentElement;
    let ticking = false;
    const update = () => {
      ticking = false;
      const max = doc.scrollHeight - doc.clientHeight;
      const p = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 0;
      header.style.setProperty('--scroll-progress', String(p));
    };
    const onScroll = () => {
      if (!ticking) {
        ticking = true;
        requestAnimationFrame(update);
      }
    };
    update();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
    };
  }, []);
}

/* ── writing.js: initNavSolidOnScroll ──
   分类页:banner 底边滚过顶栏下沿后给顶栏加 .nav-solid(无 banner 的页面自动跳过) */
export function useNavSolidOnScroll() {
  useEffect(() => {
    const nav = document.querySelector('.header.home-nav');
    const banner = document.querySelector('.design-banner-frame');
    if (!nav || !banner) return;
    const update = () => {
      const solid = banner.getBoundingClientRect().bottom <= (nav as HTMLElement).offsetHeight;
      nav.classList.toggle('nav-solid', solid);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update);
    return () => {
      window.removeEventListener('scroll', update);
      window.removeEventListener('resize', update);
    };
  }, []);
}

/* ── writing.js: initNavSpy ──
   右侧导航(.nav-cat[href^="#"])随滚动高亮当前模块 */
export function useNavSpy() {
  useEffect(() => {
    const links = Array.from(
      document.querySelectorAll<HTMLAnchorElement>('.nav-cat[href^="#"]'),
    );
    if (!links.length || !('IntersectionObserver' in window)) return;

    const map = new Map<Element, HTMLAnchorElement>();
    links.forEach((a) => {
      const sec = document.querySelector(a.getAttribute('href')!);
      if (sec) map.set(sec, a);
    });
    if (!map.size) return;

    const spy = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          const a = map.get(entry.target);
          if (a) a.dataset.visible = entry.isIntersecting ? '1' : '';
        });
        let active: HTMLAnchorElement | null = null;
        for (const [, a] of map) {
          if (a.dataset.visible) {
            active = a;
            break;
          }
        }
        links.forEach((a) => a.classList.toggle('active', a === active));
      },
      { rootMargin: '-120px 0px -55% 0px', threshold: 0 },
    );

    map.forEach((_, sec) => spy.observe(sec));
    return () => spy.disconnect();
  }, []);
}

/* ── script.js: initCoverFade ──
   卡片封面媒体加载就绪后淡入(.cover-in),2s 兜底 */
export function useCoverFade() {
  useEffect(() => {
    const covers = document.querySelectorAll(
      '.home-v2 .card-video, .home-v2 .icon-preview-frame, .home-v2 .card-iframe',
    );
    const timers: number[] = [];
    covers.forEach((el) => {
      const show = () => el.classList.add('cover-in');
      if (el.tagName === 'VIDEO') {
        if ((el as HTMLVideoElement).readyState >= 2) show();
        else el.addEventListener('loadeddata', show, { once: true });
      } else {
        el.addEventListener('load', show, { once: true });
      }
      timers.push(window.setTimeout(show, 2000));
    });
    return () => timers.forEach(clearTimeout);
  }, []);
}

/* ── script.js: initPillarEntrance ──
   支柱页加载入场:菜单 / banner / 标题 / 卡片按垂直位置分「片」级联淡入。
   常量与原实现一致:STAGGER=110 / ROW_TOL=28 / COL_STAGGER=180;
   双 rAF 跨过首次绘制;首页 loading 遮罩(html.is-loading)在场时等其摘除再开始。 */
export function usePillarEntrance() {
  useEffect(() => {
    const targets = Array.from(
      document.querySelectorAll<HTMLElement>(
        '.design-menu, .design-banner-frame, .section-divider h2, .card-wrapper',
      ),
    );
    if (!targets.length) return;

    const reveal = (el: HTMLElement) =>
      el.classList.add(el.classList.contains('heading-rise') ? 'heading-rise-in' : 'visible');

    if (!('IntersectionObserver' in window)) {
      targets.forEach(reveal);
      return;
    }

    const STAGGER = 110;
    const ROW_TOL = 28;
    const COL_STAGGER = 180;
    const timers: number[] = [];
    let observer: IntersectionObserver | null = null;
    let mo: MutationObserver | null = null;

    const revealByRow = (els: HTMLElement[]) => {
      const sorted = els
        .slice()
        .sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);
      const rows: HTMLElement[][] = [];
      let lastTop: number | null = null;
      sorted.forEach((el) => {
        const top = Math.round(el.getBoundingClientRect().top);
        if (lastTop === null || top - lastTop > ROW_TOL) rows.push([]);
        lastTop = top;
        rows[rows.length - 1].push(el);
      });
      rows.forEach((row, step) => {
        const rowDelay = step * STAGGER;
        const ordered = row
          .slice()
          .sort((a, b) => a.getBoundingClientRect().left - b.getBoundingClientRect().left);
        ordered.forEach((el, col) => {
          timers.push(window.setTimeout(() => reveal(el), rowDelay + col * COL_STAGGER));
          el.dataset.entered = '1';
        });
      });
    };

    const start = () =>
      requestAnimationFrame(() =>
        requestAnimationFrame(() => {
          const vh = window.innerHeight || document.documentElement.clientHeight;
          const inView = targets.filter((el) => {
            const r = el.getBoundingClientRect();
            return r.top < vh - 40 && r.bottom > 0;
          });
          revealByRow(inView);

          observer = new IntersectionObserver(
            (entries) => {
              const hits = entries
                .filter((e) => e.isIntersecting)
                .map((e) => e.target as HTMLElement);
              hits.forEach((el) => observer!.unobserve(el));
              if (hits.length) revealByRow(hits);
            },
            { root: null, rootMargin: '0px 0px -50px 0px', threshold: 0.1 },
          );
          targets.forEach((el) => {
            if (!el.dataset.entered) observer!.observe(el);
          });
        }),
      );

    const docEl = document.documentElement;
    if (docEl.classList.contains('is-loading')) {
      mo = new MutationObserver((_, obs) => {
        if (docEl.classList.contains('is-loading')) return;
        obs.disconnect();
        start();
      });
      mo.observe(docEl, { attributes: true, attributeFilter: ['class'] });
    } else {
      start();
    }

    return () => {
      timers.forEach(clearTimeout);
      observer?.disconnect();
      mo?.disconnect();
    };
  }, []);
}

/* ── script.js: 顶部平滑滚动 IIFE(a[href^="#"] → scrollIntoView smooth) ──
   React 页里用事件代理实现同样行为,作用域限定在挂载根之内 + 头部(头部由 nav-boot 注入,
   其内部无 # 锚点,保持与旧版 document 级绑定等效) */
export function useSmoothScrollAnchors() {
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      const anchor = (e.target as Element).closest?.('a[href^="#"]');
      if (!anchor) return;
      e.preventDefault();
      const target = document.querySelector(anchor.getAttribute('href')!);
      if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };
    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);
}

/* ── script.js: Sticky Header IIFE ── 顶栏常驻(摘除可能存在的 .header-hidden) */
export function useHeaderAlwaysVisible() {
  useEffect(() => {
    document.querySelector('.header')?.classList.remove('header-hidden');
  }, []);
}

/* ── script.js: updateDynamicScale ──
   .card-dynamic-scale 内容按卡片高度自适应(--content-scale) */
export function useDynamicScale() {
  useEffect(() => {
    const update = () => {
      document.querySelectorAll<HTMLElement>('.card-dynamic-scale').forEach((card) => {
        const cardHeight = card.offsetHeight;
        const contentHeight = parseInt(card.dataset.contentHeight || '') || 812;
        const targetRatio = parseFloat(card.dataset.targetRatio || '') || 0.9;
        card.style.setProperty('--content-scale', String((cardHeight * targetRatio) / contentHeight));
      });
    };
    update();
    window.addEventListener('load', update);
    window.addEventListener('resize', update);
    let ro: ResizeObserver | undefined;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(update);
      document.querySelectorAll('.card-dynamic-scale').forEach((card) => ro!.observe(card));
    }
    return () => {
      window.removeEventListener('load', update);
      window.removeEventListener('resize', update);
      ro?.disconnect();
    };
  }, []);
}
