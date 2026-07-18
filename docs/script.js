/**
 * Portfolio - Staggered Card Animation
 * Uses Intersection Observer for scroll-triggered animations
 */

document.addEventListener('DOMContentLoaded', () => {
    initCardAnimations();
    initCoverFade();
    initCategoryFilter();
    initBrandBanner();
    initIconShowcaseFrames();
    initSectionHeadingRise();
});

/* 卡片封面媒体:加载就绪后透明度淡入(视频首帧 loadeddata / iframe load),
   避免封面内容突然弹出。带兜底定时器,确保即使 load 不触发也会显示。 */
function initCoverFade() {
    const covers = document.querySelectorAll(
        '.home-v2 .card-video, .home-v2 .icon-preview-frame, .home-v2 .card-iframe'
    );
    covers.forEach((el) => {
        const show = () => el.classList.add('cover-in');
        if (el.tagName === 'VIDEO') {
            if (el.readyState >= 2) show();                       // 已有首帧
            else el.addEventListener('loadeddata', show, { once: true });
        } else {
            el.addEventListener('load', show, { once: true });    // iframe
        }
        setTimeout(show, 2000);   // 兜底:最迟 2s 一定淡入,避免永久隐藏
    });
}

/**
 * Per-character rise animation for section headings.
 * Spec follows pixel-point/animate-text "per-character-rise":
 *   - Each letter starts translateY(110%) + opacity 0
 *   - On enter-view, letters rise to translateY(0) + opacity 1
 *   - Stagger ~35ms per char, ease cubic-bezier(0.22, 1, 0.36, 1), 700ms
 *   - Parent mask uses overflow:hidden so letters appear from below the baseline
 */
function initSectionHeadingRise() {
    const headings = document.querySelectorAll('.section-divider h2');
    if (!headings.length) return;

    headings.forEach((h2) => {
        // 已处理过的跳过(用 class 判断,避免被 HTML 里预置的 data-rise-init 挡住)
        if (h2.classList.contains('heading-rise')) return;

        // 保留标题前的图标,只把文字拆成逐字上升的字符
        const icon = h2.querySelector('.heading-icon');
        const text = h2.textContent.trim();
        if (!text) return;

        h2.setAttribute('aria-label', text);
        h2.classList.add('heading-rise');
        h2.textContent = '';
        if (icon) h2.appendChild(icon);

        const mask = document.createElement('span');
        mask.className = 'heading-rise-mask';
        mask.setAttribute('aria-hidden', 'true');

        Array.from(text).forEach((char, i) => {
            const span = document.createElement('span');
            span.className = 'heading-rise-char';
            span.textContent = char === ' ' ? ' ' : char;
            span.style.setProperty('--d', `${i * 35}ms`);
            mask.appendChild(span);
        });
        h2.appendChild(mask);
    });

    // design-page:标题的「升起」交给 initPillarEntrance 的级联统一调度
    // (这样能排在 banner 之后),此处只做拆字准备,不自行触发显现
    if (document.body.classList.contains('design-page')) return;

    if (!('IntersectionObserver' in window)) {
        // Fallback: just reveal everything.
        headings.forEach((h2) => h2.classList.add('heading-rise-in'));
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                entry.target.classList.add('heading-rise-in');
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.25, rootMargin: '0px 0px -10% 0px' });

    headings.forEach((h2) => observer.observe(h2));
}

function initIconShowcaseFrames() {
    const frames = Array.from(document.querySelectorAll('.icon-showcase-frame'));
    if (!frames.length) return;

    const setFrameHeight = (frame, height) => {
        const value = Number(height);
        if (!Number.isFinite(value) || value <= 0) return;
        frame.style.height = `${Math.ceil(value)}px`;
    };

    const resizeFrame = (frame) => {
        try {
            const doc = frame.contentDocument || frame.contentWindow?.document;
            if (!doc) return;
            const content = doc.querySelector('main') || doc.body || doc.documentElement;
            const rect = content.getBoundingClientRect ? content.getBoundingClientRect() : { height: 0 };

            const height = Math.max(
                content.scrollHeight || 0,
                content.offsetHeight || 0,
                rect.height || 0
            );

            setFrameHeight(frame, height);
        } catch {
            // Keep the CSS fallback height when the browser blocks file access.
        }
    };

    const requestFrameResize = (frame) => {
        resizeFrame(frame);
        try {
            frame.contentWindow?.postMessage({ type: 'icon-showcase:request-height' }, '*');
        } catch {}
    };

    const resizeAll = () => frames.forEach(requestFrameResize);

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || data.type !== 'icon-showcase:height') return;

        const frame = frames.find(item => item.contentWindow === event.source);
        if (!frame) return;
        setFrameHeight(frame, data.height);
    });

    frames.forEach((frame) => {
        frame.addEventListener('load', () => {
            requestFrameResize(frame);
            requestAnimationFrame(() => requestFrameResize(frame));
            setTimeout(() => requestFrameResize(frame), 250);

            try {
                const doc = frame.contentDocument || frame.contentWindow?.document;
                if (doc?.body && typeof ResizeObserver !== 'undefined') {
                    const observer = new ResizeObserver(() => requestFrameResize(frame));
                    observer.observe(doc.body);
                    frame._iconShowcaseObserver = observer;
                }
            } catch {}
        });
    });

    window.addEventListener('load', resizeAll);
    window.addEventListener('resize', () => requestAnimationFrame(resizeAll));
}

/**
 * Single-level category filter — each .category-btn[data-filter] toggles
 * the corresponding .category-section[data-category]; "all" shows everything.
 */
function initCategoryFilter() {
    const buttons = document.querySelectorAll('.category-btn[data-filter]');
    const sections = document.querySelectorAll('.category-section');

    let activeFilter = 'all';

    const applyFilter = () => {
        sections.forEach((section) => {
            const sCat = section.dataset.category;
            const visible = activeFilter === 'all' || sCat === activeFilter;
            section.style.display = visible ? '' : 'none';
        });
        requestAnimationFrame(updateDynamicScale);
    };

    buttons.forEach((btn) => {
        btn.addEventListener('click', () => {
            activeFilter = btn.dataset.filter || 'all';
            buttons.forEach((b) => b.classList.toggle('active', b === btn));
            applyFilter();
        });
    });
}

/**
 * Pixel VIBEDESIGN banner — renders the header logo grid and cycles through
 * three character styles (ascii / block / dots). Click to advance manually.
 */
function initBrandBanner() {
    const grid = document.getElementById('brand-banner-grid');
    if (!grid) return;

    function mulberry32(seed) {
        let s = seed >>> 0;
        return function () {
            s = (s + 0x6D2B79F5) >>> 0;
            let t = s;
            t = Math.imul(t ^ (t >>> 15), t | 1);
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
            return ((t ^ (t >>> 16)) >>> 0) / 4294967296;
        };
    }
    function hashStr(str) {
        let h = 2166136261 >>> 0;
        for (let i = 0; i < str.length; i++) {
            h ^= str.charCodeAt(i);
            h = Math.imul(h, 16777619);
        }
        return h >>> 0;
    }
    let rand = Math.random;

    const base = [
        "*   *  ***  ****  ***** ****  *****  ****  ***   ***  *   *",
        "*   *   *   *   * *     *   * *     *       *   *   * **  *",
        "*   *   *   *   * *     *   * *     *       *   *     * * *",
        "*   *   *   ****  ****  *   * ****   ***    *   * *** * * *",
        " * *    *   *   * *     *   * *         *   *   *   * * * *",
        " * *    *   *   * *     *   * *         *   *   *   * *  **",
        "  *    ***  ****  ***** ****  ***** ****   ***   ***  *   *",
    ];
    const SCALE = 2;
    const expanded = [];
    for (const row of base) {
        const wide = Array.from(row, ch => ch.repeat(SCALE)).join('');
        for (let v = 0; v < SCALE; v++) expanded.push(wide);
    }
    const lh = expanded.length;
    const lw = expanded[0].length;
    const padCols = 3;
    const padRows = 1;
    const cols = lw + padCols * 2;
    const rows = lh + padRows * 2;
    const colOff = padCols;
    const rowOff = padRows;

    const isLetter = (r, c) => {
        const lr = r - rowOff, lc = c - colOff;
        return lr >= 0 && lr < lh && lc >= 0 && lc < lw && expanded[lr][lc] === '*';
    };

    const MAX_HALO = 3;
    const distToLetter = (r, c) => {
        for (let d = 1; d <= MAX_HALO; d++) {
            for (let dr = -d; dr <= d; dr++) {
                for (let dc = -d; dc <= d; dc++) {
                    if (Math.max(Math.abs(dr), Math.abs(dc)) !== d) continue;
                    if (isLetter(r + dr, c + dc)) return d;
                }
            }
        }
        return Infinity;
    };

    const pick = arr => () => arr[Math.floor(rand() * arr.length)];
    const STYLES = [
        { id: 'ascii', letter: () => '*', accent: () => '\\', ambient: pick(['*', '\\']),
          densityByDist: { 1: 0.28, 2: 0.22 }, ambientDensity: 0.015 },
        { id: 'block', letter: () => '▄', accent: pick(['▀', '▄']), ambient: pick(['▀', '▄']),
          densityByDist: { 1: 0.18, 2: 0.14 }, ambientDensity: 0.012 },
        { id: 'dots',  letter: () => '•', accent: () => '•',
          ambient: pick(['•', '•', '•', '✦', '✦', '▪', '▴']),
          densityByDist: {}, ambientDensity: 0.038 },
    ];
    const SWITCH_MS = 2200;

    const cell = (cls, text, maxDelay) => {
        const s = document.createElement('span');
        s.className = cls;
        s.style.setProperty('--d', (rand() * maxDelay).toFixed(2) + 's');
        s.textContent = text;
        return s;
    };

    function build(style) {
        rand = mulberry32(hashStr(style.id));
        const frag = document.createDocumentFragment();
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < cols; c++) {
                if (isLetter(r, c)) {
                    frag.appendChild(cell('px-letter', style.letter(), 2.6));
                    continue;
                }
                const d = distToLetter(r, c);
                const haloDensity = style.densityByDist[d];
                if (haloDensity !== undefined) {
                    if (rand() < haloDensity) {
                        frag.appendChild(cell('px-accent', style.accent(), 3.6));
                    } else {
                        frag.appendChild(document.createTextNode(' '));
                    }
                } else if (rand() < style.ambientDensity) {
                    frag.appendChild(cell('px-star', style.ambient(), 3.6));
                } else {
                    frag.appendChild(document.createTextNode(' '));
                }
            }
            if (r < rows - 1) frag.appendChild(document.createTextNode('\n'));
        }
        return frag;
    }

    function applyStyle(style) {
        grid.dataset.styleId = style.id;
        grid.replaceChildren(build(style));
    }

    let idx = 0;
    let timer;
    const advance = () => {
        idx = (idx + 1) % STYLES.length;
        applyStyle(STYLES[idx]);
    };
    const scheduleAutoSwitch = () => {
        clearInterval(timer);
        timer = setInterval(advance, SWITCH_MS);
    };

    applyStyle(STYLES[idx]);
    scheduleAutoSwitch();

    const trigger = grid.closest('.header-banner-link') || grid.parentElement;
    trigger.addEventListener('click', (e) => {
        e.preventDefault();
        advance();
        scheduleAutoSwitch();
    });
}

/**
 * Initialize card entrance animations with stagger effect
 */
function initCardAnimations() {
    // Writing / Design 支柱页:整页从上到下一片接一片淡入;其余页保持原有逐卡入场
    if (document.body.classList.contains('design-page')) {
        initPillarEntrance();
        return;
    }
    initCardStagger();
}

/* 旧版作品页:卡片滚动进入视口时按各自 data-delay 错开淡入 */
function initCardStagger() {
    const cardWrappers = document.querySelectorAll('.card-wrapper');
    if (!cardWrappers.length) return;

    if (!('IntersectionObserver' in window)) {
        cardWrappers.forEach((el) => el.classList.add('visible'));
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            const wrapper = entry.target;
            const delay = parseInt(wrapper.dataset.delay) || 0;
            setTimeout(() => wrapper.classList.add('visible'), delay);
            observer.unobserve(wrapper);
        });
    }, { root: null, rootMargin: '0px 0px -50px 0px', threshold: 0.1 });

    cardWrappers.forEach((wrapper) => observer.observe(wrapper));
}

/* 支柱页加载入场:菜单 / banner / 卡片从上到下「一片接一片」淡入。
   按元素垂直位置分行成「片」,同一行一起淡入,行与行依次错开;
   首屏元素加载即排好波次,屏外元素滚动到时继续同样的节奏。 */
function initPillarEntrance() {
    // 把小标题一并纳入级联:这样它会按垂直位置排在 banner 之后才升起
    const targets = Array.from(document.querySelectorAll(
        '.design-menu, .design-banner-frame, .section-divider h2, .card-wrapper'
    ));
    if (!targets.length) return;

    // 标题用「逐字升起」(heading-rise-in),其余元素用淡入(visible)
    const reveal = (el) => el.classList.add(
        el.classList.contains('heading-rise') ? 'heading-rise-in' : 'visible'
    );

    if (!('IntersectionObserver' in window)) {
        targets.forEach(reveal);
        return;
    }

    const STAGGER = 110;   // 相邻「片」(行)之间的间隔(ms)
    const ROW_TOL = 28;    // 顶部相差小于此值视为同一片
    const COL_STAGGER = 180; // 同一行内多张卡片,从左到右依次出现的间隔(ms)

    const revealByRow = (els) => {
        // 先按垂直位置把元素分成一「片」一「片」(行)
        const sorted = els.slice().sort(
            (a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top
        );
        const rows = [];
        let lastTop = null;
        sorted.forEach((el) => {
            const top = Math.round(el.getBoundingClientRect().top);
            if (lastTop === null || top - lastTop > ROW_TOL) rows.push([]);
            lastTop = top;
            rows[rows.length - 1].push(el);
        });

        // 行与行依次错开;行内有 2 张及以上时,再从左到右依次出现,带错落感
        rows.forEach((row, step) => {
            const rowDelay = step * STAGGER;
            const ordered = row.slice().sort(
                (a, b) => a.getBoundingClientRect().left - b.getBoundingClientRect().left
            );
            ordered.forEach((el, col) => {
                setTimeout(() => reveal(el), rowDelay + col * COL_STAGGER);
                el.dataset.entered = '1';
            });
        });
    };

    // 关键:先让初始 opacity:0 真正绘制至少一帧,再开始逐行显现。
    // 双 requestAnimationFrame 确保跨过一次绘制——否则首屏第一波可能在首次绘制前
    // 就被加上 .visible,浏览器直接以最终态绘制、跳过过渡(表现为「没有淡入」)。
    const start = () => requestAnimationFrame(() => requestAnimationFrame(() => {
        // 首屏:一次性从上到下排好波次
        const vh = window.innerHeight || document.documentElement.clientHeight;
        const inView = targets.filter((el) => {
            const r = el.getBoundingClientRect();
            return r.top < vh - 40 && r.bottom > 0;
        });
        revealByRow(inView);

        // 屏外:滚动进入视口时继续按行淡入
        const observer = new IntersectionObserver((entries) => {
            const hits = entries.filter((e) => e.isIntersecting).map((e) => e.target);
            hits.forEach((el) => observer.unobserve(el));
            if (hits.length) revealByRow(hits);
        }, { root: null, rootMargin: '0px 0px -50px 0px', threshold: 0.1 });

        targets.forEach((el) => { if (!el.dataset.entered) observer.observe(el); });
    }));

    // 首页 loading 遮罩在场时(html.is-loading 用 !important 把卡片按住),级联的
    // setTimeout 会在遮罩期间全部跑完,放闸后所有卡片同时上移、错峰节奏丢失。
    // 所以等 is-loading 摘掉(遮罩完全离场)再开始级联;无遮罩的页面直接开始。
    const docEl = document.documentElement;
    if (docEl.classList.contains('is-loading')) {
        new MutationObserver((_, obs) => {
            if (docEl.classList.contains('is-loading')) return;
            obs.disconnect();
            start();
        }).observe(docEl, { attributes: true, attributeFilter: ['class'] });
    } else {
        start();
    }
}

/**
 * Smooth scroll for navigation links
 */
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

/**
 * Sticky Header — 常驻顶栏
 * 已取消「下滑隐藏 / 上滑显示」交互:顶栏始终固定可见,
 * 二级分类筛选列表(.design-menu)也不再跟随顶栏上滑(其跟随依赖 .header-hidden,此处不再添加)。
 */
(() => {
    const header = document.querySelector('.header');
    if (!header) return;
    header.classList.remove('header-hidden');
})();

/**
 * Video Skeleton - hide when video is loaded
 */
document.querySelectorAll('.card-visual-padded video.card-img').forEach(video => {
    const skeleton = video.parentElement.querySelector('.video-skeleton');
    if (skeleton) {
        video.addEventListener('loadeddata', () => {
            skeleton.style.display = 'none';
        });
        // If already loaded
        if (video.readyState >= 3) {
            skeleton.style.display = 'none';
        }
    }
});

/**
 * 动态缩放卡片内容
 * 根据卡片高度自适应，内容占据卡片高度的 90%
 */
function updateDynamicScale() {
    const scaledCards = document.querySelectorAll('.card-dynamic-scale');
    scaledCards.forEach(card => {
        const cardHeight = card.offsetHeight;
        const contentHeight = parseInt(card.dataset.contentHeight) || 812;
        const targetRatio = parseFloat(card.dataset.targetRatio) || 0.9; // 默认占据 90%
        const scale = (cardHeight * targetRatio) / contentHeight;
        card.style.setProperty('--content-scale', scale);
    });
}

// 初始化和窗口调整时更新
window.addEventListener('load', updateDynamicScale);
window.addEventListener('resize', updateDynamicScale);

// 使用 ResizeObserver 监听卡片尺寸变化
if (typeof ResizeObserver !== 'undefined') {
    const resizeObserver = new ResizeObserver(updateDynamicScale);
    document.querySelectorAll('.card-dynamic-scale').forEach(card => {
        resizeObserver.observe(card);
    });
}

/**
 * 点赞功能
 */
function initLikeButtons() {
    // 从 localStorage 读取点赞状态
    const likedItems = JSON.parse(localStorage.getItem('likedItems') || '{}');

    const likeButtons = document.querySelectorAll('.card-like');
    likeButtons.forEach(button => {
        const id = button.dataset.id;
        const countEl = button.querySelector('.like-count');

        // 更新显示数字（0时隐藏）
        const updateCount = (count) => {
            if (count > 0) {
                countEl.textContent = count;
                countEl.style.display = '';
            } else {
                countEl.textContent = '';
                countEl.style.display = 'none';
            }
        };

        // 初始化状态
        if (likedItems[id]) {
            button.classList.add('liked');
            updateCount(likedItems[id].count || 1);
        } else {
            updateCount(0);
        }

        // 点击事件
        button.addEventListener('click', () => {
            const isLiked = button.classList.contains('liked');
            let count = parseInt(countEl.textContent) || 0;

            if (isLiked) {
                // 取消点赞
                button.classList.remove('liked');
                count = Math.max(0, count - 1);
                delete likedItems[id];
            } else {
                // 点赞
                button.classList.add('liked');
                count += 1;
                likedItems[id] = { count: count, liked: true };
            }

            updateCount(count);
            localStorage.setItem('likedItems', JSON.stringify(likedItems));
        });
    });
}

// 初始化点赞功能
document.addEventListener('DOMContentLoaded', initLikeButtons);

/**
 * QR Code Modal
 */
const qrcodeModal = document.getElementById('qrcodeModal');
const gzhLink = document.getElementById('gzhLink');
const qrcodeClose = document.getElementById('qrcodeClose');

if (gzhLink && qrcodeModal) {
    gzhLink.addEventListener('click', () => {
        qrcodeModal.classList.add('show');
    });

    qrcodeClose.addEventListener('click', () => {
        qrcodeModal.classList.remove('show');
    });

    qrcodeModal.addEventListener('click', (e) => {
        if (e.target === qrcodeModal) {
            qrcodeModal.classList.remove('show');
        }
    });
}
