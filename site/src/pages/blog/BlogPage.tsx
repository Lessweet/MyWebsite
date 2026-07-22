/**
 * Blog 页(docs/blog.html 的 React 版)。DOM 结构与旧页逐类名一致;
 * 筛选逻辑 = writing.js initWritingFilter 的状态化移植(卡片日期倒序、hidden 显隐)。
 */
import { useEffect, useState } from 'react';
import type { CSSProperties } from 'react';
import { blogCards } from '../../content/articles';
import { CatIcon } from '../../shared/catIcons';
import {
  useStickyMenu,
  useScrollProgress,
  usePillarEntrance,
  useHeaderAlwaysVisible,
  useScrollLag,
  useHideNavOnScrollMobile,
} from '../../shared/hooks';

type Filter = 'all' | 'ui' | 'product';

const FILTERS: { key: Filter; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'ui', label: 'UI' },
  { key: 'product', label: 'Product' },
];

export default function BlogPage() {
  const [filter, setFilter] = useState<Filter>('all');
  /* 「Blog.」标题入场:per-character-rise(与首页索引行同一套 pixel-point 规范,
     复用 style.css 的 heading-rise 通用样式,35ms/字)。双 rAF 先让初始隐藏态
     绘制一帧再显现,避免跳过过渡(与站内其它入场动画同一纪律)。 */
  const [titleIn, setTitleIn] = useState(false);
  const cards = blogCards();

  useHeaderAlwaysVisible();
  useStickyMenu();
  useScrollProgress();
  usePillarEntrance();
  useHideNavOnScrollMobile();
  useScrollLag();

  useEffect(() => {
    /* 刷新恢复滚动位置(不在页顶)时不播入场:直接以完成态渲染 ——
       否则动画在视口外照播,用户滑回顶部会撞见「播到一半」(2026-07-22 修复) */
    if (window.scrollY > 100) {
      setTitleIn(true);
      return;
    }
    let r2: number;
    const r1 = requestAnimationFrame(() => {
      r2 = requestAnimationFrame(() => setTitleIn(true));
    });
    return () => {
      cancelAnimationFrame(r1);
      cancelAnimationFrame(r2);
    };
  }, []);

  return (
    <>
      <h1
        className={'page-title heading-rise' + (titleIn ? ' heading-rise-in' : '')}
        aria-label="Blog"
      >
        <span className="heading-rise-mask" aria-hidden="true">
          {'Blog'.split('').map((ch, i) => (
            <span
              key={i}
              className="heading-rise-char"
              style={{ '--d': `${i * 35}ms` } as CSSProperties}
            >
              {ch}
            </span>
          ))}
        </span>
      </h1>
      <aside aria-label="Writing 分类" className="design-menu">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            className={'nav-cat' + (filter === f.key ? ' active' : '')}
            data-filter={f.key}
            type="button"
            onClick={() => setFilter(f.key)}
          >
            <CatIcon kind={f.key} />
            {f.label}
          </button>
        ))}
      </aside>
      <div className="design-content">
        <section className="category-section" id="writing-all">
          <div className="category-grid">
            {cards.map((a) => (
              <div
                key={a.slug}
                className="card-wrapper"
                data-cat={a.cat}
                data-date={a.date}
                data-delay={a.blogDelay}
                data-slug={a.slug}
                hidden={!(filter === 'all' || a.cat === filter)}
              >
                <a className="writing-card" href={`writing/${a.file}`}>
                  {a.blogCover?.type === 'video' ? (
                    <video
                      autoPlay
                      loop
                      muted
                      playsInline
                      poster={a.blogCover.poster}
                      src={a.blogCover.src}
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                        display: 'block',
                      }}
                    />
                  ) : (
                    <iframe
                      loading="lazy"
                      src={a.blogCover!.src}
                      style={{
                        width: '100%',
                        height: '100%',
                        border: 0,
                        display: 'block',
                        pointerEvents: 'none',
                      }}
                    />
                  )}
                </a>
                <div className="card-info writing-info">
                  <h3 className="w-title">{a.title}</h3>
                  <div className="w-excerpt">{a.excerpt}</div>
                  <div className="w-meta">
                    <div className="w-tags">
                      <span className="a-tag">{a.blogTag}</span>
                    </div>
                    <div className="w-date">{a.date}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </>
  );
}
