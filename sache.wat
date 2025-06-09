;; sache.wat — minimal WebAssembly Text Format
(module
  ;; Exported function that returns an RGB color for the "Sache" block
  (func $get_sache_block_color (result i32)
    i32.const 0x6a3cff ;; purple-ish Sache block!
  )
  (export "get_sache_block_color" (func $get_sache_block_color))
)
;; sache.wat — WASM Text Format
(module
  (memory (export "memory") 1)
  (data (i32.const 0) "Sache Block\00Sache Grass\00Sache Ore\00Mystery Block\00")

  ;; color table: sache (purple), grass (green), ore (yellow), mystery (blue)
  (func $get_block_color (param $type i32) (result i32)
    (local $color i32)
    (block
      (br_table 0 1 2 3 (local.get $type))
      (return (i32.const 0x6a3cff)) ;; sache yellow
      (return (i32.const 0x29d167)) ;; grass green
      (return (i32.const 0xffe14d)) ;; sache ore yellow
      (return (i32.const 0x49bfff)) ;; wood 
    )
    (i32.const 0x222222) ;; fallback gray
  )
  (export "get_block_color" (func $get_block_color))

  ;; returns a pointer to the name string for a block type
  (func $get_block_name (param $type i32) (result i32)
    (local $ptr i32)
    (local.set $ptr
      (select
        (i32.const 32) ;; Sache Grass
        (i32.const 0)  ;; Sache Block
        (i32.eqz (local.get $type))
      )
    )
    (local.set $ptr
      (select
        (i32.const 44) ;; Sache Ore
        (local.get $ptr)
        (i32.eq (local.get $type) (i32.const 2))
      )
    )
    (local.set $ptr
      (select
        (i32.const 55) ;; Mystery Block
        (local.get $ptr)
        (i32.eq (local.get $type) (i32.const 3))
      )
    )
    (local.get $ptr)
  )
  (export "get_block_name" (func $get_block_name))
)
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

function movePlayer(dx, dy) {
  if (wasmInstance) {
    wasmInstance.exports.move_player(dx, dy);
    drawWorld();
  }
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
  if (!wasmInstance) return;
  let moved = false;
  switch (e.key) {
    case "ArrowUp": case "w": movePlayer(0, -1); moved = true; break;
    case "ArrowDown": case "s": movePlayer(0, 1); moved = true; break;
    case "ArrowLeft": case "a": movePlayer(-1, 0); moved = true; break;
    case "ArrowRight": case "d": movePlayer(1, 0); moved = true; break;
    case "1": case "2": case "3": case "4":
      selectedBlock = parseInt(e.key) - 1;
      updateInventory();
      break;
  }
  if (moved) {
    let px = wasmInstance.exports.get_player_x();
    let py = wasmInstance.exports.get_player_y();
    statusDiv.textContent = `Player at (${px},${py}) - Use arrow keys/WASD. Click to place, Shift+Click to break.`;
  }
});

async function loadWasm() {
  const resp = await fetch('sache_all.wasm');
  const bytes = await resp.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {env:{}});
  wasmInstance = instance;
  updateInventory();
  drawWorld();
  statusDiv.textContent = `Player at (${wasmInstance.exports.get_player_x()},${wasmInstance.exports.get_player_y()}) - Use arrow keys/WASD. Click to place, Shift+Click to break.`;
}

loadWasm();
