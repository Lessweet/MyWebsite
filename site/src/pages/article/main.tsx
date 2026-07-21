import { createRoot } from 'react-dom/client';
import ArticlePage from './ArticlePage';

/* 根元素 = 入口 HTML 的 <div class="reading-layout" id="app" data-slug="…">。
   slug 优先取 data-slug,兜底从 URL 解析(popstate 后直刷同样成立)。 */
const el = document.getElementById('app')!;
const slug =
  el.dataset.slug ||
  (location.pathname.split('/').pop() || '').replace(/^article-/, '').replace(/\.html?$/, '');
createRoot(el).render(<ArticlePage initialSlug={slug} />);
