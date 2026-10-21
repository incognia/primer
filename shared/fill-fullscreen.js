// Emulates HTML5 fullscreen: the requested element fills the window or the pane instead of
// switching the operating system to fullscreen. Shared by every platform version.
//
// Each platform defines these globals in a user script that runs BEFORE this file:
//   window.__primerDebug  true to measure and log; anything else disables diagnostics
//   window.__primerLog    function(message: string) that receives the diagnostic events
//   window.__pane         number that identifies the pane (used only in diagnostics)
(() => {
  if (window.__fillFS) return; window.__fillFS = true;
  const DEBUG = window.__primerDebug === true;
  let cur = null, anc = [], hid = [], obs = null, savedStyle = null;
  const st = document.createElement('style');
  st.textContent = `
    .__fs{position:fixed!important;top:0!important;left:0!important;right:0!important;bottom:0!important;width:100vw!important;height:100vh!important;max-width:none!important;max-height:none!important;margin:0!important;z-index:2147483647!important;background:#000!important;transform:none!important}
    .__fsh{visibility:hidden!important}
    .__fsa{opacity:1!important;visibility:visible!important;transform:none!important;filter:none!important;perspective:none!important;contain:none!important;overflow:visible!important;clip-path:none!important;will-change:auto!important}
    video.__fs{object-fit:contain!important}`;
  (document.head || document.documentElement).appendChild(st);
  const dbg = o => { if (!DEBUG) return; try { o.top = window === top; if (typeof window.__primerLog === 'function') window.__primerLog(JSON.stringify(o)); } catch (e) {} };
  const desc = e => e ? (e.tagName + '#' + e.id + '.' + String(e.className).slice(0, 70)) : 'null';
  const rc = e => { const r = e.getBoundingClientRect(); return [r.x|0, r.y|0, r.width|0, r.height|0].join(','); };
  if (DEBUG) {
    const pg = t => dbg({ev:'page:' + t, pane:window.__pane, w:innerWidth, h:innerHeight, href:location.pathname.slice(0, 60)});
    for (const t of ['resize', 'pagehide', 'beforeunload', 'DOMContentLoaded', 'load', 'visibilitychange']) addEventListener(t, () => pg(t), true);
    pg('script-start');
    // Mide el hueco entre celdas del multiview de DAZN (solo cuando cambia)
    let lastMv = '';
    setInterval(() => {
      const c = document.querySelector('[class*="multiview-container"]');
      if (!c) return;
      const cs = getComputedStyle(c);
      const o = {ev:'mvgap', vw:innerWidth + 'x' + innerHeight, dpr:devicePixelRatio, rect:rc(c), display:cs.display, gap:cs.gap, rowGap:cs.rowGap, colGap:cs.columnGap,
                 cols:cs.gridTemplateColumns, rows:cs.gridTemplateRows, pad:cs.padding,
                 kids:[...c.children].slice(0, 6).map(k => desc(k).slice(0, 40) + ' ' + rc(k)),
                 vids:[...c.querySelectorAll('video')].slice(0, 6).map(rc)};
      const j = JSON.stringify(o);
      if (j !== lastMv) { lastMv = j; dbg(o); }
    }, 3000);
  }
  const fire = (el) => {
    for (const n of ['fullscreenchange','webkitfullscreenchange']) {
      document.dispatchEvent(new Event(n, {bubbles:true}));
      if (el) el.dispatchEvent(new Event(n, {bubbles:true}));
    }
  };
  const exit = () => {
    if (!cur) return Promise.resolve();
    dbg({ev:'exit', stack:String(new Error().stack).slice(0, 500)});
    if (obs) { obs.disconnect(); obs = null; }
    const el = cur; cur = null;
    if (savedStyle === null) el.removeAttribute('style'); else el.setAttribute('style', savedStyle);
    el.classList.remove('__fs'); anc.forEach(a => a.classList.remove('__fsa')); anc = [];
    hid.forEach(h => h.classList.remove('__fsh')); hid = [];
    fire(el); return Promise.resolve();
  };
  const enter = function () {
    if (cur) exit();
    cur = this; this.classList.add('__fs');
    savedStyle = this.getAttribute('style');
    for (const [k, v] of [['margin', '0'], ['left', '0'], ['top', '0'], ['right', '0'], ['bottom', '0']]) this.style.setProperty(k, v, 'important');
    for (let a = this.parentElement; a; a = a.parentElement) { a.classList.add('__fsa'); anc.push(a); }
    // oculta todo lo que no sea el elemento ni sus ancestros (capas DRM de otros videos incluidas)
    for (let a = this; a && a !== document.documentElement; a = a.parentElement)
      for (const sib of a.parentElement ? a.parentElement.children : [])
        if (sib !== a && sib.tagName !== 'STYLE' && sib.tagName !== 'SCRIPT') { sib.classList.add('__fsh'); hid.push(sib); }
    // React/DAZN reescribe className al detectar el fullscreen y borra nuestras marcas: se reponen al vuelo
    const keep = [[cur, '__fs'], ...anc.map(a => [a, '__fsa']), ...hid.map(h => [h, '__fsh'])];
    const want = new Map(keep);
    obs = new MutationObserver(ms => { for (const m of ms) { const c = want.get(m.target); if (c && !m.target.classList.contains(c)) m.target.classList.add(c); } });
    keep.forEach(([e]) => obs.observe(e, {attributes:true, attributeFilter:['class']}));
    dbg({ev:'enter', el:desc(this), rect:rc(this), vw:innerWidth+'x'+innerHeight,
         chain:(() => { const c = []; for (let a = this.parentElement, i = 0; a && i < 8; a = a.parentElement, i++) c.push(desc(a) + '@' + rc(a)); return c; })(),
         videos:this.querySelectorAll('video').length, stack:String(new Error().stack).slice(0, 300)});
    if (DEBUG) setTimeout(() => {
      if (!cur) return dbg({ev:'after', note:'ya salio (cur null)'});
      const cs = getComputedStyle(cur), r = cur.getBoundingClientRect();
      dbg({ev:'after', el:desc(cur), rect:rc(cur), display:cs.display, vis:cs.visibility, op:cs.opacity, pos:cs.position, z:cs.zIndex,
           atCenter:desc(document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2)),
           videos:[...cur.querySelectorAll('video')].map(v => rc(v) + ' ' + getComputedStyle(v).display)});
    }, 500);
    if (DEBUG) setTimeout(() => {
      if (!cur) return;
      const dflt = {opacity:'1', maskImage:'none', backdropFilter:'none', isolation:'auto', mixBlendMode:'normal', clipPath:'none',
                    contain:'none', contentVisibility:'visible', transform:'none', filter:'none', overflow:'visible', zIndex:'auto', position:'static', visibility:'visible'};
      const dump = e => { const cs = getComputedStyle(e), d = {};
        for (const k in dflt) if (cs[k] !== dflt[k]) d[k] = String(cs[k]).slice(0, 40);
        return desc(e).slice(0, 50) + ' ' + rc(e) + ' ' + JSON.stringify(d); };
      const chain = []; for (let a = cur, i = 0; a && i < 12; a = a.parentElement, i++) chain.push(dump(a));
      const pts = [[.05,.05],[.5,.5],[.95,.05],[.05,.95],[.95,.95],[.5,.02]].map(([x, y]) => {
        const e = document.elementFromPoint(innerWidth * x, innerHeight * y);
        return x + ',' + y + ':' + (e ? (cur.contains(e) ? 'DENTRO ' : 'FUERA ') + desc(e).slice(0, 60) : 'null'); });
      const vids = [...cur.querySelectorAll('video')].map(v => ({paused:v.paused, rs:v.readyState, vw:v.videoWidth + 'x' + v.videoHeight, t:v.currentTime|0, style:v.getAttribute('style')}));
      const kids = [...cur.children].slice(0, 8).map(k => { const cs = getComputedStyle(k);
        return desc(k).slice(0, 60) + ' ' + rc(k) + ' style=' + (k.getAttribute('style') || '') + ' pos=' + cs.position + ' ml=' + cs.marginLeft + ' left=' + cs.left + ' tr=' + cs.transform; });
      const ccs = getComputedStyle(cur);
      dbg({ev:'grid', kids, curCss:{display:ccs.display, cols:ccs.gridTemplateColumns, rows:ccs.gridTemplateRows, pl:ccs.paddingLeft, ml:ccs.marginLeft, left:ccs.left, w:ccs.width, tr:ccs.transform}});
      // [desactivado] Qué hay justo en el margen derecho e inferior: elemento y color de fondo de cada ancestro hasta el que está en pantalla completa
      // const edge = [[innerWidth - 2, innerHeight / 2], [innerWidth / 2, innerHeight - 2]].map(([x, y]) => {
      //   const out = []; for (let e = document.elementFromPoint(x, y), i = 0; e && i < 14; e = e.parentElement, i++) {
      //     const cs = getComputedStyle(e); out.push(desc(e).slice(0, 44) + ' ' + rc(e) + ' bg=' + cs.backgroundColor + (cs.backgroundImage !== 'none' ? ' img' : ''));
      //     if (e === cur) break; }
      //   return (x | 0) + ',' + (y | 0) + ' => ' + out.join(' < '); });
      // dbg({ev:'edge', edge, vv:[...cur.querySelectorAll('video')].map(v => { const c = getComputedStyle(v); return rc(v) + ' fit=' + c.objectFit + ' m=' + c.margin + ' bg=' + c.backgroundColor; })});
      dbg({ev:'deep', chain, pts, vids, curStyle:cur.getAttribute('style'), curClass:String(cur.className).slice(-120)});
    }, 1200);
    fire(this); return Promise.resolve();
  };
  for (const n of ['requestFullscreen','webkitRequestFullscreen','webkitRequestFullScreen'])
    Element.prototype[n] = enter;
  for (const n of ['exitFullscreen','webkitExitFullscreen','webkitCancelFullScreen'])
    document[n] = exit;
  const def = (k, g) => { try { Object.defineProperty(document, k, {get:g, configurable:true}); } catch (e) {} };
  def('fullscreenElement', () => cur); def('webkitFullscreenElement', () => cur);
  def('webkitCurrentFullScreenElement', () => cur);
  def('fullscreenEnabled', () => true); def('webkitFullscreenEnabled', () => true);
  def('webkitIsFullScreen', () => !!cur); def('fullscreen', () => !!cur);
  addEventListener('keydown', e => { if (e.key === 'Escape' && cur) exit(); }, true);
})();
