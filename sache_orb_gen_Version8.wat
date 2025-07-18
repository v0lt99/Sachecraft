(module
  (memory (export "memory") 1)
  (global $player_x (mut i32) (i32.const 10))
  (global $player_y (mut i32) (i32.const 7))
  (global $player_vy (mut i32) (i32.const 0))
  (global $on_ground (mut i32) (i32.const 0))

  ;; Block IDs: 0 = Sache, 1 = Grass, 2 = Ore, 3 = Mystery, 4 = Sache Orb, 5 = Air

  ;; Simple pseudo-random number generator based on x, y, and a seed
  (func $rand (param $x i32) (param $y i32) (result i32)
    (local $v i32)
    (local.set $v (i32.add (i32.mul (local.get $x) (i32.const 374761393))
                          (i32.mul (local.get $y) (i32.const 668265263))))
    (local.set $v (i32.xor (local.get $v) (i32.const 0x5a5a5a5a)))
    (local.set $v (i32.xor (local.get $v) (i32.shr_u (local.get $v) (i32.const 13))))
    (local.set $v (i32.mul (local.get $v) (i32.const 1274126177)))
    (local.set $v (i32.and (local.get $v) (i32.const 0x7FFFFFFF)))
    (local.get $v)
  )

  ;; World generation
  (func $init_world
    (local $x i32) (local $y i32) (local $off i32) (local $r i32)
    (loop $yloop
      (local.set $x (i32.const 0))
      (loop $xloop
        (local.set $off (i32.add (i32.mul (local.get $y) (i32.const 20)) (local.get $x)))
        (if (i32.eq (local.get $y) (i32.const 14))
          (then
            (i32.store8 (local.get $off) (i32.const 1)) ;; bottom = grass
          )
          (else
            (if (i32.lt_s (local.get $y) (i32.const 3))
              (then (i32.store8 (local.get $off) (i32.const 5))) ;; top rows = air
              (else
                ;; Generate terrain using randomness
                (local.set $r (call $rand (local.get $x) (local.get $y)))
                (if (i32.lt_u (i32.rem_u (local.get $r) (i32.const 100)) (i32.const 5))
                  (then (i32.store8 (local.get $off) (i32.const 2))) ;; ore
                  (else
                    (if (i32.lt_u (i32.rem_u (local.get $r) (i32.const 100)) (i32.const 10))
                      (then (i32.store8 (local.get $off) (i32.const 3))) ;; mystery
                      (else
                        (if (i32.lt_u (i32.rem_u (local.get $r) (i32.const 100)) (i32.const 30))
                          (then (i32.store8 (local.get $off) (i32.const 0))) ;; sache block
                          (else (i32.store8 (local.get $off) (i32.const 5))) ;; air
                        )
                      )
                    )
                  )
                )
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

  ;; get/set block
  (func $get_block (param $x i32) (param $y i32) (result i32)
    (local $off i32)
    (if (i32.or (i32.lt_s (local.get $x) (i32.const 0))
                (i32.ge_s (local.get $x) (i32.const 20))
                (i32.lt_s (local.get $y) (i32.const 0))
                (i32.ge_s (local.get $y) (i32.const 15)))
      (then (return (i32.const 5)))
    )
    (local.set $off (i32.add (i32.mul (local.get $y) (i32.const 20)) (local.get $x)))
    (i32.load8_u (local.get $off))
  )
  (export "get_block" (func $get_block))
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

  ;; Player movement (horizontal, collision)
  (func $move_player (param $dx i32) (param $dy i32)
    (local $nx i32)
    (local $ny i32)
    (local.set $nx (i32.add (global.get $player_x) (local.get $dx)))
    (local.set $ny (i32.add (global.get $player_y) (local.get $dy)))
    (if (i32.or (i32.lt_s (local.get $nx) (i32.const 0))
                (i32.ge_s (local.get $nx) (i32.const 20))
                (i32.lt_s (local.get $ny) (i32.const 0))
                (i32.ge_s (local.get $ny) (i32.const 15)))
      (then (return))
    )
    (local $off i32)
    (local.set $off (i32.add (i32.mul (local.get $ny) (i32.const 20)) (local.get $nx)))
    (if (i32.ne (i32.load8_u (local.get $off)) (i32.const 5))
      (then (return))
    )
    (global.set $player_x (local.get $nx))
    (global.set $player_y (local.get $ny))
  )
  (export "move_player" (func $move_player))

  ;; Gravity/jumping/game tick
  (func $tick
    (local $px i32) (local $py i32) (local $ny i32) (local $off i32)
    (local.set $px (global.get $player_x))
    (local.set $py (global.get $player_y))
    (if (i32.eq (global.get $player_vy) (i32.const 0))
      (then
        (local.set $ny (i32.add (local.get $py) (i32.const 1)))
        (if (i32.and (i32.lt_s (local.get $ny) (i32.const 15))
              (i32.ne (i32.load8_u (i32.add (i32.mul (local.get $ny) (i32.const 20)) (local.get $px))) (i32.const 5)))
          (then (global.set $on_ground (i32.const 1)))
          (else (global.set $on_ground (i32.const 0)))
        )
      )
    )
    (if (i32.eq (global.get $on_ground) (i32.const 0))
      (then (global.set $player_vy (i32.add (global.get $player_vy) (i32.const 1))))
      (else (global.set $player_vy (i32.const 0)))
    )
    (if (i32.ne (global.get $player_vy) (i32.const 0))
      (then
        (local.set $ny (i32.add (local.get $py) (global.get $player_vy)))
        (if (i32.lt_s (local.get $ny) (i32.const 0)) (then (local.set $ny (i32.const 0))))
        (if (i32.ge_s (local.get $ny) (i32.const 15)) (then (local.set $ny (i32.const 14))))
        (block
          (loop
            (if (i32.or (i32.eq (local.get $py) (local.get $ny))
                        (i32.ne (i32.load8_u (i32.add (i32.mul (local.get $ny) (i32.const 20)) (local.get $px))) (i32.const 5)))
              (then (br 1))
            )
            (if (i32.lt_s (local.get $ny) (local.get $py))
              (then (local.set $ny (i32.add (local.get $ny) (i32.const 1))))
              (else (local.set $ny (i32.sub (local.get $ny) (i32.const 1))))
            )
            (br 0)
          )
        )
        (global.set $player_y (local.get $ny))
        (local.set $off (i32.add (i32.mul (i32.add (local.get $ny) (i32.const 1)) (i32.const 20)) (local.get $px)))
        (if (i32.and (i32.lt_s (i32.add (local.get $ny) (i32.const 1)) (i32.const 15))
                 (i32.ne (i32.load8_u (local.get $off)) (i32.const 5)))
          (then (global.set $player_vy (i32.const 0)) (global.set $on_ground (i32.const 1)))
        )
      )
    )
  )
  (export "tick" (func $tick))

  (func $can_jump (result i32)
    (global.get $on_ground)
  )
  (export "can_jump" (func $can_jump))

  (func $jump
    (if (i32.eq (global.get $on_ground) (i32.const 1))
      (then
        (global.set $player_vy (i32.const -2))
        (global.set $on_ground (i32.const 0))
      )
    )
  )
  (export "jump" (func $jump))

  (func $explode (param $cx i32) (param $cy i32)
    (local $x i32) (local $y i32)
    (local.set $y (i32.sub (local.get $cy) (i32.div_s (i32.const 10) (i32.const 2))))
    (block $outY
      (loop $loopY
        (local.set $x (i32.sub (local.get $cx) (i32.div_s (i32.const 20) (i32.const 2))))
        (block $outX
          (loop $loopX
            (call $set_block (local.get $x) (local.get $y) (i32.const 5)) ;; Air
            (local.set $x (i32.add (local.get $x) (i32.const 1)))
            (br_if $loopX (i32.lt_s (local.get $x) (i32.add (local.get $cx) (i32.div_s (i32.const 20) (i32.const 2)))))
          )
        )
        (local.set $y (i32.add (local.get $y) (i32.const 1)))
        (br_if $loopY (i32.lt_s (local.get $y) (i32.add (local.get $cy) (i32.div_s (i32.const 10) (i32.const 2)))))
      )
    )
  )
  (export "explode" (func $explode))

  (func $get_player_x (result i32)
    (global.get $player_x)
  )
  (func $get_player_y (result i32)
    (global.get $player_y)
  )
  (export "get_player_x" (func $get_player_x))
  (export "get_player_y" (func $get_player_y))
)