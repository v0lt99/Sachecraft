const TILE_SIZE = 32;
const GRID_W = 20;
const GRID_H = 15;
const BLOCKS = [
  {name: "Sache Block", color: "#6a3cff"},
  {name: "Sache Grass", color: "#29d167"},
  {name: "Sache Ore", color: "#ffe14d"},
  {name: "Mystery Block", color: "#49bfff"},
  {name: "Air", color: "#222"}
];

let wasmInstance;
let selectedBlock = 0;
let keys = {};

const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
const statusDiv = document.getElementById('status');
const inventoryDiv = document.getElementById('inventory');

function updateInventory() {
  inventoryDiv.innerHTML = '';
  BLOCKS.slice(0, BLOCKS.length-1).forEach((block, i) => {
    const btn = document.createElement('button');
    btn.textContent = `${i+1}: ${block.name}`;
    btn.className = 'inv-btn' + (i === selectedBlock ? ' selected' : '');
    btn.onclick = () => { selectedBlock = i; updateInventory(); };
    inventoryDiv.appendChild(btn);
  });
}

function drawWorld() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  // Draw world blocks
  for (let y = 0; y < GRID_H; y++) {
    for (let x = 0; x < GRID_W; x++) {
      let id = wasmInstance.exports.get_block(x, y);
      ctx.fillStyle = BLOCKS[id]?.color || "#000";
      ctx.fillRect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
      ctx.strokeStyle = "#333";
      ctx.strokeRect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
    }
  }
  // Draw player
  let px = wasmInstance.exports.get_player_x();
  let py = wasmInstance.exports.get_player_y();
  ctx.fillStyle = "#fff";
  ctx.fillRect(px * TILE_SIZE + 6, py * TILE_SIZE + 6, TILE_SIZE - 12, TILE_SIZE - 12);
  ctx.strokeStyle = "#000";
  ctx.strokeRect(px * TILE_SIZE + 6, py * TILE_SIZE + 6, TILE_SIZE - 12, TILE_SIZE - 12);
}

function gameLoop() {
  if (!wasmInstance) return;
  let left = keys["ArrowLeft"] || keys["a"];
  let right = keys["ArrowRight"] || keys["d"];
  if (left) wasmInstance.exports.move_player(-1, 0);
  if (right) wasmInstance.exports.move_player(1, 0);
  // Jumping
  if (keys[" "] && wasmInstance.exports.can_jump()) {
    wasmInstance.exports.jump();
  }
  // Gravity/tick
  wasmInstance.exports.tick();
  drawWorld();
  requestAnimationFrame(gameLoop);
}

function placeBlock(x, y, blockId) {
  if (wasmInstance) {
    wasmInstance.exports.set_block(x, y, blockId);
    drawWorld();
  }
}

function breakBlock(x, y) {
  if (wasmInstance) {
    wasmInstance.exports.set_block(x, y, 4); // 4 = Air
    drawWorld();
  }
}

canvas.addEventListener('mousedown', e => {
  const rect = canvas.getBoundingClientRect();
  const mx = Math.floor((e.clientX - rect.left) / TILE_SIZE);
  const my = Math.floor((e.clientY - rect.top) / TILE_SIZE);
  if (mx >= 0 && mx < GRID_W && my >= 0 && my < GRID_H) {
    if (e.shiftKey) breakBlock(mx, my);
    else placeBlock(mx, my, selectedBlock);
  }
});

window.addEventListener('keydown', e => {
  keys[e.key] = true;
  if (!wasmInstance) return;
  switch (e.key) {
    case "1": case "2": case "3": case "4":
      selectedBlock = parseInt(e.key) - 1;
      updateInventory();
      break;
  }
});
window.addEventListener('keyup', e => {
  keys[e.key] = false;
});

async function loadWasm() {
  const resp = await fetch('sache_ultimate.wasm');
  const bytes = await resp.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {env:{}});
  wasmInstance = instance;
  updateInventory();
  drawWorld();
  statusDiv.textContent = `Player at (${wasmInstance.exports.get_player_x()},${wasmInstance.exports.get_player_y()}) - Use arrow keys/WASD to move, space to jump. Click to place, Shift+Click to break.`;
  requestAnimationFrame(gameLoop);
}

// ... (all your previous code above)

let activeOrb = null; // {x, y, dx, dy, targetX, targetY}

function shootOrb(targetX, targetY) {
  // Player position (center of player tile)
  let px = wasmInstance.exports.get_player_x() + 0.5;
  let py = wasmInstance.exports.get_player_y() + 0.5;
  // Direction vector
  let dx = targetX + 0.5 - px;
  let dy = targetY + 0.5 - py;
  let dist = Math.sqrt(dx * dx + dy * dy);
  dx /= dist; dy /= dist;
  let speed = 0.5; // tiles per frame
  activeOrb = {x: px, y: py, dx: dx * speed, dy: dy * speed, targetX, targetY};
}

function updateOrb() {
  if (!activeOrb) return;
  // Move orb
  activeOrb.x += activeOrb.dx;
  activeOrb.y += activeOrb.dy;
  // Check if reached or passed target
  let tx = activeOrb.targetX + 0.5, ty = activeOrb.targetY + 0.5;
  let prev = Math.hypot(activeOrb.x - tx, activeOrb.y - ty);
  if (prev < 0.6) {
    // Explode in WASM
    wasmInstance.exports.explode(activeOrb.targetX, activeOrb.targetY);
    activeOrb = null;
    drawWorld();
  }
}

function drawWorld() {
  // ... (your existing code for drawing blocks and player)
  // Draw orb if it's active
  if (activeOrb) {
    ctx.beginPath();
    ctx.arc(activeOrb.x * TILE_SIZE, activeOrb.y * TILE_SIZE, TILE_SIZE / 3, 0, 2 * Math.PI);
    ctx.fillStyle = "#ff44ee";
    ctx.fill();
    ctx.strokeStyle = "#fff";
    ctx.stroke();
  }
}

// Replace canvas mousedown handler:
canvas.addEventListener('mousedown', e => {
  const rect = canvas.getBoundingClientRect();
  const mx = Math.floor((e.clientX - rect.left) / TILE_SIZE);
  const my = Math.floor((e.clientY - rect.top) / TILE_SIZE);
  if (mx >= 0 && mx < GRID_W && my >= 0 && my < GRID_H) {
    if (e.button === 2 && selectedBlock === 4) {
      // Sache Orb right-click: shoot orb toward (mx, my)
      if (!activeOrb) shootOrb(mx, my);
    } else if (e.shiftKey) {
      breakBlock(mx, my);
    } else if (e.button === 0 && selectedBlock !== 4) {
      placeBlock(mx, my, selectedBlock);
    }
  }
});
canvas.addEventListener('contextmenu', e => e.preventDefault());

// In your game loop, call updateOrb() before drawWorld():
function gameLoop() {
  if (!wasmInstance) return;
  let left = keys["ArrowLeft"] || keys["a"];
  let right = keys["ArrowRight"] || keys["d"];
  if (left) wasmInstance.exports.move_player(-1, 0);
  if (right) wasmInstance.exports.move_player(1, 0);
  if (keys[" "] && wasmInstance.exports.can_jump()) {
    wasmInstance.exports.jump();
  }
  wasmInstance.exports.tick();
  updateOrb();
  drawWorld();
  requestAnimationFrame(gameLoop);
}

loadWasm()
