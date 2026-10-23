#!/usr/bin/env python3
"""首页「公众号 AI 设计内容」作品卡：8 张不同类型的公众号封面缩略图。

封面来源：aiadong_mp 仓库里已发布文章的封面（以文章 md frontmatter 的 `cover:`
为准；多数是 cover.png，少数文章发布时挂的是 cover4 / cover_v9 这类候选）。
类型划分按 aiadong_mp/.claude/skills/mp-cover/SKILL.md 的主图形层 6 类
（glass-hero / wordmark / glass-tag / posters(+shards) / icon / portrait / wireframe）。

每张按 16:9 等比铺满、居中裁切（`shift` 可水平偏移裁切窗），
输出 384×216 webp(q85)，另写 manifest.json;预览拼图写到 site/assets/cover-types-preview.png(不发布)。

用法：
  python3 site/scripts/build-work-cover-types.py [--src /path/to/aiadong_mp]
"""
import argparse
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs/writing/assets/works/cover-types")
W, H = 384, 216

# 展示顺序 = 两列四行、按行从左到右。
# shift：裁切窗相对居中位置的水平偏移，单位 = 可移动余量的比例（-1 贴左，+1 贴右）。
ITEMS = [
    # file,                          type(中文),     key,          article dir,                                  cover file,  shift
    ("01-glass-hero-codebase",       "磁块字标",     "glass-hero", "20260718 Figma Make 设计师发PR",              "cover4.png", 0),
    ("02-posters-3d-emoji",          "拼图海报",     "posters",    "20260918 Google 3D Emoji 设计",               "cover.png",  0),
    ("03-icon-siri-blueprint",       "图标构造线",   "icon",       "20260623 SiriAI",                             "cover_v9.png", 0),
    ("04-wordmark-config",           "文字字标",     "wordmark",   "20260626 Figma config/发布会介绍",             "cover.png",  0),
    ("05-glass-tag-ai-craft",        "毛玻璃词块",   "glass-tag",  "20260902 让AI成为世界级设计师",               "cover.png",  0),
    ("06-shards-gemini-argon",       "不规则拼贴",   "shards",     "20261014 Gemini 4 Argon",                     "cover.png",  0),
    ("07-portrait-meaghan-choi",     "人物封面",     "portrait",   "20261022 Meaghan Choi 设计再也回不去了",       "cover.png",  0),
    ("08-wireframe-anthropic-jobs",  "界面线框",     "wireframe",  "20261017 Anthropic内部工作方式变化",           "cover.png",  0),
    # 用户后来指定的右侧封面之一（另外 6 张网站已有缩略图），按同规格补出
    ("ai-mode-google-search",        "界面线框",     "wireframe",  "20261007 Google搜索设计VP谈AI设计",            "cover.png",  0),
]


def article_title(d):
    p = os.path.join(d, "publish_html.py")
    if os.path.exists(p):
        m = re.search(r"""title\s*=\s*(['"])(.+?)\1""", open(p, encoding="utf-8").read())
        if m:
            return m.group(2)
    mds = sorted((f for f in os.listdir(d) if f.endswith(".md")), key=lambda f: ("终稿" not in f, f))
    for f in mds:
        txt = open(os.path.join(d, f), encoding="utf-8").read()
        m = re.search(r"^title:\s*(.+)$", txt, re.M) or re.search(r"^#\s+(.+)$", txt, re.M)
        if m:
            return m.group(1).strip()
    return ""


def crop_16_9(im, shift=0.0):
    w, h = im.size
    if w / h > 16 / 9:
        cw = round(h * 16 / 9)
        x0 = (w - cw) / 2 * (1 + shift)
        return im.crop((round(x0), 0, round(x0) + cw, h))
    ch = round(w * 9 / 16)
    y0 = (h - ch) // 2
    return im.crop((0, y0, w, y0 + ch))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.path.join(os.path.dirname(ROOT), "aiadong_mp"))
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)

    manifest, thumbs = [], []
    for name, tname, key, art, cover, shift in ITEMS:
        d = os.path.join(a.src, art)
        im = Image.open(os.path.join(d, cover)).convert("RGB")
        th = crop_16_9(im, shift).resize((W, H), Image.LANCZOS)
        fn = name + ".webp"
        th.save(os.path.join(OUT, fn), "WEBP", quality=85, method=6)
        thumbs.append((fn, tname, key, th))
        manifest.append({"file": fn, "type": tname, "article": art, "title": article_title(d)})

    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")

    # 两列预览拼图（只供检查，不上线）
    g, lab = 16, 28
    rows = (len(thumbs) + 1) // 2
    pv = Image.new("RGB", (2 * W + 3 * g, rows * (H + lab) + (rows + 1) * g - 4), "#f2f2f2")
    dr = ImageDraw.Draw(pv)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", 14)
    except OSError:
        font = ImageFont.load_default()
    for i, (fn, tname, key, th) in enumerate(thumbs):
        x = g + (i % 2) * (W + g)
        y = g + (i // 2) * (H + lab + g)
        pv.paste(th, (x, y))
        dr.text((x, y + H + 6), f"{fn}  ·  {tname} {key}", fill="#333", font=font)
    # 预览拼图只供检查,不放进会发布的 docs/(site/assets 不发布)
    pv.save(os.path.join(ROOT, "site/assets/cover-types-preview.png"))

    total = sum(os.path.getsize(os.path.join(OUT, t[0])) for t in thumbs)
    print(f"wrote {len(thumbs)} webp, total {total / 1024:.1f} KB -> {OUT}")


if __name__ == "__main__":
    main()
