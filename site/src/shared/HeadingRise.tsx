/**
 * 区头逐字升起标题 —— script.js initSectionHeadingRise 的 JSX 直渲版:
 * 旧版在运行时把 h2 文本拆成 mask/char span;这里渲染即拆好(产物 DOM 一致,
 * 且不做挂载后变异)。design-page 上「升起」时机由 usePillarEntrance 级联统一调度
 * (识别 .heading-rise → 加 .heading-rise-in),与旧版一致。
 */
import type { CSSProperties, ReactNode } from 'react';

export default function HeadingRise({ text, icon }: { text: string; icon?: ReactNode }) {
  return (
    <h2 data-rise-init="1" aria-label={text} className="heading-rise">
      {icon}
      <span className="heading-rise-mask" aria-hidden="true">
        {Array.from(text).map((char, i) => (
          <span
            key={i}
            className="heading-rise-char"
            style={{ '--d': `${i * 35}ms` } as CSSProperties}
          >
            {char === ' ' ? ' ' : char}
          </span>
        ))}
      </span>
    </h2>
  );
}
