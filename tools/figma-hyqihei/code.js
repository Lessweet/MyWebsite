// 把作品集文件里用到的字体换成汉仪旗黑(2026-10-24 用户:只要用到的字号都改成汉仪旗黑,旧作品集的组件也一起改)。
// 在 Figma 桌面端运行:Plugins → Development → Import plugin from manifest… 选本目录的 manifest.json,再运行。
// 改动范围:
//   1. 本文件全部本地文字样式(作品集/…、T1、正文、标签…)
//   2.「作品集 2026」页上所有没挂文字样式的文字
//   3.「Portfolio」页里组件母版(COMPONENT)内没挂文字样式的文字(实例跟着变)
// 字重对应:细 / 常规 → HY QiHei50;中粗(Medium / Semibold)→ HY QiHei70;粗(Bold / Heavy / Black)→ HYQiHei 80J。
// 已经是汉仪字体(HY 开头,如雅酷黑、长宋)的不动。改完可以 ⌘Z 撤销。

(async () => {
  const avail = await figma.listAvailableFontsAsync();
  const has = ([family, style]) => avail.some((f) => f.fontName.family === family && f.fontName.style === style);
  const pick = (list) => list.find(has);
  const LIGHT = pick([['HY QiHei50', 'Regular'], ['HYQiHei', '60J'], ['HYQiHei', '50S'], ['HYQiHei', '50J'], ['HY QiHei60', 'Regular']]);
  const MED = pick([['HY QiHei70', 'Regular'], ['HYQiHei', '70J'], ['HYQiHei', '70S'], ['HYQiHei', '65J'], ['HY QiHei65', 'Regular']]);
  const BOLD = pick([['HYQiHei', '80J'], ['HY QiHei80', 'Regular'], ['HYQiHei', '80S'], ['HYQiHei', '85S']]) || MED;
  if (!LIGHT || !MED) {
    const qi = [...new Set(avail.filter((f) => /qihei/i.test(f.fontName.family)).map((f) => `${f.fontName.family} ${f.fontName.style}`))];
    figma.closePlugin(`没找到汉仪旗黑。本机能用的旗黑:${qi.join('、') || '无'}`);
    return;
  }
  const target = (fn) => {
    if (/^HY|汉仪/.test(fn.family)) return null;
    const s = fn.style.toLowerCase();
    if (/semi ?bold|demi ?bold|medium/.test(s)) return MED;
    if (/bold|heavy|black/.test(s)) return BOLD;
    return LIGHT;
  };
  const loaded = new Set();
  const load = async (f) => {
    const k = f[0] ? `${f[0]}|${f[1]}` : `${f.family}|${f.style}`;
    if (loaded.has(k)) return true;
    try {
      await figma.loadFontAsync(f[0] ? { family: f[0], style: f[1] } : f);
      loaded.add(k);
      return true;
    } catch (e) {
      return false;
    }
  };

  let styles = 0, texts = 0, skipped = 0;
  // 1. 文字样式
  for (const st of await figma.getLocalTextStylesAsync()) {
    const t = target(st.fontName);
    if (!t) continue;
    await load(t);
    st.fontName = { family: t[0], style: t[1] };
    styles++;
  }
  // 2 / 3. 没挂样式的文字
  const swapText = async (node) => {
    const segs = node.getStyledTextSegments(['fontName', 'textStyleId']);
    let changed = false;
    for (const seg of segs) {
      if (seg.textStyleId) continue;   // 挂了样式的,上面改样式时已经换掉
      const t = target(seg.fontName);
      if (!t) continue;
      if (!(await load(seg.fontName))) { skipped++; continue; }   // 原字体缺失,改不了
      await load(t);
      node.setRangeFontName(seg.start, seg.end, { family: t[0], style: t[1] });
      changed = true;
    }
    if (changed) texts++;
  };
  for (const page of figma.root.children) {
    if (page.name !== '作品集 2026' && page.name !== 'Portfolio') continue;
    await page.loadAsync();
    let nodes = page.findAllWithCriteria({ types: ['TEXT'] });
    if (page.name === 'Portfolio') {
      nodes = nodes.filter((n) => {
        for (let p = n.parent; p && p.type !== 'PAGE'; p = p.parent) {
          if (p.type === 'INSTANCE') return false;   // 实例里的字跟着母版走,不单独改
          if (p.type === 'COMPONENT') return true;
        }
        return false;
      });
    }
    for (const n of nodes) await swapText(n);
  }
  figma.closePlugin(`已换成汉仪旗黑:${styles} 个文字样式、${texts} 段文字${skipped ? `;${skipped} 段原字体缺失,没改` : ''}。用到:${LIGHT.join(' ')} / ${MED.join(' ')} / ${BOLD.join(' ')}`);
})();
