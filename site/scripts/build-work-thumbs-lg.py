# 「公众号 AI 设计内容」右侧封面集合用的大号 16:9 封面(2026-10-31 用户:集合图放大 1.5 倍后好模糊 ——
# 原来的 thumbs/ 只有 384×216,放大后被拉伸)。按和 thumbs/ 一样的裁切规则,改出 768×432。
# 素材:
#   - 普通封面 / poster:同 build-work-thumbs.py(build-work-collage.py 的 load();poster 优先用 @3x 原图)
#     site/assets/ 只在主仓库本地(不进 git),worktree 里没有就用 --assets 指过去
#   - cover-types:同 build-work-cover-types.py,从 aiadong_mp 仓库的文章封面原图出
#   - vibedesign:Figma 作品集 478:4359 导出的 768×432(没有本地原图,第一次手动放进 thumbs-lg/)
# 用法:python3 site/scripts/build-work-thumbs-lg.py [--assets ~/Documents/projects/MyWebsite/site/assets] [--mp ~/Documents/projects/aiadong_mp]
import argparse
import importlib.util
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = ROOT / 'docs/writing/assets/works/thumbs-lg'
TW, TH = 768, 432


def mod(name, file):
    spec = importlib.util.spec_from_file_location(name, HERE / file)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--assets', default=str(ROOT / 'site/assets'))
    ap.add_argument('--mp', default=str(ROOT.parent / 'aiadong_mp'))
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)

    collage = mod('build_work_collage', 'build-work-collage.py')
    collage.SRC = Path(a.assets) / 'work-collage'
    thumbs = mod('build_work_thumbs', 'build-work-thumbs.py')
    for src, out in thumbs.THUMBS:
        if src.startswith('poster:'):
            p3 = collage.POSTERS / f'{src[7:]}@3x.webp'
            if p3.exists():
                im = Image.open(p3).convert('RGB')
                s = max(TW / im.width, TH / im.height)
                im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
                x, y = (im.width - TW) // 2, (im.height - TH) // 2
                im = im.crop((x, y, x + TW, y + TH))
            else:
                im = collage.load(src, TW, TH)
        else:
            im = collage.load(src, TW, TH)
        im.save(OUT / f'{out}.webp', 'WEBP', quality=86, method=6)
        print(f'thumbs-lg/{out}.webp')

    ct = mod('build_work_cover_types', 'build-work-cover-types.py')
    for name, _t, _k, art, cover, shift in ct.ITEMS:
        p = Path(a.mp) / art / cover
        if not p.exists():
            print(f'skip {name}(找不到 {p})')
            continue
        im = ct.crop_16_9(Image.open(p).convert('RGB'), shift).resize((TW, TH), Image.LANCZOS)
        im.save(OUT / f'{name}.webp', 'WEBP', quality=86, method=6)
        print(f'thumbs-lg/{name}.webp')


if __name__ == '__main__':
    main()
