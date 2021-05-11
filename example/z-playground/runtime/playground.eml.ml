(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let welcome =
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
  <style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Open Sans, Helvetica Neue, Helvetica, Arial, sans-serif;
    margin: 0 1rem;
  }

  a, a:visited {
    color: blue;
    text-decoration: none;
  }

  a:hover {
    text-decoration: underline;
  }

  @media (min-width: 100px) {
    body > ul:nth-of-type(2) {
      columns: 2;
    }
  }
  </style>
  </head>
  <body>
  <h1>Welcome to the Dream Playground!</h1>
  <p>
    Edit the code to the left, and press <strong>Run</strong> to recompile! Use
    the navigation bar above to visit different paths on your server. Many of
    the <a href="https://github.com/aantron/dream/tree/master/example#readme">
    examples</a> are loaded into the playground. For example, try
    <a href="http://dream.as/1-hello">dream.as/2-middleware</a>.
  </p>
  <p>Links:</p>
  <ul>
    <li><a target="_blank" href="https://github.com/aantron/dream">
      GitHub</a></li>
    <li><a target="_blank" href="https://github.com/aantron/dream/tree/master/example#readme">
      Tutorial</a></li>
    <li><a target="_blank" href="https://aantron.github.io/dream">
      API reference</a></li>
  </ul>
  <p>Loaded examples:</p>
  <ul>
%   Examples.list |> List.iter (fun example ->
      <li><a target="_parent" href="http://dream.as/<%s example %>">
        <%s example %>
      </a></li><% ); %>
  </ul>
  </body>
  </html>
