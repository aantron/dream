let input_form request =
  <html>
    <body>
      Enter some text:
      <%s! Dream.form_tag ~action:"/" request %>
        <input name="text" autofocus>
      </form>
    </body>
  </html>


let results_page messages text =
  let open Tyxml.Html in
  let to_p (category, msg) = p [txt (category ^ " : " ^ msg)] in
  html ( head (title (txt "Flash Messages Demo")) [] )
    ( body @@
        List.map to_p messages @
        [p [txt @@ Option.value text ~default:""]]
    )


let html_to_string html =
  Format.asprintf "%a" (Tyxml.Html.pp ()) html


let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash_messages
  @@ Dream.router [
    Dream.get  "/"
      (fun request ->
         Dream.html (input_form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["text", text] ->
          let () = Dream.put_flash "Info" "Message 1" request in
          let () = Dream.put_flash "Info" "Message 2" request in
          let () = Dream.put_flash "Debug" "Message 3" request in
          let%lwt () = Dream.put_session "text" text request in
          Dream.redirect request "/results"
        | _ ->
          Dream.redirect request "/"
      );

    Dream.get "/results"
      (fun request ->
         let messages = Dream.get_flash request in
         let text = Dream.session "text" request in
         Dream.html @@ html_to_string @@ results_page messages text);
  ]
  @@ Dream.not_found
