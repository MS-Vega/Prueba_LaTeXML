document.addEventListener('DOMContentLoaded', function () {
  // ---- Estilos ----
  const style = document.createElement('style');
  style.textContent = `
    #ref-preview {
      position: absolute;
      display: none;
      width: max-content;
      max-width: min(600px, 92vw);
      max-height: 320px;
      overflow: auto;
      padding: 12px 16px;
      background: #fff;
      color: #000;
      border: 1px solid #888;
      border-radius: 6px;
      box-shadow: 0 4px 16px rgba(0,0,0,.25);
      z-index: 1000;
      font-size: 0.95em;
    }
    #ref-preview .ref-go {
      display: block;
      margin-top: 8px;
      font-size: 0.85em;
    }
  `;
  document.head.appendChild(style);

  // ---- Caja flotante ----
  const box = document.createElement('div');
  box.id = 'ref-preview';
  document.body.appendChild(box);

  const SELECTOR = 'a[href^="#"]';
  const isTouch = window.matchMedia('(hover: none)').matches;
  let showTimer, hideTimer;

  function getLinkTarget(link) {
    if (link.closest('nav, .ltx_toc')) return null;   // ignora el índice
    const href = link.getAttribute('href');
    if (!href || href.length < 2) return null;
    return document.getElementById(decodeURIComponent(href.slice(1)));
  }

  function show(link) {
    const target = getLinkTarget(link);
    if (!target) return false;

    const clone = target.cloneNode(true);
    clone.removeAttribute('id');
    clone.querySelectorAll('[id]').forEach(el => el.removeAttribute('id'));

    box.innerHTML = '';
    let content = clone;
    // Si el destino es un elemento de lista (p. ej. una entrada de bibliografía),
    // lo envolvemos en una copia vacía de su lista para conservar los estilos
    if (/^(LI|DT|DD)$/.test(target.tagName) && target.parentElement) {
      const wrap = target.parentElement.cloneNode(false);
      wrap.removeAttribute('id');
      wrap.appendChild(clone);
      content = wrap;
    }
    box.appendChild(content);

    // En pantallas táctiles añadimos un botón para ir al destino
    if (isTouch) {
      const go = document.createElement('a');
      go.href = link.getAttribute('href');
      go.className = 'ref-go';
      go.textContent = 'Ir al teorema →';
      go.addEventListener('click', hide);
      box.appendChild(go);
    }

    box.style.display = 'block';
    if (window.MathJax && MathJax.typesetPromise) MathJax.typesetPromise([box]);

    // Posición: debajo del enlace; si no cabe, encima
    const r = link.getBoundingClientRect();
    const below = window.innerHeight - r.bottom;
    const top = below > box.offsetHeight + 12 || below > r.top
      ? r.bottom + 6
      : r.top - box.offsetHeight - 6;
    const left = Math.max(8, Math.min(r.left, window.innerWidth - box.offsetWidth - 8));
    box.style.top = (window.scrollY + top) + 'px';
    box.style.left = (window.scrollX + left) + 'px';
    return true;
  }

  function hide() {
    clearTimeout(showTimer);
    box.style.display = 'none';
  }

  // ---- Ratón (escritorio) ----
  if (!isTouch) {
    document.addEventListener('mouseover', e => {
      const link = e.target.closest(SELECTOR);
      if (link && !box.contains(link)) {
        clearTimeout(hideTimer);
        clearTimeout(showTimer);
        showTimer = setTimeout(() => show(link), 250);
      } else if (box.contains(e.target)) {
        clearTimeout(hideTimer);          // el ratón está sobre la caja
      }
    });

    document.addEventListener('mouseout', e => {
      const link = e.target.closest(SELECTOR);
      if ((link && !box.contains(link)) || box.contains(e.target)) {
        clearTimeout(showTimer);
        hideTimer = setTimeout(hide, 300);
      }
    });
  }

  // ---- Táctil: un toque = vista previa ----
  if (isTouch) {
    document.addEventListener('click', e => {
      const link = e.target.closest(SELECTOR);
      if (link && !box.contains(link) && show(link)) {
        e.preventDefault();
        return;
      }
      if (!box.contains(e.target)) hide();
    });
  }

  document.addEventListener('keydown', e => { if (e.key === 'Escape') hide(); });
});
