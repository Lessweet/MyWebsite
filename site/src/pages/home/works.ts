/* 首页「代表作」单列 Feed 的数据。每条:日期 + 标题同一行 → 简介(展开讲做了什么)→ 横版封面(16:9)。
   date 写成 YYYY / MM,斜杠前后各一个空格(2026-10-23 用户:要带月份;斜杠两边加空格)。
   cover 为站点根相对路径;没有封面时显示灰色占位块。
   排序:最新在前,每年一条(2026-10-23 用户定)。 */
import { HIDDEN_WORKS } from 'virtual:hidden-works';

/* summary 里的 {…} 是断行词组(2026-10-31 用户:手机换行要最优):手机和横排按词组断行,词不会被拆到两行;
   电脑竖排去掉花括号逐字排(拖窗口时行尾不跳)。改简介时照这个格式把词或短语括起来,标点跟在 } 后面 */
export interface Work {
  date: string;
  title: string;
  summary?: string;
  cover?: string;
  /* 封面换成「两图式」展示(2026-10-23 用户):卡片 16:9 一分为二 ——
     左:手机里的公众号文章页 + 几个排版样式组件;右:文章封面静态罗列(不做平移动效)。
     有它就不用 cover。图片:showcase/ 由 site/scripts/build-work-showcase.* 生成,
     thumbs/ 由 site/scripts/build-work-thumbs.py 生成 */
  /* phones:左容器并排的几屏手机(2026-10-23 用户:改为三屏);comps 保留素材,当前不展示 */
  showcase?: {
    phones: string[];
    comps?: string[];
    /* 右侧封面 + 封面下方的文章标题(2026-10-23 用户:卡片下面加文章标题);src 为空 = 占位块 */
    covers: { src: string; title: string }[];
    /* 两个容器的浅底色(不写用默认:珊瑚 / 黄);空字符串的手机或封面渲染成占位块 */
    tint?: [string, string];
  };
  /* 「四图式」(2026-10-23 用户):两行两列、每张 16:9;src 为空 = 占位块(浅灰底)。
     有它就不用 cover / showcase */
  /* zoom:图在格子里放大几倍、居中裁切(展示范围更小);不写 = 1 */
  gallery?: { src: string; zoom?: number }[];
}

export const WORKS: Work[] = [
  {
    date: 'July 2026',   /* 英文月份 + 年(2026-10-24 用户:用 June 2024 这种格式) */
    title: '公众号 AI 设计内容',
    /* 2026-10-23 用户:改从「怎么用 AI 提升创作 / 写作」讲。事实依据 aiadong_mp 的 Claude.md 工具链:
       yt-detail / scout / mp-writing(规范 + fewshot 范文)/ title / mp-polish / article-template /
       mp-md2html 发草稿箱;mp-cover 出封面。控制在 2~3 行(2026-10-23 用户)。
       末句原为「封面也由 skill 生成,毛玻璃卡片配 shader 流动渐变」,用户改成讲成套视觉元素 skill */
    summary:
      '{把公众号}{「AI设计师阿东」}{的写作}{做成一套 }{Claude Code }{工作流：}{抓素材、}{找选题、}{按自己的}{写作规范}{起稿，}{到润色、}{排版、}{发草稿箱，}{每一步}{都是一个 }{skill；}{视觉也}{做成了}{成套的 }{skill，}{包括封面、}{icon、}{banner、}{引用样式}{这类}{个性化}{元素。}',
    /* 原创文章封面三行,行与行反向自动平移、循环(2026-10-23 用户);
       中间一行放「AI 设计工作流 / Shader & Motion / SKILLS / DESIGN SIGNAL」 */
    /* 网站上用整张位图(2026-10-31 用户:任何作品的加载态都是 16:9 整图):由下面的 showcase 拼图导出,
       改了拼图跑 node site/scripts/build-work-showcase-bitmap.mjs 重新导出(导出时页面加 ?render-showcase 显示拼图原版) */
    gallery: [
      { src: 'writing/assets/works/gallery/wechat-ai-1.webp?v=15' },
      { src: 'writing/assets/works/gallery/wechat-ai-2.webp?v=16' },
    ],
    showcase: {
      phones: [
        'writing/assets/works/showcase/article-phone.webp?v=4',
        'writing/assets/works/showcase/article-phone-2.webp?v=1',
        'writing/assets/works/showcase/article-phone-3.webp?v=1',
      ],
      comps: [
        'writing/assets/works/showcase/comp-1.webp?v=2',
        'writing/assets/works/showcase/comp-2.webp?v=2',
        'writing/assets/works/showcase/comp-3.webp?v=2',
      ],
      /* 右侧封面:15 张原创封面排 3 行 × 5 张,中间一行错开半张,整组倾斜视角铺满容器(2026-10-31 用户;
         之前两行 7–8 张、左右越出;试过 4×2 网格,用户:太愣)。封面用 thumbs-lg/ 的 768×432 大图(放大后不糊,site/scripts/build-work-thumbs-lg.py);VIBEDESIGN 是 Figma 作品集 478:4359;
         统一用渐变玻璃风格的,3D emoji、Gemini Argon、人物照这类不搭的不放(2026-10-31 用户) */
      covers: [
        /* 第 1 行 */
        { src: 'writing/assets/works/thumbs-lg/09-shader-motion.webp', title: '在设计系统里，Figma Shader 和 Motion ，正从效果变成可复用元素' },
        { src: 'writing/assets/works/thumbs-lg/01-thinking-fast-slow.webp', title: 'Thinking Fast & Slow' },
        { src: 'writing/assets/works/thumbs-lg/skills.webp', title: '设计师的新资产，是 Skills' },
        { src: 'writing/assets/works/thumbs-lg/06-claude-code-desktop.webp', title: 'Claude Code Desktop' },
        { src: 'writing/assets/works/thumbs-lg/ai-mode-google-search.webp', title: 'Google AI 搜索设计负责人：你会因为 AI 做出最好的设计' },
        /* 第 2 行(往右错开半张) */
        { src: 'writing/assets/works/thumbs-lg/01-glass-hero-codebase.webp', title: 'AI native 设计师的交付物，不只设计稿，还有 GitHub PR' },
        { src: 'writing/assets/works/thumbs-lg/vibedesign.webp', title: 'VIBEDESIGN' },
        { src: 'writing/assets/works/thumbs-lg/08-ai-design-workflow-2026.webp', title: '今年的 AI 设计工作流：进代码、做工具、用多个 agent、多做判断' },
        { src: 'writing/assets/works/thumbs-lg/08-wireframe-anthropic-jobs.webp', title: 'Anthropic 公开内部就业数据：初级岗招聘变少，员工转向管理 agent' },
        { src: 'writing/assets/works/thumbs-lg/design-signal.webp', title: '跳过 Figma 直接用 GenUI 做设计，踩了一路坑，也跑通了上线' },
        /* 第 3 行 */
        { src: 'writing/assets/works/thumbs-lg/05-figma-config.webp', title: 'Figma Config 一次更新五项，设计和代码双向打通' },
        { src: 'writing/assets/works/thumbs-lg/05-glass-tag-ai-craft.webp', title: '前 Apple AI 设计专家：去除 AI 味、解锁 AI 设计创造力的 8 种技法' },
        { src: 'writing/assets/works/thumbs-lg/04-type-system.webp', title: 'Type System' },
        { src: 'writing/assets/works/thumbs-lg/07-intelligent-ui.webp', title: 'Intelligent UI' },
        { src: 'writing/assets/works/thumbs-lg/03-anthropic-design-workflow.webp', title: 'Anthropic 设计工作流' },
      ],
    },
  },
  {
    date: 'December 2025',
    title: 'AI 辅助生成视觉设计',   /* 2026-10-23 用户:原「2021 内容创作者平台 App 端 Web 端整体设计体验轻量化」 */
    /* 简介(2026-10-23):按四张图的内容写 —— 总览画板「AI 创意海报 / UI 视觉辅助 / 生成式 UI / Co Design」
       及其工具清单(ChatGPT Image2 / 即梦 / LiblibAI、ClaudeCode / Codex、Cursor / FigmaMake) */
    summary:
      '{把 AI }{用进 App }{视觉设计：}{海报和}{设计字体}{用 }{ChatGPT Image2、}{即梦、}{LiblibAI }{多方向}{并行出稿，}{拟物图标、}{主题插图、}{视觉动效}{也交给 AI }{生成；}{界面用 }{Claude Code、}{Cursor、}{Figma Make }{直接生成，}{再沉淀成 }{Design Skill }{复用。}',
    /* 四图(2026-10-23 用户:下面用四图) */
    gallery: [
      /* Figma「作品集」画板 2333:16551(原图存 site/assets/figma/),导出 3840×2160 → 1600×900 webp */
      { src: 'writing/assets/works/gallery/ai-visual-1.webp' },
      /* 整张 Figma 画板 2506:13621(新时代 / 不仅是守望 两台手机),由 site/scripts/build-work-gallery.py 生成 */
      { src: 'writing/assets/works/gallery/ai-visual-2.webp?v=3' },
      /* 单张 Figma 画板 2337:18711(热门剧目 3D 图标 + 手机界面);原为四个拼 2×2 再放大 1.4,
         2026-10-23 用户改成只放这一张。由 site/scripts/build-work-gallery.py 生成 */
      { src: 'writing/assets/works/gallery/ai-visual-3.webp?v=3' },
      /* 整张 Figma 画板 2336:17407(金刚位 / 卡片区 / Banner 区等组件),由 site/scripts/build-work-gallery.py 生成 */
      { src: 'writing/assets/works/gallery/ai-visual-4.webp?v=8' },
    ],
  },
  {
    date: 'September 2024',   /* 月份是占位(2026-10-24 用户:随机给下半年),真实月份待补 */
    title: 'AI 语音聊天产品设计',
    /* 简介(2026-10-23):按 Figma 画板内容写 —— 封面写明设计范围「产品体验 / 交互 / 视觉 / 动效设计」,
       界面合集里有语音键、声音角色(年轻的女教师)、中英文对话、按周订阅页 */
    summary:
      '{Hello Chat }{是一款 }{AI 语音聊天 }{App：}{点一下}{语音键}{就能}{开口聊，}{可以切换}{不同的}{声音角色，}{中英文}{都能对话。}{我负责从}{产品体验、}{交互到}{视觉和动效的}{整套设计，}{包括}{按周订阅的}{付费页。}',
    /* 两张并排(2026-10-23 用户):Figma 画板 2304:14351 封面 + 2304:14348 界面合集,由 site/scripts/build-work-gallery.py 生成 */
    gallery: [
      { src: 'writing/assets/works/gallery/hello-chat-1.webp' },
      { src: 'writing/assets/works/gallery/hello-chat-2.webp?v=2' },
    ],
  },
  /* 网易作品:只在本地测试版接在末尾,线上为空(见 vite.config.ts hiddenWorks) */
  ...(HIDDEN_WORKS as Work[]),
];
