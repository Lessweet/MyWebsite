# 首页第二个作品「AI 辅助生成视觉设计」的四图式拼图(2026-10-23 用户)。
# 原图是从 Figma「作品集」文件导出的画板,存在 site/assets/figma/<名字>-<node>.png,条目里写不带 .png 的文件名。
# 用法:python3 site/scripts/build-work-gallery.py
# 产出:docs/writing/assets/works/gallery/ai-visual-<n>.webp(1920×1080)
import math
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'site/assets/figma'
OUT = ROOT / 'docs/writing/assets/works/gallery'
W, H = 1920, 1080
GAP = 24          # 四周与图之间同一个间距
RADIUS = 16
BG = '#EAF0FC'   # 与四图式格子的淡蓝底一致(2026-10-23 用户:容器背景统一淡蓝)

# 每组:产出文件名 → 按顺序排的画板。1 张 = 铺满整格;4 张 = 两行两列(左上、右上、左下、右下);2 张 = 左右并排、上下居中
GRIDS = {
    # 图 2、图 4 改成「一个背景 + 抠出来的手机 / 素材」重新合成,见 build-work-mockups.py
    # 原为四个拼 2×2(2283-12629 / 2337-18711 / 2336-17407 / 2337-19087),2026-10-23 用户改成只放 2337-18711 一张
    'ai-visual-3.webp': ['ai-visual-2337-18711'],
    # 图 2:2026-10-23 用户改成整张放 Figma 画板 2506:13621(两台手机:新时代 / 不仅是守望)
    'ai-visual-2.webp': ['ai-visual-2506-13621'],
    # 图 4:2026-10-23 用户改成整张放 Figma 画板 2336:17407(金刚位 / 卡片区 / Banner 区等组件)
    'ai-visual-4.webp': ['ai-visual-2336-17407'],
    # 第三个作品「AI 语音聊天产品设计」(2024):封面画板 2304:14351 + 界面合集画板 2304:14348,各自整张
    'hello-chat-1.webp': ['w2024-2304-14351'],
    'hello-chat-2.webp': ['w2024-2304-14348'],
    # 另有暂不展示的作品条目,完整版见本地 site/private/scripts/build-work-gallery.full.py(2026-10-24)
}
# 不留四周内边距、图稍微出血越过格子边(2026-10-23 用户:不要留四边内边距,可以破一点点)。
# 只适合竖版画板:按高度铺满再上下各多出 BLEED,左右自然越出格子;中间仍隔 GAP
BLEED_SET = {'ai-visual-4.webp'}
BLEED = 24


# 画板 2336:17407 六个格子的白底改成左上角画板的黑底 #111111(2026-10-23 用户;之前试过浅灰)。
# 做法:从每格顶边的白点开始填色,得到「底」的区域(手机有深色外框挡着,界面里的白卡片不受影响);
# 区域外扩 2px 的边缘按「原来是白底」反推:去掉每个像素里白底的那一份、换成黑底,
# 文字和手机边缘就不会留白毛边。公式:新色 = 原色 − min(R,G,B) + 底色 × min(R,G,B) / 255
RECOLOR = {'ai-visual-2336-17407': (17, 17, 17)}


# 界面合集画板 2304:14348 里有一块只有一条天气对话、下面大片空白的屏:换成 Figma 2304:14319 的
# 「说 Hello Chat 以唤醒对话」欢迎屏(2026-10-23 用户:只放界面,不带旁边的箭头和标注)。
# 那块屏嵌在整体旋转的组件里没法单独替换导出,就在图上贴:用「Hello Chat !」标题和语音键两处蓝色的
# 重心做锚点(两张图里各量一次),算出缩放 + 旋转(约 0.62 倍、16°),圆角 160(3x)抠掉白角后贴上
PATCH = {
    'w2024-2304-14348': dict(
        screen=SRC / 'screens/hello-empty-2304-14319.png', radius=160,
        src_pts=((300.655, 218.467), (603.104, 2318.558)),   # 新屏(3x)里的标题、语音键
        dst_pts=((805.757, 544.922), (620.673, 1850.267)),   # 画板(2x)里旧屏的标题、语音键
    ),
}


def patch_screen(board, cfg):
    new = Image.open(cfg['screen']).convert('RGBA')
    w, h = new.size
    m = Image.new('L', (w * 4, h * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w * 4 - 1, h * 4 - 1), cfg['radius'] * 4, fill=255)
    new.putalpha(m.resize((w, h), Image.LANCZOS))
    (n0, n1), (b0, b1) = cfg['src_pts'], cfg['dst_pts']
    vn, vb = (n1[0] - n0[0], n1[1] - n0[1]), (b1[0] - b0[0], b1[1] - b0[1])
    sc = math.hypot(*vb) / math.hypot(*vn)
    th = math.atan2(vb[1], vb[0]) - math.atan2(vn[1], vn[0])
    c, sn = math.cos(th), math.sin(th)
    tx = b0[0] - sc * (c * n0[0] - sn * n0[1])
    ty = b0[1] - sc * (sn * n0[0] + c * n0[1])
    a, b, d, e = c / sc, sn / sc, -sn / sc, c / sc   # 反向映射:画板坐标 → 新屏坐标
    warped = new.transform(board.size, Image.AFFINE, (a, b, -(a * tx + b * ty), d, e, -(d * tx + e * ty)),
                           resample=Image.BICUBIC)
    return Image.alpha_composite(board.convert('RGBA'), warped).convert('RGB')


# 画板里的手机墙整体斜着放(组件「满屏页面」转了约 18.45°,按手机缝隙横竖投影最锐利量出来),单个手机没法单独导出:
# 把整张图反向转正,再从中间裁出能放下的最大 16:9(2026-10-23 用户:改成竖向、不要倾斜)
UPRIGHT = {}


def upright(im, ang):
    w, h = im.size
    r = im.rotate(ang, resample=Image.BICUBIC, center=(w / 2, h / 2))
    t = math.radians(ang)
    k = min(w / (w * math.cos(t) + h * math.sin(t)), h / (w * math.sin(t) + h * math.cos(t)))
    cw, ch = int(w * k), int(h * k)
    return r.crop(((w - cw) // 2, (h - ch) // 2, (w + cw) // 2, (h + ch) // 2))


def load(n):
    im = Image.open(SRC / f'{n}.png').convert('RGB')
    if n in UPRIGHT:
        im = upright(im, UPRIGHT[n])
    if n in PATCH:
        im = patch_screen(im, PATCH[n])
    if n not in RECOLOR:
        return im
    marker = im.copy()
    for y in (3, 566):   # 上排格子顶边、下排格子顶边(分隔线在 y≈560)
        for x in range(3, im.width, 40):
            if marker.getpixel((x, y)) == (255, 255, 255):
                ImageDraw.floodfill(marker, (x, y), (255, 0, 255), thresh=6)
    r, g, b = marker.split()
    mask = ImageChops.multiply(ImageChops.multiply(r.point(lambda v: 255 if v == 255 else 0),
                                                   g.point(lambda v: 255 if v == 0 else 0)),
                               b.point(lambda v: 255 if v == 255 else 0))
    chans = im.split()
    lo = ImageChops.darker(ImageChops.darker(chans[0], chans[1]), chans[2])
    hi = ImageChops.lighter(ImageChops.lighter(chans[0], chans[1]), chans[2])
    # 格子标题那两条横带里没有手机:接近白的像素(含字里封闭的小白空)一律算底
    title = Image.new('L', im.size, 0)
    for y0, y1 in ((40, 135), (585, 680)):
        title.paste(lo.crop((0, y0, im.width, y1)).point(lambda v: 255 if v >= 200 else 0), (0, y0))
    mask = ImageChops.lighter(mask, title).filter(ImageFilter.MaxFilter(5))   # 外扩 2px,把抗锯齿边缘也包进来
    # 只处理「接近白」或「中性灰」的边缘像素;有颜色的字、界面本身不动(否则标题会被压暗出缺口)
    near_white = lo.point(lambda v: 0 if v < 140 else 255 if v > 240 else (v - 140) * 255 // 100)
    neutral = ImageChops.subtract(hi, lo).point(lambda v: 255 if v < 24 else 0)
    weight = ImageChops.multiply(mask, ImageChops.lighter(near_white, neutral))
    bg = RECOLOR[n]
    out = Image.merge('RGB', [ImageChops.add(ImageChops.subtract(c, lo), lo.point(lambda v, k=k: v * k // 255))
                              for c, k in zip(chans, bg)])
    return Image.composite(out, im, weight)


def rounded(im, r):
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), r, fill=255)
    out = Image.new('RGBA', im.size)
    out.paste(im, (0, 0), mask)
    return out


def build(nodes, bleed=False):
    if len(nodes) == 1:
        return ImageOps.fit(load(nodes[0]), (W, H), Image.LANCZOS)
    sheet = Image.new('RGB', (W, H), BG)
    cw = (W - GAP * 3) // 2
    if len(nodes) == 4:
        ch = (H - GAP * 3) // 2
        spots = [(GAP + (k % 2) * (cw + GAP), GAP + (k // 2) * (ch + GAP)) for k in range(4)]
    else:   # 2 张:按画板自己的比例(16:9 或竖版都行)左右并排,整排水平、垂直居中,不裁切
        im0 = Image.open(SRC / f'{nodes[0]}.png')
        ratio = im0.height / im0.width
        ch = int(cw * ratio)
        if bleed:   # 出血:高度 = 格子高 + 上下各 BLEED,宽度按比例,左右越出格子的部分被裁掉
            ch = H + BLEED * 2
            cw = int(ch / ratio)
        elif ch > H - GAP * 2:   # 太高放不下时按高度收
            ch = H - GAP * 2
            cw = int(ch / ratio)
        x0 = (W - (cw * 2 + GAP)) // 2
        if bleed:   # 左边的图贴齐格子左边、不越出(用户:左边手机别贴边被切),多出的宽度全部从右边越出
            x0 = 0
        spots = [(x0 + k * (cw + GAP), (H - ch) // 2) for k in range(2)]
    for n, (x, y) in zip(nodes, spots):
        im = load(n)
        tile = rounded(ImageOps.fit(im, (cw, ch), Image.LANCZOS), RADIUS)   # 等比铺满,比例差的部分上下各裁一点
        # 淡阴影:画板底色和外面的浅灰太接近时,靠它托出卡片边界
        sh = Image.new('L', (W, H), 0)
        ImageDraw.Draw(sh).rounded_rectangle((x, y + 6, x + cw, y + ch + 6), RADIUS, fill=40)
        sh = sh.filter(ImageFilter.GaussianBlur(14))
        sheet.paste(Image.new('RGB', (W, H), '#3A4060'), (0, 0), sh)
        sheet.paste(tile, (x, y), tile)
    return sheet


OUT.mkdir(parents=True, exist_ok=True)
for name, nodes in GRIDS.items():
    build(nodes, name in BLEED_SET).save(OUT / name, 'WEBP', quality=86, method=6)
    print(name, (OUT / name).stat().st_size, 'B')
