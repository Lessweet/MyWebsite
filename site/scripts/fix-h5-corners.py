# 用法:/usr/bin/python3 site/scripts/fix-h5-corners.py <MyWebsite>/site/assets/figma/ai-visual-h5-2110-12252.png <同目录>/ai-visual-h5-2110-12252-fixed.png
# 公益 H5 画板 2110:12252 角标改字(2026-11-21 用户):左上去掉序号「2）」,右上改成「体现温暖、友爱」
# Figma MCP 加载不了汉仪旗黑,所以在导出图上改:左上把原字整体左移,右上用本机 HYQiHei-70J 28 号重写
import sys
from PIL import Image, ImageDraw, ImageFont
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB')
def clean(x0, y0, x1, y1, dx):   # 擦字:从同一行、横向错开 dx 的空白处搬一块底盖上(底是竖向渐变,同行颜色一致,颗粒也对得上)
    im.paste(im.crop((x0 + dx, y0, x1 + dx, y1)), (x0, y0))
# 左上:「H5 辅助元素生成」在 x 121–393,左移到序号原来的起点 62。只搬字的像素(暗于底色的部分),底色保持原渐变
text = im.crop((118, 62, 396, 112))
clean(56, 62, 400, 112, 420)
mask = text.convert('L').point(lambda v: max(0, min(255, (225 - v) * 255 // 150)))
im.paste(text, (118 - 59, 62), mask)
# 右上:擦掉「插画装饰 友好感」,右对齐原来的右边 1859 重写
clean(1640, 62, 1870, 100, -260)
f = ImageFont.truetype('/Users/chentongrong/Library/Fonts/HYQiHei-70J.ttf', 28)
ImageDraw.Draw(im).text((1859, 65), '体现温暖、友爱', font=f, fill=(17, 17, 17), anchor='ra')
im.save(out)
