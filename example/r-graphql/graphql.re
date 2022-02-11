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
  ]);
