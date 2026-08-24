// ====================
// NOTION-STYLE CLIENT CONTROLLER FOR SETUN HARDWARE STUDIO
// ====================

const trits = Array(24).fill(0);
let hoveredTritIndex = null;

const PRESETS = {
    PROTON:       "+-++-++-++-++-++-++-++-+",
    ELECTRON:     "-+--+--+--+--+--+--+--+-",
    KINK:         "---000+++---000+++---000",
    QUASICRYSTAL: "+0-+0-+0-+0-+0-+0-+0-+0-",
    HOPFION:      "++0--++0--++0--++0--++0-",
    ZERO:         "000000000000000000000000"
};

const SAMPLE_PROGRAMS = {
    UNKNOT: `-- 1. Automatic Unknot Annihilator\nSET +-+--+-+-+-+-+-+-+-+-\nSIMP\nSHFT 1\nSIMP\nSAVE 0\nHALT`,
    SOLITON_LOOP: `-- 2. Traveling Soliton Pulse\nSET +00000000000000000000000\nSHFT 2\nROT 1\nSAVE 1\nHALT`,
    CHIRALITY_FLIP: `-- 3. Topological Chirality Oscillator\nSET +++000---+++000---+++000\nINV\nSAVE 2\nHALT`,
    MEMORY_BACKUP: `-- 4. Triple-Rail Flash Backup\nLOAD 0\nINV\nSAVE 1\nHALT`
};

// 1. Initialize 24 Trit Interactive Grid (2 Rows of 12)
function initTritGrid() {
    const gridHigh = document.getElementById('tritGridHigh');
    const gridLow  = document.getElementById('tritGridLow');
    if (!gridHigh || !gridLow) return;

    gridHigh.innerHTML = '';
    gridLow.innerHTML  = '';

    // High Bank (13 to 24)
    for (let i = 12; i < 24; i++) {
        gridHigh.appendChild(createTritCell(i));
    }

    // Low Bank (1 to 12)
    for (let i = 0; i < 12; i++) {
        gridLow.appendChild(createTritCell(i));
    }

    updateTritUI();
}

function createTritCell(index) {
    const el = document.createElement('div');
    el.className = 'trit-cell trit-zero';
    el.dataset.index = index;

    const idxLabel = document.createElement('span');
    idxLabel.className = 'trit-cell-index';
    idxLabel.textContent = `T${index + 1}`;

    const valLabel = document.createElement('span');
    valLabel.className = 'trit-cell-val';
    valLabel.textContent = '0';

    el.appendChild(idxLabel);
    el.appendChild(valLabel);

    el.addEventListener('click', () => {
        // Cycle: 0 -> +1 -> -1 -> 0
        if (trits[index] === 0) trits[index] = 1;
        else if (trits[index] === 1) trits[index] = -1;
        else trits[index] = 0;

        updateTritUI();
    });

    el.addEventListener('mouseenter', () => {
        hoveredTritIndex = index;
    });

    el.addEventListener('mouseleave', () => {
        if (hoveredTritIndex === index) hoveredTritIndex = null;
    });

    return el;
}

function updateTritUI() {
    const cells = document.querySelectorAll('.trit-cell');

    cells.forEach(cell => {
        const idx = parseInt(cell.dataset.index);
        const val = trits[idx];
        const valLabel = cell.querySelector('.trit-cell-val');

        cell.classList.remove('trit-plus', 'trit-minus', 'trit-zero');

        if (val === 1) {
            cell.classList.add('trit-plus');
            valLabel.textContent = '+1';
        } else if (val === -1) {
            cell.classList.add('trit-minus');
            valLabel.textContent = '-1';
        } else {
            cell.classList.add('trit-zero');
            valLabel.textContent = '0';
        }
    });

    // Update Net Chirality Badge
    let netQ = 0;
    for (let i = 0; i < 24; i++) netQ += trits[i];
    const badge = document.getElementById('busChiralityBadge');
    if (badge) {
        badge.classList.remove('badge-mint', 'badge-rose', 'badge-lavender');
        if (netQ > 0) {
            badge.classList.add('badge-mint');
            badge.textContent = `Q: +${netQ} (Chiral Right)`;
        } else if (netQ < 0) {
            badge.classList.add('badge-rose');
            badge.textContent = `Q: ${netQ} (Chiral Left)`;
        } else {
            badge.classList.add('badge-lavender');
            badge.textContent = `Q: 0 (Neutral Knot)`;
        }
    }

    // Render Dynamic 3-Strand Braid Ribbon
    renderBraidSvg();
}

// 2. Interactive SVG 3-Strand Braid Ribbon Generator
function renderBraidSvg() {
    const svg = document.getElementById('braidSvg');
    if (!svg) return;

    const W = 940;
    const H = 32;
    const stepX = W / 24;
    const yLanes = [6, 16, 26];

    // Current permutation of 3 strands: [strandAtTop, strandAtMid, strandAtBot]
    let perm = [0, 1, 2];

    // Path coordinate histories for the 3 physical strands
    const strandCoords = [[{ x: 0, y: yLanes[0] }], [{ x: 0, y: yLanes[1] }], [{ x: 0, y: yLanes[2] }]];

    for (let i = 0; i < 24; i++) {
        const t = trits[i];
        const xNext = (i + 1) * stepX;

        if (t === 1) {
            // Swap top 2 strands: perm[0] <-> perm[1]
            const s0 = perm[0];
            const s1 = perm[1];
            perm[0] = s1;
            perm[1] = s0;
        } else if (t === -1) {
            // Swap bottom 2 strands: perm[1] <-> perm[2]
            const s1 = perm[1];
            const s2 = perm[2];
            perm[1] = s2;
            perm[2] = s1;
        }

        // Record positions
        strandCoords[perm[0]].push({ x: xNext, y: yLanes[0] });
        strandCoords[perm[1]].push({ x: xNext, y: yLanes[1] });
        strandCoords[perm[2]].push({ x: xNext, y: yLanes[2] });
    }

    // Colors for 3 strands
    const colors = ['#0099ff', '#888888', '#ff4466'];

    let svgHtml = '';
    for (let s = 0; s < 3; s++) {
        const pts = strandCoords[s];
        let d = `M ${pts[0].x} ${pts[0].y}`;
        for (let k = 0; k < pts.length - 1; k++) {
            const p1 = pts[k];
            const p2 = pts[k + 1];
            const mx = (p1.x + p2.x) / 2;
            d += ` C ${mx} ${p1.y}, ${mx} ${p2.y}, ${p2.x} ${p2.y}`;
        }
        svgHtml += `<path d="${d}" stroke="${colors[s]}" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.9"/>`;
    }

    svg.innerHTML = svgHtml;
}

function loadTritString(str) {
    for (let i = 0; i < 24; i++) {
        const c = str[i] || '0';
        if (c === '+' || c === '1') trits[i] = 1;
        else if (c === '-' || c === '2') trits[i] = -1;
        else trits[i] = 0;
    }
    updateTritUI();
}

function getTritString() {
    return trits.map(t => (t === 1 ? '+' : (t === -1 ? '-' : '0'))).join('');
}

// 3. API Dispatchers
async function sendCommand(cmd) {
    if (!cmd || !cmd.trim()) return;
    try {
        const res = await fetch('/api/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ command: cmd.trim() })
        });
        const data = await res.json();
        console.log(`[Sent] "${cmd}"`, data);
        updateStatus();
    } catch (e) {
        console.error('Failed to send command:', e);
    }
}

async function injectTrits() {
    const tritStr = getTritString();
    try {
        const res = await fetch('/api/trits', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ trits: tritStr })
        });
        const data = await res.json();
        console.log('[Injected Trits]:', tritStr, data);
        updateStatus();
    } catch (e) {
        console.error('Failed to inject trits:', e);
    }
}

async function uploadAndRunScript() {
    const editor = document.getElementById('basmEditor');
    const text = editor ? editor.value : '';
    const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0 && !l.startsWith('--'));

    if (lines.length === 0) return;

    for (let i = 0; i < lines.length; i++) {
        await sendCommand(`BSET ${i + 1} ${lines[i]}`);
    }
    await sendCommand('RUN 1');
}

async function stepScript() {
    await sendCommand('STEP');
}

// 4. Custom User Script Storage (localStorage)
function initUserScripts() {
    const sel = document.getElementById('userScriptSelect');
    const btnSave = document.getElementById('btnSaveCustomScript');
    if (!sel || !btnSave) return;

    function refreshSelect() {
        const saved = JSON.parse(localStorage.getItem('setun_saved_scripts') || '{}');
        const keys = Object.keys(saved);
        if (keys.length === 0) {
            sel.style.display = 'none';
            return;
        }
        sel.style.display = 'inline-block';
        sel.innerHTML = '<option value="">-- My Scripts --</option>';
        keys.forEach(k => {
            const opt = document.createElement('option');
            opt.value = k;
            opt.textContent = k;
            sel.appendChild(opt);
        });
    }

    btnSave.addEventListener('click', () => {
        const editor = document.getElementById('basmEditor');
        const text = editor ? editor.value : '';
        if (!text.trim()) return;

        const name = prompt('Enter a name for this B-ASM script:');
        if (!name || !name.trim()) return;

        const saved = JSON.parse(localStorage.getItem('setun_saved_scripts') || '{}');
        saved[name.trim()] = text;
        localStorage.setItem('setun_saved_scripts', JSON.stringify(saved));
        refreshSelect();
        sel.value = name.trim();
    });

    sel.addEventListener('change', (e) => {
        const name = e.target.value;
        if (!name) return;
        const saved = JSON.parse(localStorage.getItem('setun_saved_scripts') || '{}');
        if (saved[name]) {
            const editor = document.getElementById('basmEditor');
            if (editor) editor.value = saved[name];
        }
    });

    refreshSelect();
}

// 5. Polling & Connection Health
async function updateStatus() {
    try {
        const res = await fetch('/api/status');
        const data = await res.json();

        const pill = document.getElementById('connectionStatus');
        const label = document.getElementById('connectionLabel');
        const qCount = document.getElementById('queueCount');

        if (pill && label) {
            pill.classList.remove('status-offline');
            pill.classList.add('status-online');
            const mode = (data.telemetry && data.telemetry.mode) ? `Connected (${data.telemetry.mode})` : 'Connected';
            label.textContent = mode;
        }

        if (qCount) {
            qCount.textContent = data.pendingQueueLength || 0;
        }
    } catch (e) {
        const pill = document.getElementById('connectionStatus');
        const label = document.getElementById('connectionLabel');
        if (pill && label) {
            pill.classList.remove('status-online');
            pill.classList.add('status-offline');
            label.textContent = 'Disconnected';
        }
    }
}

// 6. Global Setup & Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    initTritGrid();
    initUserScripts();

    // Bus Action Buttons
    document.getElementById('btnInjectTrits')?.addEventListener('click', injectTrits);

    document.getElementById('btnCopyBus')?.addEventListener('click', () => {
        const str = getTritString();
        navigator.clipboard.writeText(str).then(() => {
            const btn = document.getElementById('btnCopyBus');
            if (btn) {
                const old = btn.textContent;
                btn.textContent = 'Copied!';
                setTimeout(() => btn.textContent = old, 1200);
            }
        });
    });

    document.getElementById('btnPasteBus')?.addEventListener('click', async () => {
        try {
            const text = await navigator.clipboard.readText();
            if (text && text.trim()) {
                loadTritString(text.trim());
            }
        } catch (e) {
            const input = prompt('Paste 24-trit string:');
            if (input) loadTritString(input.trim());
        }
    });

    document.getElementById('btnInvertBus')?.addEventListener('click', () => {
        for (let i = 0; i < 24; i++) {
            if (trits[i] === 1) trits[i] = -1;
            else if (trits[i] === -1) trits[i] = 1;
        }
        updateTritUI();
    });

    document.getElementById('btnSimplifyBus')?.addEventListener('click', () => {
        for (let i = 0; i < 23; i++) {
            if ((trits[i] === 1 && trits[i+1] === -1) || (trits[i] === -1 && trits[i+1] === 1)) {
                trits[i] = 0;
                trits[i+1] = 0;
                i++;
            }
        }
        updateTritUI();
    });

    // Preset Buttons
    document.querySelectorAll('.preset-tag').forEach(btn => {
        btn.addEventListener('click', () => {
            const key = btn.dataset.preset;
            if (PRESETS[key]) loadTritString(PRESETS[key]);
        });
    });

    // Sample Microcode Selector
    const sampleSelect = document.getElementById('sampleProgSelect');
    sampleSelect?.addEventListener('change', (e) => {
        const key = e.target.value;
        const editor = document.getElementById('basmEditor');
        if (editor && SAMPLE_PROGRAMS[key]) {
            editor.value = SAMPLE_PROGRAMS[key];
        }
    });

    // B-ASM Action Buttons
    document.getElementById('btnUploadScript')?.addEventListener('click', uploadAndRunScript);
    document.getElementById('btnStepScript')?.addEventListener('click', stepScript);

    // Command Dispatcher Form
    const cmdForm = document.getElementById('cmdForm');
    const cmdInput = document.getElementById('cmdInput');
    cmdForm?.addEventListener('submit', (e) => {
        e.preventDefault();
        if (cmdInput && cmdInput.value) {
            sendCommand(cmdInput.value);
            cmdInput.value = '';
        }
    });

    // Chip & Bank Command Buttons
    document.querySelectorAll('.chip-btn, .btn-micro').forEach(chip => {
        chip.addEventListener('click', () => {
            const cmd = chip.dataset.cmd;
            if (!cmd) return;

            if (cmd.startsWith('SAVE ')) {
                const bankId = cmd.split(' ')[1];
                const tritStr = getTritString();
                localStorage.setItem(`setun_bank_${bankId}`, tritStr);
                sendCommand(cmd);
                const oldText = chip.textContent;
                chip.textContent = 'Saved!';
                setTimeout(() => chip.textContent = oldText, 1000);
            } else if (cmd.startsWith('LOAD ')) {
                const bankId = cmd.split(' ')[1];
                const savedTrits = localStorage.getItem(`setun_bank_${bankId}`);
                if (savedTrits && savedTrits.length === 24) {
                    loadTritString(savedTrits);
                }
                sendCommand(cmd);
                const oldText = chip.textContent;
                chip.textContent = 'Loaded!';
                setTimeout(() => chip.textContent = oldText, 1000);
            } else {
                sendCommand(cmd);
            }
        });
    });

    // TPM Security Buttons
    document.getElementById('btnRequestTpm')?.addEventListener('click', () => sendCommand('SIGN 137'));
    document.getElementById('btnRequestPuf')?.addEventListener('click', () => sendCommand('PUF'));

    // Clear Queue Button
    document.getElementById('btnQueueClear')?.addEventListener('click', async () => {
        try {
            await fetch('/api/poll');
            updateStatus();
        } catch (e) {
            console.error(e);
        }
    });

    // Documentation Modal & KaTeX Math Rendering
    const docsModal = document.getElementById('docsModal');
    const btnOpenDocs = document.getElementById('btnOpenDocs');
    const btnCloseDocs = document.getElementById('btnCloseDocs');
    const docsSearch = document.getElementById('docsSearch');
    const docsContent = document.getElementById('docsContent');
    const navItems = document.querySelectorAll('.doc-nav-item');

    function renderMathIfAvailable() {
        if (window.renderMathInElement && docsModal) {
            try {
                window.renderMathInElement(docsModal, {
                    delimiters: [
                        { left: '$$', right: '$$', display: true },
                        { left: '\\[', right: '\\]', display: true },
                        { left: '\\(', right: '\\)', display: false },
                        { left: '$', right: '$', display: false }
                    ],
                    throwOnError: false
                });
            } catch (err) {
                console.warn('KaTeX render note:', err);
            }
        }
    }

    btnOpenDocs?.addEventListener('click', () => {
        if (docsModal) {
            docsModal.style.display = 'flex';
            docsSearch?.focus();
            renderMathIfAvailable();
        }
    });

    btnCloseDocs?.addEventListener('click', () => {
        if (docsModal) docsModal.style.display = 'none';
    });

    docsModal?.addEventListener('click', (e) => {
        if (e.target === docsModal) docsModal.style.display = 'none';
    });

    // Sidebar ScrollSpy Tracking (Highlights current active section as user scrolls)
    if (docsContent) {
        docsContent.addEventListener('scroll', () => {
            const sections = document.querySelectorAll('.doc-section');
            const isAtBottom = docsContent.scrollTop + docsContent.clientHeight >= docsContent.scrollHeight - 40;

            let currentId = null;

            if (isAtBottom && sections.length > 0) {
                currentId = sections[sections.length - 1].getAttribute('id');
            } else {
                sections.forEach(sec => {
                    const top = sec.offsetTop - docsContent.offsetTop;
                    if (docsContent.scrollTop >= top - 80) {
                        currentId = sec.getAttribute('id');
                    }
                });
            }

            if (currentId) {
                navItems.forEach(item => {
                    const href = item.getAttribute('href').substring(1);
                    if (href === currentId) {
                        if (!item.classList.contains('active')) {
                            item.classList.add('active');
                            item.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
                        }
                    } else {
                        item.classList.remove('active');
                    }
                });
            }
        });
    }

    // Instant Search Filter inside Documentation
    docsSearch?.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase().trim();
        const sections = document.querySelectorAll('.doc-section');
        const navLinks = document.querySelectorAll('.doc-nav-item');

        sections.forEach(sec => {
            const text = sec.textContent.toLowerCase();
            const matches = !query || text.includes(query);
            sec.style.display = matches ? 'block' : 'none';
        });

        navLinks.forEach(link => {
            const targetId = link.getAttribute('href').substring(1);
            const sec = document.getElementById(targetId);
            link.style.display = (sec && sec.style.display !== 'none') ? 'flex' : 'none';
        });
    });

    // Code Block Copy Buttons
    document.querySelectorAll('.btn-copy-code').forEach(btn => {
        btn.addEventListener('click', () => {
            const code = btn.dataset.code || btn.closest('.code-card')?.querySelector('.code-block code')?.textContent || '';
            if (code) {
                navigator.clipboard.writeText(code).then(() => {
                    const old = btn.textContent;
                    btn.textContent = 'Copied!';
                    setTimeout(() => btn.textContent = old, 1200);
                });
            }
        });
    });

    // Documentation Sidebar Navigation Click
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            navItems.forEach(n => n.classList.remove('active'));
            item.classList.add('active');

            const targetId = item.getAttribute('href').substring(1);
            const targetSection = document.getElementById(targetId);
            if (targetSection && docsContent) {
                docsContent.scrollTo({
                    top: targetSection.offsetTop - 10,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Global Keyboard Shortcuts
    document.addEventListener('keydown', (e) => {
        // Esc to close docs modal
        if (e.key === 'Escape' && docsModal && docsModal.style.display !== 'none') {
            docsModal.style.display = 'none';
            return;
        }

        // Ctrl+Enter or Cmd+Enter -> Upload & Run Script
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
            e.preventDefault();
            uploadAndRunScript();
            return;
        }

        // Ctrl+K or / (when not in editor) -> Focus Command Dispatcher
        if (((e.ctrlKey || e.metaKey) && e.key === 'k') || (e.key === '/' && document.activeElement.tagName !== 'INPUT' && document.activeElement.tagName !== 'TEXTAREA')) {
            e.preventDefault();
            cmdInput?.focus();
            return;
        }

        // Trit Painting when hovering over cell
        if (hoveredTritIndex !== null && document.activeElement.tagName !== 'INPUT' && document.activeElement.tagName !== 'TEXTAREA') {
            if (e.key === '1' || e.key === '+') {
                trits[hoveredTritIndex] = 1;
                updateTritUI();
            } else if (e.key === '0') {
                trits[hoveredTritIndex] = 0;
                updateTritUI();
            } else if (e.key === '-' || e.key === '2') {
                trits[hoveredTritIndex] = -1;
                updateTritUI();
            }
        }
    });

    // Start Telemetry Polling (every 1 second)
    updateStatus();
    setInterval(updateStatus, 1000);
});
