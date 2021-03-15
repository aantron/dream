open Soup

let if_expected expected test f =
  let actual = test () in
  if actual = expected then
    f ()
  else begin
    Soup.write_file "actual" actual;
    Printf.ksprintf failwith "Mismatch; wrote %s"
      (Filename.concat (Sys.getcwd ()) "actual")
  end

let response_expected = {|<div class="spec value" id="val-response">
 <a href="#val-response" class="anchor"></a><code><span><span class="keyword">val</span> response : <span>?version:<span>(int * int)</span> <span class="arrow">-&gt;</span></span> <span>?status:<a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span>?reason:string <span class="arrow">-&gt;</span></span>
<span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span>?set_content_length:bool <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-response">response</a></span></code>
</div>
|}

let response_replacement = {|
<pre><code><span class="keyword">val</span> response :
  ?version:int * int -&gt;
  ?status:<a href="#type-status">status</a> -&gt;
  ?reason:string -&gt;
  ?headers:(string * string) list -&gt;
  ?set_content_length:bool -&gt;
  string -&gt;
    <a href="#type-response">response</a>
</code></pre>
|}

let respond_expected = {|<div class="spec value" id="val-respond">
 <a href="#val-respond" class="anchor"></a><code><span><span class="keyword">val</span> respond : <span>?version:<span>(int * int)</span> <span class="arrow">-&gt;</span></span> <span>?status:<a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span>?reason:string <span class="arrow">-&gt;</span></span>
<span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span>?set_content_length:bool <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <span class="xref-unresolved">Lwt</span>.t</span></span></code>
</div>
|}

let respond_replacement = {|
<pre><span class="keyword">val</span> respond :
  ?version:int * int -&gt;
  ?status:<a href="#type-status">status</a> -&gt;
  ?reason:string -&gt;
  ?headers:(string * string) list -&gt;
  ?set_content_length:bool -&gt;
  string -&gt;
    <a href="#type-response">response</a> Lwt.t
</pre>
|}

let pretty_print_signatures soup =
  let response = soup $ "#val-response" in
  if_expected
    response_expected
    (fun () -> pretty_print response)
    (fun () ->
      Soup.replace (response $ "> code") (Soup.parse response_replacement));

  let respond = soup $ "#val-respond" in
  if_expected
    respond_expected
    (fun () -> pretty_print respond)
    (fun () ->
      Soup.replace (respond $ "> code") (Soup.parse respond_replacement))

let () =
  let source = Sys.argv.(1) in
  let destination = Sys.argv.(2) in

  let soup = Soup.(read_file source |> parse) in

  let content = soup $ "div.odoc-content" in

  soup
  $ "nav.odoc-toc"
  |> Soup.prepend_child content;

  let preamble = Soup.create_element ~id:"pp-preamble" "div" in
  soup
  $$ "header.odoc-preamble > h1 ~ *"
  |> iter (Soup.append_child preamble);
  Soup.prepend_child content preamble;

  pretty_print_signatures soup;

  Soup.(to_string content |> write_file destination)
