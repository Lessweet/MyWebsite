/**
 * Portfolio - Staggered Card Animation
 * Uses Intersection Observer for scroll-triggered animations
 */

document.addEventListener('DOMContentLoaded', () => {
    initCardAnimations();
    initCategoryFilter();
    initLogoFontShuffle();
});

/**
 * Continuously swap the header logo's font through 6 fonts at a relaxed pace.
 */
function initLogoFontShuffle() {
    const el = document.querySelector('.logo-shuffle');
    if (!el) return;

    const fonts = [
        "'SF Mono', 'JetBrains Mono', Menlo, monospace",
        "Georgia, 'Times New Roman', serif",
        "'Snell Roundhand', 'Brush Script MT', cursive",
        "Impact, 'Arial Black', sans-serif",
        "'Helvetica Neue', Helvetica, Arial, sans-serif",
        "'Courier New', Courier, monospace"
    ];

    let idx = 0;
    const tick = () => {
        el.style.fontFamily = fonts[idx];
        idx = (idx + 1) % fonts.length;
        setTimeout(tick, 650);
    };

    tick();
}

/**
 * Category filter: clicking a button hides cards whose data-category doesn't match.
 * "all" shows everything.
 */
function initCategoryFilter() {
    const buttons = document.querySelectorAll('.category-btn');
    const cards = document.querySelectorAll('.card-wrapper');

    buttons.forEach((btn) => {
        btn.addEventListener('click', () => {
            const filter = btn.dataset.filter;

            buttons.forEach((b) => b.classList.toggle('active', b === btn));

            cards.forEach((card) => {
                const cat = card.dataset.category;
                const match = filter === 'all' || cat === filter;
                card.style.display = match ? '' : 'none';
            });

            requestAnimationFrame(updateDynamicScale);
        });
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
 * - Shows when scrolling up
 * - Hides when scrolling down (after scrolling a distance)
 */
let lastScrollY = 0;
let scrollDelta = 0;
const header = document.querySelector('.header');
const scrollThreshold = 10; // Minimum scroll distance to trigger hide/show

window.addEventListener('scroll', () => {
    const currentScrollY = window.scrollY;
    const scrollDiff = currentScrollY - lastScrollY;

    // Accumulate scroll delta
    scrollDelta += scrollDiff;

    // Scrolling down - hide header after threshold
    if (scrollDiff > 0 && currentScrollY > 100) {
        if (scrollDelta > scrollThreshold) {
            header.classList.add('header-hidden');
            scrollDelta = 0;
        }
    }
    // Scrolling up - show header
    else if (scrollDiff < 0) {
        if (scrollDelta < -scrollThreshold) {
            header.classList.remove('header-hidden');
            scrollDelta = 0;
        }
    }

    // At top of page - always show
    if (currentScrollY <= 10) {
        header.classList.remove('header-hidden');
        scrollDelta = 0;
    }

    lastScrollY = currentScrollY;
}, { passive: true });

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
