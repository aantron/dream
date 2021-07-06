# `r-graphql`

<br>

Most of this example defines a GraphQL schema using
[ocaml-graphql-server](https://github.com/andreas/ocaml-graphql-server#readme).
Then, it's [one line](https://aantron.github.io/dream/#val-graphql) to serve
the schema from Dream, and a second line to serve
[GraphiQL](https://github.com/graphql/graphiql/tree/main/packages/graphiql#readme)
to explore it!

```reason
type user = {
  id: int,
  name: string,
};

let hardcoded_users = [
  {id: 1, name: "alice"},
  {id: 2, name: "bob"},
];

let user =
  Graphql_lwt.Schema.(
    obj("user", ~fields=_info =>
      [
        field("id", ~typ=non_null(int), ~args=Arg.[], ~resolve=(_info, user) =>
          user.id
        ),
        field(
          "name", ~typ=non_null(string), ~args=Arg.[], ~resolve=(_info, user) =>
          user.name
        ),
      ]
    )
  );

let schema =
  Graphql_lwt.Schema.(
    schema([
      field(
        "users",
        ~typ=non_null(list(non_null(user))),
        ~args=Arg.[arg("id", ~typ=int)],
        ~resolve=(_info, (), id) => {
        switch (id) {
        | None => hardcoded_users
        | Some(id') =>
          switch (List.find_opt(({id, _}) => id == id', hardcoded_users)) {
          | None => []
          | Some(user) => [user]
          }
        }
      }),
    ])
  );

let default_query =
  "{\\n  users {\\n    name\\n    id\\n  }\\n}\\n";

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referrer_check
  @@ Dream.router([
    Dream.any("/graphql", Dream.graphql(Lwt.return, schema)),
    Dream.get("/", Dream.graphiql(~default_query, "/graphql")),
  ])
  @@ Dream.not_found;
```

<pre><code><b>$ cd example/r-graphql</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Visit [http://localhost:8080](http://localhost:8080)
[[playground](http://dream.as/r-graphql)], and you can interact with the schema:

![GraphiQL](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/graphiql.png)

<br>

**See also:**

- [**`i-graphql`**](../i-graphql#files), the OCaml version of this example, for
  some more discussion.
- [**`w-graphql-subscription`**](../w-graphql-subscription#files) for GraphQL
  subscriptions.

<br>

[Up to the example index](../#reason)
