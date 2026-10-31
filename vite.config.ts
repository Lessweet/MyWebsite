import { defineConfig, type Plugin } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';
import sirv from 'sirv';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const ROOT = resolve(__dirname, 'site');
const DOCS = resolve(__dirname, 'docs');

/* 文章 slug 从 site/writing/ 实际入口文件推导(入口由 extract-articles.mjs 生成,
   与 docs/writing/article-<slug>.html 一一对应),不再维护手写清单 */
const ARTICLE_SLUGS = fs
  .readdirSync(resolve(ROOT, 'writing'))
  .filter((f) => /^article-[\w-]+\.html$/.test(f))
  .map((f) => f.slice('article-'.length, -'.html'.length))
  .sort();

/* 16 个入口。按 site/ 里实际存在的文件过滤,迁移期间可逐页添加 */
const ALL_ENTRIES: Record<string, string> = {
  index: resolve(ROOT, 'index.html'),
  classic: resolve(ROOT, 'classic.html'), // 旧版首页,与新首页互不穿插(2026-10-23)
  blog: resolve(ROOT, 'blog.html'),
  archive: resolve(ROOT, 'archive.html'),
  ...Object.fromEntries(
    ARTICLE_SLUGS.map((s) => [`article-${s}`, resolve(ROOT, `writing/article-${s}.html`)]),
  ),
};
const entries = Object.fromEntries(
  Object.entries(ALL_ENTRIES).filter(([, p]) => fs.existsSync(p)),
);

/* dev 下由 Vite 处理(而非回落到 docs/ 旧文件)的 URL 路径 */
const ENTRY_PATHS = new Set(
  Object.values(entries).flatMap((p) => {
    const rel = '/' + p.slice(ROOT.length + 1).replace(/\\/g, '/');
    return rel === '/index.html' ? [rel, '/'] : [rel];
  }),
);

/* dev:入口之外的请求(style.css、banner/demo iframe、封面、视频、articles.json …)
   回落到 docs/ 静态文件,URL 与线上完全一致;
   入口路径不回落,避免 docs/ 里旧构建的同名 HTML 遮蔽 dev 页面。 */
const PRIVATE = resolve(ROOT, 'private');
const GALLERY_URL = '/writing/assets/works/gallery/';

/* 网易作品只在测试版(本地 dev)展示、不上线(2026-10-31 用户,同右下角三个开发按钮):
   作品数据在 site/private/hidden-works.ts(.gitignore,只留本地)。dev 时虚拟模块读这个文件,
   build 时一律导出空数组 —— 线上包里不会有这些作品 */
function hiddenWorks(): Plugin {
  const ID = 'virtual:hidden-works';
  let serving = false;
  return {
    name: 'hidden-works',
    configResolved(c) {
      serving = c.command === 'serve';
    },
    resolveId(id) {
      if (id === ID) return '\0' + ID;
    },
    load(id) {
      if (id !== '\0' + ID) return;
      const file = join(PRIVATE, 'hidden-works.ts');
      if (serving && fs.existsSync(file)) {
        this.addWatchFile(file);
        return fs.readFileSync(file, 'utf8');
      }
      return 'export const HIDDEN_WORKS = [];';
    },
  };
}

function docsStatic(): Plugin {
  const serve = sirv(DOCS, { dev: true, etag: true });
  const servePrivate = sirv(join(PRIVATE, 'gallery'), { dev: true, etag: true });
  return {
    name: 'docs-static-fallback',
    apply: 'serve',
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        const url = decodeURIComponent((req.url || '/').split('?')[0]);
        if (ENTRY_PATHS.has(url)) return next();
        const file = join(DOCS, url);
        if (fs.existsSync(file) && fs.statSync(file).isFile()) return serve(req, res, next);
        /* 网易作品的图只在本地 site/private/gallery/(不进 git、不上线),测试版按线上同一路径取 */
        if (url.startsWith(GALLERY_URL)) {
          const name = url.slice(GALLERY_URL.length);
          const priv = join(PRIVATE, 'gallery', name);
          if (fs.existsSync(priv) && fs.statSync(priv).isFile()) {
            req.url = '/' + name;
            return servePrivate(req, res, next);
          }
        }
        next();
      });
    },
  };
}

/* build:只清空 Vite 专属的 docs/assets/(哈希 bundle 不累积);
   构建后断言 CNAME 仍在 —— docs/ 整体绝不允许被清空。 */
function cleanBundles(): Plugin {
  return {
    name: 'clean-vite-bundles',
    apply: 'build',
    buildStart() {
      fs.rmSync(join(DOCS, 'assets'), { recursive: true, force: true });
    },
    closeBundle() {
      if (!fs.existsSync(join(DOCS, 'CNAME'))) {
        throw new Error('docs/CNAME 丢失 —— 构建误伤了 docs/,立即检查!');
      }
    },
  };
}

export default defineConfig({
  root: ROOT,
  base: '/',
  /* 关闭 publicDir:docs/ 里 399MB 静态资产绝不进构建管线;
     入口 HTML 里 /style.css 等根绝对引用因此解析不到 → Vite 原样透传(这正是要的) */
  publicDir: false,
  /* 端口锁死:5173 被 design-gallery(--strictPort)长期占着,不锁的话本站会飘到 5174/5175。
     strictPort = 被占就报错而不是悄悄换一个,本站预览地址永远是 localhost:5174。 */
  server: { port: 5174, strictPort: true },
  plugins: [react(), hiddenWorks(), docsStatic(), cleanBundles()],
  build: {
    outDir: DOCS,
    emptyOutDir: false, // 绝不清空 docs/(CNAME + 全部静态资产)
    rollupOptions: {
      input: entries,
      output: {
        /* 全部文章正文片段进同一共享 chunk:阅读器内切换文章零网络请求。
           只圈 fragments(约 670KB)—— 注册表 articles.ts / articleShell.ts 是几 KB 的
           元数据,曾跟着一起进这个 chunk,结果 Blog / 首页只为读卡片元数据就要等整个
           正文包下完才首绘,冷缓存下长时间白屏(2026-08-23 用户线上实测)。 */
        manualChunks(id) {
          if (id.includes('/src/content/fragments')) return 'article-content';
        },
      },
    },
  },
});
