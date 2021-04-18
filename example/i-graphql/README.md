# `i-graphql`

<br>

Most of this example defines a GraphQL schema using
[ocaml-graphql-server](https://github.com/andreas/ocaml-graphql-server#readme).
Then, it's [one line](https://aantron.github.io/dream/#val-graphql) to serve
the schema from Dream, and a second line to serve
[GraphiQL](https://github.com/graphql/graphiql/tree/main/packages/graphiql#readme)
to explore it!

```ocaml
type user = {id : int; name : string}

let hardcoded_users = [
  {id = 1; name = "alice"};
  {id = 2; name = "bob"};
]

let user =
  Graphql_lwt.Schema.(obj "user"
    ~fields:(fun _info -> [
      field "id"
        ~typ:(non_null int)
        ~args:Arg.[]
        ~resolve:(fun _info user -> user.id);
      field "name"
        ~typ:(non_null string)
        ~args:Arg.[]
        ~resolve:(fun _info user -> user.name);
    ]))

let schema =
  Graphql_lwt.Schema.(schema [
    field "users"
      ~typ:(non_null (list (non_null user)))
      ~args:Arg.[arg "id" ~typ:int]
      ~resolve:(fun _info () id ->
        match id with
        | None -> hardcoded_users
        | Some id' ->
          match List.find_opt (fun {id; _} -> id = id') hardcoded_users with
          | None -> []
          | Some user -> [user]);
  ])

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referer_check
  @@ Dream.router [
    Dream.any "/graphql"  (Dream.graphql Lwt.return schema);
    Dream.get "/graphiql" (Dream.graphiql "/graphql");
  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./graphql.exe</b></code></pre>

<br>

Visit [http://localhost:8080/graphiql](http://localhost:8080/graphiql), and you
can interact with the schema:

![GraphiQL](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/graphiql.png)

<br>

Even though this toy schema does not define any
[mutations](https://github.com/andreas/ocaml-graphql-server/blob/d615cbb164d4ddfdc2efeb246a198dfe114adf24/graphql/src/graphql_intf.ml#L66),
the example uses
[`Dream.origin_referer_check`](https://aantron.github.io/dream/#val-origin_referer_check)
to protect future extensions of it
[against CSRF](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#identifying-source-origin-via-originreferer-header). See example
[**`e-json`**](../e-json#security) for more details on how this works.

See example [**`w-graphql-subscription`**](../w-graphql-subscription#files) for
an example with a GraphQL subscription.

<br>

**Next steps:**

- [**`j-stream`**](../j-stream#files) streams response bodies to clients.
- [**`k-websocket`**](../k-websocket#files) sends and receives messages over a
  WebSocket.

<br>

[Up to the tutorial index](../#readme)
