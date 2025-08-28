const RNAME = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'tk_modul';

const els = {
  scrim: document.getElementById('scrim'),
  app: document.getElementById('app'),
  btnClose: document.getElementById('btnClose'),
  jenis: document.getElementById('jenis'),
  days: document.getElementById('days'),
  targetWrap: document.getElementById('targetWrap'),
  targetId: document.getElementById('targetId'),
  btnCreate: document.getElementById('btnCreate'),
  createResult: document.getElementById('createResult'),
  codeBox: document.getElementById('codeBox'),
  btnCopy: document.getElementById('btnCopy'),
  vipRows: document.getElementById('vipRows'),
  search: document.getElementById('search'),
  btnSearch: document.getElementById('btnSearch'),
  prevPage: document.getElementById('prevPage'),
  nextPage: document.getElementById('nextPage'),
  pageInfo: document.getElementById('pageInfo'),
};

let jenisMap = {};
let jenisList = [];
let maxDays = 365;
let lockTo = false;
let page = 1, total = 0, pageSize = 20, q = '';

function normalizeJenisMap(input) {
  const list = [];
  if (Array.isArray(input)) {
    for (let i = 0; i < input.length; i++) {
      const label = input[i];
      if (label != null) list.push({ id: i + 1, label: String(label) }); // shift ke 1..n
    }
  } else if (input && typeof input === 'object') {
    // Object '1','2','3'
    Object.keys(input).forEach(k => {
      const id = parseInt(k, 10);
      list.push({ id: isNaN(id) ? k : id, label: String(input[k]) });
    });
    list.sort((a, b) => Number(a.id) - Number(b.id));
  }
  return list;
}

function nui(name, data) {
  return fetch(`https://${RNAME}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify(data || {})
  }).then(r => r.json());
}

function setVisible(node, vis) {
  node.classList[vis ? 'remove' : 'add']('hidden');
}

function renderJenisSelect() {
  els.jenis.innerHTML = '';
  jenisList.forEach(it => {
    const opt = document.createElement('option');
    opt.value = String(it.id);
    opt.textContent = `${it.id} - ${it.label}`;
    els.jenis.appendChild(opt);
  });
}

function renderList(items) {
  els.vipRows.innerHTML = '';
  items.forEach(it => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${it.citizenid}</td>
      <td>${it.steam}</td>
      <td><span class="badge">${it.jenis} - ${it.jenisLabel}</span></td>
      <td>${it.expiry}</td>
      <td>
        <div class="action">
          <button class="btn small" data-license="${it.license}" data-jenis="${it.jenis}">Revoke</button>
        </div>
      </td>
    `;
    els.vipRows.appendChild(tr);
  });

  els.vipRows.querySelectorAll('button[data-license]').forEach(btn => {
    btn.addEventListener('click', async () => {
      const license = btn.dataset.license;
      const jenis = parseInt(btn.dataset.jenis, 10);
      await nui('revoke_vip', { license, jenis });
      loadList();
    });
  });
}

async function loadList() {
  const resp = await nui('list_vip', { page, q });
  if (!resp || !resp.ok) return;
  total = resp.total || 0;
  pageSize = resp.pageSize || 20;
  renderList(resp.items || []);
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  els.pageInfo.textContent = `${page} / ${totalPages}`;
}

window.addEventListener('message', (ev) => {
  const data = ev.data || {};
  if (data.action === 'open') {
    jenisMap = data.jenis || {};
    jenisList = normalizeJenisMap(jenisMap);
    maxDays = data.maxDays || 365;
    lockTo  = !!data.lockTo;
    renderJenisSelect();
    setVisible(els.targetWrap, lockTo);
    els.days.setAttribute('max', String(maxDays));
    page = 1; q = ''; els.search.value = '';
    setVisible(els.scrim, true);
    setVisible(els.app, true);
    loadList();
    } else if (data.action === 'forceClose') {
    setVisible(els.app, false);
    setVisible(els.scrim, false);
  }
});

els.btnClose.addEventListener('click', () => nui('close', {}));
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') nui('close', {});
});

els.btnCreate.addEventListener('click', async () => {
  const jenis = parseInt(els.jenis.value, 10);
  const days  = parseInt(els.days.value, 10);
  const targetId = lockTo ? parseInt(els.targetId.value || '0', 10) : undefined;

  const payload = { jenis, days };
  if (lockTo) payload.targetId = targetId;

  const resp = await nui('create_code', payload);
  if (!resp || !resp.ok) {
    els.codeBox.textContent = (resp && resp.error) || 'Gagal membuat kode';
    setVisible(els.createResult, true);
    return;
  }
  els.codeBox.textContent = resp.code;
  setVisible(els.createResult, true);
});

async function copyText(text) {
  if (!text) return false;
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch (_) {}
  const ta = document.createElement('textarea');
  ta.value = text;
  ta.style.position = 'fixed';
  ta.style.opacity = '0';
  document.body.appendChild(ta);
  ta.select();
  let ok = false;
  try {
    ok = document.execCommand('copy');
  } catch(_) { ok = false; }
  document.body.removeChild(ta);
  return ok;
}

els.btnCopy.addEventListener('click', async () => {
  const code = (els.codeBox.textContent || '').trim();
  const ok = await copyText(code);
  els.btnCopy.textContent = ok ? 'Copied!' : 'Gagal Copy';
  setTimeout(() => (els.btnCopy.textContent = 'Copy'), 1200);
});

els.btnSearch.addEventListener('click', () => {
  q = (els.search.value || '').trim();
  page = 1;
  loadList();
});

els.prevPage.addEventListener('click', () => {
  if (page > 1) { page--; loadList(); }
});
els.nextPage.addEventListener('click', () => {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  if (page < totalPages) { page++; loadList(); }
});