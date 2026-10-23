/* 公众号封面卡片的流动渐变底(2026-10-23 用户:背景也要用封面那套 shader 的效果)。
   shader 原样搬自公众号封面系统(~/Documents/projects/aiadong_mp 各篇 cover.html 的 makeMesh:
   Lissajous 漂浮色点 + domain warp + swirl + Shepard 反距离混色 + 胶片颗粒,源自
   paper-design/shaders mesh-gradient),外加同款 SVG 噪点叠层。
   只在卡片进入视口时逐帧绘制;减少动态效果时只画一帧;不支持 WebGL2 时露出 CSS 渐变底。 */
import { useEffect, useRef } from 'react';

/* 三色:主色 / 近白 / 辅色 —— 取自「AI 设计工作流」那张封面(桃 / 米白 / 淡紫) */
const COLORS = ['#F2B08E', '#FBF1E6', '#E9B6EA'];
const PARAMS = { dist: 0.4, swirl: 0.3, grain: 0.25 };
const TIME0 = 30;
const SPEED = 0.5; // 封面里是 0.9,放在页面里慢一些

const VERT = '#version 300 es\nin vec2 a_pos;out vec2 v_uv;\nvoid main(){v_uv=a_pos*0.5+0.5;gl_Position=vec4(a_pos,0.0,1.0);}';
const N = COLORS.length;
const FRAG = `#version 300 es
precision highp float;
in vec2 v_uv;
out vec4 fragColor;
uniform float u_time;
uniform float u_aspect;
uniform vec4  u_colors[${N}];
uniform float u_distortion;
uniform float u_swirl;
uniform float u_grain;
uniform float u_seed;
float hash21(vec2 p){p=fract(p*vec2(0.3183099,0.3678794))+0.1;p+=dot(p,p+19.19);return fract(p.x*p.y);}
float valueNoise(vec2 st){vec2 i=floor(st);vec2 f=fract(st);float a=hash21(i);float b=hash21(i+vec2(1.,0.));float c=hash21(i+vec2(0.,1.));float d=hash21(i+vec2(1.,1.));vec2 u=f*f*(3.-2.*f);return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);}
vec2 rotate(vec2 p,float th){return mat2(cos(th),sin(th),-sin(th),cos(th))*p;}
vec2 getPosition(int i,float t){
  float a=float(i)*0.37+u_seed*(1.7+0.9*float(i));
  float b=0.6+fract(float(i)/3.0)*0.9;
  float c=0.8+fract(float(i+1)/4.0);
  return 0.5+0.5*vec2(sin(t*b+a),cos(t*c+a*1.5));
}
void main(){
  vec2 uv=v_uv;
  vec2 uvSq=(uv-0.5)*vec2(u_aspect,1.0)+0.5;
  vec2 grainUV=uv*vec2(u_aspect,1.0)*1000.0;
  float mixerGrain=0.4*u_grain*(valueNoise(grainUV)-0.5);
  float t=0.5*(u_time+41.5);
  float radius=smoothstep(0.0,1.0,length(uvSq-0.5));
  float center=1.0-radius;
  for(float i=1.0;i<=2.0;i++){
    uvSq.x+=u_distortion*center/i*sin(t+i*0.4*smoothstep(0.0,1.0,uvSq.y))*cos(0.2*t+i*2.4*smoothstep(0.0,1.0,uvSq.y));
    uvSq.y+=u_distortion*center/i*cos(t+i*2.0*smoothstep(0.0,1.0,uvSq.x));
  }
  vec2 uvR=uvSq-0.5;
  float angle=3.0*u_swirl*radius;
  uvR=rotate(uvR,-angle);
  uvR+=0.5;
  vec3 color=vec3(0.0);
  float totalWeight=0.0;
  for(int i=0;i<${N};i++){
    vec2 pos=getPosition(i,t)+mixerGrain;
    float d=length(uvR-pos);
    d=pow(d,3.5);
    float w=1.0/(d+1e-3);
    color+=u_colors[i].rgb*u_colors[i].a*w;
    totalWeight+=w;
  }
  color/=max(1e-4,totalWeight);
  float go=valueNoise(rotate(grainUV,1.0)+vec2(3.0));
  go=mix(go,valueNoise(rotate(grainUV,2.0)+vec2(-1.0)),0.5);
  go=pow(go,1.3);
  float goV=go*2.0-1.0;
  float goStrength=pow(u_grain*abs(goV),0.8);
  color=mix(color,vec3(step(0.0,goV)),0.35*goStrength);
  fragColor=vec4(color,1.0);
}`;

const hex = (h: string) => [1, 3, 5].map((k) => parseInt(h.slice(k, k + 2), 16) / 255);

function makeMesh(cv: HTMLCanvasElement, seed: number) {
  const gl = cv.getContext('webgl2', { antialias: false, premultipliedAlpha: false });
  if (!gl) return null;
  const compile = (type: number, src: string) => {
    const sh = gl.createShader(type)!;
    gl.shaderSource(sh, src);
    gl.compileShader(sh);
    return sh;
  };
  const prog = gl.createProgram()!;
  gl.attachShader(prog, compile(gl.VERTEX_SHADER, VERT));
  gl.attachShader(prog, compile(gl.FRAGMENT_SHADER, FRAG));
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) return null;
  gl.useProgram(prog);
  gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW);
  const aPos = gl.getAttribLocation(prog, 'a_pos');
  gl.enableVertexAttribArray(aPos);
  gl.vertexAttribPointer(aPos, 2, gl.FLOAT, false, 0, 0);
  const U = (k: string) => gl.getUniformLocation(prog, k);
  gl.uniform4fv(U('u_colors[0]'), new Float32Array(COLORS.flatMap((c) => [...hex(c), 1])));
  gl.uniform1f(U('u_distortion'), PARAMS.dist);
  gl.uniform1f(U('u_swirl'), PARAMS.swirl);
  gl.uniform1f(U('u_grain'), PARAMS.grain);
  gl.uniform1f(U('u_seed'), seed);
  const uTime = U('u_time');
  const uAspect = U('u_aspect');
  return (t: number) => {
    const r = cv.getBoundingClientRect();
    const dpr = Math.min(devicePixelRatio || 1, 2);
    const w = Math.max(1, Math.round(r.width * dpr));
    const h = Math.max(1, Math.round(r.height * dpr));
    if (cv.width !== w || cv.height !== h) {
      cv.width = w;
      cv.height = h;
    }
    gl.viewport(0, 0, w, h);
    gl.uniform1f(uTime, t);
    gl.uniform1f(uAspect, r.height > 0 ? r.width / r.height : 16 / 9);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  };
}

/* seed = 色点轨迹相位:同一张卡里并排的几个容器给不同 seed,形态各不相同 */
export default function MeshBg({ seed = 12.3 }: { seed?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const cv = ref.current;
    if (!cv) return;
    const draw = makeMesh(cv, seed);
    if (!draw) return;
    cv.classList.add('ready');
    let t = TIME0;
    let raf = 0;
    let last = 0;
    const still = matchMedia('(prefers-reduced-motion: reduce)').matches;
    const frame = (now: number) => {
      const dt = last ? Math.min(0.05, (now - last) / 1000) : 0;
      last = now;
      t += dt * SPEED;
      draw(t);
      raf = requestAnimationFrame(frame);
    };
    draw(t);
    /* 只在卡片露出时动 */
    const io = new IntersectionObserver(([e]) => {
      cancelAnimationFrame(raf);
      last = 0;
      if (e.isIntersecting && !still) raf = requestAnimationFrame(frame);
    });
    io.observe(cv);
    const ro = new ResizeObserver(() => draw(t));
    ro.observe(cv);
    return () => {
      cancelAnimationFrame(raf);
      io.disconnect();
      ro.disconnect();
    };
  }, [seed]);
  return (
    <>
      <canvas aria-hidden="true" className="mesh-bg" ref={ref} />
      <svg aria-hidden="true" className="mesh-grain">
        <filter id="mesh-grain-n">
          <feTurbulence baseFrequency="0.9" numOctaves={2} type="fractalNoise" />
        </filter>
        <rect filter="url(#mesh-grain-n)" height="100%" width="100%" />
      </svg>
    </>
  );
}
