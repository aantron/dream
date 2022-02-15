# `w-template-logic`

<br>

OCaml control expressions can be used inside Dream templates.  This example
shows a template with a loop written with `List.iter`, an `if`-expression, and
a `match`-expression.

It's helpful to know that template fragments are written to a buffer
imperatively. That means that template fragments evaluate to `unit`, and the
surrounding OCaml code often needs semicolons. Templates also tend to use
`List.iter` rather than `List.map`.

```ocaml
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
```

<pre><code><b>$ cd example/w-template-logic</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/w-template-logic).

<br>

**See also:**

- [**`7-template`**](../7-template#files) for more information about templates.
- [**`r-template-logic`**](../r-template-logic#files) for the Reason syntax
  version of this example.

<br>

[Up to the example index](../#examples)
