# 公益主题 H5 第二张图(2026-11-21 用户):从 Figma 画板 2120:11129 挑出的 6 个页面拼在一起
#   排行榜、两张列表页(2223:11763 / 11792 / 11760)、三张详情页(2223:11749 / 11752 / 11753)
#   (2151:12353 的爱心排行榜与 2223:11763 同一页;2228:11003 的 AI 客服三页 11-21 用户去掉)
# 原图放在 <MyWebsite>/site/assets/figma/h5-pages/(不进 git)
# 一排 6 张太扁、上下空(用户:这个排版不行),两种排法:
#   tilt    —— 页面铺满整张、整体斜放、四边出血(同「运营视觉活动设计」那张的做法)
#   stagger —— 一排 6 张放大,单双列上下错开、越出上下边
# 用法:/usr/bin/python3 site/scripts/build-h5-pages-collage.py <h5-pages 目录> <输出.png> [tilt|stagger]
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps

SRC, OUT = Path(sys.argv[1]), sys.argv[2]
MODE = sys.argv[3] if len(sys.argv) > 3 else 'tilt'
PAGES = [
    'p-rank-small-2223-11763', 'p-list-2223-11792', 'p-list-2223-11760',
    'p-detail-2223-11749', 'p-detail-2223-11752', 'p-detail-2223-11753',
]
W, H = 1920, 1080
TOP, BOTTOM = (254, 241, 215), (255, 150, 166)   # 同公益 H5 第一张图的暖粉渐变
SS = 2                                           # 先按 2 倍画、最后缩回,边缘更顺


def gradient(w, h):
    col = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / (h - 1)
        col.putpixel((0, y), tuple(round(TOP[i] * (1 - t) + BOTTOM[i] * t) for i in range(3)))
    return col.resize((w, h))


def card(name, cw, ch, r):
    im = Image.open(SRC / f'{name}.png').convert('RGB')
    tile = ImageOps.fit(im, (cw, ch), Image.LANCZOS, centering=(0.5, 0)).convert('RGBA')
    m = Image.new('L', (cw, ch), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, cw - 1, ch - 1), r, fill=255)
    tile.putalpha(m)
    return tile


def place(layer, shadow, tile, x, y, r):
    cw, ch = tile.size
    ImageDraw.Draw(shadow).rounded_rectangle((x, y + 14 * SS, x + cw, y + ch + 14 * SS), r, fill=80)
    layer.alpha_composite(tile, (x, y))


def compose(layer, shadow, cw, angle=0):
    shadow = shadow.filter(ImageFilter.GaussianBlur(20 * SS))
    sh = Image.new('RGBA', layer.size, (190, 70, 90, 0))
    sh.putalpha(shadow)
    out = Image.new('RGBA', layer.size, (0, 0, 0, 0))
    out.alpha_composite(sh)
    out.alpha_composite(layer)
    if angle:
        out = out.rotate(angle, Image.BICUBIC, expand=False)
    out = out.resize((out.width // SS, out.height // SS), Image.LANCZOS)
    bg = gradient(W, H).convert('RGBA')
    bg.alpha_composite(out, ((W - out.width) // 2, (H - out.height) // 2))
    return bg.convert('RGB')


if MODE == 'tilt':
    CW = 330 * SS
    CH = round(CW * 812 / 375)
    GAP, R = 32 * SS, 22 * SS
    S = 2600 * SS                                  # 画布够大,转 16° 后仍盖满 1920×1080
    layer, shadow = Image.new('RGBA', (S, S)), Image.new('L', (S, S), 0)
    cols = S // (CW + GAP) + 1
    x0 = (S - cols * (CW + GAP) + GAP) // 2
    for c in range(cols):
        y = -((c % 2) * (CH // 2)) - CH // 4       # 单双列错开半张
        r = 0
        while y < S:
            name = PAGES[(c * 2 + r) % len(PAGES)]   # 相邻两列错开顺序,同一页不并排
            place(layer, shadow, card(name, CW, CH, R), x0 + c * (CW + GAP), y, R)
            y += CH + GAP
            r += 1
    compose(layer, shadow, CW, angle=16).save(OUT)
else:   # stagger
    CW = 296 * SS
    CH = round(CW * 812 / 375)
    GAP, R = 22 * SS, 22 * SS
    n = len(PAGES)
    layer, shadow = Image.new('RGBA', (W * SS, H * SS)), Image.new('L', (W * SS, H * SS), 0)
    x0 = (W * SS - (CW * n + GAP * (n - 1))) // 2
    for k, name in enumerate(PAGES):
        y = (H * SS - CH) // 2 + (-1 if k % 2 == 0 else 1) * 130 * SS   # 单列偏上、双列偏下,上下都越出边
        place(layer, shadow, card(name, CW, CH, R), x0 + k * (CW + GAP), y, R)
    compose(layer, shadow, CW).save(OUT)
print(OUT, MODE)
