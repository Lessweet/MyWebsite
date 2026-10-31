import { createRoot } from 'react-dom/client';
import HomePage from './HomePage';

/* 本地测试版(vite dev)才显示主题键;线上构建里这行被整段去掉 */
if (import.meta.env.DEV) document.documentElement.classList.add('dev-tools');

createRoot(document.getElementById('app')!).render(<HomePage />);
