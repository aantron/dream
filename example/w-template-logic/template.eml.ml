let render_home tasks =
  <html>
  <body>
%   tasks |> List.iter begin fun (name, complete) ->
      <p>Task <%s name %>:
%       if complete then begin
          complete!
%       end
%       else begin
          not complete.
%       end;
      </p>
%   end;
  </body>
  </html>

let render_task tasks task =
  <html>
  <body>
%   begin match List.assoc_opt task tasks with
%   | Some complete ->
      <p>Task: <%s task %></p>
      <p>Complete: <%B complete %></p>
%   | None ->
      <p>Task not found!</p>
%   end;
  </body>
  </html>

let tasks = [
  ("Write documentation", true);
  ("Create examples", true);
  ("Publish website", true);
  ("Profit", false);
]

let () =
  Dream.run
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
