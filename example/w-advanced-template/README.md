# `w-advanced-template`

<br>

Dream templates allow for interleaving any control structures with your template code. This example shows how to do this with if statements, list iterations, and pattern matching. Although it may seem intuitive that the code somehow 'returns' the template, in reality the HTML generation happens in an imperative style. This means that any code within the template must evaluate to `unit`, and so the semicolons in this example are not optional. We use `List.iter` instead of `List.map` for a similar reason. 

```ocaml
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
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/"
      (fun _ ->
        render_home tasks
        |> Dream.html);
        

    Dream.get "/:task"
      (fun request ->
        Dream.param "task" request
        |> render_task tasks
        |> Dream.html);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ cd example/w-advanced-template</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/w-advanced-template).

<br>

**See also:**

- [**`w-template**](../w-template) for more information about templates.
- [**`r-advanced-template**](../r-advanced-template) for the Reason syntax version of this example.

<br>

[Up to the example index](../#examples)
