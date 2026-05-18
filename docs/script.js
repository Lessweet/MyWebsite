/**
 * Portfolio - Staggered Card Animation
 * Uses Intersection Observer for scroll-triggered animations
 */

document.addEventListener('DOMContentLoaded', () => {
    initCardAnimations();
    initCategoryFilter();
    initBrandBanner();
    initIconShowcaseFrames();
    initSectionHeadingRise();
});

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
        // Only split text nodes that haven't been processed yet.
        if (h2.dataset.riseInit) return;
        const text = h2.textContent.trim();
        if (!text) return;

        h2.dataset.riseInit = '1';
        h2.setAttribute('aria-label', text);
        h2.classList.add('heading-rise');
        h2.textContent = '';

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
    const cardWrappers = document.querySelectorAll('.card-wrapper');

    // Intersection Observer configuration
    const observerOptions = {
        root: null, // viewport
        rootMargin: '0px 0px -50px 0px', // trigger slightly before fully visible
        threshold: 0.1 // 10% visible
    };

    // Create observer
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                const wrapper = entry.target;
                const delay = parseInt(wrapper.dataset.delay) || 0;

                // Apply staggered delay
                setTimeout(() => {
                    wrapper.classList.add('visible');
                }, delay);

                // Stop observing once animated
                observer.unobserve(wrapper);
            }
        });
    }, observerOptions);

    // Observe all card wrappers
    cardWrappers.forEach((wrapper) => {
        observer.observe(wrapper);
    });
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
 * Smart Sticky Header
 * - Always visible on load (no flash of hidden state)
 * - Hides when scrolling down past 100px
 * - Shows again when scrolling up
 * - At very top: forced visible
 */
(() => {
    const header = document.querySelector('.header');
    if (!header) return;

    // Start visible — fixes the "banner disappears on refresh" issue.
    header.classList.remove('header-hidden');

    let lastScrollY = window.scrollY;
    let scrollDelta = 0;
    const scrollThreshold = 10;

    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        const scrollDiff = currentScrollY - lastScrollY;
        scrollDelta += scrollDiff;

        // Scrolling down past 100px — hide after threshold of consecutive down-scroll
        if (scrollDiff > 0 && currentScrollY > 100) {
            if (scrollDelta > scrollThreshold) {
                header.classList.add('header-hidden');
                scrollDelta = 0;
            }
        }
        // Scrolling up — reveal once threshold of consecutive up-scroll is met
        else if (scrollDiff < 0) {
            if (scrollDelta < -scrollThreshold) {
                header.classList.remove('header-hidden');
                scrollDelta = 0;
            }
        }

        // At the very top: always show
        if (currentScrollY <= 10) {
            header.classList.remove('header-hidden');
            scrollDelta = 0;
        }

        lastScrollY = currentScrollY;
    }, { passive: true });
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
