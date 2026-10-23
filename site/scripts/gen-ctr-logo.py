# CTR 字标生成器:C 气泡团(LENSLAB 同风格)+ T / R 用户 Figma 手绘字形。
# 用法:python3 site/scripts/gen-ctr-logo.py file > docs/logo-ctr-v4.svg
#       python3 site/scripts/gen-ctr-logo.py inline   → 输出 currentColor 版,贴进 site/index.html 顶栏
# 改形状只动下面三段参数;random.seed 固定,气泡布局每次一致。
import math, random, re, sys
random.seed(7)
out=[]
# ---- C:气泡团(同 LENSLAB 的 S)----
cx, cy, R = 145, 145, 108
def bubbles(R, r0, jitter, a0, a1, n, rad_j):
    res=[]
    for i in range(n):
        a=math.radians(a0+(a1-a0)*i/(n-1))
        rr=R+random.uniform(-rad_j,rad_j)
        r=r0+random.uniform(-jitter,jitter)
        res.append((cx+rr*math.cos(a), cy-rr*math.sin(a), r))
    return res
cs = bubbles(R, 37, 5, 42, 318, 11, 5) + bubbles(R-24, 30, 4, 60, 300, 8, 4)
c_paths=[f'M{x-r:.1f} {y:.1f}a{r:.1f} {r:.1f} 0 1 0 {2*r:.1f} 0a{r:.1f} {r:.1f} 0 1 0 {-2*r:.1f} 0Z' for x,y,r in cs]
# C 的轮廓线:圆的并集边界 = 每个圆上没被其他圆盖住的弧段。只描这些弧,
# 线宽 / 虚线就与 T、R 的普通描边完全一致(不再用「2 倍描边 + 底色盖一半」)
FREE=[]
def exposed_arcs(cs):
    out=[]
    for i,(xi,yi,ri) in enumerate(cs):
        cov=[]; inside=False
        for j,(xj,yj,rj) in enumerate(cs):
            if i==j: continue
            d=math.hypot(xj-xi,yj-yi)
            if d+ri<=rj: inside=True; break
            if d>=ri+rj or d+rj<=ri: continue
            th=math.atan2(yj-yi,xj-xi); al=math.acos(max(-1,min(1,(ri*ri+d*d-rj*rj)/(2*ri*d))))
            cov.append((th-al,th+al))
        if inside: continue
        # 归一到 [0, 2π) 并拆开跨零的区间,再合并
        segs=[]
        for a0,b0 in cov:
            w=b0-a0; a=a0%(2*math.pi); b=a+w
            if b>2*math.pi: segs+= [(a,2*math.pi),(0,b-2*math.pi)]
            else: segs.append((a,b))
        segs.sort(); merged=[]
        for a,b in segs:
            if merged and a<=merged[-1][1]: merged[-1]=(merged[-1][0],max(merged[-1][1],b))
            else: merged.append((a,b))
        free=[]; cur=0
        for a,b in merged:
            if a>cur: free.append((cur,a))
            cur=max(cur,b)
        if cur<2*math.pi: free.append((cur,2*math.pi))
        # 跨 0 的空隙首尾相接
        if len(free)>1 and free[0][0]==0 and free[-1][1]==2*math.pi:
            free=[(free[-1][0],free[0][1]+2*math.pi)]+free[1:-1]
        if not merged: free=[(0,2*math.pi)]
        for a,b in free:
            FREE.append((xi,yi,ri,a,b))
            if b-a<1e-3: continue
            if b-a>=2*math.pi-1e-6:
                out.append(f'M{xi-ri:.1f} {yi:.1f}a{ri:.1f} {ri:.1f} 0 1 0 {2*ri:.1f} 0a{ri:.1f} {ri:.1f} 0 1 0 {-2*ri:.1f} 0'); continue
            x0,y0=xi+ri*math.cos(a),yi+ri*math.sin(a); x1,y1=xi+ri*math.cos(b),yi+ri*math.sin(b)
            out.append(f'M{x0:.1f} {y0:.1f}A{ri:.1f} {ri:.1f} 0 {1 if b-a>math.pi else 0} 1 {x1:.1f} {y1:.1f}')
    return out
c_arcs=exposed_arcs(cs)
minx=min(x-r for x,y,r in cs); maxx=max(x+r for x,y,r in cs)
miny=min(y-r for x,y,r in cs); maxy=max(y+r for x,y,r in cs)
c_off=-minx
c_w=maxx-minx
# ---- T:用户在 Figma 手绘(公众号-字体-生图 node 7-39,导出 T.svg,133×159)----
SC=290/159   # T 与 R 同一比例放大(Figma 里两字同尺寸绘制),T 顶满字高
T_D='M109.287 0.0961101C117.671 -0.0763899 135.373 -1.31386 131.886 13.6261C131.042 17.2411 127.803 20.5261 125.308 23.2486C127.913 29.7361 135.229 38.3086 131.157 45.7636C123.894 59.0611 100.662 52.2436 91.6403 55.1911C87.002 62.8711 97.6463 70.6262 98.9471 80.1212C100.615 92.2862 91.8114 99.7411 93.41 109.716C94.7288 117.936 102.826 124.904 103.134 134.826C103.408 143.661 99.9546 150.479 94.2525 156.981C82.0515 159.216 62.8963 157.611 50.1417 157.281C44.4426 157.131 40.0728 155.534 36.4134 151.079C27.9513 130.101 40.5746 121.806 42.7644 103.356C43.4523 97.5586 36.123 87.3661 37.9925 79.0636C39.898 70.5961 45.6804 66.5536 43.7997 58.0036C36.5454 50.2336 -11.9037 66.4936 4.32879 26.7886C-7.64264 3.61358 6.98217 0.703643 26.6355 0.973643C54.2407 1.35614 81.6974 0.77861 109.287 0.0961101Z'
t_w=133*SC
# ---- R:用户在 Figma 手绘(node 12-28,导出 Exclude.svg,122×153),底边与 T 对齐 ----
R_D='M46.5408 0.197021C65.1453 -1.09447 77.1486 4.08228 93.075 12.2175C96.4582 19.3026 100.187 41.8118 101.8 50.3445C93.7577 61.6424 84.4253 76.1021 74.9431 85.7478C78.9115 91.2347 83.2694 97.7942 87.5378 102.955C98.3254 116.004 110.629 128.691 121.994 141.269L84.5154 152.78C81.5522 149.521 77.0733 142.913 73.78 138.935C64.7104 128.905 60.9962 119.167 53.2244 108.033C47.0206 107.427 41.882 107.147 35.6482 106.954C35.0856 121.139 36.5483 132.06 37.366 146.126C27.1261 147.119 10.4572 148.713 0.562256 148.275C-1.0131 136.445 0.809308 9.27389 4.9353 2.22241C10.6142 -0.485088 37.2385 0.881021 46.5408 0.197021ZM61.3572 32.281C42.6851 35.926 41.5893 34.8307 37.4783 54.0525C36.4806 58.742 35.6407 61.794 36.4958 66.6628L37.531 68.0027C37.9135 67.9584 39.3382 67.831 39.6462 67.7185C43.8697 65.3523 53.7044 60.1275 57.1628 57.489C59.1283 52.1296 65.1751 38.57 64.3054 34.1033C62.6401 32.3881 63.5999 32.9536 61.3572 32.281Z'
r_w=122*SC
gap=48   # 字母间距 ≥ 挤出量 DX(26)+ hover 左移量(10)+ 余量;60 太松、36 hover 时贴住邻字(2026-10-23 用户)
tx=c_w+gap; rx=tx+t_w+gap
parts=[]; lines=[]
c_tf=f'translate({c_off:.1f} {-miny+ (290-(maxy-miny))/2:.1f})'
parts.append(f'<path transform="{c_tf}" d="'+''.join(c_paths)+'"/>')
lines.append(f'<path transform="{c_tf}" d="'+''.join(c_arcs)+'"/>')
# T / R 的缩放 + 位移直接换算进坐标(不用 transform):三个字母处在同一个用户坐标系,
# 描边粗细、斜线图案(userSpaceOnUse)才完全一致 —— 2026-10-23 用户:按 C 的实线 / 斜线来
def bake(d, sx, ox, oy):
    toks=re.findall(r'[MLCZ]|-?\d*\.?\d+(?:e-?\d+)?', d)
    out=[]; nums=[]
    def flush():
        for k in range(0,len(nums),2):
            out.append(f'{nums[k]*sx+ox:.2f} {nums[k+1]*sx+oy:.2f}')
        nums.clear()
    for t in toks:
        if t in 'MLCZ': flush(); out.append(t)
        else: nums.append(float(t))
    flush()
    return ' '.join(out)
T_B=bake(T_D, SC, tx, 0); R_B=bake(R_D, SC, rx, (159-153)*SC)
parts.append('<path d="'+T_B+'"/>')
parts.append('<path d="'+R_B+'"/>')
lines += parts[1:]
W=rx+r_w
# json 模式:导出几何(C 的圆 / T、R 的已烘焙路径,均为最终坐标),交给 gen-ctr-logo-3d.mjs
# 做挤出体积 / 布尔运算并出 SVG(2026-10-23 起字标由它生成)
if len(sys.argv)>1 and sys.argv[1]=='json':
    import json
    ox=c_off; oy=-miny+(290-(maxy-miny))/2
    print(json.dumps({'W':W,'circles':[[x+ox,y+oy,r] for x,y,r in cs],'T':T_B,'R':R_B}))
    sys.exit(0)

# 线框 + 挤出体积(2026-10-23,视觉语言参考:实线 = 正面轮廓;虚线 = 背面露出的轮廓 +
# 连接正背面的结构棱(在轮廓切线平行于挤出方向的切点、以及转角处);侧壁 = 正背面之间的整块挤出体积,铺斜线)
#   每个字母一组 <g class="logo-letter">,hover 时整组一起往左上移、线条加深(simple.css)。
#   三个字母坐标都在同一用户坐标系(T / R 已烘焙缩放),描边与斜线图案因此完全一致。
DX, DY = 26, 22
VBW, VBH = W + DX + 8, 292 + DY + 8
DL=math.hypot(DX,DY); UX,UY=DX/DL,DY/DL

def cubic(p0,p1,p2,p3,t):
    mt=1-t
    return (mt**3*p0[0]+3*mt*mt*t*p1[0]+3*mt*t*t*p2[0]+t**3*p3[0],
            mt**3*p0[1]+3*mt*mt*t*p1[1]+3*mt*t*t*p2[1]+t**3*p3[1])
def sample_path(d, n=48):
    """把 M/L/C/Z 绝对路径按子路径采样成闭合折线"""
    toks=re.findall(r'[MLCZ]|-?\d*\.?\d+', d); i=0; polys=[]; cur=None; pts=[]
    def num():
        nonlocal i; v=float(toks[i]); i+=1; return v
    while i<len(toks):
        c=toks[i]; i+=1
        if c=='M':
            if pts: polys.append(pts)
            cur=(num(),num()); pts=[cur]
        elif c=='L':
            cur=(num(),num()); pts.append(cur)
        elif c=='C':
            p1=(num(),num()); p2=(num(),num()); p3=(num(),num())
            pts += [cubic(cur,p1,p2,p3,k/n) for k in range(1,n+1)]; cur=p3
        elif c=='Z':
            pass
    if pts: polys.append(pts)
    return polys
def silhouette_pts(polys):
    """轮廓上切线与挤出方向平行的点(含转角):相邻弦与方向叉积变号处"""
    out=[]
    for pts in polys:
        n=len(pts); crs=[]
        for k in range(n):
            a=pts[k]; b=pts[(k+1)%n]
            crs.append((b[0]-a[0])*UY-(b[1]-a[1])*UX)
        for k in range(n):
            if crs[k-1]*crs[k]<0 or (crs[k]==0):
                p=pts[k]
                if all(math.hypot(p[0]-q[0],p[1]-q[1])>4 for q in out): out.append(p)
    return out
def circle_silhouette():
    """C:每个圆上法线垂直于挤出方向的两个切点,落在外露弧段上的才算"""
    ox=c_off; oy=-miny+(290-(maxy-miny))/2; out=[]
    for (x,y,r,a,b) in FREE:
        for sgn in (1,-1):
            nx,ny=-UY*sgn,UX*sgn; t=math.atan2(ny,nx)%(2*math.pi)
            if a<=t<=b or a<=t+2*math.pi<=b:
                out.append((x+r*nx+ox, y+r*ny+oy))
    return out
conns=[circle_silhouette(), silhouette_pts(sample_path(T_B)), silhouette_pts(sample_path(R_B))]

print(f'W={W:.1f} arcs={len(c_arcs)} conns={[len(c) for c in conns]}', file=sys.stderr)
mode=sys.argv[1] if len(sys.argv)>1 else 'file'
pat=lambda pid, cls: (f'<pattern id="{pid}" patternUnits="userSpaceOnUse" width="14" height="14" patternTransform="rotate(45)">'
                      f'<line class="{cls}" x1="0" y1="0" x2="0" y2="14"/></pattern>')
STEPS=16
defs='<defs>'+''.join(f'<g id="ctr-f{i}">{f}</g><g id="ctr-l{i}">{l}</g>' for i,(f,l) in enumerate(zip(parts,lines)))
for i in range(len(parts)):
    sweep=''.join(f'<use href="#ctr-f{i}" transform="translate({DX*k/STEPS:.2f} {DY*k/STEPS:.2f})"/>' for k in range(STEPS+1))
    defs+=f'<mask id="ctr-sweep{i}" maskUnits="userSpaceOnUse" x="-20" y="-20" width="{VBW+40:.0f}" height="{VBH+40}"><g fill="#fff">{sweep}</g></mask>'
defs+=pat('ctr-hatch','logo-hatch')+pat('ctr-hatch-dark','logo-hatch-dark')+'</defs>'
letters=''
for i in range(len(parts)):
    cl=''.join(f'M{x:.1f} {y:.1f}l{DX} {DY}' for x,y in conns[i])
    letters+=(f'<g class="logo-letter">'
              f'<rect class="logo-hatch-fill" x="-20" y="-20" width="{VBW+40:.0f}" height="{VBH+40}" mask="url(#ctr-sweep{i})"/>'
              f'<use class="logo-back-line" href="#ctr-l{i}" transform="translate({DX} {DY})"/>'
              f'<path class="logo-back-line" d="{cl}"/>'
              f'<use class="logo-fill" href="#ctr-f{i}"/><use class="logo-front-line" href="#ctr-l{i}"/>'
              f'</g>')
body=f'<g transform="translate(4 4)">{letters}</g>'
if mode=='file':
    style=('<style>.logo-fill{fill:#FDFDFC}.logo-hatch-fill{fill:url(#ctr-hatch)}.logo-hatch{stroke:#aeaeb2;stroke-width:3}.logo-hatch-dark{stroke:#636366;stroke-width:3}'
           '.logo-back-line{fill:none;stroke:#8e8e93;stroke-width:1.25;stroke-dasharray:4 3}'
           '.logo-front-line{fill:none;stroke:#141414;stroke-width:1.5}</style>')
    print(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VBW:.1f} {VBH}" role="img" aria-label="CTR">{style}{defs}{body}</svg>')
else:
    print(f'<svg class="site-logo" viewBox="0 0 {VBW:.1f} {VBH}" role="img" aria-label="CTR">{defs}{body}</svg>')
