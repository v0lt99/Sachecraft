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
