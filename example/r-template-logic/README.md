# `r-template-logic`

<br>

Reason control expressions can be used inside Dream templates.  This example
shows a template with a loop written with `List.iter`, an `if`-expression, and
a `switch`-expression.

It's helpful to know that template fragments are written to a buffer
imperatively. That means that template fragments evaluate to `unit`, and the
surrounding Reason code often needs semicolons. Templates also tend to use
`List.iter` rather than `List.map`.

```reason
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
```

<pre><code><b>$ cd example/r-template-logic</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/r-template-logic).

<br>

**See also:**

- [**`7-template`**](../7-template#files) for basic information about templates.
- [**`w-template-logic`**](../w-template-logic#files) for the OCaml version
  of this example.

<br>

[Up to the example index](../#reason)
