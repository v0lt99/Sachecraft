(module
  (memory (export "memory") 1)
  ;; World: 20x15 grid, each cell 1 byte
  (global $world_ptr (mut i32) (i32.const 0))
  (global $player_x (mut i32) (i32.const 10))
  (global $player_y (mut i32) (i32.const 7))

  ;; Block IDs: 0 = Sache, 1 = Grass, 2 = Ore, 3 = Mystery, 4 = Air

  ;; Initialize world (called once)
  (func $init_world
    (local $x i32) (local $y i32) (local $off i32)
    (loop $yloop
      (local.set $x (i32.const 0))
      (loop $xloop
        ;; Ground layer: grass, others air, ore/mystery random
        (local.set $off (i32.add (i32.mul (local.get $y) (i32.const 20)) (local.get $x)))
        (if (i32.eq (local.get $y) (i32.const 14))
          (then ;; bottom layer = sache grass
            (i32.store8 (local.get $off) (i32.const 1))
          )
          (else
            (if (i32.eq (local.get $y) (i32.const 13))
              (then ;; second-to-bottom = sache ore/mystery/sache/grass random
                (i32.store8 (local.get $off)
                  (i32.rem_u (i32.add (local.get $x) (local.get $y) (i32.const 2)) (i32.const 4))
                )
              )
              (else
                (i32.store8 (local.get $off) (i32.const 4)) ;; air
              )
            )
          )
        )
        (local.set $x (i32.add (local.get $x) (i32.const 1)))
        (br_if $xloop (i32.lt_s (local.get $x) (i32.const 20)))
      )
      (local.set $y (i32.add (local.get $y) (i32.const 1)))
      (br_if $yloop (i32.lt_s (local.get $y) (i32.const 15)))
    )
  )
  (start $init_world)

  ;; get_block(x, y) -> i32
  (func $get_block (param $x i32) (param $y i32) (result i32)
    (local $off i32)
    (if (i32.or (i32.lt_s (local.get $x) (i32.const 0))
                (i32.ge_s (local.get $x) (i32.const 20))
                (i32.lt_s (local.get $y) (i32.const 0))
                (i32.ge_s (local.get $y) (i32.const 15)))
      (then (return (i32.const 4))) ;; return air for out of bounds
    )
    (local.set $off (i32.add (i32.mul (local.get $y) (i32.const 20)) (local.get $x)))
    (i32.load8_u (local.get $off))
  )
  (export "get_block" (func $get_block))

  ;; set_block(x, y, id)
  (func $set_block (param $x i32) (param $y i32) (param $id i32)
    (local $off i32)
    (if (i32.or (i32.lt_s (local.get $x) (i32.const 0))
                (i32.ge_s (local.get $x) (i32.const 20))
                (i32.lt_s (local.get $y) (i32.const 0))
                (i32.ge_s (local.get $y) (i32.const 15)))
      (then (return))
    )
    (local.set $off (i32.add (i32.mul (local.get $y) (i32.const 20)) (local.get $x)))
    (i32.store8 (local.get $off) (local.get $id))
  )
  (export "set_block" (func $set_block))

  ;; Player movement with collision (can't walk through non-air)
  (func $move_player (param $dx i32) (param $dy i32)
    (local $nx i32)
    (local $ny i32)
    (local.set $nx (i32.add (global.get $player_x) (local.get $dx)))
    (local.set $ny (i32.add (global.get $player_y) (local.get $dy)))
    ;; bounds check
    (if (i32.or (i32.lt_s (local.get $nx) (i32.const 0))
                (i32.ge_s (local.get $nx) (i32.const 20))
                (i32.lt_s (local.get $ny) (i32.const 0))
                (i32.ge_s (local.get $ny) (i32.const 15)))
      (then (return))
    )
    ;; collision check (must be air)
    (local $off i32)
    (local.set $off (i32.add (i32.mul (local.get $ny) (i32.const 20)) (local.get $nx)))
    (if (i32.ne (i32.load8_u (local.get $off)) (i32.const 4)) ;; not air
      (then (return))
    )
    (global.set $player_x (local.get $nx))
    (global.set $player_y (local.get $ny))
  )
  (export "move_player" (func $move_player))

  (func $get_player_x (result i32)
    (global.get $player_x)
  )
  (func $get_player_y (result i32)
    (global.get $player_y)
  )
  (export "get_player_x" (func $get_player_x))
  (export "get_player_y" (func $get_player_y))
)
