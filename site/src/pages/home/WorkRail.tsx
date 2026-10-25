/* 作品导航刻度(2026-10-25 用户:参考 Codex 对话导航栏的「消息摘要刻度」,直接加)。
   只在宽屏双栏出现,竖排在页面最右边、垂直居中(试过两栏之间,用户:不合适):每条作品一根刻度,之间几根短的小刻度当尺子;
   正在看的那条刻度变长变深;悬停 / 键盘聚焦浮出这条的日期、标题、简介;点击平滑滚到这条。
   单栏没有悬停、也没有地方放,不显示。样式见 simple.css .work-rail */
import { Fragment, useEffect, useState } from 'react';

type Item = { date: string; title: string; summary?: string };

const WIDE = '(min-width: 1152px)';

export default function WorkRail({ items }: { items: Item[] }) {
  const [wide, setWide] = useState(() => window.matchMedia(WIDE).matches);
  const [active, setActive] = useState(0);

  useEffect(() => {
    const mq = window.matchMedia(WIDE);
    const on = () => setWide(mq.matches);
    mq.addEventListener('change', on);
    return () => mq.removeEventListener('change', on);
  }, []);

  /* 正在看哪条:顶边过了视口 40% 那条线的最后一条;滚到底就是最后一条 */
  useEffect(() => {
    if (!wide) return;
    const update = () => {
      const works = document.querySelectorAll<HTMLElement>('.work');
      const line = window.innerHeight * 0.4;
      let a = 0;
      works.forEach((w, i) => {
        if (w.getBoundingClientRect().top <= line) a = i;
      });
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) a = works.length - 1;
      setActive(a);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update);
    return () => {
      window.removeEventListener('scroll', update);
      window.removeEventListener('resize', update);
    };
  }, [wide]);

  /* 跳到第 i 条:让它的日期落在和第一条刚打开页面时一样的位置 */
  const go = (i: number) => {
    const works = document.querySelectorAll<HTMLElement>('.work');
    const first = works[0];
    const target = works[i];
    if (!first || !target) return;
    const docTop = (el: HTMLElement) => el.getBoundingClientRect().top + window.scrollY;
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.scrollTo({ top: Math.max(0, docTop(target) - docTop(first)), behavior: reduce ? 'auto' : 'smooth' });
  };

  if (!wide || items.length < 2) return null;

  return (
    <nav aria-label="作品导航" className="work-rail">
      {items.map((it, i) => (
        <Fragment key={it.title}>
          {i > 0 && (
            <span aria-hidden="true" className="wr-minor">
              <i />
              <i />
              <i />
            </span>
          )}
          <button
            aria-current={i === active ? 'true' : undefined}
            aria-label={`${it.date} ${it.title}`}
            className={`wr-tick${i === active ? ' is-active' : ''}`}
            type="button"
            onClick={() => go(i)}
          >
            <i />
            <span aria-hidden="true" className="wr-card">
              <small>{it.date}</small>
              <b>{it.title}</b>
              {it.summary && <span>{it.summary}</span>}
            </span>
          </button>
        </Fragment>
      ))}
    </nav>
  );
}
