/**
 * Writing — 列表页标签筛选 + reveal 动效 + 阅读页目录(TOC)
 * 复用 ../script.js 的 brand banner / sticky header,这里只补文章特有逻辑。
 */
document.addEventListener('DOMContentLoaded', () => {
    initSiteNav();
    initStickyMenu();
    initReveal();
    initTagFilter();
    initWritingFilter();
    initTOC();
    initNavSpy();
});

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
    nav.innerHTML =
        '<div class="header-left">' +
            '<a href="' + base + 'index-v2.html" class="site-title" aria-label="VIBEUX"><img src="' + base + 'logo-wordmark.png?v=2" class="site-wordmark" alt="VIBEUX"></a>' +
        '</div>' +
        '<nav class="nav-cats" aria-label="分类">' +
            '<a href="' + base + 'index-v2.html#writing" class="' + a('writing') + '">' + I(pencil) + 'Writing</a>' +
            '<a href="' + base + 'design.html" class="' + a('design') + '">' + I(design) + 'Design</a>' +
        '</nav>' +
        '<div class="header-right">' +
            '<a href="mailto:chentongrong1@gmail.com" class="header-connect" title="chentongrong1@gmail.com" aria-label="Connect me">' +
                '<svg class="connect-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"></rect><path d="M22 6 L12 13 L2 6"></path></svg>' +
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
