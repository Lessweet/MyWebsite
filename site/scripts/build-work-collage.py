# 首页代表作「公众号 AI 设计内容」的封面拼图:用户原创的公众号文章封面排三行、逐行错开。
# 预先拼成一张透明底 webp(缝隙透出卡片底色,深浅主题通用),只占一次请求。
# 用法:python3 site/scripts/build-work-collage.py   → docs/writing/assets/works/gzh-collage.webp
# 素材:site/assets/work-collage/(公众号写作目录 ~/Documents/projects/aiadong_mp 里的封面原图,
#       按用户截图逐张做图像比对找到;2.35:1,不发布)
#       + docs 里已有的两张文章封面首帧(SKILLS / DESIGN SIGNAL)。
# 排法(2026-10-23 用户定):中间一行放「AI 设计工作流 / Shader & Motion / SKILLS / DESIGN SIGNAL」,
#       其余上下两行。
# 比例(2026-10-23 用户改):小卡统一 16:9。2.35:1 的公众号封面等比铺满后居中裁掉两侧各约 12%,
#       主体或标签被切的单张用 CROP_X 调裁切位置;16:9 的首帧原样缩放。
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'site/assets/work-collage'
POSTERS = ROOT / 'docs/writing/assets/posters'
OUT = ROOT / 'docs/writing/assets/works/gzh-collage.webp'

CW, CH = 1120, 630      # 卡片 560×315 的 2 倍(16:9)
GAP = 16                # 缝 8px @1x
RADIUS = 8              # 小卡圆角 4px @1x
RATIO = 16 / 9          # 小卡比例
ROWS_DEF = [   # (封面, 行起点 x;None = 整行居中)
    (['01-thinking-fast-slow', '02-jobs-data', '03-anthropic-design-workflow', '04-type-system'], -118),
    (['08-ai-design-workflow-2026', '09-shader-motion', 'poster:figma-skills', 'poster:genui-no-style-to-write'], -18),
    (['05-figma-config', '06-claude-code-desktop', '07-intelligent-ui'], 82),
]
# 水平裁切位置:-1 = 贴左,0 = 居中(默认),1 = 贴右
CROP_X = {
    '04-type-system': 0.3,      # 在上排最右、被卡片右缘切掉一点,往左挪免得「Variables」被切
    '07-intelligent-ui': 0.6,   # 右侧「Intelligent UI」标签居中裁会被切掉一截
}
# 行高 170(小卡 302×170):4 张一行宽 1256,比卡片宽 136;上排向左、中排向右出血,
#       两端封面都露出约六成;下排 3 张再右移一步,三行按 100px 阶梯错开;三行整体垂直居中
th = 170
tw = round(th * RATIO)
TOP = (CH - (th * 3 + GAP * 2)) // 2

def load(name, tw=tw, th=th):
    """读一张封面,等比铺满 tw×th,多出的部分按 CROP_X 水平裁掉(默认居中)、垂直居中。
    build-work-thumbs.py 也 import 这个函数出单张缩略图。"""
    if name.startswith('poster:'):
        im = Image.open(POSTERS / f'{name[7:]}.webp').convert('RGB')
    else:
        im = Image.open(SRC / f'{name}.webp').convert('RGB')
    w, h = im.size
    s = max(tw / w, th / h)
    im = im.resize((round(w * s), round(h * s)), Image.LANCZOS)
    x = round((im.width - tw) / 2 * (1 + CROP_X.get(name, 0)))
    y = (im.height - th) // 2
    return im.crop((x, y, x + tw, y + th))


def main():
    mask = Image.new('L', (tw, th), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, tw - 1, th - 1), RADIUS, fill=255)

    canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    for r, (names, shift) in enumerate(ROWS_DEF):
        y = TOP + r * (th + GAP)
        row_w = len(names) * tw + (len(names) - 1) * GAP
        x = (CW - row_w) // 2 if shift is None else shift   # None = 整行居中
        for name in names:
            canvas.paste(load(name), (x, y), mask)
            x += tw + GAP

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT, 'WEBP', quality=82, method=6)
    print(f'{OUT.relative_to(ROOT)}  {CW}x{CH}  thumb {tw}x{th}  {OUT.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main()
