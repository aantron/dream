(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* let%expect_test _ =
  Dream.cipher
  |> Dream.cipher_name
  |> print_endline;
  Dream.decryption_ciphers
  |> List.map Dream.cipher_name
  |> List.iter print_endline;
  [%expect {|
    AEAD_AES_256_GCM
    AEAD_AES_256_GCM |}] *)



let secret_1 =
  "abc"

let secret_2 =
  "def"

let nonce_1 =
  "abcdefghijkl"

let nonce_2 =
  "opqrstuvwxyz"

let encrypt secret nonce plaintext =
  Dream__cipher.Cipher.AEAD_AES_256_GCM.test_encrypt ~secret ~nonce plaintext
  |> Dream.to_base64url
  |> print_endline

let%expect_test _ =
  encrypt secret_1 nonce_1 "foo";
  encrypt secret_1 nonce_1 "fon";
  encrypt secret_1 nonce_2 "foo";
  encrypt secret_1 nonce_2 "fon";
  encrypt secret_2 nonce_1 "foo";
  encrypt secret_2 nonce_1 "fon";
  encrypt secret_2 nonce_2 "foo";
  encrypt secret_2 nonce_2 "fon";
  [%expect {|
    AGFiY2RlZmdoaWprbAzPcSEY4l7tSiDwIkk8ZfrFQQk
    AGFiY2RlZmdoaWprbAzPcCTJ-mJdrOKmcXtgqKJjGrI
    AG9wcXJzdHV2d3h5eqAJLHQ4dESlArPNBNiZza-USfI
    AG9wcXJzdHV2d3h5eqAJLXHpbHgV5HGbV-rFAPcyEkk
    AGFiY2RlZmdoaWprbNnUV1LsmdeLx8BgzZbQCzhRhQM
    AGFiY2RlZmdoaWprbNnUVrOLjFEg9zHbIfit_bhMglc
    AG9wcXJzdHV2d3h5etiGF4AINO312f7CMjZrdBQYJDA
    AG9wcXJzdHV2d3h5etiGFmFvIWte6Q953lgWgpQFI2Q |}]



let decrypt secret ciphertext =
  match Dream__cipher.Cipher.AEAD_AES_256_GCM.decrypt ~secret ciphertext with
  | None -> print_endline "None"
  | Some plaintext -> Printf.printf "%S\n" plaintext

let encrypt secret nonce plaintext =
  Dream__cipher.Cipher.AEAD_AES_256_GCM.test_encrypt ~secret ~nonce plaintext

let%expect_test _ =
  decrypt secret_1 (encrypt secret_1 nonce_1 "foo");
  decrypt secret_1 (encrypt secret_1 nonce_2 "foo");
  decrypt secret_1 (encrypt secret_2 nonce_1 "foo");
  decrypt secret_1 (encrypt secret_1 nonce_1 "bar");
  decrypt secret_2 (encrypt secret_1 nonce_1 "foo");
  decrypt secret_1 "";
  decrypt secret_1 "ab";
  decrypt secret_1 "\x00abcdefghijklmnopqrstuvwxyz";
  decrypt secret_1 "\x01abcdefghijklmnopqrstuvwxyz";
  [%expect {|
    "foo"
    "foo"
    None
    "bar"
    None
    None
    None
    None
    None |}]
