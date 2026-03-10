/**
 * Shoot Signaling Server
 * ─────────────────────────────
 * Run on your VPS with:
 *   npm install ws
 *   node server.js
 *
 * For production (with TLS, required for HTTPS browser exports):
 *   npm install ws
 *   node server.js --cert /etc/letsencrypt/live/yourdomain/fullchain.pem \
 *                  --key  /etc/letsencrypt/live/yourdomain/privkey.pem
 */

const { WebSocketServer } = require("ws");
const https = require("https");
const http = require("http");
const fs = require("fs");
const args = process.argv.slice(2);

// set up server with tls(secure, http) or vunerable(dev, https) 
let server;
const certIndex = args.indexOf("--cert");
const keyIndex  = args.indexOf("--key");

if (certIndex !== -1 && keyIndex !== -1) {
  server = https.createServer({
    cert: fs.readFileSync(args[certIndex + 1]),
    key:  fs.readFileSync(args[keyIndex  + 1]),
  });
  console.log("WSS (TLS) mode");
} else {
  server = http.createServer();
  console.log("WS (dev) mode");
}

const PORT = 9080;
const MAX_ROOMS   = 100;
const MAX_PLAYERS = 2;   



let nextId = 1;
const clients = {};   // id → { ws, room }
const rooms   = {};   // roomCode → { host: id, peers: Set<id> }

// server
const wss = new WebSocketServer({ server });

wss.on("connection", (ws) => {
  const id = nextId++;
  clients[id] = { ws, room: null };

  send(id, { type: "connected", id });
  console.log(`[+] Client ${id} connected  (total: ${Object.keys(clients).length})`);

  ws.on("message", (raw) => {
    let msg;
    try { msg = JSON.parse(raw); }
    catch { return; }
    handleMessage(id, msg);
  });

  ws.on("close", () => {
    const room = clients[id]?.room;
    if (room) leaveRoom(id, room);
    delete clients[id];
    console.log(`[-] Client ${id} disconnected`);
  });
});

//message routing
function handleMessage(id, msg) {
  switch (msg.type) {

    case "create_room": {
      if (Object.keys(rooms).length >= MAX_ROOMS) {
        send(id, { type: "error", message: "Server full" });
        return;
      }
      const code = makeRoomCode();
      rooms[code] = { host: id, peers: new Set([id]) };
      clients[id].room = code;
      send(id, { type: "room_created", code, peer_id: id });
      console.log(`[R] Room ${code} created by ${id}`);
      break;
    }

    case "join_room": {
      const code = msg.code?.toUpperCase();
      if (!rooms[code]) {
        send(id, { type: "error", message: "Room not found" });
        return;
      }
      const room = rooms[code];
      if (room.peers.size >= MAX_PLAYERS) {
        send(id, { type: "error", message: "Room full" });
        return;
      }

      // Tell the newcomer about everyone already in the room
      for (const existingId of room.peers) {
        send(id, { type: "peer_connected", peer_id: existingId });
      }

      // Tell everyone in the room about the newcomer
      broadcastRoom(code, { type: "peer_connected", peer_id: id }, id);

      room.peers.add(id);
      clients[id].room = code;
      send(id, { type: "room_joined", code, peer_id: id });
      console.log(`[R] ${id} joined room ${code}  (${room.peers.size}/${MAX_PLAYERS})`);
      break;
    }

    // WebRTC signals
    case "offer":
    case "answer":
    case "candidate": {
      const target = msg.target;
      if (!clients[target]) return;
      relay(target, { ...msg, source: id });
      break;
    }

    case "start_game": {
      // Only host can broadcast start
      const code = clients[id]?.room;
      if (!code || rooms[code]?.host !== id) return;
      broadcastRoom(code, { type: "start_game" });
      console.log(`[G] Game started in room ${code}`);
      break;
    }
  }
}

// -room helpers 
function leaveRoom(id, code) {
  const room = rooms[code];
  if (!room) return;
  room.peers.delete(id);
  broadcastRoom(code, { type: "peer_disconnected", peer_id: id });
  if (room.peers.size === 0 || room.host === id) {
    // close room if host left or empty
    for (const pid of room.peers) {
      send(pid, { type: "room_closed" });
      if (clients[pid]) clients[pid].room = null;
    }
    delete rooms[code];
    console.log(`[R] Room ${code} closed`);
  }
}

function makeRoomCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code;
  do { code = Array.from({ length: 4 }, () => chars[Math.random() * chars.length | 0]).join(""); }
  while (rooms[code]);
  return code;
}

// ── send helpers 
function send(id, msg) {
  const c = clients[id];
  if (c?.ws.readyState === 1) 
    c.ws.send(JSON.stringify(msg));
}

function relay(id, msg) { send(id, msg); }

function broadcastRoom(code, msg, excludeId = null) {
  for (const pid of (rooms[code]?.peers ?? [])) {
    if (pid !== excludeId) send(pid, msg);
  }
}

// ── Boot ──────────────────────────────────────────────────────────────────────
server.listen(PORT, () => console.log(`Signaling server listening on port ${PORT}`));