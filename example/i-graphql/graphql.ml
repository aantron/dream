type user = {
  id : int;
  name : string;
}

let hardcoded_users = [
  {id = 1; name = "alice"};
  {id = 2; name = "bob"};
]

let user =
  Graphql_lwt.Schema.(obj "user"
    ~doc:"A user"
    ~fields:(fun _ -> [
      field "id"
        ~doc:"User id"
        ~typ:(non_null int)
        ~args:Arg.[]
        ~resolve:(fun _ user -> user.id);
      field "name"
        ~doc:"User name"
        ~typ:(non_null string)
        ~args:Arg.[]
        ~resolve:(fun _ user -> user.name);
    ]))

let schema =
  Graphql_lwt.Schema.(schema [
    field "users"
      ~typ:(non_null (list (non_null user)))
      ~args:Arg.[
        arg "id" ~typ:int;
      ]
      ~resolve:(fun _ () id ->
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
  @@ Dream.router [
    Dream.post "/graphql"  (Dream.graphql Lwt.return schema);
    Dream.get  "/graphiql" (Dream.graphiql "/graphql");
  ]
  @@ Dream.not_found
