# `e-json`

<br>

<!-- TODO Add ppx_deriving example. -->

JSON handling is a bit awkward in OCaml at the present time, and Dream will look
into improving it in its first few releases. The example below shows manual
JSON handling with [Yojson](https://github.com/ocaml-community/yojson#readme).
It can also be greatly simplified with
[ppx_yojson_conv](https://github.com/janestreet/ppx_yojson_conv#readme).

```ocaml
let to_json request =

  match Dream.header "Content-Type" request with
  | Some "application/json" ->

    let%lwt body = Dream.body request in

    begin match Yojson.Basic.from_string body with
    | exception _ -> Lwt.return None
    | json -> Lwt.return (Some json)
    end

  | _ -> Lwt.return None

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referer_check
  @@ Dream.router [

    Dream.post "/"
      (fun request ->
        match%lwt to_json request with
        | None -> Dream.empty `Bad_Request
        | Some json ->

          let maybe_message =
            Yojson.Basic.Util.(member "message" json |> to_string_option) in
          match maybe_message with
          | None -> Dream.empty `Bad_Request
          | Some message ->

            `String message
            |> Yojson.Basic.to_string
            |> Dream.respond ~headers:["Content-Type", "application/json"]);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./json.exe</b></code></pre>

<br>

This example expects JSON of the form `{"message": "some-message"}`, and echoes
the message as a JSON string. Let's test it immediately with both curl and
[HTTPie](https://httpie.io/):

<pre><b>$ curl http://localhost:8080 \
    -H "Origin: http://localhost:8080" \
    -H "Host: localhost:8080" \
    -H "Content-Type: application/json" \
    --data '{"message": "foo"}'</b>

"foo"

<b>$ echo '{"message": "foo"}' | \
    http POST :8080 Origin:http://localhost:8080 Host:localhost:8080</b>

HTTP/1.1 200 OK
Content-Length: 5
Content-Type: application/json

"foo"
</pre>

<br>

## Security

[`Dream.origin_referer_check`](https://aantron.github.io/dream/#val-origin_referer_check)
implements the
[OWASP Verifying Origin With Standard Headers](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#verifying-origin-with-standard-headers)
CSRF protection technique. It doesn't protect `GET` requests, so they shouldn't
do mutations. It also isn't good enough for cross-origin usage in its current
form. But it is enough to do AJAX in small and medium web apps without the need
for [generating tokens](https://aantron.github.io/dream/#csrf-tokens).

This technique relies on that the browser will send matching `Origin:` (or
`Referer:`) and `Host:` headers to the Web app for a genuine request, while,
for a cross-site request, `Origin:` and `Host:` will not match &mdash;
`Origin:` will be the other site or `null`. Try varying the headers in the
`curl` and `http` commands to see the check in action, rejecting your nefarious
requests!

<br>
<br>

**Next steps:**

- [**`f-static`**](../f-static#files) serves static files from the local
  file system.
- [**`g-upload`**](../g-upload#files) receives files from an upload form.

<br>

[Up to the tutorial index](../#readme)

