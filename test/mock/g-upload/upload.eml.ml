let post =
  "POST / HTTP/1.1\r\n\
Host: http://localhost:8080\r\n\
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/110.0\r\n\
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8\r\n\
Accept-Language: en,de;q=0.5\r\n\
Accept-Encoding: gzip, deflate, br\r\n\
Content-Type: multipart/form-data; boundary=---------------------------625375598897756021854574453\r\n\
Content-Length: 49912627\r\n\
\r\n\
"

let home request =
  <html>
  <body>
    <form method="POST" action="/" enctype="multipart/form-data">
      <%s! Dream.csrf_tag request %>
      <input name="files" type="file" multiple>
      <button>Submit!</button>
    </form>
  </body>
  </html>

let report files =
  <html>
  <body>
%   files |> List.iter begin fun (name, content) ->
%     let name =
%       match name with
%       | None -> "None"
%       | Some name -> name
%     in
      <p><%s name %>, <%i String.length content %> bytes</p>
%   end;
  </body>
  </html>

let () =
  Eio_main.run @@ fun env ->
  let net = Eio_mock.Net.make "Mocked network" in
  let socket =  Eio_mock.Net.listening_socket "Mocked socket" in
  let flow = Eio_mock.Flow.make "Mocked flow" in
  Eio_mock.Flow.on_read flow [
    `Return post;
    `Return post;
    `Return post;
  ];

  let unresolved, _ = Eio.Promise.create () in
  let sockaddr_stream : Eio.Net.Sockaddr.stream = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8080) in
  Eio_mock.Handler.seq socket#on_accept [
    `Return (flow, sockaddr_stream);
    (* No further connections are coming in but the socket is still open *)
    `Await unresolved;
  ];
  Eio_mock.Net.on_listen net [`Return socket];
  let env_mocked = object
    method clock = env#clock
    method secure_random = env#secure_random
    method net = net
  end in
  let module Http = Dream__http.Http in
  Eio.traceln "Running";
  Dream.serve ~net ~builtins:false
  @@ fun request ->
  Eio.traceln "Starting read";
  Dream_pure.Message.read (Dream_pure.Message.server_stream request) |> ignore;
  Eio.traceln "Ending read";
  failwith "Success"
