/* =============================================================
   supabase.js — 지력사무소 후원보상 안내 공통 연동 스크립트
   ✅ 아래 두 줄만 본인 값으로 교체하면 끝!
   ============================================================= */

const SUPABASE_URL  = 'https://guonejbrlhfaammdcwrf.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1b25lamJybGhmYWFtbWRjd3JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ4Mjc1MjUsImV4cCI6MjEwMDQwMzUyNX0.QBAIWLme7DBcc5gs8GiQghDJfh38O-1xDjRA9unh63U';

/* ── 클라이언트 ── */
var db = null;
try {
  var _c = (window.supabase && window.supabase.createClient);
  if (_c) db = _c(SUPABASE_URL, SUPABASE_ANON);
} catch (e) { console.warn('supabase 초기화 실패 — 기본값으로 표시됩니다.', e); }

/** DB 연결 여부 */
function dbReady() { return !!db; }

/* =============================================================
   CRUD 헬퍼
   ============================================================= */

/** 전체 조회
 *  ⚠️ 성공하면 배열([] 포함), 실패하면 null 을 돌려준다.
 *     "진짜 비어 있음(=[])" 과 "못 읽음(=null)" 을 구분해야
 *     관리자에서 전부 지웠을 때 화면이 기본값으로 되돌아가지 않는다.
 *  예) await fetchAll('pledges', { order:'sort_order' })
 */
async function fetchAll(table, options) {
  options = options || {};
  if (!db) return null;
  try {
    var q = db.from(table).select('*');
    if (options.order) q = q.order(options.order, { ascending: options.asc !== false });
    if (options.filter) q = q.eq(options.filter.col, options.filter.val);
    if (options.limit) q = q.limit(options.limit);
    var r = await q;
    if (r.error) { console.error('fetchAll(' + table + ')', r.error); return null; }
    return r.data || [];
  } catch (e) { console.error('fetchAll 예외', e); return null; }
}

/** 단건 삽입 */
async function insertRow(table, row) {
  if (!db) return false;
  try {
    var r = await db.from(table).insert(row);
    if (r.error) { console.error('insertRow(' + table + ')', r.error); return false; }
    return true;
  } catch (e) { console.error('insertRow 예외', e); return false; }
}

/** 단건 수정 */
async function updateRow(table, id, updates) {
  if (!db) return false;
  try {
    var r = await db.from(table).update(updates).eq('id', id);
    if (r.error) { console.error('updateRow(' + table + ')', r.error); return false; }
    return true;
  } catch (e) { console.error('updateRow 예외', e); return false; }
}

/** 단건 삭제 */
async function deleteRow(table, id) {
  if (!db) return false;
  try {
    var r = await db.from(table).delete().eq('id', id);
    if (r.error) { console.error('deleteRow(' + table + ')', r.error); return false; }
    return true;
  } catch (e) { console.error('deleteRow 예외', e); return false; }
}

/** profile(id=1).data 통째로 읽기 */
async function fetchProfile() {
  if (!db) return {};
  try {
    var r = await db.from('profile').select('data').eq('id', 1).single();
    if (r.error) { console.error('fetchProfile', r.error); return {}; }
    return (r.data && r.data.data) || {};
  } catch (e) { console.error('fetchProfile 예외', e); return {}; }
}

/** profile(id=1).data 부분 저장 (기존 값 유지 + 덮어쓰기) */
async function saveProfile(patch) {
  if (!db) return false;
  try {
    var cur = await fetchProfile();
    var next = Object.assign({}, cur, patch);
    var r = await db.from('profile').upsert({ id: 1, data: next, updated_at: new Date().toISOString() });
    if (r.error) { console.error('saveProfile', r.error); return false; }
    return true;
  } catch (e) { console.error('saveProfile 예외', e); return false; }
}

/* =============================================================
   🎨 색 팔레트 자동 적용 (index · admin 공통)
   admin > 🎨 테마 탭에서 저장한 색을 전 페이지에 반영
   ============================================================= */
var THEME_MAP = {
  'theme-wu-red': '--wu-red',   /* 주색 (인장 · 사이드바 · 강조선) */
  'theme-accent': '--accent',   /* 보조 강조 (번호칸 · 캡션) */
  'theme-gold':   '--gold',     /* 금박 테두리 */
  'theme-signal': '--signal',   /* 형광 신호점 */
  'theme-ink':    '--ink',      /* 먹색 (본문 글자 · 테두리) */
  'theme-paper':  '--paper'     /* 종이색 (패널 · 카드 바탕) */
};
var THEME_DEFAULT = {
  'theme-wu-red': '#7a1f1b',
  'theme-accent': '#ad342b',
  'theme-gold':   '#b38636',
  'theme-signal': '#58d9d7',
  'theme-ink':    '#211b15',
  'theme-paper':  '#f7f0df'
};

/** 팔레트 값 객체를 CSS 변수로 적용 */
function paintTheme(p) {
  if (!p) return;
  Object.keys(THEME_MAP).forEach(function (k) {
    if (p[k]) document.documentElement.style.setProperty(THEME_MAP[k], p[k]);
  });
}

/** DB에서 팔레트를 읽어 적용 (실패해도 기본 색 유지) */
async function applyTheme() {
  try { paintTheme(await fetchProfile()); } catch (e) { /* 무시 */ }
}

/* ── SOOP 아이디 → 프로필 사진 주소 ──
   예) rkdmsdl782 → https://profile.img.sooplive.co.kr/LOGO/rk/rkdmsdl782/rkdmsdl782.jpg */
function soopAvatar(id) {
  id = String(id || '').trim().toLowerCase();
  if (id.length < 2) return '';
  return 'https://profile.img.sooplive.co.kr/LOGO/' + id.slice(0, 2) + '/' + id + '/' + id + '.jpg';
}

/* =============================================================
   보상기록 — 같은 시청자의 여러 건을 하나로 묶기
   같은 SOOP 아이디(없으면 같은 닉네임)를 한 사람으로 본다.
   ============================================================= */
function recKey(r) {
  var id = String((r && r.soop_id) || '').trim().toLowerCase();
  return id ? 'id:' + id : 'nm:' + String((r && r.nickname) || '').trim();
}

/** 행 배열 → [{key, nickname, soop_id, items[], base}] (표시 순서대로) */
function recGroups(rows) {
  var map = {}, order = [];
  (rows || []).forEach(function (r) {
    var k = recKey(r);
    if (!map[k]) {
      map[k] = { key: k, nickname: r.nickname, soop_id: r.soop_id || '', items: [], base: Number(r.sort_order) || 0 };
      order.push(k);
    }
    map[k].items.push(r);
    map[k].base = Math.min(map[k].base, Number(r.sort_order) || 0);
  });
  var list = order.map(function (k) { return map[k]; });
  list.sort(function (a, b) { return a.base - b.base; });
  list.forEach(function (g) {
    g.items.sort(function (a, b) { return (Number(a.sort_order) || 0) - (Number(b.sort_order) || 0); });
  });
  return list;
}

/** 처리 현황 요약 → {done, total, cls} */
function recSummary(items) {
  items = items || [];
  var done = 0, ing = 0;
  items.forEach(function (i) {
    var st = String(i.status || '');
    if (st.indexOf('완료') > -1) done += 1;
    else if (st.indexOf('진행') > -1) ing += 1;
  });
  var cls = (items.length && done === items.length) ? 'done' : ((ing || done) ? 'ing' : 'wait');
  return { done: done, total: items.length, cls: cls };
}

/* ── 토스트 ── */
function showToast(msg, ms) {
  var t = document.getElementById('toast');
  if (!t) { t = document.createElement('div'); t.id = 'toast'; t.className = 'toast'; document.body.appendChild(t); }
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(showToast._t);
  showToast._t = setTimeout(function () { t.classList.remove('show'); }, ms || 2400);
}

/* ── SOOP 게시글 iframe 높이 자동 전달 ── */
function enableIframeAutoHeight() {
  var send = function () {
    try { window.parent.postMessage({ type: 'resize', height: document.body.scrollHeight }, '*'); } catch (e) {}
  };
  send();
  if (window.ResizeObserver) new ResizeObserver(send).observe(document.body);
  window.addEventListener('load', send);
}
