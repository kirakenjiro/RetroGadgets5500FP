// ====================
// 5500FP SETUN 24: NOTION-STYLED HTTP & UDP BRIDGE SERVER
// Ultra-low latency bidirectional hardware polling queue & live telemetry hub
// ====================

const http = require('http');
const dgram = require('dgram');
const fs = require('fs');
const path = require('path');

const HTTP_PORT = 8080;
const UDP_PORT  = 8081;

// Thread-safe FIFO in-memory command queue
const commandQueue = [];
let lastGadgetHeartbeat = 0;
let gadgetTelemetry = {
    connected: false,
    trits: "000000000000000000000000",
    mode: "BOOT",
    qProb: [0.333, 0.333, 0.333],
    purity: 1.0,
    netQ: 0,
    docked: false,
    lastSeen: "Never"
};

// Optional UDP Broadcast Socket for legacy fallback
const udpServer = dgram.createSocket('udp4');
udpServer.bind(UDP_PORT, () => {
    console.log(`[UDP] Broadcast listener ready on port ${UDP_PORT}`);
});

function broadcastUDP(msg) {
    const buf = Buffer.from(msg);
    udpServer.send(buf, 0, buf.length, 8082, '127.0.0.1', (err) => {
        if (err && err.code !== 'ENETUNREACH') {
            // Ignore offline fallback errors
        }
    });
}

function queueCommand(payload) {
    commandQueue.push(payload);
    broadcastUDP(payload);
    console.log(`[Queue] Added (${commandQueue.length} pending): ${payload.substring(0, 32)}`);
}

const MIME_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
    // CORS headers for local development
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    const url = req.url.split('?')[0];

    // ====================
    // GADGET IN-GAME ENDPOINTS (Called by Lua Wifi0)
    // ====================

    // 1. In-game HTTP Poll: Wifi0:WebGet("http://127.0.0.1:8080/api/poll")
    if (req.method === 'GET' && url === '/api/poll') {
        lastGadgetHeartbeat = Date.now();
        gadgetTelemetry.connected = true;
        gadgetTelemetry.lastSeen = new Date().toLocaleTimeString();

        if (commandQueue.length > 0) {
            const nextCmd = commandQueue.shift();
            console.log(`[HTTP Poll -> Gadget Dispatched]: ${nextCmd}`);
            res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end(nextCmd);
        } else {
            res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end("IDLE");
        }
        return;
    }

    // 2. In-game Telemetry Ingestion: Wifi0:WebPostData("http://127.0.0.1:8080/api/telemetry", jsonStr)
    if (req.method === 'POST' && (url === '/api/telemetry' || url === '/api/status')) {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            lastGadgetHeartbeat = Date.now();
            gadgetTelemetry.connected = true;
            gadgetTelemetry.lastSeen = new Date().toLocaleTimeString();
            try {
                const parsed = JSON.parse(body);
                Object.assign(gadgetTelemetry, parsed);
                console.log(`[Telemetry Ingested]: Mode=${gadgetTelemetry.mode || '?'} Trits=${(gadgetTelemetry.trits || '').substring(0, 12)}...`);
            } catch (e) {
                gadgetTelemetry.rawStatus = body;
            }
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end("ACK");
        });
        return;
    }

    // ====================
    // WEB DASHBOARD API ENDPOINTS (Called by browser UI)
    // ====================

    // Telemetry & Connection Query
    if (req.method === 'GET' && (url === '/api/telemetry' || url === '/api/status')) {
        const isOnline = (Date.now() - lastGadgetHeartbeat) < 8000;
        gadgetTelemetry.connected = isOnline;
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            online: isOnline,
            pendingQueueLength: commandQueue.length,
            pendingCommands: commandQueue.length,
            telemetry: gadgetTelemetry
        }));
        return;
    }

    // Inject 24-trit word
    if (req.method === 'POST' && (url === '/api/trits' || url === '/api/inject-trits')) {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                const trits = (data.trits || '').padEnd(24, '0').substring(0, 24);
                queueCommand(`TRITS:${trits}`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, injected: trits, queueLength: commandQueue.length }));
            } catch (e) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: e.message }));
            }
        });
        return;
    }

    // Execute Terminal CLI command
    if (req.method === 'POST' && (url === '/api/command' || url === '/api/exec-command')) {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                const cmd = (data.command || '').trim();
                if (cmd) queueCommand(`EXEC:${cmd}`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, command: cmd, queueLength: commandQueue.length }));
            } catch (e) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: e.message }));
            }
        });
        return;
    }

    // Upload multi-line B-ASM microcode program
    if (req.method === 'POST' && url === '/api/upload-script') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                const lines = (data.script || '').split('\n');
                let progLine = 1;
                for (let rawLine of lines) {
                    const clean = rawLine.trim();
                    if (!clean || clean.startsWith('--') || clean.startsWith('#')) continue;
                    queueCommand(`EXEC:BSET ${progLine} ${clean}`);
                    progLine++;
                }
                if (data.autoRun) {
                    queueCommand(`EXEC:RUN 1`);
                }
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, linesLoaded: progLine - 1, queueLength: commandQueue.length }));
            } catch (e) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: e.message }));
            }
        });
        return;
    }

    // TPM Signature Request
    if (req.method === 'POST' && url === '/api/tpm-sign') {
        queueCommand(`TPM:SIGN`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, status: 'TPM requested', queueLength: commandQueue.length }));
        return;
    }

    // Clear Pending Command Queue
    if (req.method === 'POST' && (url === '/api/clear-queue' || url === '/api/poll')) {
        commandQueue.length = 0;
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, cleared: true }));
        return;
    }

    // ====================
    // STATIC ASSET SERVING
    // ====================
    let filePath = path.join(__dirname, 'public', url === '/' ? 'index.html' : url);
    const ext = path.extname(filePath);

    fs.readFile(filePath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/plain' });
                res.end('404 Not Found');
            } else {
                res.writeHead(500, { 'Content-Type': 'text/plain' });
                res.end(`500 Server Error: ${err.code}`);
            }
        } else {
            res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'text/plain' });
            res.end(content);
        }
    });
});

server.listen(HTTP_PORT, '0.0.0.0', () => {
    console.log(`====================`);
    console.log(` 5500FP SETUN 24: NOTION-STYLED HTTP & UDP BRIDGE SERVER `);
    console.log(` HTTP Bridge listening on http://localhost:${HTTP_PORT}`);
    console.log(` Web Studio UI served at  http://localhost:${HTTP_PORT}/index.html`);
    console.log(` Retro Gadgets Poll URI:  http://127.0.0.1:${HTTP_PORT}/api/poll`);
    console.log(` Live Telemetry Post URI: http://127.0.0.1:${HTTP_PORT}/api/telemetry`);
    console.log(`====================`);
});
