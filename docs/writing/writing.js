/**
 * Writing — 列表页标签筛选 + reveal 动效 + 阅读页目录(TOC)
 * 复用 ../script.js 的 brand banner / sticky header,这里只补文章特有逻辑。
 */
document.addEventListener('DOMContentLoaded', () => {
    initReveal();
    initTagFilter();
    initTOC();
    initNavSpy();
});

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
