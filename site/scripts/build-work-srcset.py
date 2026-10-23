# 首页作品封面的小尺寸版本(2026-10-23 用户:封面体积会不会太大)。
# 原图按 1920 宽出,但卡片在页面上一般只显示 400–560 像素宽(高清屏要 800–1100),
# 另出一张小的,页面用 srcset 让浏览器按实际显示大小挑:
#   gallery/<名>.webp            → gallery/<名>-960.webp(960 宽)、<名>-1280.webp(1280 宽,给 3 倍屏手机)
#   showcase/article-phone*.webp → 同名 -400.webp(手机截图实际只显示约 120–170 像素宽)
# 用法:改完拼图 / 截图后跑一遍  python3 site/scripts/build-work-srcset.py
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / 'docs/writing/assets/works'
JOBS = [('gallery/*.webp', 960), ('gallery/*.webp', 1280), ('showcase/article-phone*.webp', 400)]

for pattern, width in JOBS:
    for src in sorted(ROOT.glob(pattern)):
        if src.stem.endswith(('-960', '-1280', '-400')):
            continue
        out = src.with_name(f'{src.stem}-{width}.webp')
        im = Image.open(src).convert('RGB')
        if im.width > width:
            im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
        im.save(out, 'WEBP', quality=84, method=6)
        print(f'{out.relative_to(ROOT)}  {src.stat().st_size // 1024} KB → {out.stat().st_size // 1024} KB')
