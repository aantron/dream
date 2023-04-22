(* In OCaml, `begin ... end` is the same as `( ... )` *)
let render_home tasks =
  <html>
  <body>
    <h1>My TODO</h1>
    <% tasks |> List.iter begin fun (name, complete) -> %>
      <p>Task <%s name %>:
        <% if complete then ( %>
          complete!
        <% ) else ( %>
          not complete
        <% ); %>
      </p>
    <% end; %>
  </body>
  </html>


(* You can also begin a line with `%` instead of using `<% ... %>` *)
let render_task tasks task =
  <html>
  <body>
%   (match List.find_opt (fun (task_, _) -> task = task_) tasks with
%   | Some (name, complete) ->
      <h1>TODO task: <%s name %>, complete: <%B complete %></h1>
%   | None -> begin
      <h1>Task not found!</h1>
%   end);
  </body>
  </html>

let tasks = [
  ("write documentation", true);
  ("create examples", true);
  ("publish website", true);
  ("profit", false);
]

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/"
      (fun _ ->
        render_home tasks
        |> Dream.html);


    Dream.get "/:task"
      (fun request ->
        Dream.param request "task"
        |> render_task tasks
        |> Dream.html);

  ]
  @@ Dream.not_found
