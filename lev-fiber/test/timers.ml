open Fiber.O
module Timer = Lev_fiber.Timer
module Wheel = Timer.Wheel

let%expect_test "sleep" =
  Lev_fiber.run (Lev.Loop.create ()) ~f:(fun () ->
      print_endline "sleep";
      let+ () = Lev_fiber.Timer.sleepf 0.1 in
      print_endline "awake");
  [%expect {|
    sleep
    awake |}]

let%expect_test "timer wheel start/stop" =
  Lev_fiber.run (Lev.Loop.create ()) ~f:(fun () ->
      let* wheel = Wheel.create ~delay:10. in
      Fiber.fork_and_join_unit
        (fun () ->
          print_endline "wheel: run";
          Wheel.run wheel)
        (fun () ->
          print_endline "wheel: stop";
          Wheel.stop wheel));
  [%expect {|
    wheel: run
    wheel: stop |}]

let%expect_test "timer wheel cancellation" =
  Lev_fiber.run (Lev.Loop.create ()) ~f:(fun () ->
      let* wheel = Wheel.create ~delay:10. in
      Fiber.fork_and_join_unit
        (fun () ->
          let* task = Wheel.task wheel in
          let* () = Wheel.cancel task in
          let* result = Wheel.await task in
          match result with
          | `Ok -> assert false
          | `Cancelled ->
              print_endline "cancellation succeeded";
              Wheel.stop wheel)
        (fun () ->
          print_endline "wheel: stop";
          Wheel.run wheel));
  [%expect {|
    cancellation succeeded
    wheel: stop |}]
