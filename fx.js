/* =============================================================
   fx.js — 지력사무소 연출 (떠다니는 금박 · 클릭 인장 · 카드 기울기 · 로딩 커버)
   ▣ 사람마다 바꾸는 건 아래 4줄뿐
   ============================================================= */
var FX_COUNT = 14;                 // 떠다니는 금박 조각 개수
var FX_CLICK = ['吳', '朱', '✦'];  // 클릭했을 때 튀는 모양 (글자 / 이모지 / 이미지 URL 가능)
var FX_TILT  = true;               // 카드 기울기 사용
var FX_TILT_SEL = '.look-card,.product-card,.reward-row,.pledge-row,.top-list li,.roulette-card,.records-table';

(function () {
  'use strict';

  var reduce = false;
  try { reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches; } catch (e) {}

  /* ─────────────────────────────────────────────
     1) 떠다니는 금박 조각 (배경)
     ───────────────────────────────────────────── */
  function fxHearts() {
    var root = document.getElementById('fx');
    if (!root || root.dataset.mounted === 'true') return;
    root.dataset.mounted = 'true';
    if (reduce) return;

    for (var i = 0; i < FX_COUNT; i += 1) {
      var s = document.createElement('span');
      s.className = 'fxfb';
      s.style.left = Math.round(Math.random() * 100) + '%';
      s.style.animationDuration = (9 + Math.random() * 8) + 's';
      s.style.animationDelay = (-Math.random() * 16) + 's';
      s.style.opacity = (0.25 + Math.random() * 0.45).toFixed(2);
      root.appendChild(s);
    }
  }
  window.fxHearts = fxHearts;

  /* ─────────────────────────────────────────────
     2) 클릭 인장 — 누른 자리에서 조각이 튄다
     ───────────────────────────────────────────── */
  function isImage(v) { return /^data:|^https?:\/\/|^\/[^/]/.test(String(v)); }

  function pop(x, y) {
    if (reduce) return;
    var list = [].concat(FX_CLICK);
    for (var i = 0; i < 5; i += 1) {
      var shape = list[Math.floor(Math.random() * list.length)];
      var el = document.createElement('span');
      el.style.cssText =
        'position:fixed;z-index:70;left:' + x + 'px;top:' + y + 'px;' +
        'pointer-events:none;will-change:transform,opacity;' +
        'transform:translate(-50%,-50%);opacity:1;';

      if (isImage(shape)) {
        el.style.width = '20px';
        el.style.height = '20px';
        el.style.backgroundImage = 'url("' + shape + '")';
        el.style.backgroundSize = 'contain';
        el.style.backgroundRepeat = 'no-repeat';
        el.style.backgroundPosition = 'center';
      } else {
        el.textContent = shape;
        el.style.font = '800 15px/1 "Noto Serif KR",Georgia,serif';
        el.style.color = i % 3 === 0
          ? 'var(--signal, #58d9d7)'
          : (i % 2 === 0 ? 'var(--gold, #b38636)' : 'var(--wu-red, #7a1f1b)');
        el.style.textShadow = '0 1px 0 rgba(255,244,214,.85)';
      }

      document.body.appendChild(el);
      var dx = (Math.random() - 0.5) * 96;
      var dy = -(34 + Math.random() * 62);
      var rot = (Math.random() - 0.5) * 300;

      (function (node, dx, dy, rot) {
        try {
          node.animate(
            [
              { transform: 'translate(-50%,-50%) translate(0,0) rotate(0deg) scale(.6)', opacity: 1 },
              { transform: 'translate(-50%,-50%) translate(' + dx + 'px,' + dy + 'px) rotate(' + rot + 'deg) scale(1.1)', opacity: 0 }
            ],
            { duration: 760 + Math.random() * 260, easing: 'cubic-bezier(.2,.7,.3,1)' }
          ).onfinish = function () { node.remove(); };
        } catch (e) { setTimeout(function () { node.remove(); }, 800); }
      })(el, dx, dy, rot);
    }
  }

  document.addEventListener('click', function (e) {
    if (e.target.closest && e.target.closest('input,textarea,select,.ask-box')) return;
    pop(e.clientX, e.clientY);
  });

  /* ─────────────────────────────────────────────
     3) 카드 기울기 — 문서 위임 (나중에 렌더된 박스도 적용)
     ───────────────────────────────────────────── */
  var TILT_DEG = 2.2;
  var tilted = null;

  function clearTilt() {
    if (!tilted) return;
    tilted.style.transform = '';
    tilted.style.transition = 'transform 260ms ease';
    tilted = null;
  }

  if (FX_TILT && !reduce) {
    document.addEventListener('mousemove', function (e) {
      var card = e.target.closest ? e.target.closest(FX_TILT_SEL) : null;
      if (!card) { clearTilt(); return; }
      if (tilted && tilted !== card) clearTilt();
      tilted = card;
      var r = card.getBoundingClientRect();
      if (!r.width || !r.height) return;
      var px = (e.clientX - r.left) / r.width - 0.5;
      var py = (e.clientY - r.top) / r.height - 0.5;
      card.style.transition = 'transform 90ms ease';
      card.style.transform =
        'perspective(900px) rotateX(' + (-py * TILT_DEG * 2).toFixed(2) + 'deg) ' +
        'rotateY(' + (px * TILT_DEG * 2).toFixed(2) + 'deg)';
    }, { passive: true });
    document.addEventListener('mouseleave', clearTilt);
  }

  /* ─────────────────────────────────────────────
     4) 로딩 커버 — 도장 찍히고 걷힌다
     ───────────────────────────────────────────── */
  function hideLoader() {
    var c = document.getElementById('wuload');
    if (!c || c.dataset.off === '1') return;
    c.dataset.off = '1';
    c.classList.add('off');
    setTimeout(function () { if (c.parentNode) c.parentNode.removeChild(c); }, 520);
  }
  window.fxHideLoader = hideLoader;

  /* ─────────────────────────────────────────────
     5) 시작
     ───────────────────────────────────────────── */
  function boot() {
    fxHearts();
    document.body.classList.add('ready');
    setTimeout(hideLoader, 260);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot, { once: true });
  } else {
    boot();
  }
  /* 데이터 로딩이 늦어도 화면이 영영 숨지 않게 (FOUC 폴백) */
  setTimeout(function () { document.body.classList.add('ready'); hideLoader(); }, 1600);
})();
