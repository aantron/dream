let if_expected = Common.if_expected

open Soup

let method_expected = {|<div class="spec type" id="type-method_">
 <a href="#type-method_" class="anchor"></a><code><span><span class="keyword">type</span> method_</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-method_.GET" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.GET" class="anchor"></a><code><span>| </span></code><code><span>`GET</span></code>
    </td>
   </tr>
   <tr id="type-method_.POST" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.POST" class="anchor"></a><code><span>| </span></code><code><span>`POST</span></code>
    </td>
   </tr>
   <tr id="type-method_.PUT" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.PUT" class="anchor"></a><code><span>| </span></code><code><span>`PUT</span></code>
    </td>
   </tr>
   <tr id="type-method_.DELETE" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.DELETE" class="anchor"></a><code><span>| </span></code><code><span>`DELETE</span></code>
    </td>
   </tr>
   <tr id="type-method_.HEAD" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.HEAD" class="anchor"></a><code><span>| </span></code><code><span>`HEAD</span></code>
    </td>
   </tr>
   <tr id="type-method_.CONNECT" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.CONNECT" class="anchor"></a><code><span>| </span></code><code><span>`CONNECT</span></code>
    </td>
   </tr>
   <tr id="type-method_.OPTIONS" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.OPTIONS" class="anchor"></a><code><span>| </span></code><code><span>`OPTIONS</span></code>
    </td>
   </tr>
   <tr id="type-method_.TRACE" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.TRACE" class="anchor"></a><code><span>| </span></code><code><span>`TRACE</span></code>
    </td>
   </tr>
   <tr id="type-method_.PATCH" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.PATCH" class="anchor"></a><code><span>| </span></code><code><span>`PATCH</span></code>
    </td>
   </tr>
   <tr id="type-method_.Method" class="anchored">
    <td class="def constructor">
     <a href="#type-method_.Method" class="anchor"></a><code><span>| </span></code><code><span>`Method <span class="keyword">of</span> string</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let method_replacement = {|
<pre class="compact"><span class="keyword">type</span> method_ = [
  | `GET
  | `POST
  | `PUT
  | `DELETE
  | `HEAD
  | `CONNECT
  | `OPTIONS
  | `TRACE
  | `PATCH
  | `Method <span class="keyword">of</span> string
]
</pre>
|}

let informational_expected = {|<div class="spec type" id="type-informational">
 <a href="#type-informational" class="anchor"></a><code><span><span class="keyword">type</span> informational</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-informational.Continue" class="anchored">
    <td class="def constructor">
     <a href="#type-informational.Continue" class="anchor"></a><code><span>| </span></code><code><span>`Continue</span></code>
    </td>
   </tr>
   <tr id="type-informational.Switching_Protocols" class="anchored">
    <td class="def constructor">
     <a href="#type-informational.Switching_Protocols" class="anchor"></a><code><span>| </span></code><code><span>`Switching_Protocols</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let informational_replacement = {|
<pre class="compact"><span class="keyword">type</span> informational = [
  | `Continue
  | `Switching_Protocols
]
</pre>
|}

let success_expected = {|<div class="spec type" id="type-successful">
 <a href="#type-successful" class="anchor"></a><code><span><span class="keyword">type</span> successful</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-successful.OK" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.OK" class="anchor"></a><code><span>| </span></code><code><span>`OK</span></code>
    </td>
   </tr>
   <tr id="type-successful.Created" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.Created" class="anchor"></a><code><span>| </span></code><code><span>`Created</span></code>
    </td>
   </tr>
   <tr id="type-successful.Accepted" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.Accepted" class="anchor"></a><code><span>| </span></code><code><span>`Accepted</span></code>
    </td>
   </tr>
   <tr id="type-successful.Non_Authoritative_Information" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.Non_Authoritative_Information" class="anchor"></a><code><span>| </span></code><code><span>`Non_Authoritative_Information</span></code>
    </td>
   </tr>
   <tr id="type-successful.No_Content" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.No_Content" class="anchor"></a><code><span>| </span></code><code><span>`No_Content</span></code>
    </td>
   </tr>
   <tr id="type-successful.Reset_Content" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.Reset_Content" class="anchor"></a><code><span>| </span></code><code><span>`Reset_Content</span></code>
    </td>
   </tr>
   <tr id="type-successful.Partial_Content" class="anchored">
    <td class="def constructor">
     <a href="#type-successful.Partial_Content" class="anchor"></a><code><span>| </span></code><code><span>`Partial_Content</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let success_replacement = {|
<pre class="compact"><span class="keyword">type</span> successful = [
  | `OK
  | `Created
  | `Accepted
  | `Non_Authoritative_Information
  | `No_Content
  | `Reset_Content
  | `Partial_Content
]</pre>
|}

let redirect_expected = {|<div class="spec type" id="type-redirection">
 <a href="#type-redirection" class="anchor"></a><code><span><span class="keyword">type</span> redirection</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-redirection.Multiple_Choices" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.Multiple_Choices" class="anchor"></a><code><span>| </span></code><code><span>`Multiple_Choices</span></code>
    </td>
   </tr>
   <tr id="type-redirection.Moved_Permanently" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.Moved_Permanently" class="anchor"></a><code><span>| </span></code><code><span>`Moved_Permanently</span></code>
    </td>
   </tr>
   <tr id="type-redirection.Found" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.Found" class="anchor"></a><code><span>| </span></code><code><span>`Found</span></code>
    </td>
   </tr>
   <tr id="type-redirection.See_Other" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.See_Other" class="anchor"></a><code><span>| </span></code><code><span>`See_Other</span></code>
    </td>
   </tr>
   <tr id="type-redirection.Not_Modified" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.Not_Modified" class="anchor"></a><code><span>| </span></code><code><span>`Not_Modified</span></code>
    </td>
   </tr>
   <tr id="type-redirection.Temporary_Redirect" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.Temporary_Redirect" class="anchor"></a><code><span>| </span></code><code><span>`Temporary_Redirect</span></code>
    </td>
   </tr>
   <tr id="type-redirection.Permanent_Redirect" class="anchored">
    <td class="def constructor">
     <a href="#type-redirection.Permanent_Redirect" class="anchor"></a><code><span>| </span></code><code><span>`Permanent_Redirect</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let redirect_replacement = {|
<pre class="compact"><span class="keyword">type</span> redirection = [
  | `Multiple_Choices
  | `Moved_Permanently
  | `Found
  | `See_Other
  | `Not_Modified
  | `Temporary_Redirect
  | `Permanent_Redirect
]</pre>
|}

let client_expected = {|<div class="spec type" id="type-client_error">
 <a href="#type-client_error" class="anchor"></a><code><span><span class="keyword">type</span> client_error</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-client_error.Bad_Request" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Bad_Request" class="anchor"></a><code><span>| </span></code><code><span>`Bad_Request</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Unauthorized" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Unauthorized" class="anchor"></a><code><span>| </span></code><code><span>`Unauthorized</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Payment_Required" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Payment_Required" class="anchor"></a><code><span>| </span></code><code><span>`Payment_Required</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Forbidden" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Forbidden" class="anchor"></a><code><span>| </span></code><code><span>`Forbidden</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Not_Found" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Not_Found" class="anchor"></a><code><span>| </span></code><code><span>`Not_Found</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Method_Not_Allowed" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Method_Not_Allowed" class="anchor"></a><code><span>| </span></code><code><span>`Method_Not_Allowed</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Not_Acceptable" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Not_Acceptable" class="anchor"></a><code><span>| </span></code><code><span>`Not_Acceptable</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Proxy_Authentication_Required" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Proxy_Authentication_Required" class="anchor"></a><code><span>| </span></code><code><span>`Proxy_Authentication_Required</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Request_Timeout" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Request_Timeout" class="anchor"></a><code><span>| </span></code><code><span>`Request_Timeout</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Conflict" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Conflict" class="anchor"></a><code><span>| </span></code><code><span>`Conflict</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Gone" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Gone" class="anchor"></a><code><span>| </span></code><code><span>`Gone</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Length_Required" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Length_Required" class="anchor"></a><code><span>| </span></code><code><span>`Length_Required</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Precondition_Failed" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Precondition_Failed" class="anchor"></a><code><span>| </span></code><code><span>`Precondition_Failed</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Payload_Too_Large" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Payload_Too_Large" class="anchor"></a><code><span>| </span></code><code><span>`Payload_Too_Large</span></code>
    </td>
   </tr>
   <tr id="type-client_error.URI_Too_Long" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.URI_Too_Long" class="anchor"></a><code><span>| </span></code><code><span>`URI_Too_Long</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Unsupported_Media_Type" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Unsupported_Media_Type" class="anchor"></a><code><span>| </span></code><code><span>`Unsupported_Media_Type</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Range_Not_Satisfiable" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Range_Not_Satisfiable" class="anchor"></a><code><span>| </span></code><code><span>`Range_Not_Satisfiable</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Expectation_Failed" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Expectation_Failed" class="anchor"></a><code><span>| </span></code><code><span>`Expectation_Failed</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Misdirected_Request" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Misdirected_Request" class="anchor"></a><code><span>| </span></code><code><span>`Misdirected_Request</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Too_Early" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Too_Early" class="anchor"></a><code><span>| </span></code><code><span>`Too_Early</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Upgrade_Required" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Upgrade_Required" class="anchor"></a><code><span>| </span></code><code><span>`Upgrade_Required</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Precondition_Required" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Precondition_Required" class="anchor"></a><code><span>| </span></code><code><span>`Precondition_Required</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Too_Many_Requests" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Too_Many_Requests" class="anchor"></a><code><span>| </span></code><code><span>`Too_Many_Requests</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Request_Header_Fields_Too_Large" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Request_Header_Fields_Too_Large" class="anchor"></a><code><span>| </span></code><code><span>`Request_Header_Fields_Too_Large</span></code>
    </td>
   </tr>
   <tr id="type-client_error.Unavailable_For_Legal_Reasons" class="anchored">
    <td class="def constructor">
     <a href="#type-client_error.Unavailable_For_Legal_Reasons" class="anchor"></a><code><span>| </span></code><code><span>`Unavailable_For_Legal_Reasons</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let client_replacement = {|
<pre class="compact"><span class="keyword">type</span> client_error = [
  | `Bad_Request
  | `Unauthorized
  | `Payment_Required
  | `Forbidden
  | `Not_Found
  | `Method_Not_Allowed
  | `Not_Acceptable
  | `Proxy_Authentication_Required
  | `Request_Timeout
  | `Conflict
  | `Gone
  | `Length_Required
  | `Precondition_Failed
  | `Payload_Too_Large
  | `URI_Too_Long
  | `Unsupported_Media_Type
  | `Range_Not_Satisfiable
  | `Expectation_Failed
  | `Misdirected_Request
  | `Too_Early
  | `Upgrade_Required
  | `Precondition_Required
  | `Too_Many_Requests
  | `Request_Header_Fields_Too_Large
  | `Unavailable_For_Legal_Reasons
]</pre>
|}

let server_expected = {|<div class="spec type" id="type-server_error">
 <a href="#type-server_error" class="anchor"></a><code><span><span class="keyword">type</span> server_error</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-server_error.Internal_Server_Error" class="anchored">
    <td class="def constructor">
     <a href="#type-server_error.Internal_Server_Error" class="anchor"></a><code><span>| </span></code><code><span>`Internal_Server_Error</span></code>
    </td>
   </tr>
   <tr id="type-server_error.Not_Implemented" class="anchored">
    <td class="def constructor">
     <a href="#type-server_error.Not_Implemented" class="anchor"></a><code><span>| </span></code><code><span>`Not_Implemented</span></code>
    </td>
   </tr>
   <tr id="type-server_error.Bad_Gateway" class="anchored">
    <td class="def constructor">
     <a href="#type-server_error.Bad_Gateway" class="anchor"></a><code><span>| </span></code><code><span>`Bad_Gateway</span></code>
    </td>
   </tr>
   <tr id="type-server_error.Service_Unavailable" class="anchored">
    <td class="def constructor">
     <a href="#type-server_error.Service_Unavailable" class="anchor"></a><code><span>| </span></code><code><span>`Service_Unavailable</span></code>
    </td>
   </tr>
   <tr id="type-server_error.Gateway_Timeout" class="anchored">
    <td class="def constructor">
     <a href="#type-server_error.Gateway_Timeout" class="anchor"></a><code><span>| </span></code><code><span>`Gateway_Timeout</span></code>
    </td>
   </tr>
   <tr id="type-server_error.HTTP_Version_Not_Supported" class="anchored">
    <td class="def constructor">
     <a href="#type-server_error.HTTP_Version_Not_Supported" class="anchor"></a><code><span>| </span></code><code><span>`HTTP_Version_Not_Supported</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let server_replacement = {|
<pre class="compact"><span class="keyword">type</span> server_error = [
  | `Internal_Server_Error
  | `Not_Implemented
  | `Bad_Gateway
  | `Service_Unavailable
  | `Gateway_Timeout
  | `HTTP_Version_Not_Supported
]</pre>
|}

let standard_expected = {|<div class="spec type" id="type-standard_status">
 <a href="#type-standard_status" class="anchor"></a><code><span><span class="keyword">type</span> standard_status</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-standard_status.informational" class="anchored">
    <td class="def type">
     <a href="#type-standard_status.informational" class="anchor"></a><code><span>| </span></code><code><span><a href="#type-informational">informational</a></span></code>
    </td>
   </tr>
   <tr id="type-standard_status.successful" class="anchored">
    <td class="def type">
     <a href="#type-standard_status.successful" class="anchor"></a><code><span>| </span></code><code><span><a href="#type-successful">successful</a></span></code>
    </td>
   </tr>
   <tr id="type-standard_status.redirection" class="anchored">
    <td class="def type">
     <a href="#type-standard_status.redirection" class="anchor"></a><code><span>| </span></code><code><span><a href="#type-redirection">redirection</a></span></code>
    </td>
   </tr>
   <tr id="type-standard_status.client_error" class="anchored">
    <td class="def type">
     <a href="#type-standard_status.client_error" class="anchor"></a><code><span>| </span></code><code><span><a href="#type-client_error">client_error</a></span></code>
    </td>
   </tr>
   <tr id="type-standard_status.server_error" class="anchored">
    <td class="def type">
     <a href="#type-standard_status.server_error" class="anchor"></a><code><span>| </span></code><code><span><a href="#type-server_error">server_error</a></span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let standard_replacement = {|
<pre class="compact"><span class="keyword">type</span> standard_status = [
  | <a href="#type-informational">informational</a>
  | <a href="#type-successful">successful</a>
  | <a href="#type-redirection">redirection</a>
  | <a href="#type-client_error">client_error</a>
  | <a href="#type-server_error">server_error</a>
]</pre>
|}

let status_expected = {|<div class="spec type" id="type-status">
 <a href="#type-status" class="anchor"></a><code><span><span class="keyword">type</span> status</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-status.standard_status" class="anchored">
    <td class="def type">
     <a href="#type-status.standard_status" class="anchor"></a><code><span>| </span></code><code><span><a href="#type-standard_status">standard_status</a></span></code>
    </td>
   </tr>
   <tr id="type-status.Status" class="anchored">
    <td class="def constructor">
     <a href="#type-status.Status" class="anchor"></a><code><span>| </span></code><code><span>`Status <span class="keyword">of</span> int</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let status_replacement = {|
<pre class="compact"><span class="keyword">type</span> status = [
  | <a href="#type-standard_status">standard_status</a>
  | `Status <span class="keyword">of</span> int
]</pre>
|}

let pretty_print_signatures soup =
  let method_ = soup $ "#type-method_" in
  if_expected
    method_expected
    (fun () -> pretty_print method_)
    (fun () ->
      method_ $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (method_ $ "> table") (Soup.parse method_replacement);
      Soup.add_class "multiline" method_);

  let rewrite_status_group id expected replacement =
    let group = soup $ id in
    if_expected
      expected
      (fun () -> pretty_print group)
      (fun () ->
        group $$ "> code" |> Soup.iter Soup.delete;
        Soup.replace (group $ "> table") (Soup.parse replacement);
        Soup.add_class "multiline" group)
  in

  rewrite_status_group
    "#type-informational"
    informational_expected
    informational_replacement;

  rewrite_status_group
    "#type-successful"
    success_expected
    success_replacement;

  rewrite_status_group
    "#type-redirection"
    redirect_expected
    redirect_replacement;

  rewrite_status_group
    "#type-client_error"
    client_expected
    client_replacement;

  rewrite_status_group
    "#type-server_error"
    server_expected
    server_replacement;

  rewrite_status_group
    "#type-standard_status"
    standard_expected
    standard_replacement;

  let status = soup $ "#type-status" in
  if_expected
    status_expected
    (fun () -> pretty_print status)
    (fun () ->
      status $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (status $ "> table") (Soup.parse status_replacement);
      Soup.add_class "multiline" status)

let () =
  let source = Sys.argv.(1) in
  let destination = Sys.argv.(2) in
  let soup = Soup.(read_file source |> parse) in
  let content = soup $ "div.odoc-content" in

  soup
  $ "nav.odoc-toc"
  |> Soup.prepend_child content;

  pretty_print_signatures soup;

  Soup.(to_string content |> write_file destination)
