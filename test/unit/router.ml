(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let (-:) name f = Alcotest.test_case name `Quick f



let tests = "router", [
]
