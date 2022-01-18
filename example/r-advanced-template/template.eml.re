let render_home = tasks => {
  <html>
  <body>
    <h1>My TODO</h1>
    <% tasks |> List.iter(((name, complete)) => { %>
      <p>Task <%s name %>:
        <% if (complete) { %>
          complete!
        <% } else { %>
          not complete
        <% }; %>
      </p>
    <% }); %>
  </body>
  </html>
};


// You can begin a line with `%` instead of using `<% ... %>`
let render_task = (tasks, task) => {
  <html>
  <body>
%   (switch (List.find_opt(((task_, _)) => task == task_, tasks)) {
%   | Some((name, complete)) =>
      <h1>TODO task: <%s name %>, complete: <%B complete %></h1>
%   | None =>
      <h1>Task not found!</h1>
%   });
  </body>
  </html>
};

let tasks = [
  ("write documentation", true),
  ("create examples", true),
  ("publish website", true),
  ("profit", false),
];

let () =
  Eio_main.run @@ env =>
  Dream.run(env)
  @@ Dream.logger
  @@ Dream.router([
    Dream.get("/", _ => render_home(tasks) |> Dream.html),
    Dream.get("/:task", request =>
      Dream.param(request, "task") |> render_task(tasks) |> Dream.html
    ),
  ])
  @@ Dream.not_found;

