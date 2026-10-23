# 首页代表作「公众号 AI 设计内容」横向循环滚动用的单张 16:9 小封面。
# 用法:python3 site/scripts/build-work-thumbs.py   → docs/writing/assets/works/thumbs/*.webp
# 素材、CROP_X 与裁切规则(等比铺满 → 按 CROP_X 水平裁切、垂直居中)全部复用
# build-work-collage.py 的 load(),只换输出尺寸;纯矩形、不透明、无圆角。
import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location('build_work_collage', HERE / 'build-work-collage.py')
collage = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(collage)   # 该脚本主体在 main() 里,import 不会重写拼图

ROOT = collage.ROOT
OUT_DIR = ROOT / 'docs/writing/assets/works/thumbs'
TW, TH = 384, 216        # 192×108 的 2 倍(16:9)
QUALITY = 85

# (load() 用的素材名, 输出文件名)
THUMBS = [
    ('01-thinking-fast-slow', '01-thinking-fast-slow'),
    ('02-jobs-data', '02-jobs-data'),
    ('03-anthropic-design-workflow', '03-anthropic-design-workflow'),
    ('04-type-system', '04-type-system'),
    ('05-figma-config', '05-figma-config'),
    ('06-claude-code-desktop', '06-claude-code-desktop'),
    ('07-intelligent-ui', '07-intelligent-ui'),
    ('08-ai-design-workflow-2026', '08-ai-design-workflow-2026'),
    ('09-shader-motion', '09-shader-motion'),
    ('poster:figma-skills', 'skills'),
    ('poster:genui-no-style-to-write', 'design-signal'),
]


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    total = 0
    for src, out in THUMBS:
        path = OUT_DIR / f'{out}.webp'
        collage.load(src, TW, TH).save(path, 'WEBP', quality=QUALITY, method=6)
        size = path.stat().st_size
        total += size
        print(f'{path.relative_to(ROOT)}  {TW}x{TH}  {size / 1024:.1f} KB')
    print(f'{len(THUMBS)} files, total {total / 1024:.1f} KB')


if __name__ == '__main__':
    main()
