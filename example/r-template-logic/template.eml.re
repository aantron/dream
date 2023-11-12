let render_home = tasks => {
  <html>
  <body>
%   tasks |> List.iter(((name, complete)) => {
      <p>Task <%s name %>:
%       if (complete) {
          complete!
%       } else {
          not complete
%       };
      </p>
%   });
  </body>
  </html>
};

let render_task = (tasks, task) => {
  <html>
  <body>
%   (switch (List.assoc_opt(task, tasks)) {
%   | Some(complete) =>
      <p>Task: <%s task %></p>
      <p>Complete: <%B complete %></p>
%   | None =>
      <p>Task not found!</p>
%   });
  </body>
  </html>
};

let tasks = [
  ("Write documentation", true),
  ("Create examples", true),
  ("Publish website", true),
  ("Profit", false),
];

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/", _ =>
      render_home(tasks)
      |> Dream.html),

    Dream.get("/:task", request =>
      Dream.param(request, "task")
      |> render_task(tasks)
      |> Dream.html),

  ]);
