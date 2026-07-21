/**
 * 点赞按钮 —— script.js initLikeButtons 的组件化移植。
 * 存储与旧版同 key 同结构:localStorage['likedItems'] = { [id]: {count, liked:true} },
 * 老访客的点赞状态无缝延续;数字为 0 时隐藏(与旧版 updateCount 行为一致)。
 */
import { useState } from 'react';

interface LikeState {
  liked: boolean;
  count: number;
}

function readAll(): Record<string, { count: number; liked: boolean }> {
  try {
    return JSON.parse(localStorage.getItem('likedItems') || '{}');
  } catch {
    return {};
  }
}

function readLike(id: string): LikeState {
  const all = readAll();
  return all[id] ? { liked: true, count: all[id].count || 1 } : { liked: false, count: 0 };
}

function toggleLike(id: string, prev: LikeState): LikeState {
  const all = readAll();
  let next: LikeState;
  if (prev.liked) {
    next = { liked: false, count: Math.max(0, prev.count - 1) };
    delete all[id];
  } else {
    next = { liked: true, count: prev.count + 1 };
    all[id] = { count: next.count, liked: true };
  }
  try {
    localStorage.setItem('likedItems', JSON.stringify(all));
  } catch {
    /* 隐私模式静默 */
  }
  return next;
}

export default function LikeButton({ id }: { id: string }) {
  const [state, setState] = useState<LikeState>(() => readLike(id));
  return (
    <button
      className={'card-like' + (state.liked ? ' liked' : '')}
      data-id={id}
      onClick={() => setState((prev) => toggleLike(id, prev))}
    >
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
      </svg>
      <span className="like-count" style={state.count > 0 ? undefined : { display: 'none' }}>
        {state.count > 0 ? state.count : ''}
      </span>
    </button>
  );
}
