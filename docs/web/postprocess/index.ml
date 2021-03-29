let if_expected = Common.if_expected

open Soup

let method_expected = {|<div class="spec type" id="type-method_">
 <a href="#type-method_" class="anchor"></a><code><span><span class="keyword">type</span> method_</span><span> = <a href="Method_and_status/index.html#type-method_">Method_and_status.method_</a></span></code>
</div>
|}

let method_replacement = {|
<code><span class="keyword">type</span> method_ = [ `GET | `POST | ... ]</code>
|}

let status_expected = {|<div class="spec type" id="type-status">
 <a href="#type-status" class="anchor"></a><code><span><span class="keyword">type</span> status</span><span> = <a href="Method_and_status/index.html#type-status">Method_and_status.status</a></span></code>
</div>
|}

let status_replacement = {|
<pre class="compact"><span class="keyword">type</span> status = [
  | `OK
  | `Moved_Permanently
  | `See_Other
  | `Bad_Request
  | `Not_Found
  | ...
]</pre>
|}

let response_expected = {|<div class="spec value" id="val-response">
 <a href="#val-response" class="anchor"></a><code><span><span class="keyword">val</span> response : <span>?status:<a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-response">response</a></span></code>
</div>
|}

let response_replacement = {|
<pre><span class="keyword">val</span> response :
  <span class="optional">?status:<a href="#type-status">status</a> -&gt;
  ?code:int ->
  ?headers:(string * string) list -&gt;</span>
    string -&gt; <a href="#type-response">response</a>
</pre>
|}

let respond_expected = {|<div class="spec value" id="val-respond">
 <a href="#val-respond" class="anchor"></a><code><span><span class="keyword">val</span> respond : <span>?status:<a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let respond_replacement = {|
<pre><span class="keyword">val</span> respond :
  <span class="optional">?status:<a href="#type-status">status</a> ->
  ?code:int ->
  ?headers:(string * string) list -></span>
    string -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let stream_expected = {|<div class="spec value" id="val-stream">
 <a href="#val-stream" class="anchor"></a><code><span><span class="keyword">val</span> stream : <span>?status:<a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span><span>(<span><a href="#type-response">response</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span>)</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let stream_replacement = {|
<pre><span class="keyword">val</span> stream :
  ?status:<a href="#type-status">status</a> ->
  ?code:int ->
  ?headers:(string * string) list ->
    (<a href="#type-response">response</a> -> unit <a href="#type-promise">promise</a>) -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let empty_expected = {|<div class="spec value" id="val-empty">
 <a href="#val-empty" class="anchor"></a><code><span><span class="keyword">val</span> empty : <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let empty_replacement = {|
<pre><span class="keyword">val</span> empty :
  ?headers:(string * string) list ->
    status -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let add_set_cookie_expected = {|<div class="spec value" id="val-add_set_cookie">
 <a href="#val-add_set_cookie" class="anchor"></a><code><span><span class="keyword">val</span> add_set_cookie : <span>?cookie_prefix:string <span class="arrow">-&gt;</span></span> <span>?encrypt:bool <span class="arrow">-&gt;</span></span> <span>?expires:float <span class="arrow">-&gt;</span></span>
<span>?max_age:float <span class="arrow">-&gt;</span></span> <span>?domain:string <span class="arrow">-&gt;</span></span> <span>?path:string <span class="arrow">-&gt;</span></span> <span>?secure:bool <span class="arrow">-&gt;</span></span> <span>?http_only:bool <span class="arrow">-&gt;</span></span>
<span>?same_site:<span>[ `Strict <span>| `Lax</span> <span>| `None</span> ]</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <span class="arrow">-&gt;</span></span> <a href="#type-response">response</a></span></code>
</div>
|}

let add_set_cookie_replacement = {|
<pre><span class="keyword">val</span> add_set_cookie :
  <span class="optional">?cookie_prefix:string ->
  ?encrypt:bool ->
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[ `Strict | `Lax | `None ] -></span>
    string -> string -> <a href="#type-request">request</a> -> <a href="#type-response">response</a> -> <a href="#type-response">response</a>
</pre>|}

let bigstring_expected = {|<div class="spec type" id="type-bigstring">
 <a href="#type-bigstring" class="anchor"></a><code><span><span class="keyword">type</span> bigstring</span><span> = <span><span>(char,&nbsp;<span class="xref-unresolved">Stdlib</span>.Bigarray.int8_unsigned_elt,&nbsp;<span class="xref-unresolved">Stdlib</span>.Bigarray.c_layout)</span> <span class="xref-unresolved">Stdlib</span>.Bigarray.Array1.t</span></span></code>
</div>
|}

let bigstring_replacement = {|
<pre><span class="keyword">type</span> bigstring =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout)
    Bigarray.Array1.t
</pre>
|}

let next_expected = {|<div class="spec value" id="val-next">
 <a href="#val-next" class="anchor"></a><code><span><span class="keyword">val</span> next : <span>bigstring:<span>(<span><a href="#type-bigstring">bigstring</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>close:<span>(<span>unit <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>exn:<span>(<span>exn <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span>
<span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let next_replacement = {|
<pre><span class="keyword">val</span> next :
  bigstring:(<a href="#type-bigstring">bigstring</a> -> int -> int -> unit) ->
  close:(unit -> unit) ->
  exn:(exn -> unit) ->
  <a href="#type-request">request</a> ->
    unit
</pre>
|}

let write_bigstring_expected = {|<div class="spec value" id="val-write_bigstring">
 <a href="#val-write_bigstring" class="anchor"></a><code><span><span class="keyword">val</span> write_bigstring : <span><a href="#type-bigstring">bigstring</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let write_bigstring_replacement = {|
<pre><span class="keyword">val</span> write_bigstring :
  <a href="#type-bigstring">bigstring</a> -> int -> int -> <a href="#type-response">response</a> -> unit <a href="#type-promise">promise</a>
</pre>
|}

let form_expected = {|<div class="spec type" id="type-form">
 <a href="#type-form" class="anchor"></a><code><span><span class="keyword">type</span> form</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-form.Ok" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Ok" class="anchor"></a><code><span>| </span></code><code><span>`Ok <span class="keyword">of</span> <span><span>(string * string)</span> list</span></span></code>
    </td>
   </tr>
   <tr id="type-form.Expired" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Expired" class="anchor"></a><code><span>| </span></code><code><span>`Expired <span class="keyword">of</span> <span><span>(string * string)</span> list</span> * int64</span></code>
    </td>
   </tr>
   <tr id="type-form.Wrong_session" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Wrong_session" class="anchor"></a><code><span>| </span></code><code><span>`Wrong_session <span class="keyword">of</span> <span><span>(string * string)</span> list</span> * string</span></code>
    </td>
   </tr>
   <tr id="type-form.Invalid_token" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Invalid_token" class="anchor"></a><code><span>| </span></code><code><span>`Invalid_token <span class="keyword">of</span> <span><span>(string * string)</span> list</span></span></code>
    </td>
   </tr>
   <tr id="type-form.Missing_token" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Missing_token" class="anchor"></a><code><span>| </span></code><code><span>`Missing_token <span class="keyword">of</span> <span><span>(string * string)</span> list</span></span></code>
    </td>
   </tr>
   <tr id="type-form.Many_tokens" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Many_tokens" class="anchor"></a><code><span>| </span></code><code><span>`Many_tokens <span class="keyword">of</span> <span><span>(string * string)</span> list</span></span></code>
    </td>
   </tr>
   <tr id="type-form.Not_form_urlencoded" class="anchored">
    <td class="def constructor">
     <a href="#type-form.Not_form_urlencoded" class="anchor"></a><code><span>| </span></code><code><span>`Not_form_urlencoded</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let form_replacement = {|
<pre class="compact"><span class="keyword">type</span> form = [
  | `Ok            <span class="of">of</span> (string * string) list
  | `Expired       <span class="of">of</span> (string * string) list * int64
  | `Wrong_session <span class="of">of</span> (string * string) list * string
  | `Invalid_token <span class="of">of</span> (string * string) list
  | `Missing_token <span class="of">of</span> (string * string) list
  | `Many_tokens   <span class="of">of</span> (string * string) list
  | `Not_form_urlencoded
]
|}

let csrf_result_expected = {|<div class="spec type" id="type-csrf_result">
 <a href="#type-csrf_result" class="anchor"></a><code><span><span class="keyword">type</span> csrf_result</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-csrf_result.Ok" class="anchored">
    <td class="def constructor">
     <a href="#type-csrf_result.Ok" class="anchor"></a><code><span>| </span></code><code><span>`Ok</span></code>
    </td>
   </tr>
   <tr id="type-csrf_result.Expired" class="anchored">
    <td class="def constructor">
     <a href="#type-csrf_result.Expired" class="anchor"></a><code><span>| </span></code><code><span>`Expired <span class="keyword">of</span> int64</span></code>
    </td>
   </tr>
   <tr id="type-csrf_result.Wrong_session" class="anchored">
    <td class="def constructor">
     <a href="#type-csrf_result.Wrong_session" class="anchor"></a><code><span>| </span></code><code><span>`Wrong_session <span class="keyword">of</span> string</span></code>
    </td>
   </tr>
   <tr id="type-csrf_result.Invalid" class="anchored">
    <td class="def constructor">
     <a href="#type-csrf_result.Invalid" class="anchor"></a><code><span>| </span></code><code><span>`Invalid</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let csrf_result_replacement = {|
<pre class="compact"><span class="keyword">type</span> csrf_result = [
  | `Ok
  | `Expired <span class="of">of</span> int64
  | `Wrong_session <span class="of">of</span> string
  | `Invalid
]
|}

let conditional_log_expected = {|<div class="spec type" id="type-conditional_log">
 <a href="#type-conditional_log" class="anchor"></a><code><span><span class="keyword">type</span> <span>('a, 'b) conditional_log</span></span><span> = <span><span>(<span><span>(<span>?request:<a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span><span><span>(<span class="type-var">'a</span>,&nbsp;<span class="xref-unresolved">Stdlib</span>.Format.formatter,&nbsp;unit,&nbsp;<span class="type-var">'b</span>)</span> <span class="xref-unresolved">Stdlib</span>.format4</span> <span class="arrow">-&gt;</span></span> <span class="type-var">'a</span>)</span> <span class="arrow">-&gt;</span></span> <span class="type-var">'b</span>)</span> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let conditional_log_replacement = {|
<pre class="compact"><span class="keyword">type</span> ('a, 'b) conditional_log =
  ((?request:<a href="#type-request">request</a> ->
   ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b) ->
    unit
</pre>
|}

let sub_log_expected = {|<div class="spec type" id="type-sub_log">
 <a href="#type-sub_log" class="anchor"></a><code><span><span class="keyword">type</span> sub_log</span><span> = </span><span>{</span></code>
 <table>
  <tbody>
   <tr id="type-sub_log.error" class="anchored">
    <td class="def record field">
     <a href="#type-sub_log.error" class="anchor"></a><code><span>error : a. <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span>;</span></code>
    </td>
   </tr>
   <tr id="type-sub_log.warning" class="anchored">
    <td class="def record field">
     <a href="#type-sub_log.warning" class="anchor"></a><code><span>warning : a. <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span>;</span></code>
    </td>
   </tr>
   <tr id="type-sub_log.info" class="anchored">
    <td class="def record field">
     <a href="#type-sub_log.info" class="anchor"></a><code><span>info : a. <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span>;</span></code>
    </td>
   </tr>
   <tr id="type-sub_log.debug" class="anchored">
    <td class="def record field">
     <a href="#type-sub_log.debug" class="anchor"></a><code><span>debug : a. <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span>;</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span>}</span></code>
</div>
|}

let sub_log_replacement = {|
<pre class="compact"><span class="keyword">type</span> sub_log = {
  error   <span class="of">:</span> 'a. ('a, unit) <a href="#type-conditional_log">conditional_log</a>;
  warning <span class="of">:</span> 'a. ('a, unit) <a href="#type-conditional_log">conditional_log</a>;
  info    <span class="of">:</span> 'a. ('a, unit) <a href="#type-conditional_log">conditional_log</a>;
  debug   <span class="of">:</span> 'a. ('a, unit) <a href="#type-conditional_log">conditional_log</a>;
}
</pre>|}

let log_level_expected = {|<div class="spec type" id="type-log_level">
 <a href="#type-log_level" class="anchor"></a><code><span><span class="keyword">type</span> log_level</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-log_level.Error" class="anchored">
    <td class="def constructor">
     <a href="#type-log_level.Error" class="anchor"></a><code><span>| </span></code><code><span>`Error</span></code>
    </td>
   </tr>
   <tr id="type-log_level.Warning" class="anchored">
    <td class="def constructor">
     <a href="#type-log_level.Warning" class="anchor"></a><code><span>| </span></code><code><span>`Warning</span></code>
    </td>
   </tr>
   <tr id="type-log_level.Info" class="anchored">
    <td class="def constructor">
     <a href="#type-log_level.Info" class="anchor"></a><code><span>| </span></code><code><span>`Info</span></code>
    </td>
   </tr>
   <tr id="type-log_level.Debug" class="anchored">
    <td class="def constructor">
     <a href="#type-log_level.Debug" class="anchor"></a><code><span>| </span></code><code><span>`Debug</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let log_level_replacement = {|
<code><span class="keyword">type</span> log_level = [ `Error | `Warning | `Info | `Debug ]</code>
|}

let initialize_log_expected = {|<div class="spec value" id="val-initialize_log">
 <a href="#val-initialize_log" class="anchor"></a><code><span><span class="keyword">val</span> initialize_log : <span>?backtraces:bool <span class="arrow">-&gt;</span></span> <span>?async_exception_hook:bool <span class="arrow">-&gt;</span></span> <span>?level:<a href="#type-log_level">log_level</a> <span class="arrow">-&gt;</span></span>
<span>?enable:bool <span class="arrow">-&gt;</span></span> <span>unit <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let initialize_log_replacement = {|
<pre><span class="keyword">val</span> initialize_log :
  <span class="optional">?backtraces:bool ->
  ?async_exception_hook:bool ->
  ?level:<a href="#type-log_level">log_level</a> ->
  ?enable:bool -></span>
    unit -> unit
</pre>|}

let error_expected = {|<div class="spec type" id="type-error">
 <a href="#type-error" class="anchor"></a><code><span><span class="keyword">type</span> error</span><span> = </span><span>{</span></code>
 <table>
  <tbody>
   <tr id="type-error.condition" class="anchored">
    <td class="def record field">
     <a href="#type-error.condition" class="anchor"></a><code><span>condition : <span>[ <span>`Response of <a href="#type-response">response</a></span> <span><span>| `String</span> of string</span> <span><span>| `Exn</span> of exn</span> ]</span>;</span></code>
    </td>
   </tr>
   <tr id="type-error.layer" class="anchored">
    <td class="def record field">
     <a href="#type-error.layer" class="anchor"></a><code><span>layer : <span>[ `TLS <span>| `HTTP</span> <span>| `HTTP2</span> <span>| `WebSocket</span> <span>| `App</span> ]</span>;</span></code>
    </td>
   </tr>
   <tr id="type-error.caused_by" class="anchored">
    <td class="def record field">
     <a href="#type-error.caused_by" class="anchor"></a><code><span>caused_by : <span>[ `Server <span>| `Client</span> ]</span>;</span></code>
    </td>
   </tr>
   <tr id="type-error.request" class="anchored">
    <td class="def record field">
     <a href="#type-error.request" class="anchor"></a><code><span>request : <span><a href="#type-request">request</a> option</span>;</span></code>
    </td>
   </tr>
   <tr id="type-error.response" class="anchored">
    <td class="def record field">
     <a href="#type-error.response" class="anchor"></a><code><span>response : <span><a href="#type-response">response</a> option</span>;</span></code>
    </td>
   </tr>
   <tr id="type-error.client" class="anchored">
    <td class="def record field">
     <a href="#type-error.client" class="anchor"></a><code><span>client : <span>string option</span>;</span></code>
    </td>
   </tr>
   <tr id="type-error.severity" class="anchored">
    <td class="def record field">
     <a href="#type-error.severity" class="anchor"></a><code><span>severity : <a href="#type-log_level">log_level</a>;</span></code>
    </td>
   </tr>
   <tr id="type-error.debug" class="anchored">
    <td class="def record field">
     <a href="#type-error.debug" class="anchor"></a><code><span>debug : bool;</span></code>
    </td>
   </tr>
   <tr id="type-error.will_send_response" class="anchored">
    <td class="def record field">
     <a href="#type-error.will_send_response" class="anchor"></a><code><span>will_send_response : bool;</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span>}</span></code>
</div>
|}

let error_replacement = {|
<pre class="compact"><span class="keyword">type</span> error = {
  condition <span class="of">:</span> [ `Response of <a href="#type-response">response</a> | `String of string | `Exn of exn ];
  layer     <span class="of">:</span> [ `TLS | `HTTP | `HTTP2 | `WebSocket | `App ];
  caused_by <span class="of">:</span> [ `Server | `Client ];
  request   <span class="of">:</span> <a href="#type-request">request</a>  option;
  response  <span class="of">:</span> <a href="#type-response">response</a> option;
  client    <span class="of">:</span> string     option;
  severity  <span class="of">:</span> <a href="#type-log_level">log_level</a>;
  debug     <span class="of">:</span> bool;
  will_send_response <span class="of">:</span> bool;
}
</pre>|}

let run_expected = {|<div class="spec value" id="val-run">
 <a href="#val-run" class="anchor"></a><code><span><span class="keyword">val</span> run : <span>?interface:string <span class="arrow">-&gt;</span></span> <span>?port:int <span class="arrow">-&gt;</span></span> <span>?stop:<span>unit <a href="#type-promise">promise</a></span> <span class="arrow">-&gt;</span></span> <span>?debug:bool <span class="arrow">-&gt;</span></span>
<span>?error_handler:<a href="#type-error_handler">error_handler</a> <span class="arrow">-&gt;</span></span> <span>?secret:string <span class="arrow">-&gt;</span></span> <span>?prefix:string <span class="arrow">-&gt;</span></span>
<span>?https:<span>[ `No <span>| `OpenSSL</span> <span>| `OCaml_TLS</span> ]</span> <span class="arrow">-&gt;</span></span> <span>?certificate_file:string <span class="arrow">-&gt;</span></span>
<span>?key_file:string <span class="arrow">-&gt;</span></span> <span>?certificate_string:string <span class="arrow">-&gt;</span></span> <span>?key_string:string <span class="arrow">-&gt;</span></span>
<span>?greeting:bool <span class="arrow">-&gt;</span></span> <span>?stop_on_input:bool <span class="arrow">-&gt;</span></span> <span>?graceful_stop:bool <span class="arrow">-&gt;</span></span>
<span>?adjust_terminal:bool <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let run_replacement = {|
<pre><span class="keyword">val</span> run :
  <span class="optional">?interface:string ->
  ?port:int ->
  ?stop:unit <a href="#type-promise">promise</a> ->
  ?debug:bool ->
  ?error_handler:<a href="#type-error_handler">error_handler</a> ->
  ?secret:string ->
  ?prefix:string ->
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
  ?greeting:bool ->
  ?stop_on_input:bool ->
  ?graceful_stop:bool ->
  ?adjust_terminal:bool -></span>
    <a href="#type-handler">handler</a> -> unit
</pre>|}

let serve_expected = {|<div class="spec value" id="val-serve">
 <a href="#val-serve" class="anchor"></a><code><span><span class="keyword">val</span> serve : <span>?interface:string <span class="arrow">-&gt;</span></span> <span>?port:int <span class="arrow">-&gt;</span></span> <span>?stop:<span>unit <a href="#type-promise">promise</a></span> <span class="arrow">-&gt;</span></span> <span>?debug:bool <span class="arrow">-&gt;</span></span>
<span>?error_handler:<a href="#type-error_handler">error_handler</a> <span class="arrow">-&gt;</span></span> <span>?secret:string <span class="arrow">-&gt;</span></span> <span>?prefix:string <span class="arrow">-&gt;</span></span>
<span>?https:<span>[ `No <span>| `OpenSSL</span> <span>| `OCaml_TLS</span> ]</span> <span class="arrow">-&gt;</span></span> <span>?certificate_file:string <span class="arrow">-&gt;</span></span>
<span>?key_file:string <span class="arrow">-&gt;</span></span> <span>?certificate_string:string <span class="arrow">-&gt;</span></span> <span>?key_string:string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let serve_replacement = {|
<pre><span class="keyword">val</span> serve :
  <span class="optional">?interface:string ->
  ?port:int ->
  ?stop:unit <a href="#type-promise">promise</a> ->
  ?debug:bool ->
  ?error_handler:<a href="#type-error_handler">error_handler</a> ->
  ?secret:string ->
  ?prefix:string ->
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string -></span>
    <a href="#type-handler">handler</a> -> unit <a href="#type-promise">promise</a>
</pre>|}

let request_expected = {|<div class="spec value" id="val-request">
 <a href="#val-request" class="anchor"></a><code><span><span class="keyword">val</span> request : <span>?client:string <span class="arrow">-&gt;</span></span> <span>?method_:<a href="#type-method_">method_</a> <span class="arrow">-&gt;</span></span> <span>?target:string <span class="arrow">-&gt;</span></span> <span>?version:<span>(int * int)</span>
<span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-request">request</a></span></code>
</div>
|}

let request_replacement = {|
<pre><span class="keyword">val</span> request :
  <span class="optional">?client:string ->
  ?method_:<a href="#type-method_">method_</a> ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list -></span>
    string -> <a href="#type-request">request</a>
</pre>|}

let pretty_print_signatures soup =
  let method_ = soup $ "#type-method_" in
  if_expected
    method_expected
    (fun () -> pretty_print method_)
    (fun () ->
      Soup.replace (method_ $ "> code") (Soup.parse method_replacement));

  let status = soup $ "#type-status" in
  if_expected
    status_expected
    (fun () -> pretty_print status)
    (fun () ->
      Soup.replace (status $ "> code") (Soup.parse status_replacement);
      Soup.add_class "multiline" status);

  let response = soup $ "#val-response" in
  if_expected
    response_expected
    (fun () -> pretty_print response)
    (fun () ->
      Soup.replace (response $ "> code") (Soup.parse response_replacement);
      Soup.add_class "multiline" response);

  let respond = soup $ "#val-respond" in
  if_expected
    respond_expected
    (fun () -> pretty_print respond)
    (fun () ->
      Soup.replace (respond $ "> code") (Soup.parse respond_replacement);
      Soup.add_class "multiline" respond);

  let stream = soup $ "#val-stream" in
  if_expected
    stream_expected
    (fun () -> pretty_print stream)
    (fun () ->
      Soup.replace (stream $ "> code") (Soup.parse stream_replacement);
      Soup.add_class "multiline" stream);

  let empty = soup $ "#val-empty" in
  if_expected
    empty_expected
    (fun () -> pretty_print empty)
    (fun () ->
      Soup.replace (empty $ "> code") (Soup.parse empty_replacement);
      Soup.add_class "multiline" empty);

  let add_set_cookie = soup $ "#val-add_set_cookie" in
  if_expected
    add_set_cookie_expected
    (fun () -> pretty_print add_set_cookie)
    (fun () ->
      Soup.replace
        (add_set_cookie $ "> code")
        (Soup.parse add_set_cookie_replacement);
      Soup.add_class "multiline" add_set_cookie);

  let bigstring = soup $ "#type-bigstring" in
  if_expected
    bigstring_expected
    (fun () -> pretty_print bigstring)
    (fun () ->
      Soup.replace (bigstring $ "> code") (Soup.parse bigstring_replacement);
      Soup.add_class "multiline" bigstring);

  let next = soup $ "#val-next" in
  if_expected
    next_expected
    (fun () -> pretty_print next)
    (fun () ->
      Soup.replace (next $ "> code") (Soup.parse next_replacement);
      Soup.add_class "multiline" next);

  let write_bigstring = soup $ "#val-write_bigstring" in
  if_expected
    write_bigstring_expected
    (fun () -> pretty_print write_bigstring)
    (fun () ->
      Soup.replace
        (write_bigstring $ "> code") (Soup.parse write_bigstring_replacement);
      Soup.add_class "multiline" write_bigstring);

  let form = soup $ "#type-form" in
  if_expected
    form_expected
    (fun () -> pretty_print form)
    (fun () ->
      form $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (form $ "> table") (Soup.parse form_replacement);
      Soup.add_class "multiline" form);

  let csrf_result = soup $ "#type-csrf_result" in
  if_expected
    csrf_result_expected
    (fun () -> pretty_print csrf_result)
    (fun () ->
      csrf_result $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (csrf_result $ "> table")
        (Soup.parse csrf_result_replacement);
      Soup.add_class "multiline" csrf_result);

  let conditional_log = soup $ "#type-conditional_log" in
  if_expected
    conditional_log_expected
    (fun () -> pretty_print conditional_log)
    (fun () ->
      Soup.replace
        (conditional_log $ "> code")
        (Soup.parse conditional_log_replacement);
      Soup.add_class "multiline" conditional_log);

  let sub_log = soup $ "#type-sub_log" in
  if_expected
    sub_log_expected
    (fun () -> pretty_print sub_log)
    (fun () ->
      sub_log $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace
        (sub_log $ "> table")
        (Soup.parse sub_log_replacement);
      Soup.add_class "multiline" sub_log);

  let log_level = soup $ "#type-log_level" in
  if_expected
    log_level_expected
    (fun () -> pretty_print log_level)
    (fun () ->
      log_level $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (log_level $ "> table") (Soup.parse log_level_replacement));

  let initialize_log = soup $ "#val-initialize_log" in
  if_expected
    initialize_log_expected
    (fun () -> pretty_print initialize_log)
    (fun () ->
      Soup.replace
        (initialize_log $ "> code")
        (Soup.parse initialize_log_replacement);
      Soup.add_class "multiline" initialize_log);

  let error = soup $ "#type-error" in
  if_expected
    error_expected
    (fun () -> pretty_print error)
    (fun () ->
      error $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (error $ "> table") (Soup.parse error_replacement);
      Soup.add_class "multiline" error);

  let run = soup $ "#val-run" in
  if_expected
    run_expected
    (fun () -> pretty_print run)
    (fun () ->
      Soup.replace
        (run $ "> code")
        (Soup.parse run_replacement);
      Soup.add_class "multiline" run);

  let serve = soup $ "#val-serve" in
  if_expected
    serve_expected
    (fun () -> pretty_print serve)
    (fun () ->
      Soup.replace
        (serve $ "> code")
        (Soup.parse serve_replacement);
      Soup.add_class "multiline" serve);

  let request = soup $ "#val-request" in
  if_expected
    request_expected
    (fun () -> pretty_print request)
    (fun () ->
      Soup.replace (request $ "> code") (Soup.parse request_replacement);
      Soup.add_class "multiline" request)

let remove_specs soup =
  let selectors = [
    "#module-Method_and_status";
  ] in

  selectors |> List.iter (fun selector ->
    soup $ selector |> Soup.R.parent |> Soup.delete)

let remove_stdlib soup =
  soup $$ ".xref-unresolved:contains(\"Stdlib\")" |> Soup.iter (fun element ->
    begin match Soup.next_sibling element with
    | None -> ()
    | Some next ->
      match Soup.element next with
      | Some _ -> ()
      | None ->
        match Soup.leaf_text next with
        | None -> ()
        | Some s ->
          match s.[0] with
          | '.' ->
            String.sub s 1 (String.length s - 1)
            |> Soup.create_text
            |> Soup.replace next
          | _ | exception _ -> ()
    end;
    delete element;
  )

let () =
  let source = Sys.argv.(1) in
  let destination = Sys.argv.(2) in
  let soup = Soup.(read_file source |> parse) in
  let content = soup $ "div.odoc-content" in

  soup $$ "nav.odoc-toc li > ul" |> Soup.iter delete;

  soup
  $ "nav.odoc-toc"
  |> Soup.prepend_child content;

  pretty_print_signatures soup;
  remove_specs soup;

  let error_template = soup $ "#val-error_template" |> Soup.R.parent in
  let error = soup $ "#type-error" |> Soup.R.parent in
  Soup.prepend_child error error_template;

  Common.add_backing_lines soup;

  remove_stdlib content;

  Soup.(to_string content |> write_file destination)
