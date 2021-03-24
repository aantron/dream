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
      ~args:Arg.[]
      ~resolve:(fun _ () -> hardcoded_users);
  ])

let () =
  Dream.run
    (Dream.graphql Lwt.return schema)
