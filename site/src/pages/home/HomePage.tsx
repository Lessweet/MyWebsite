/**
 * 首页 —— v4 简化版(2026-10-23):单页、无 loading、无转场。
 * 自上而下:CTR 字标 + 主题键(index.html 静态标记)→ 自我介绍段(行内手绘图形 +
 * hover 微交互)→ 联系方式一句话 → 城市 + 时间(LocalTime)→ 细分割线 → 代表作单列 Feed(works.ts)。
 * 样式全部在 docs/simple.css。
 */
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import type { CSSProperties } from 'react';
import { createPortal } from 'react-dom';
import NeteaseWordmark from './NeteaseWordmark';
import { WORKS } from './works';
import LocalTime from './LocalTime';
import RevealTuner, { applyRevealParams, loadRevealParams } from './RevealTuner';

/* 入场节拍(soft-blur-in):介绍段 + 联系方式共用一条队列,逐字从左到右连续错峰,
   换行 / 换段处多停一口。2026-10-23 用户嫌慢:15ms/120ms ×1.4(整段约 4.6s)
   收到 6ms/60ms(整段约 2s 内走完),单字时长见 simple.css .hero-ch。 */
const INTRO_CHAR_STEP = 6;
const INTRO_LINE_STEP = 60;


/* 介绍段拆分:行是折行结果、随视口变,没法在 JSX 里预知 —— 拆成最小折行单元
   (CJK 单字 / 拉丁词,句读并进前一单元防行首标点),挂载后按几何分行、逐行下发 --d。
   {…} 括起的词整组算一个单元、不会被折开(2026-10-23 用户:「被 / 看见」「视 / 觉」「常 / 态」断得难看) */
/* groups = false 时忽略 {…} 词组、照常逐字拆(手机上介绍段要像作品简介一样排满右边,2026-10-25 用户) */
function splitIntro(text: string, groups = true): string[] {
  if (!groups) text = text.replace(/[{}]/g, '');
  const raw = text.match(/\{[^}]*\}|[A-Za-z0-9]+|\s+|./g) || [];
  const out: string[] = [];
  let pending = '';
  for (const t of raw) {
    if (t[0] === '{') {
      out.push(pending + t.slice(1, -1));
      pending = '';
    } else if (out.length && (/^\s+$/.test(t) || /[。，、；：！？）》」』…]/.test(t))) {
      out[out.length - 1] += t;
    } else if (/^\s+$/.test(t)) {
      pending += t;
    } else {
      out.push(pending + t);
      pending = '';
    }
  }
  return out;
}

/* Feed 文字也逐字 soft-blur 入场,节拍与介绍段相同(2026-10-23 用户:三段整块浮现
   不如 hero 流畅)。日期、标题、简介拆成 .feed-ch,封面等文字走完再浮现 */
function feedChars(text: string) {
  return splitIntro(text).map((t, i) => (
    <span key={i} className="feed-ch">{t}</span>
  ));
}
function staggerWork(el: HTMLElement, base: number) {
  let line = 0;
  let prevLeft = -Infinity;
  let last = base;
  el.querySelectorAll<HTMLElement>('.feed-ch').forEach((u, i) => {
    const { left } = u.getBoundingClientRect();
    if (left < prevLeft - 1) line++;
    prevLeft = left;
    last = base + i * INTRO_CHAR_STEP + line * INTRO_LINE_STEP;
    u.style.setProperty('--d', `${last}ms`);
  });
  el.style.setProperty('--line-d', `${base}ms`);   /* 日期上方的细线和第一个字同时浮现 */
  el.style.setProperty('--cover-d', `${last + 120}ms`);
  return last + 120;   /* 封面开始浮现的时刻(相对 base 所在的时间零点) */
}

/* 入场方式开关(2026-10-25 用户:试斜向渐清入场):true = 打开页面一道斜向扫光从左上揭到右下(index.html 的 .page-reveal);
   false = 换回原来的介绍段逐字浮现 + 首屏作品依次入场 */
const REVEAL_ENTRANCE = true;
/* 调参面板里的预览(?embed=1):不再显示调节按钮 */
const IS_EMBED = new URLSearchParams(location.search).has('embed');

const MAIL = 'chentongrong1@gmail.com';
const MAILTO = `mailto:${MAIL}`;

/* 公众号链接 + 二维码弹层:桌面 hover / 聚焦弹出,触屏点按切换,点页面别处收起。
   介绍段末句与右上角各用一份,各管各的开合 */
function Gzh({ className = '', linkClass }: { className?: string; linkClass: string }) {
  const [open, setOpen] = useState(false);
  /* 鼠标悬停也会显示弹层(CSS :hover);shut = 用户点了收起,盖过悬停 / 聚焦,鼠标移开后复位
     (2026-10-25 用户:支持再次点击收起) */
  const [hover, setHover] = useState(false);
  const [shut, setShut] = useState(false);
  const btnRef = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    if (!open) return;
    const close = () => setOpen(false);
    document.addEventListener('click', close);
    return () => document.removeEventListener('click', close);
  }, [open]);
  const shown = !shut && (open || hover);
  /* 弹层挂在这个单元里:单元入场动画带 filter/transform 会自成层叠上下文,
     .gzh 自身给 z-index,弹层才盖得住后面(折行后)的字 */
  return (
    <span
      className={`${className} gzh${open && !shut ? ' open' : ''}${shut ? ' shut' : ''}`.trim()}
      /* 只认真鼠标:触屏点按也会先发 mouseenter,不能当成悬停 */
      onPointerEnter={(e) => {
        if (e.pointerType !== 'mouse') return;
        setHover(true);
      }}
      onPointerLeave={(e) => {
        if (e.pointerType !== 'mouse') return;
        setHover(false);
        setShut(false);
      }}
    >
      <span className="gzh-anchor">
      <button
        aria-expanded={shown}
        className={linkClass}
        ref={btnRef}
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          if (shown) {
            setOpen(false);
            setShut(true);
            btnRef.current?.blur();   /* 不然 :focus-within 又把弹层顶出来 */
          } else {
            setShut(false);
            setOpen(true);
          }
        }}
      >
        公众号
      </button>
      {/* 排版照微信名片:二维码 / 号名 / 灰色说明 */}
      <span className="gzh-pop" role="tooltip">
        <img alt="公众号二维码" height={148} src="qrcode-gzh-360.webp?v=2" width={148} />
        <span className="gzh-name">AI设计师阿东</span>
        <span className="gzh-cap">微信扫描二维码，关注我的帐号</span>
      </span>
      </span>
    </span>
  );
}

export default function HomePage() {
  /* 首屏一起出现(2026-10-23 用户):静态的字标 / 开关和 React 渲染的内容同一帧显示 ——
     index.html 先给 <html> 挂 app-loading 藏起整页,这里在首次渲染提交后、浏览器绘制前去掉 */
  useLayoutEffect(() => {
    const root = document.documentElement;
    /* 斜向渐清入场(REVEAL_ENTRANCE):关掉介绍段逐字 / 按钮入场,首屏只靠扫光;要换回逐字入场把开关设成 false */
    if (REVEAL_ENTRANCE) root.classList.add('reveal-entrance');
    /* 本地开发:用调参面板存下的扫光参数(线上用 simple.css 里的默认值) */
    if (import.meta.env.DEV) applyRevealParams(loadRevealParams());
    root.classList.remove('app-loading');
  }, []);

  /* 扫光播完就移除那层白雾(不移除的话透明蒙版下的 backdrop-filter 还会一直算) */
  useEffect(() => {
    const veil = document.querySelector<HTMLElement>('.page-reveal');
    if (!veil) return;
    if (!REVEAL_ENTRANCE || window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      veil.remove();
      return;
    }
    const done = () => veil.remove();
    veil.addEventListener('animationend', done, { once: true });
    const fallback = window.setTimeout(done, 4500);   /* 动画没跑(后台标签等)也别一直挂着 */
    return () => clearTimeout(fallback);
  }, []);

  /* 页面滚动过才显示顶部边缘模糊(simple.css .edge-top),回到最顶上就收起 */
  useEffect(() => {
    const root = document.documentElement;
    const on = () => root.classList.toggle('page-scrolled', window.scrollY > 4);
    on();
    window.addEventListener('scroll', on, { passive: true });
    return () => window.removeEventListener('scroll', on);
  }, []);

  /* 单栏(≤ 1151)介绍段不按词组断行,逐字排(2026-10-25 用户:右边参差;拖动窗口时字来回跳)。
     原来只在 < 640 逐字,拖过 640 时断行方式一换,行尾的字就跳一下;现在只在单栏 / 双栏切换时变 */
  const [phoneWrap, setPhoneWrap] = useState(() => window.matchMedia('(max-width: 1151px)').matches);
  useEffect(() => {
    const mq = window.matchMedia('(max-width: 1151px)');
    const on = () => setPhoneWrap(mq.matches);
    mq.addEventListener('change', on);
    return () => mq.removeEventListener('change', on);
  }, []);

  /* 逐行下发入场延迟:行的判定 = 单元左缘比前一个更靠左(换行、换段都会回退左缘) */
  const introRef = useRef<HTMLDivElement>(null);
  /* 介绍区最后一个单元(城市时间那行)开始浮现的时刻,Feed 接在它后面 */
  const introLastRef = useRef(0);
  useLayoutEffect(() => {
    const p = introRef.current;
    if (!p) return;
    let line = 0;
    let prevLeft = -Infinity;
    /* 联系方式那句在 header 之外,同样排进队列尾部(之前它按固定延迟整块出现,
       文案变长后抢在介绍段之前) */
    const units = [
      ...p.querySelectorAll('.hero-ch'),
      ...document.querySelectorAll('.hero-loc .hero-ch'),   /* 联系方式那句现在在 .hero-intro 里,上一行已包含 */
    ];
    /* 单栏(< 1152)时主题键在页面最上面,先出;介绍段晚 PILLS_LEAD 再起步(2026-10-24 用户:从上到下)。
       公众号 / 邮箱单栏时在介绍区下方(2026-10-25),和宽屏一样接在介绍区最后一行后面 */
    const topFirst = window.matchMedia('(max-width: 1151px)').matches;
    const PILLS_LEAD = 200;
    const offset = topFirst ? PILLS_LEAD : 0;
    units.forEach((el, i) => {
      const { left } = el.getBoundingClientRect();
      if (left < prevLeft - 1) line++;
      prevLeft = left;
      const d = offset + i * INTRO_CHAR_STEP + line * INTRO_LINE_STEP;
      (el as HTMLElement).style.setProperty('--d', `${d}ms`);
      introLastRef.current = d;
    });
    /* 公众号 / 邮箱(宽屏还有主题键)接在介绍区最后一行后面浮现(2026-10-23 用户:入场也要有动画) */
    document.documentElement.style.setProperty('--pills-d', `${introLastRef.current + 150}ms`);
    /* 介绍区入场播完(最后一个字的延迟 + 动画 560ms)后挂 .intro-done:之后重新生成的字不再播入场 */
    const done = window.setTimeout(
      () => document.documentElement.classList.add('intro-done'),
      introLastRef.current + 700,
    );
    return () => clearTimeout(done);
  }, []);

  /* Feed 入场(2026-10-23 用户):介绍段收尾 → 细分割线画出 → 作品依次逐字浮现(同批错开);
     出现过就常驻,来回滚动不重播。首屏就在视口里的作品排在分割线之后 */
  useEffect(() => {
    const items = Array.from(document.querySelectorAll<HTMLElement>('.work'));
    const works = document.querySelector<HTMLElement>('.works');
    if (!('IntersectionObserver' in window)) {
      works?.classList.add('in');
      items.forEach((el) => el.classList.add('in'));
      return;
    }
    const t0 = performance.now();
    /* 分割线紧跟介绍区最后一行(城市时间)开始浮现后 300ms 出来,不再写死 1.5s ——
       删掉联系方式那句后介绍区约 0.5s 就走完,写死的 1.5s 让下面空等了 1 秒(2026-10-23 用户:掉队) */
    const HERO_DONE = introLastRef.current + 300;
    /* 上一条封面开始浮现后,下一条再等这么久开始 */
    const NEXT_GAP = 400;
    /* 排队中的作品:end = 下一条最早可以开始的时刻(该条封面开始浮现 + NEXT_GAP) */
    const pending: { el: HTMLElement; end: number }[] = [];
    /* 分割线在介绍段收尾时画出,第一条作品再晚 DIVIDER_LEAD 跟上 */
    const DIVIDER_LEAD = 250;
    let raf = 0;
    if (works) {
      works.style.setProperty('--d', `${HERO_DONE}ms`);
      /* 双 rAF:先让初始态(透明、下移)绘制一帧,过渡才有起点 */
      raf = requestAnimationFrame(() => (raf = requestAnimationFrame(() => works.classList.add('in'))));
    }
    const io = new IntersectionObserver(
      (entries) => {
        const hits = entries.filter((e) => e.isIntersecting).map((e) => e.target as HTMLElement);
        const now = performance.now();
        const base = Math.max(0, HERO_DONE + DIVIDER_LEAD - (now - t0));
        /* 一条一条来(2026-10-23 用户:不要所有作品先统一出文字):下一条等上一条的封面开始浮现、
           再过 NEXT_GAP 才开始逐字;队列跨批次累计(滚动后新进视口的也排在后面) */
        /* 上面的作品直接显示、不再补播入场(2026-10-23 用户:从底部往上划回去时,上面不要入场动画了):
           一下滑到底、或刷新后停在下面时,上面那些从没进过视口;某条出现时,把它上面还没出现的全部直接亮出来 */
        const reveal = (el: HTMLElement) => {
          el.classList.add('in', 'instant');
          io.unobserve(el);
        };
        hits.forEach((el) => {
          items.slice(0, items.indexOf(el)).forEach((above) => {
            if (!above.classList.contains('in')) reveal(above);
          });
          if (el.classList.contains('in')) return;
          /* 斜向渐清入场时,打开页面就在视口里的作品直接显示,交给扫光;之后滚动进来的照常依次浮现 */
          if (REVEAL_ENTRANCE && now - t0 < 400) {
            reveal(el);
            return;
          }
          /* 严格依次(2026-10-24 用户:第一条没出完,第二条不能出来):每条都等上一条封面开始浮现、
             再过 NEXT_GAP 才开始。原来滚动进来的最多只等 300ms,首屏同时在视口里的两条会一起开始。
             滑得快时不空等:还在排队、但已经滑出视口上方的作品直接显示,不再挡着后面 */
          pending.forEach((q) => {
            if (q.end > now && q.el.getBoundingClientRect().bottom < 0) {
              q.el.classList.add('instant');
              q.end = 0;
            }
          });
          const queueEnd = Math.max(0, ...pending.map((q) => q.end));
          const start = Math.max(base, queueEnd - now);
          const coverAt = staggerWork(el, start);
          pending.push({ el, end: now + coverAt + NEXT_GAP });
          el.classList.add('in');
          io.unobserve(el);
        });
      },
      { rootMargin: '0px 0px -40px 0px', threshold: 0.1 },
    );
    items.forEach((el) => io.observe(el));
    return () => {
      cancelAnimationFrame(raf);
      io.disconnect();
    };
  }, []);


  /* 右上角(主题键左边)也放一份「公众号 / 邮箱」,正文字号(2026-10-23 用户);
     顶栏是 index.html 的静态标记,这里渲染进它预留的 #head-links */
  /* 顶栏是 index.html 的静态标记,脚本运行时已经在页面里:首次渲染就直接拿到,
     公众号 / 邮箱与其他内容同一帧出现(2026-10-23 用户:原来等 effect 再取,晚了一拍) */
  const [headSlot] = useState<HTMLElement | null>(() => document.getElementById('head-links'));

  return (
    <>
      {headSlot &&
        createPortal(
          <>
            <Gzh linkClass="head-link" />
            <a className="head-link" href={MAILTO} title={MAIL}>
              邮箱
            </a>
          </>,
          headSlot,
        )}
      {/* 宽屏两栏(2026-10-23 用户:单列在电脑上浪费空间):左 = 介绍区(介绍段 + 联系方式 + 城市时间,
          吸顶),右 = 作品区。窄屏仍是单列,见 simple.css .intro-col */}
      <div className="intro-col">
      <header className="home-hero">
        {/* 图形与它标注的词包进 .hero-intro-unit(nowrap):否则行尾可能在
            inline-block 图形和后面的词之间折开,头像/圆球被单独甩在行尾。
            文字经 splitIntro 拆成折行单元(.hero-ch),空格并入前词、标点并入前字,
            全部间距都在单元字符串里 —— JSX 元素之间不放裸文本。 */}
        {/* 一句一段(2026-10-23 用户;打招呼与「做什么」合成一句),段间距 24px 见 simple.css */}
        <div className="hero-intro" ref={introRef}>
          <p>
          {/* 开场白(2026-08-22):「UI 设计师」与后文重复已删,换成打招呼 ——
              与头像 say-hi 笔画呼应;头衔只留「曾在 NetEase 担任 UI 设计师」那处。
              2026-10-23 用户删掉开头的「Hi，」,直接从「我是」起句 */}
          {splitIntro('我是 ').map((t, i) => (
            <span key={`a${i}`} className="hero-ch">{t}</span>
          ))}
          <span className="hero-ch hero-intro-unit hero-name-unit">
            <span aria-label="同容 头像" className="hero-intro-avatar" role="img">
              <img alt="" src="writing/assets/tongrong-avatar.svg?v=2" />
            </span>
            {/* 头像两侧手绘装饰(2026-08-22 用户:默认常显,不只 hover):
                右上三道 say-hi 小笔画(左上小星试过一版,2026-08-22 用户砍掉)。
                hover 头像时两侧逐条重新描画一遍,配合摆动 —— 兄弟节点,:hover ~ 选中 */}
            <span aria-hidden="true" className="hero-hi hero-hi-right">
              <svg viewBox="0 0 24 24">
                <path pathLength={1} d="M4.5 15 C5.5 12.5, 6 10.5, 6.2 8" />
                <path pathLength={1} d="M10.5 13 C11.8 10.5, 13.4 8.8, 15.5 7.4" />
                <path pathLength={1} d="M14.5 18.5 C16.5 17.4, 18.6 16.9, 20.8 16.9" />
              </svg>
            </span>
            {/* 名字用正文字体 + 中粗(2026-10-23 用户:手写名 SVG 不好看,停用;TongrongName.tsx 保留备用) */}
            <b className="hero-name">同容</b>
            ，
          </span>
          {splitIntro('{研究}{内容}{怎么}{被创作、}{被呈现、}{被看见。}', !phoneWrap).map((t, i) => (
            <span key={`b${i}`} className="hero-ch">{t}</span>
          ))}
          </p>
          <p>
          {splitIntro('曾在 ').map((t, i) => (
            <span key={`b2${i}`} className="hero-ch">{t}</span>
          ))}
          {/* 单元带尾空格(nowrap 粘在词后):后续段不再以空格开头,免得折行后行首悬空格 */}
          <span className="hero-ch hero-intro-unit">
            {/* 字标 SVG(描线复刻,见 NeteaseWordmark.tsx):包在 <b> 里吃重点词颜色 */}
            <b className="hero-netease">
              <NeteaseWordmark />
            </b>{' '}
          </span>
          {splitIntro('担任 ').map((t, i) => (
            <span key={`c0${i}`} className="hero-ch">{t}</span>
          ))}
          {/* 「UI 设计师」独立成单元:底下垫手绘灰色双笔下划线(2026-08-22 手绘样式,10-23 红改灰);
              逗号并进单元防行首标点,但不吃下划线 */}
          <span className="hero-ch hero-intro-unit">
            <span className="hero-role-mark">
              UI 设计师
              {/* 双笔画手绘下划线(2026-08-22 用户:要两条的笔画感):主笔全宽扫过,
                  第二笔更短、垫在中段下方 —— 快速回锋的双线。两条都是变宽实心笔触
                  (上下缘不同相位抖动 = 粗细一直在变);preserveAspectRatio none 随词宽拉伸 */}
              <svg aria-hidden="true" className="hero-role-line" viewBox="0 0 200 24" preserveAspectRatio="none">
                {/* hover 画笔重描:每笔一张遮罩,沿笔画中线的粗描边按 dashoffset 扫开 ——
                    笔画本身是变宽实心轮廓、没有可描的中线,只能用遮罩露出来。
                    两笔各用各的遮罩:中线描边够粗时会盖到邻笔边缘 */}
                <defs>
                  <mask id="hero-role-m1" maskUnits="userSpaceOnUse" x="-4" y="0" width="208" height="24">
                    <path pathLength={1} d="M0 10.2 L203 6.8" />
                  </mask>
                  <mask id="hero-role-m2" maskUnits="userSpaceOnUse" x="-4" y="0" width="208" height="24">
                    <path pathLength={1} d="M19 16.6 L143 15.4" />
                  </mask>
                </defs>
                <path mask="url(#hero-role-m1)" d="M4 7.5 C 30 5.8, 60 8, 90 6.6 C 120 5.4, 155 7.2, 194 5.2 C 197 5, 198 6, 197.5 7.2 C 197 8.6, 194 9.4, 190 9.8 C 158 12, 124 10, 92 11.4 C 62 12.6, 32 11, 7 12.6 C 4.6 12.7, 3.4 11.6, 3.5 10 C 3.6 8.8, 3.8 7.9, 4 7.5 Z" />
                <path mask="url(#hero-role-m2)" d="M22 15.5 C 50 13.8, 85 15.6, 118 14 C 128 13.5, 136 14.2, 138 15 C 139.5 15.9, 137 16.9, 132 17.3 C 100 19.4, 66 17.4, 35 19 C 28 19.3, 23.5 18.6, 23 17.4 C 22.6 16.6, 22.4 15.9, 22 15.5 Z" />
              </svg>
              {/* 画笔:与下划线同框,笔尖跟着遮罩的扫开进度走(轨迹见 writing.css hero-pen-track) */}
              <span aria-hidden="true" className="hero-role-pen">
                <span className="hero-role-pen-track">
                  <svg className="hero-role-pen-icon" viewBox="0 0 24 24">
                    <path d="M16.2 3.8a2.3 2.3 0 0 1 3.3 0l.7.7a2.3 2.3 0 0 1 0 3.3L8.5 19.5 3 21l1.5-5.5Z" />
                  </svg>
                </span>
              </span>
            </span>
            ，
          </span>
          {splitIntro('{设计}{内容}{产品的}{视觉体验，}{创作者}{平台、}{阅读、}{社区这类，}{做界面、图标系统和动效。}', !phoneWrap).map(
            (t, i) => (
              <span key={`c${i}`} className="hero-ch">{t}</span>
            ),
          )}
          </p>
          <p>
          {splitIntro('{现在我}{边设计、}{边实现，}{AI coding、}{skills、}{PR }{是常态。}{同时，}{把看到的、}{想到的，}{写成}{文章。}', !phoneWrap).map((t, i) => (
            <span key={`d${i}`} className="hero-ch">{t}</span>
          ))}
          </p>
          {/* 联系方式一句话(2026-10-25 用户:单栏时用这句,不用公众号 / 邮箱两个胶囊,底部不再挤一堆);
              宽屏仍用左下角的胶囊,这句隐藏(simple.css) */}
          <p className="contact">
            {/* 链接和前面的字粘成一个单元(「在公众号」「通过邮箱联系我。」):折行时不会以链接开头,
                否则链接左边的间距会让行首缩进一格 */}
            {splitIntro('可以').map((t, i) => (   /* 去掉开头的「你」(2026-10-25 用户) */
              <span key={`e${i}`} className="hero-ch">{t}</span>
            ))}
            {/* 外层给 z-index:每个字单元入场带 filter 会自成层叠上下文,二维码弹层才盖得住后面的字 */}
            <span className="hero-ch gzh-wrap">
              在<Gzh linkClass="text-link" />
            </span>
            {splitIntro('上找到我，或者').map((t, i) => (
              <span key={`f${i}`} className="hero-ch">{t}</span>
            ))}
            <span className="hero-ch">
              通过<a className="text-link" href={MAILTO} title={MAIL}>邮箱</a>联系我。
            </span>
          </p>
        </div>
      </header>
      <LocalTime />
      {/* 入场扫光调参面板:只在本地开发出现(2026-10-25 用户) */}
      {import.meta.env.DEV && !IS_EMBED && <RevealTuner />}
      </div>
      <section className="works" aria-label="代表作">
        {WORKS.map((w) => (
          <article className="work" key={w.title}>
            {/* 年份与标题同一行(2026-10-23 用户) */}
            <div className="work-head">
              <p className="work-year">{feedChars(w.date)}</p>
              <h2 className="work-title">{feedChars(w.title)}</h2>
            </div>
            {w.summary && <p className="work-summary">{feedChars(w.summary)}</p>}
            {/* hover 封面区域时图放大到 1.05(同 Signal 的 Feed 卡片);只认封面区域,不认整条(2026-10-23 用户) */}
            {w.gallery ? (
              <Gallery items={w.gallery} />
            ) : w.showcase ? (
              <Showcase {...w.showcase} />
            ) : (
              <div className="work-cover">
                {w.cover && <img alt="" decoding="async" loading="lazy" src={w.cover} />}
              </div>
            )}
          </article>
        ))}
      </section>
    </>
  );
}

/* 封面的「两图式」(2026-10-23 用户):并排两个独立的图片容器,每个 4:3(各自圆角、浅灰底;
   流动渐变 shader 底用户改为浅灰,MeshBg.tsx 先留着不挂)。
   左:手机(CSS 画外框 + 状态栏)里的公众号文章页截图,三个排版组件浮在手机周围;
   右:文章封面两列静态罗列。内部尺寸全用 em,1em = 整体宽 / 56,随宽度等比缩放。
   hover 封面区域:两个容器里的内容一起放大(见 simple.css .sc-inner) */
type Cover = { src: string; title: string };

/* 四图式:两行两列,依次浮现(--i 控制每张的延迟,见 simple.css .gallery) */
/* 小尺寸版本(site/scripts/build-work-srcset.py 生成):x.webp?v=2 → x-960.webp?v=2 */
const sized = (src: string, w: number) => src.replace(/\.webp(\?|$)/, `-${w}.webp$1`);
/* 卡片在各布局下的实际显示宽度(两栏:作品区 = 100vw − 624;单栏:100vw − 64 / 手机 − 32;
   每张卡 ≥ 375 才并排,见 simple.css 的容器查询),浏览器据此挑 960 / 1280 / 1920 那张(1280 主要给 3 倍屏手机) */
const CARD_SIZES =
  '(min-width: 1390px) calc(50vw - 320px), (min-width: 1152px) calc(100vw - 624px), (min-width: 830px) calc(50vw - 40px), calc(100vw - 32px)';
/* 单张通栏时图片占满整栏(2026-10-24):宽屏右栏 = 100vw − 624,单栏 = 100vw − 左右边距 */
const FULL_SIZES = '(min-width: 1152px) calc(100vw - 624px), (min-width: 601px) calc(100vw - 64px), calc(100vw - 32px)';

function Gallery({ items }: { items: { src: string; tint?: string; zoom?: number }[] }) {
  return (
    <div className="work-cover gallery">
      {items.map((it, i) => (
        <div
          className="gl-item"
          key={it.src || i}
          style={{ '--i': i, '--z': it.zoom ?? 1, ...(it.tint ? { background: it.tint } : {}) } as CSSProperties}
        >
          {it.src && (
            <img
              alt=""
              decoding="async"
              loading="lazy"
              sizes={items.length === 1 || (items.length === 3 && i === 0) ? FULL_SIZES : CARD_SIZES}
              src={it.src}
              srcSet={`${sized(it.src, 960)} 960w, ${sized(it.src, 1280)} 1280w, ${it.src} 1920w`}
            />
          )}
        </div>
      ))}
    </div>
  );
}

function Showcase({ phones, covers, tint }: { phones: string[]; covers: Cover[]; tint?: [string, string] }) {
  const style = tint ? ({ '--sc-article-bg': tint[0], '--sc-covers-bg': tint[1] } as CSSProperties) : undefined;
  return (
    <div className="work-cover showcase" style={style}>
      <div className="sc-pane sc-pane-article">
        {/* 三屏:同一篇文章从上往下的三屏,三台手机并排居中 */}
        <div aria-hidden="true" className="sc-inner sc-phones">
          {phones.map((src, i) => (
            <div className="sc-phone" key={src || i}>
              {/* 不画状态栏和灵动岛(2026-10-23 用户);没有截图时画占位线条 */}
              {src ? (
                /* 手机截图在页面上最宽约 170px,一般挑 400 宽那张 */
                <img alt="" decoding="async" loading="lazy" sizes="180px" src={src} srcSet={`${sized(src, 400)} 400w, ${src} 750w`} />
              ) : (
                <div className="sc-skel">
                  <span /><span /><span /><span /><span /><span />
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
      <div className="sc-pane sc-pane-covers">
        <div aria-hidden="true" className="sc-inner">
          {/* 横排两行、左右越出容器(2026-10-23 用户):按顺序上行多一张(7 张 → 4 / 3);
              两行居中,张数一奇一偶自然错开半张 */}
          <div className="sc-covers">
            {[covers.slice(0, Math.ceil(covers.length / 2)), covers.slice(Math.ceil(covers.length / 2))].map((row, r) => (
              <div className="sc-row" key={r}>
                {row.map((c, i) =>
                  /* 封面下方的文章标题 2026-10-23 用户又去掉了(title 留在数据里备用);没有素材时是占位块 */
                  c.src ? (
                    <img alt="" className="sc-cover" decoding="async" key={c.src} loading="lazy" src={c.src} />
                  ) : (
                    <span className="sc-cover sc-cover-skel" key={i} />
                  ),
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
