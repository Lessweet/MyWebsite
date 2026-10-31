import { createRoot } from 'react-dom/client';
import HomePage from './HomePage';

/* 本地测试版(vite dev)才显示主题键;线上构建里这行被整段去掉 */
if (import.meta.env.DEV) document.documentElement.classList.add('dev-tools');

/* 每次打开 / 刷新都从页顶开始(2026-10-31 用户:各种宽度、各种设备都要从头开始,入场动画也从头播):
   关掉浏览器的「记住滚动位置」;iOS Safari 刷新时偶尔不听,离开页面前再手动滚回顶部一次 */
if ('scrollRestoration' in history) history.scrollRestoration = 'manual';
window.scrollTo(0, 0);
window.addEventListener('pagehide', () => window.scrollTo(0, 0));

createRoot(document.getElementById('app')!).render(<HomePage />);
