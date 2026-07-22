/**
 * 页面标题(Blog / Archive 共用一套,2026-07-22):
 * per-character-rise 入场(35ms/字,复用 style.css heading-rise 通用样式);
 * 刷新恢复滚动位置(不在页顶)时直接以完成态渲染,避免滑回顶部撞见半程动画。
 */
import { useEffect, useState } from 'react';
import type { CSSProperties } from 'react';

export default function PageTitle({ text }: { text: string }) {
  const [titleIn, setTitleIn] = useState(false);

  useEffect(() => {
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
    <h1
      className={'page-title heading-rise' + (titleIn ? ' heading-rise-in' : '')}
      aria-label={text}
    >
      <span className="heading-rise-mask" aria-hidden="true">
        {text.split('').map((ch, i) => (
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
  );
}
