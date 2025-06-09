let wasmInstance;
const statusDiv = document.getElementById('status');
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

function render() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  let x = wasmInstance.exports.get_player_x();
  let y = wasmInstance.exports.get_player_y();

  ctx.fillStyle = "#6a3cff";
  ctx.fillRect(x, y, 40, 40);
}

async function loadWasm() {
  const response = await fetch('sache_move.wasm');
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, { env: {} });
  wasmInstance = instance;

  render();

  window.addEventListener('keydown', e => {
    switch(e.key) {
      case "ArrowUp": wasmInstance.exports.move_player(0, -10); break;
      case "ArrowDown": wasmInstance.exports.move_player(0, 10); break;
      case "ArrowLeft": wasmInstance.exports.move_player(-10, 0); break;
      case "ArrowRight": wasmInstance.exports.move_player(10, 0); break;
      default: return;
    }
    render();
  });
}

loadWasm();
<div id="controls">
    <button onclick="setBlockType(0)">Sache Stone</button>
    <button onclick="setBlockType(1)">Grass</button>
    <button onclick="setBlockType(2)">Sache Ore</button>
    <button onclick="setBlockType(3)">wood</button>
  </div>
  <canvas id="gameCanvas" width="640" height="480"></canvas>
  <div id="status">Loading...</div>
  <script src="main.js"></script>
</body>
</html>
