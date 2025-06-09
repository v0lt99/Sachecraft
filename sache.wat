;; sache.wat — minimal WebAssembly Text Format
(module
  ;; Exported function that returns an RGB color for the "Sache" block
  (func $get_sache_block_color (result i32)
    i32.const 0x6a3cff ;; purple-ish Sache block!
  )
  (export "get_sache_block_color" (func $get_sache_block_color))
)
