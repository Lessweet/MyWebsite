/**
 * Portfolio - Staggered Card Animation
 * Uses Intersection Observer for scroll-triggered animations
 */

document.addEventListener('DOMContentLoaded', () => {
    initCardAnimations();
});

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
 * Header background on scroll
 */
let lastScrollY = 0;
const header = document.querySelector('.header');

window.addEventListener('scroll', () => {
    const currentScrollY = window.scrollY;

    if (currentScrollY > 100) {
        header.style.borderBottomColor = 'rgba(210, 210, 215, 1)';
    } else {
        header.style.borderBottomColor = 'rgba(210, 210, 215, 0.5)';
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
