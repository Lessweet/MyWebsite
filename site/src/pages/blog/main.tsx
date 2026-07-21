import { createRoot } from 'react-dom/client';
import BlogPage from './BlogPage';

/* 根元素就是 <main id="app" class="design-layout">:React 内容直接渲染为 main 的子级,
   与旧页 DOM 树完全一致(不额外包一层 div,避免影响选择器/布局) */
createRoot(document.getElementById('app')!).render(<BlogPage />);
