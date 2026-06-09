/**
 * Writing — 列表页标签筛选 + reveal 动效 + 阅读页目录(TOC)
 * 复用 ../script.js 的 brand banner / sticky header,这里只补文章特有逻辑。
 */
document.addEventListener('DOMContentLoaded', () => {
    initPageTint();
    initSiteNav();
    initStickyMenu();
    initArticleReveal();
    initReveal();
    initTagFilter();
    initWritingFilter();
    initTOC();
    initNavSpy();
    initScrollProgress();
    initNavSolidOnScroll();
});

/* 分类页:顶栏初始透明叠在通栏 banner 上;banner 向上滚出顶栏后给顶栏加 .nav-solid → 变白底。
   判据:banner 底边滚到顶栏下沿(navH)之上时,顶栏不再压着 banner。 */
function initNavSolidOnScroll() {
    const nav = document.querySelector('.header.home-nav');
    const banner = document.querySelector('.design-banner-frame');
    if (!nav || !banner) return;   // 文章页无 banner,跳过
    const update = () => {
        const solid = banner.getBoundingClientRect().bottom <= nav.offsetHeight;
        nav.classList.toggle('nav-solid', solid);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update);
}

/* 顶栏底部滚动进度条:进度 = 已滚动距离 / 可滚动总距离(0~1),写到顶栏的 --scroll-progress,
   CSS 用它 scaleX 拉伸进度条。页面不可滚动时进度为 0(条宽 0,不显示)。 */
function initScrollProgress() {
    const header = document.querySelector('.header');
    if (!header) return;
    const doc = document.documentElement;
    let ticking = false;
    const update = () => {
        ticking = false;
        const max = doc.scrollHeight - doc.clientHeight;
        const p = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 0;
        header.style.setProperty('--scroll-progress', p);
    };
    const onScroll = () => {
        if (!ticking) { ticking = true; requestAnimationFrame(update); }
    };
    update();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
}

/* 阅读页底层规则:每篇文章都必须有底色。
   手动在 <body data-tint="..."> 写了就用手动的;没写就按文章 slug 稳定哈希,
   从纯色盘里自动分配一个 —— 同一篇永远同一色,不同篇尽量不同。
   (渐变档不参与自动分配,是 opt-in 的手动选择) */
function initPageTint() {
    const body = document.body;
    if (!body || !body.classList.contains('reading-page')) return;
    if (body.dataset.tint) return;   // 手动指定优先
    const SOLIDS = ['violet', 'blue', 'mint', 'peach', 'rose', 'sand'];
    const slug = body.dataset.slug
        || (location.pathname.split('/').pop() || 'article').replace(/\.html?$/, '');
    let hash = 0;
    for (let i = 0; i < slug.length; i++) hash = (hash * 31 + slug.charCodeAt(i)) >>> 0;
    body.dataset.tint = SOLIDS[hash % SOLIDS.length];
}

/* 移动端:把胶囊分类条的 sticky top 设为顶栏实际高度,使其紧贴顶栏下方 */
function initStickyMenu() {
    const menu = document.querySelector('.design-menu');
    const header = document.querySelector('.header');
    if (!menu || !header) return;
    const set = () => document.documentElement.style.setProperty('--design-menu-top', header.offsetHeight + 'px');
    set();
    window.addEventListener('resize', set);
    window.addEventListener('load', set);
}

/* 顶部导航(一处定义,两页复用)。页面用 <header id="site-nav" data-active="writing|design"> 占位 */
function initSiteNav() {
    const nav = document.getElementById('site-nav');
    if (!nav || nav.dataset.built) return;   // 幂等:解析时已内联注入过则跳过,避免重复构建/闪烁
    nav.dataset.built = '1';
    const active = nav.dataset.active || '';
    // data-base:子目录页面(如 writing/article.html)用 "../" 把站内链接/资源指回 docs 根目录
    const base = nav.dataset.base || '';
    const I = (p) => '<span class="menu-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">' + p + '</svg></span>';
    const pencil = '<path d="M16.5 4.5 L19.5 7.5 L8 19 L4 20 L5 16 Z"/><path d="M14.5 6.5 L17.5 9.5"/>';
    const design = '<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M4 10 H20"/><path d="M10 10 V20"/>';
    const a = (cls) => 'nav-cat' + (active === cls ? ' active' : '');
    // 顶栏背景层:复用流沙渐变 banner(bare 模式,无文字)。默认透明,滚动到 banner 滚出后(.nav-solid)淡入替代白底。
    // 仅分类页(index-v2 / design = design-page 且非 writing-page / reading-page)注入,与 CSS 作用域一致;
    // 阅读页(article)与 writing/index 顶栏维持现状,不注入。
    const bd = document.body.classList;
    const wantNavBg = bd.contains('design-page') && !bd.contains('writing-page') && !bd.contains('reading-page');
    const navBg = wantNavBg
        ? '<iframe class="nav-bg" src="' + base + 'writing-banner.html?v=10&bare=1" title="" aria-hidden="true" tabindex="-1" scrolling="no"></iframe>'
        : '';
    nav.innerHTML =
        navBg +
        '<div class="header-left">' +
            '<a href="' + base + 'index-v2.html" class="site-title" aria-label="VIBEUX"><img src="' + base + 'logo-wordmark.png?v=2" class="site-wordmark" alt="VIBEUX"></a>' +
        '</div>' +
        '<nav class="nav-cats" aria-label="分类">' +
            '<a href="' + base + 'index-v2.html#writing" class="' + a('writing') + '">' + I(pencil) + 'Blog</a>' +
            '<a href="' + base + 'design.html" class="' + a('design') + '">' + I(design) + 'Skills</a>' +
        '</nav>' +
        '<div class="header-right">' +
            '<a href="mailto:chentongrong1@gmail.com" class="header-connect" title="chentongrong1@gmail.com" aria-label="Contact">' +
                '<svg class="mail-icon" viewBox="2 6.5 20 11" aria-hidden="true"><path fill-rule="evenodd" d="M3.75,6.5 3.75,6.75 3.25,6.75 3.25,7.0 3.0,7.0 3.0,7.25 3.5,7.25 3.5,7.5 3.75,7.5 3.75,7.75 4.0,7.75 4.0,8.0 4.5,8.0 4.5,8.25 4.75,8.25 4.75,8.5 5.0,8.5 5.0,8.75 5.5,8.75 5.5,9.0 5.75,9.0 5.75,9.25 6.0,9.25 6.0,9.5 6.5,9.5 6.5,9.75 6.75,9.75 6.75,10.0 7.0,10.0 7.0,10.25 7.5,10.25 7.5,10.5 7.75,10.5 7.75,10.75 8.0,10.75 8.0,11.0 8.5,11.0 8.5,11.25 8.75,11.25 8.75,11.5 9.0,11.5 9.0,11.75 9.25,11.75 9.25,12.0 9.75,12.0 9.75,12.25 10.0,12.25 10.0,12.5 10.25,12.5 10.25,12.75 10.75,12.75 10.75,13.0 11.0,13.0 11.0,13.25 11.25,13.25 11.25,13.5 11.5,13.5 11.5,13.75 12.5,13.75 12.5,13.5 12.75,13.5 12.75,13.25 13.25,13.25 13.25,13.0 13.5,13.0 13.5,12.75 13.75,12.75 13.75,12.5 14.25,12.5 14.25,12.25 14.5,12.25 14.5,12.0 14.75,12.0 14.75,11.75 15.0,11.75 15.0,11.5 15.5,11.5 15.5,11.25 15.75,11.25 15.75,11.0 16.0,11.0 16.0,10.75 16.5,10.75 16.5,10.5 16.75,10.5 16.75,10.25 17.0,10.25 17.0,10.0 17.5,10.0 17.5,9.75 17.75,9.75 17.75,9.5 18.0,9.5 18.0,9.25 18.25,9.25 18.25,9.0 18.75,9.0 18.75,8.75 19.0,8.75 19.0,8.5 19.25,8.5 19.25,8.25 19.75,8.25 19.75,8.0 20.0,8.0 20.0,7.75 20.25,7.75 20.25,7.5 20.75,7.5 20.75,7.25 21.0,7.25 21.0,7.0 20.75,7.0 20.75,6.75 20.25,6.75 20.25,6.5ZM2.0,8.5 2.0,16.75 2.25,16.75 2.25,17.0 2.5,17.0 2.5,17.25 2.75,17.25 2.75,17.5 8.0,17.5 8.0,17.25 7.5,17.25 7.5,17.0 7.25,17.0 7.25,16.75 7.0,16.75 7.0,12.25 6.75,12.25 6.75,11.75 6.5,11.75 6.5,11.5 6.25,11.5 6.25,11.25 6.0,11.25 6.0,11.0 5.5,11.0 5.5,10.75 5.25,10.75 5.25,10.5 4.75,10.5 4.75,10.25 4.5,10.25 4.5,10.0 4.25,10.0 4.25,9.75 3.75,9.75 3.75,9.5 3.5,9.5 3.5,9.25 3.0,9.25 3.0,9.0 2.75,9.0 2.75,8.75 2.5,8.75 2.5,8.5ZM21.75,8.75 21.5,8.75 21.5,9.0 21.0,9.0 21.0,9.25 20.5,9.25 20.5,9.5 20.25,9.5 20.25,9.75 20.0,9.75 20.0,10.0 19.5,10.0 19.5,10.25 19.25,10.25 19.25,10.5 19.0,10.5 19.0,10.75 18.5,10.75 18.5,11.0 18.25,11.0 18.25,11.25 17.75,11.25 17.75,11.5 17.5,11.5 17.5,11.75 17.25,11.75 17.25,12.25 17.0,12.25 17.0,16.75 16.75,16.75 16.75,17.0 16.5,17.0 16.5,17.25 16.0,17.25 16.0,17.5 21.25,17.5 21.25,17.25 21.75,17.25 21.75,16.75 22.0,16.75 22.0,9.0 21.75,9.0Z"/></svg>' +
                '<span class="connect-label">Contact</span>' +
            '</a>' +
        '</div>';
}

/* 首页 v2:右侧导航(.nav-cat)随滚动高亮当前模块 */
function initNavSpy() {
    const links = Array.from(document.querySelectorAll('.nav-cat[href^="#"]'));
    if (!links.length || !('IntersectionObserver' in window)) return;

    const map = new Map();
    links.forEach((a) => {
        const sec = document.querySelector(a.getAttribute('href'));
        if (sec) map.set(sec, a);
    });
    if (!map.size) return;

    const spy = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            const a = map.get(entry.target);
            if (a) a.dataset.visible = entry.isIntersecting ? '1' : '';
        });
        // 最上方仍在视口内的模块为 active
        let active = null;
        for (const [sec, a] of map) {
            if (a.dataset.visible) { active = a; break; }
        }
        links.forEach((a) => a.classList.toggle('active', a === active));
    }, { rootMargin: '-120px 0px -55% 0px', threshold: 0 });

    map.forEach((_, sec) => spy.observe(sec));
}

/* 进入视口逐个淡入 */
/* 阅读页:顶栏以下的正文内容(导言/标题/署名/封面/正文各块/页脚)逐块入场,
   动画与首页网格卡片(.card-wrapper)完全一致:上移 22px + 0.9s 淡入,从上到下一片接一片错开。
   关键的双 requestAnimationFrame:先让 opacity:0 的初始态真正绘制一帧,再开始显现,
   否则首屏第一波会在首次绘制前就加上 .visible、直接以最终态绘制(看起来「没有动画」)。 */
function initArticleReveal() {
    if (!document.body.classList.contains('reading-page')) return;
    const root = document.querySelector('.article-reading');
    if (!root) return;

    const blocks = [];
    Array.from(root.children).forEach((child) => {
        // 正文容器拆到段落/小标题/图片粒度,使级联更细腻;其余块整体入场
        if (child.classList.contains('article-body')) {
            Array.from(child.children).forEach((c) => blocks.push(c));
        } else {
            blocks.push(child);
        }
    });
    if (!blocks.length) return;
    blocks.forEach((el) => el.classList.add('article-enter'));

    const play = (el, delayMs) => {
        el.style.animationDelay = (delayMs || 0) + 'ms';
        el.classList.add('play');
        el.dataset.entered = '1';
    };
    if (!('IntersectionObserver' in window)) { blocks.forEach((el) => play(el, 0)); return; }

    const STAGGER = 120;   // 相邻块之间的错峰间隔(ms)
    const ROW_TOL = 28;    // 顶部相差小于此值视为同一片,一起入场
    // 首屏:按视觉顺序(getBoundingClientRect.top,已含封面 order:-1 置顶)从上到下逐块错开
    const vh = window.innerHeight || document.documentElement.clientHeight;
    const inView = blocks
        .filter((el) => { const r = el.getBoundingClientRect(); return r.top < vh - 40 && r.bottom > 0; })
        .sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);
    let lastTop = null;
    let step = 0;
    inView.forEach((el) => {
        const top = Math.round(el.getBoundingClientRect().top);
        if (lastTop !== null && top - lastTop > ROW_TOL) step += 1;
        lastTop = top;
        play(el, step * STAGGER);
    });

    // 屏外:滚动进入视口时各自即时播放(不再叠加错峰延迟,避免滚动后还要等)
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((e) => {
            if (!e.isIntersecting) return;
            observer.unobserve(e.target);
            play(e.target, 0);
        });
    }, { root: null, rootMargin: '0px 0px -50px 0px', threshold: 0.1 });
    blocks.forEach((el) => { if (!el.dataset.entered) observer.observe(el); });
}

function initReveal() {
    const items = document.querySelectorAll('.reveal-up');
    if (!items.length) return;

    if (!('IntersectionObserver' in window)) {
        items.forEach((el) => el.classList.add('visible'));
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry, i) => {
            if (!entry.isIntersecting) return;
            const el = entry.target;
            setTimeout(() => el.classList.add('visible'), i * 60);
            observer.unobserve(el);
        });
    }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

    items.forEach((el) => observer.observe(el));
}

/* Writing 列表:左栏门类作筛选。「全部」按发布时间从新到旧合并展示,
   点具体门类只看该类(相对顺序仍是新→旧)。 */
function initWritingFilter() {
    const buttons = Array.from(document.querySelectorAll('.design-menu .nav-cat[data-filter]'));
    const grid = document.querySelector('#writing-all .category-grid');
    if (!buttons.length || !grid) return;

    // 先把所有卡片按发布日期从新到旧排好(一次即可,分类视图也沿用该相对顺序)
    const cards = Array.from(grid.querySelectorAll('.card-wrapper'));
    cards
        .sort((a, b) => (b.dataset.date || '').localeCompare(a.dataset.date || ''))
        .forEach((c) => grid.appendChild(c));

    const apply = (filter) => {
        cards.forEach((c) => {
            c.hidden = !(filter === 'all' || c.dataset.cat === filter);
        });
    };

    buttons.forEach((btn) => {
        btn.addEventListener('click', () => {
            buttons.forEach((b) => b.classList.toggle('active', b === btn));
            apply(btn.dataset.filter || 'all');
        });
    });

    const initial = buttons.find((b) => b.classList.contains('active')) || buttons[0];
    apply(initial.dataset.filter || 'all');
}

/* 标签筛选:按 data-tags(逗号分隔)显隐文章 */
function initTagFilter() {
    const buttons = document.querySelectorAll('.tag-btn[data-tag]');
    const items = document.querySelectorAll('.article-item[data-tags]');
    if (!buttons.length || !items.length) return;

    const apply = (tag) => {
        items.forEach((item) => {
            const tags = (item.dataset.tags || '').split(',').map((t) => t.trim());
            const show = tag === 'all' || tags.includes(tag);
            item.hidden = !show;
        });
    };

    buttons.forEach((btn) => {
        btn.addEventListener('click', () => {
            buttons.forEach((b) => b.classList.toggle('active', b === btn));
            apply(btn.dataset.tag || 'all');
        });
    });
}

/* 阅读页:从正文 h2/h3 生成目录,滚动时高亮当前章节 */
function initTOC() {
    const toc = document.getElementById('toc');
    const body = document.querySelector('.article-body');
    if (!toc || !body) return;

    const heads = Array.from(body.querySelectorAll('h2, h3'));
    if (!heads.length) {
        const aside = toc.closest('.article-toc');
        if (aside) aside.style.display = 'none';
        return;
    }

    const links = [];
    heads.forEach((h, i) => {
        if (!h.id) h.id = 'sec-' + i;
        const a = document.createElement('a');
        a.href = '#' + h.id;
        a.textContent = h.textContent;
        if (h.tagName === 'H3') a.classList.add('sub');
        a.addEventListener('click', (e) => {
            e.preventDefault();
            h.scrollIntoView({ behavior: 'smooth', block: 'start' });
            history.replaceState(null, '', '#' + h.id);
        });
        toc.appendChild(a);
        links.push(a);
    });

    /* scrollspy */
    if (!('IntersectionObserver' in window)) return;
    const seen = new Map();
    const spy = new IntersectionObserver((entries) => {
        entries.forEach((entry) => seen.set(entry.target, entry.isIntersecting));
        let activeId = heads[0].id;
        for (const h of heads) {
            if (seen.get(h)) { activeId = h.id; break; }
            if (h.getBoundingClientRect().top < 140) activeId = h.id;
        }
        links.forEach((a) => a.classList.toggle('active', a.getAttribute('href') === '#' + activeId));
    }, { rootMargin: '-120px 0px -70% 0px', threshold: [0, 1] });

    heads.forEach((h) => spy.observe(h));
}
