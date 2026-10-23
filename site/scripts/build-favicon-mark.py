# 站点 favicon(浏览器标签页图标):用户给的气泡环图形(2026-10-23,「站点 logo/字体/材质/Vector.svg」,
# 原件存 site/assets/logo/mark-source.svg)。
# 用法:python3 site/scripts/build-favicon-mark.py
# 产出(docs/):
#   favicon-mark.svg            方形 viewBox、图形居中;浅色标签栏深色图形,深色标签栏(prefers-color-scheme: dark)换浅色
#   favicon-mark.png            64×64 透明底,给不支持 SVG favicon 的浏览器(如 Safari)
#   apple-touch-icon-mark.png   180×180,站点底色上居中图形,iOS 加到主屏用
# 只支持源文件里的绝对坐标 M / L / C / Z;多个子路径按奇偶规则(外圈 + 中间的洞)。
import re
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'site/assets/logo/mark-source.svg'
OUT = ROOT / 'docs'

INK = '#1C1B15'        # 源文件原色
INK_DARK = '#F5F5F7'   # 深色标签栏上用的浅色
BG = '#FDFDFC'         # 站点底色(apple-touch-icon 用)

src = SRC.read_text()
d = re.search(r'\sd="([^"]+)"', src).group(1)


def rings_of(d, steps=24):
    toks = re.findall(r'[MLCZ]|-?\d*\.?\d+(?:e-?\d+)?', d)
    rings, ring, cur, i = [], None, None, 0

    def num():
        nonlocal i
        i += 1
        return float(toks[i - 1])

    while i < len(toks):
        c = toks[i]
        i += 1
        if c == 'M':
            if ring:
                rings.append(ring)
            cur = (num(), num())
            ring = [cur]
        elif c == 'L':
            cur = (num(), num())
            ring.append(cur)
        elif c == 'C':
            p1, p2, p3 = (num(), num()), (num(), num()), (num(), num())
            for k in range(1, steps + 1):
                t = k / steps
                mt = 1 - t
                ring.append((
                    mt ** 3 * cur[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0],
                    mt ** 3 * cur[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1],
                ))
            cur = p3
        elif c == 'Z':
            pass
    if ring:
        rings.append(ring)
    return rings


rings = rings_of(d)
xs = [x for r in rings for x, _ in r]
ys = [y for r in rings for _, y in r]
x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
w, h = x1 - x0, y1 - y0
side = max(w, h)


def render(size, fill, bg=None, scale_in=1.0):
    """把图形居中画进 size×size;scale_in = 图形长边占画布的比例。先 8 倍超采样再缩小抗锯齿"""
    ss = size * 8
    im = Image.new('RGBA', (ss, ss), bg or (0, 0, 0, 0))
    mask = Image.new('L', (ss, ss), 0)
    dr = ImageDraw.Draw(mask)
    k = ss * scale_in / side
    ox = (ss - w * k) / 2 - x0 * k
    oy = (ss - h * k) / 2 - y0 * k
    for n, r in enumerate(rings):
        pts = [(x * k + ox, y * k + oy) for x, y in r]
        dr.polygon(pts, fill=255 if n == 0 else 0)   # 第一个子路径是外圈,其余是洞
    im.paste(Image.new('RGBA', (ss, ss), fill), (0, 0), mask)
    return im.resize((size, size), Image.LANCZOS)


# SVG:方形 viewBox;图形只占 46%,四周留白(2026-10-23 用户:浏览器标签页里缩小一半,原来占 92%)
FAV_SCALE = 0.46
pad = side * (1 / FAV_SCALE - 1) / 2
vb = f'{x0 - (side - w) / 2 - pad:.2f} {y0 - (side - h) / 2 - pad:.2f} {side + pad * 2:.2f} {side + pad * 2:.2f}'
svg = (
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}">'
    f'<style>path{{fill:{INK}}}@media (prefers-color-scheme: dark){{path{{fill:{INK_DARK}}}}}</style>'
    f'<path fill-rule="evenodd" d="{d}"/></svg>\n'
)
(OUT / 'favicon-mark.svg').write_text(svg)
render(64, INK, scale_in=FAV_SCALE).save(OUT / 'favicon-mark.png')
render(180, INK, bg=BG, scale_in=0.62).convert('RGB').save(OUT / 'apple-touch-icon-mark.png')
for f in ('favicon-mark.svg', 'favicon-mark.png', 'apple-touch-icon-mark.png'):
    print(f, (OUT / f).stat().st_size, 'B')
