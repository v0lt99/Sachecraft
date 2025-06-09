// main.js for Sachecaft

let wasmInstance;
const statusDiv = document.getElementById('status');
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// Load WASM module
async function loadWasm() {
  statusDiv.textContent = "Loading WebAssembly...";
  const response = await fetch('sache.wasm');
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {
    env: {
      // Insert any imported functions here if needed
      // Example: console_log: (ptr, len) => ...
    }
  });
  wasmInstance = instance;
  statusDiv.textContent = "WASM Loaded! Rendering Sache block...";
  render();
}

// Example: Call a WASM function to get block color (as a demo)
function render() {
  // Clear
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Get a color from WASM (returns RGB packed in an int)
  let colorInt = wasmInstance.exports.get_sache_block_color();
  let r = (colorInt >> 16) & 0xFF;
  let g = (colorInt >> 8) & 0xFF;
  let b = colorInt & 0xFF;

  // Draw a block
  ctx.fillStyle = `rgb(${r},${g},${b})`;
  ctx.fillRect(270, 190, 100, 100);

  // Outline for fun
  ctx.strokeStyle = '#fff';
  ctx.lineWidth = 2;
  ctx.strokeRect(270, 190, 100, 100);

  statusDiv.textContent = "Sache block rendered!";
}
loadWasm()
