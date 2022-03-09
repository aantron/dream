(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



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
  | `Method <span class="of">of</span> string
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
  | `Status <span class="of">of</span> int
]</pre>
|}

let response_expected = {|<div class="spec value" id="val-response">
 <a href="#val-response" class="anchor"></a><code><span><span class="keyword">val</span> response : <span>?status:<span>[&lt; <a href="#type-status">status</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span>string <span class="arrow">-&gt;</span></span> <a href="#type-response">response</a></span></code>
</div>
|}

let response_replacement = {|
<pre><span class="keyword">val</span> response :
  <span class="optional">?status:[&lt; <a href="#type-status">status</a> ] -&gt;
  ?code:int ->
  ?headers:(string * string) list -&gt;</span>
    string -&gt; <a href="#type-response">response</a>
</pre>
|}

let respond_expected = {|<div class="spec value" id="val-respond">
 <a href="#val-respond" class="anchor"></a><code><span><span class="keyword">val</span> respond : <span>?status:<span>[&lt; <a href="#type-status">status</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let respond_replacement = {|
<pre><span class="keyword">val</span> respond :
  <span class="optional">?status:[&lt; <a href="#type-status">status</a> ] ->
  ?code:int ->
  ?headers:(string * string) list -></span>
    string -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let html_expected = {|<div class="spec value" id="val-html">
 <a href="#val-html" class="anchor"></a><code><span><span class="keyword">val</span> html : <span>?status:<span>[&lt; <a href="#type-status">status</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let html_replacement = {|
<pre><span class="keyword">val</span> html :
  <span class="optional">?status:[&lt; <a href="#type-status">status</a> ] ->
  ?code:int ->
  ?headers:(string * string) list -></span>
    string -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let json_expected = {|<div class="spec value" id="val-json">
 <a href="#val-json" class="anchor"></a><code><span><span class="keyword">val</span> json : <span>?status:<span>[&lt; <a href="#type-status">status</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let json_replacement = {|
<pre><span class="keyword">val</span> json :
  <span class="optional">?status:[&lt; <a href="#type-status">status</a> ] ->
  ?code:int ->
  ?headers:(string * string) list -></span>
    string -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let val_redirect_expected = {|<div class="spec value" id="val-redirect">
 <a href="#val-redirect" class="anchor"></a><code><span><span class="keyword">val</span> redirect : <span>?status:<span>[&lt; <a href="#type-redirection">redirection</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let val_redirect_replacement = {|
<pre><span class="keyword">val</span> redirect :
  <span class="optional">?status:[&lt; <a href="#type-redirection">redirection</a> ] ->
  ?code:int ->
  ?headers:(string * string) list -></span>
    <a href="#type-request">request</a> -> string -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let stream_expected = {|<div class="spec value" id="val-stream">
 <a href="#val-stream" class="anchor"></a><code><span><span class="keyword">val</span> stream : <span>?status:<span>[&lt; <a href="#type-status">status</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?code:int <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span>
<span>?close:bool <span class="arrow">-&gt;</span></span> <span><span>(<span><a href="#type-stream">stream</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span>)</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let stream_replacement = {|
<pre><span class="keyword">val</span> stream :
  ?status:[&lt; <a href="#type-status">status</a> ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  ?close:bool ->
    (<a href="#type-stream">stream</a> -> unit <a href="#type-promise">promise</a>) -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let empty_expected = {|<div class="spec value" id="val-empty">
 <a href="#val-empty" class="anchor"></a><code><span><span class="keyword">val</span> empty : <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-status">status</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let empty_replacement = {|
<pre><span class="keyword">val</span> empty :
  ?headers:(string * string) list ->
    <a href="#type-status">status</a> -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let add_header_expected = {|<div class="spec value" id="val-add_header">
 <a href="#val-add_header" class="anchor"></a><code><span><span class="keyword">val</span> add_header : <span><span><span class="type-var">'a</span> <a href="#type-message">message</a></span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let add_header_replacement = {|
<pre><span class="keyword">val</span> add_header :
  'a <a href="#type-message">message</a> -> string -> string -> unit
|}

let set_header_expected = {|<div class="spec value" id="val-set_header">
 <a href="#val-set_header" class="anchor"></a><code><span><span class="keyword">val</span> set_header : <span><span><span class="type-var">'a</span> <a href="#type-message">message</a></span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let set_header_replacement = {|
<pre><span class="keyword">val</span> set_header :
  'a <a href="#type-message">message</a> -> string -> string -> unit
|}

let add_set_cookie_expected = {|<div class="spec value" id="val-set_cookie">
 <a href="#val-set_cookie" class="anchor"></a><code><span><span class="keyword">val</span> set_cookie : <span>?prefix:<span><span>[&lt; `Host <span>| `Secure</span> ]</span> option</span> <span class="arrow">-&gt;</span></span> <span>?encrypt:bool <span class="arrow">-&gt;</span></span>
<span>?expires:float <span class="arrow">-&gt;</span></span> <span>?max_age:float <span class="arrow">-&gt;</span></span> <span>?domain:string <span class="arrow">-&gt;</span></span> <span>?path:<span>string option</span> <span class="arrow">-&gt;</span></span>
<span>?secure:bool <span class="arrow">-&gt;</span></span> <span>?http_only:bool <span class="arrow">-&gt;</span></span> <span>?same_site:<span><span>[&lt; `Strict <span>| `Lax</span> <span>| `None</span> ]</span> option</span> <span class="arrow">-&gt;</span></span>
<span><a href="#type-response">response</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let add_set_cookie_replacement = {|
<pre><span class="keyword">val</span> set_cookie :
  <span class="optional">?prefix:[&lt; `Host | `Secure ] option ->
  ?encrypt:bool ->
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[&lt; `Strict | `Lax | `None ] option -></span>
    <a href="#type-response">response</a> -> <a href="#type-request">request</a> -> string -> string -> unit
</pre>|}

let drop_cookie_expected = {|<div class="spec value" id="val-drop_cookie">
 <a href="#val-drop_cookie" class="anchor"></a><code><span><span class="keyword">val</span> drop_cookie : <span>?prefix:<span><span>[&lt; `Host <span>| `Secure</span> ]</span> option</span> <span class="arrow">-&gt;</span></span> <span>?domain:string <span class="arrow">-&gt;</span></span>
<span>?path:<span>string option</span> <span class="arrow">-&gt;</span></span> <span>?secure:bool <span class="arrow">-&gt;</span></span> <span>?http_only:bool <span class="arrow">-&gt;</span></span>
<span>?same_site:<span><span>[&lt; `Strict <span>| `Lax</span> <span>| `None</span> ]</span> option</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let drop_cookie_replacement = {|
<pre><span class="keyword">val</span> drop_cookie :
  <span class="optional">?prefix:[&lt; `Host | `Secure ] option ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[&lt; `Strict | `Lax | `None ] option -></span>
    <a href="#type-response">response</a> -> <a href="#type-request">request</a> -> string -> unit
</pre>|}

let cookie_expected = {|<div class="spec value" id="val-cookie">
 <a href="#val-cookie" class="anchor"></a><code><span><span class="keyword">val</span> cookie : <span>?prefix:<span><span>[&lt; `Host <span>| `Secure</span> ]</span> option</span> <span class="arrow">-&gt;</span></span> <span>?decrypt:bool <span class="arrow">-&gt;</span></span>
<span>?domain:string <span class="arrow">-&gt;</span></span> <span>?path:<span>string option</span> <span class="arrow">-&gt;</span></span> <span>?secure:bool <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string option</span></span></code>
</div>
|}

let cookie_replacement = {|
<pre><span class="keyword">val</span> cookie :
  ?prefix:[&lt; `Host | `Secure ] option ->
  ?decrypt:bool ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
    <a href="#type-request">request</a> -> string -> string option
</pre>
|}

let bigstring_expected = {|<div class="spec type" id="type-buffer">
 <a href="#type-buffer" class="anchor"></a><code><span><span class="keyword">type</span> buffer</span><span> = <span><span>(char,&nbsp;<span class="xref-unresolved">Stdlib</span>.Bigarray.int8_unsigned_elt,&nbsp;<span class="xref-unresolved">Stdlib</span>.Bigarray.c_layout)</span> <span class="xref-unresolved">Stdlib</span>.Bigarray.Array1.t</span></span></code>
</div>
|}

let bigstring_replacement = {|
<pre><span class="keyword">type</span> buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout)
    Bigarray.Array1.t
</pre>
|}

let read_stream_expected = {|<div class="spec value" id="val-read_stream">
 <a href="#val-read_stream" class="anchor"></a><code><span><span class="keyword">val</span> read_stream : <span><a href="#type-stream">stream</a> <span class="arrow">-&gt;</span></span> <span>data:<span>(<span><a href="#type-buffer">buffer</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>bool <span class="arrow">-&gt;</span></span> <span>bool <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>flush:<span>(<span>unit <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span>
<span>ping:<span>(<span><a href="#type-buffer">buffer</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>pong:<span>(<span><a href="#type-buffer">buffer</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>close:<span>(<span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span>
<span>exn:<span>(<span>exn <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let read_stream_replacement = {|
<pre><span class="keyword">val</span> read_stream :
  <a href="#type-stream">stream</a> ->
  data:(<a href="#type-buffer">buffer</a> -> int -> int -> bool -> bool -> unit) ->
  flush:(unit -> unit) ->
  ping:(<a href="#type-buffer">buffer</a> -> int -> int -> unit) ->
  pong:(<a href="#type-buffer">buffer</a> -> int -> int -> unit) ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
    unit
</pre>
|}

let write_stream_expected = {|<div class="spec value" id="val-write_stream">
 <a href="#val-write_stream" class="anchor"></a><code><span><span class="keyword">val</span> write_stream : <span><a href="#type-stream">stream</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-buffer">buffer</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>bool <span class="arrow">-&gt;</span></span> <span>bool <span class="arrow">-&gt;</span></span> <span>close:<span>(<span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span>
<span>exn:<span>(<span>exn <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span><span>(<span>unit <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let write_stream_replacement = {|
<pre><span class="keyword">val</span> write_stream :
  <a href="#type-stream">stream</a> ->
  <a href="#type-buffer">buffer</a> -> int -> int ->
  bool -> bool ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
</pre>|}

let flush_stream_expected = {|<div class="spec value" id="val-flush_stream">
 <a href="#val-flush_stream" class="anchor"></a><code><span><span class="keyword">val</span> flush_stream : <span><a href="#type-stream">stream</a> <span class="arrow">-&gt;</span></span> <span>close:<span>(<span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>exn:<span>(<span>exn <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span><span>(<span>unit <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let flush_stream_replacement = {|
<pre><span class="keyword">val</span> flush_stream :
  <a href="#type-stream">stream</a> ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
</pre>|}

let ping_stream_expected = {|<div class="spec value" id="val-ping_stream">
 <a href="#val-ping_stream" class="anchor"></a><code><span><span class="keyword">val</span> ping_stream : <span><a href="#type-stream">stream</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-buffer">buffer</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>close:<span>(<span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>exn:<span>(<span>exn <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span>
<span><span>(<span>unit <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let ping_stream_replacement = {|
<pre>
<span class="keyword">val</span> ping_stream :
  <a href="#type-stream">stream</a> ->
  <a href="#type-buffer">buffer</a> -> int -> int ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
</pre>|}

let pong_stream_expected = {|<div class="spec value" id="val-pong_stream">
 <a href="#val-pong_stream" class="anchor"></a><code><span><span class="keyword">val</span> pong_stream : <span><a href="#type-stream">stream</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-buffer">buffer</a> <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>int <span class="arrow">-&gt;</span></span> <span>close:<span>(<span>int <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> <span>exn:<span>(<span>exn <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span>
<span><span>(<span>unit <span class="arrow">-&gt;</span></span> unit)</span> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let pong_stream_replacement = {|
<pre>
<span class="keyword">val</span> pong_stream :
  <a href="#type-stream">stream</a> ->
  <a href="#type-buffer">buffer</a> -> int -> int ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
</pre>|}

let form_expected = {|<div class="spec type" id="type-form_result">
 <a href="#type-form_result" class="anchor"></a><code><span><span class="keyword">type</span> <span>'a form_result</span></span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-form_result.Ok" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Ok" class="anchor"></a><code><span>| </span></code><code><span>`Ok <span class="keyword">of</span> <span class="type-var">'a</span></span></code>
    </td>
   </tr>
   <tr id="type-form_result.Expired" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Expired" class="anchor"></a><code><span>| </span></code><code><span>`Expired <span class="keyword">of</span> <span class="type-var">'a</span> * float</span></code>
    </td>
   </tr>
   <tr id="type-form_result.Wrong_session" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Wrong_session" class="anchor"></a><code><span>| </span></code><code><span>`Wrong_session <span class="keyword">of</span> <span class="type-var">'a</span></span></code>
    </td>
   </tr>
   <tr id="type-form_result.Invalid_token" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Invalid_token" class="anchor"></a><code><span>| </span></code><code><span>`Invalid_token <span class="keyword">of</span> <span class="type-var">'a</span></span></code>
    </td>
   </tr>
   <tr id="type-form_result.Missing_token" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Missing_token" class="anchor"></a><code><span>| </span></code><code><span>`Missing_token <span class="keyword">of</span> <span class="type-var">'a</span></span></code>
    </td>
   </tr>
   <tr id="type-form_result.Many_tokens" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Many_tokens" class="anchor"></a><code><span>| </span></code><code><span>`Many_tokens <span class="keyword">of</span> <span class="type-var">'a</span></span></code>
    </td>
   </tr>
   <tr id="type-form_result.Wrong_content_type" class="anchored">
    <td class="def constructor">
     <a href="#type-form_result.Wrong_content_type" class="anchor"></a><code><span>| </span></code><code><span>`Wrong_content_type</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let form_replacement = {|
<pre class="compact"><span class="keyword">type</span> 'a form_result = [
  | `Ok            <span class="of">of</span> 'a
  | `Expired       <span class="of">of</span> 'a * float
  | `Wrong_session <span class="of">of</span> 'a
  | `Invalid_token <span class="of">of</span> 'a
  | `Missing_token <span class="of">of</span> 'a
  | `Many_tokens   <span class="of">of</span> 'a
  | `Wrong_content_type
]
|}

let form'_expected = {|<div class="spec value" id="val-form">
 <a href="#val-form" class="anchor"></a><code><span><span class="keyword">val</span> form : <span>?csrf:bool <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span><span><span><span>(string * string)</span> list</span> <a href="#type-form_result">form_result</a></span> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let form'_replacement = {|
<pre><span class="keyword">val</span> form :
  ?csrf:bool ->
    <a href="#type-request">request</a> -> (string * string) list <a href="#type-form_result">form_result</a> <a href="#type-promise">promise</a>
</pre>
|}

let multipart_form_expected = {|<div class="spec type" id="type-multipart_form">
 <a href="#type-multipart_form" class="anchor"></a><code><span><span class="keyword">type</span> multipart_form</span><span> = <span><span>(string * <span><span>(<span>string option</span> * string)</span> list</span>)</span> list</span></span></code>
</div>
|}

let multipart_form_replacement = {|
<pre><span class="keyword">type</span> multipart_form =
  (string * ((string option * string) list)) list
</pre>
|}

let multipart_expected = {|<div class="spec value" id="val-multipart">
 <a href="#val-multipart" class="anchor"></a><code><span><span class="keyword">val</span> multipart : <span>?csrf:bool <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span><span><a href="#type-multipart_form">multipart_form</a> <a href="#type-form_result">form_result</a></span> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let multipart_replacement = {|
<pre><span class="keyword">val</span> multipart :
  ?csrf:bool ->
    <a href="#type-request">request</a> -> <a href="#type-multipart">multipart_form</a> <a href="#type-form_result">form_result</a> <a href="#type-promise">promise</a>
</pre>
|}

let part_expected = {|<div class="spec type" id="type-part">
 <a href="#type-part" class="anchor"></a><code><span><span class="keyword">type</span> part</span><span> = <span>string option</span> * <span>string option</span> * <span><span>(string * string)</span> list</span></span></code>
</div>
|}

let part_replacement = {|
<pre><span class="keyword">type</span> part =
  string option * string option * ((string * string) list)
</pre>
|}

let upload_event_expected = {|<div class="spec type" id="type-upload_event">
 <a href="#type-upload_event" class="anchor"></a><code><span><span class="keyword">type</span> upload_event</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-upload_event.File" class="anchored">
    <td class="def constructor">
     <a href="#type-upload_event.File" class="anchor"></a><code><span>| </span></code><code><span>`File <span class="keyword">of</span> string * string</span></code>
    </td>
   </tr>
   <tr id="type-upload_event.Field" class="anchored">
    <td class="def constructor">
     <a href="#type-upload_event.Field" class="anchor"></a><code><span>| </span></code><code><span>`Field <span class="keyword">of</span> string * string</span></code>
    </td>
   </tr>
   <tr id="type-upload_event.Done" class="anchored">
    <td class="def constructor">
     <a href="#type-upload_event.Done" class="anchor"></a><code><span>| </span></code><code><span>`Done</span></code>
    </td>
   </tr>
   <tr id="type-upload_event.Wrong_content_type" class="anchored">
    <td class="def constructor">
     <a href="#type-upload_event.Wrong_content_type" class="anchor"></a><code><span>| </span></code><code><span>`Wrong_content_type</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let upload_event_replacement = {|
<pre><span class="keyword">type</span> upload_event = [
  | `File <span class="of">of</span> string * string
  | `Field <span class="of">of</span> string * string
  | `Done
  | `Wrong_content_type
]
</pre>
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
     <a href="#type-csrf_result.Expired" class="anchor"></a><code><span>| </span></code><code><span>`Expired <span class="keyword">of</span> float</span></code>
    </td>
   </tr>
   <tr id="type-csrf_result.Wrong_session" class="anchored">
    <td class="def constructor">
     <a href="#type-csrf_result.Wrong_session" class="anchor"></a><code><span>| </span></code><code><span>`Wrong_session</span></code>
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
  | `Expired <span class="of">of</span> float
  | `Wrong_session
  | `Invalid
]
|}

let verify_csrf_token_expected = {|<div class="spec value" id="val-verify_csrf_token">
 <a href="#val-verify_csrf_token" class="anchor"></a><code><span><span class="keyword">val</span> verify_csrf_token : <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-csrf_result">csrf_result</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let verify_csrf_token_replacement = {|
<pre><span class="keyword">val</span> verify_csrf_token :
  <a href="#type-request">request</a> -> string -> <a href="#type-csrf_result">csrf_result</a> <a href="#type-promise">promise</a>
</pre>
|}

let scope_expected = {|<div class="spec value" id="val-scope">
 <a href="#val-scope" class="anchor"></a><code><span><span class="keyword">val</span> scope : <span>string <span class="arrow">-&gt;</span></span> <span><span><a href="#type-middleware">middleware</a> list</span> <span class="arrow">-&gt;</span></span> <span><span><a href="#type-route">route</a> list</span> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let scope_replacement = {|
<pre><span class="keyword">val</span> scope :
  string -> <a href="#type-middleware">middleware</a> list -> <a href="#type-route">route</a> list -> <a href="#type-route">route</a>
</pre>
|}

let get_expected = {|<div class="spec value" id="val-get">
 <a href="#val-get" class="anchor"></a><code><span><span class="keyword">val</span> get : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let get_replacement = {|
<code><span><span class="keyword">val</span> get &nbsp;&nbsp;&nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let post_expected = {|<div class="spec value" id="val-post">
 <a href="#val-post" class="anchor"></a><code><span><span class="keyword">val</span> post : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let post_replacement = {|
<code><span><span class="keyword">val</span> post &nbsp;&nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let put_expected = {|<div class="spec value" id="val-put">
 <a href="#val-put" class="anchor"></a><code><span><span class="keyword">val</span> put : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let put_replacement = {|
<code><span><span class="keyword">val</span> put &nbsp;&nbsp;&nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let delete_expected = {|<div class="spec value" id="val-delete">
 <a href="#val-delete" class="anchor"></a><code><span><span class="keyword">val</span> delete : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let delete_replacement = {|
<code><span><span class="keyword">val</span> delete &nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let head_expected = {|<div class="spec value" id="val-head">
 <a href="#val-head" class="anchor"></a><code><span><span class="keyword">val</span> head : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let head_replacement = {|
<code><span><span class="keyword">val</span> head &nbsp;&nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let trace_expected = {|<div class="spec value" id="val-trace">
 <a href="#val-trace" class="anchor"></a><code><span><span class="keyword">val</span> trace : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let trace_replacement = {|
<code><span><span class="keyword">val</span> trace &nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let patch_expected = {|<div class="spec value" id="val-patch">
 <a href="#val-patch" class="anchor"></a><code><span><span class="keyword">val</span> patch : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let patch_replacement = {|
<code><span><span class="keyword">val</span> patch &nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let any_expected = {|<div class="spec value" id="val-any">
 <a href="#val-any" class="anchor"></a><code><span><span class="keyword">val</span> any : <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
</div>
|}

let any_replacement = {|
<code><span><span class="keyword">val</span> any &nbsp;&nbsp;&nbsp;&nbsp;: <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <a href="#type-route">route</a></span></code>
|}

let static_expected = {|<div class="spec value" id="val-static">
 <a href="#val-static" class="anchor"></a><code><span><span class="keyword">val</span> static : <span>?loader:<span>(<span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-handler">handler</a>)</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-handler">handler</a></span></code>
</div>
|}

let static_replacement = {|
<pre><span class="keyword">val</span> static :
  ?loader:(string -> string -> <a href="#type-handler">handler</a>) ->
    string -> <a href="#type-handler">handler</a>
</pre>
|}

let set_session_expected = {|<div class="spec value" id="val-set_session_field">
 <a href="#val-set_session_field" class="anchor"></a><code><span><span class="keyword">val</span> set_session_field : <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let set_session_replacement = {|
<pre><span class="keyword">val</span> set_session_field :
  <a href="#type-request">request</a> -> string -> string -> unit <a href="#type-promise">promise</a>
</pre>
|}

let websocket_expected = {|<div class="spec value" id="val-websocket">
 <a href="#val-websocket" class="anchor"></a><code><span><span class="keyword">val</span> websocket : <span>?headers:<span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span>?close:bool <span class="arrow">-&gt;</span></span> <span><span>(<span><a href="#type-websocket">websocket</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span>)</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let websocket_replacement = {|
<pre><span class="keyword">val</span> websocket :
  ?headers:(string * string) list ->
  ?close:bool ->
    (<a href="#type-websocket">websocket</a> -> unit <a href="#type-promise">promise</a>) -> <a href="#type-response">response</a> <a href="#type-promise">promise</a>
</pre>
|}

let text_or_binary_expected = {|<div class="spec type" id="type-text_or_binary">
 <a href="#type-text_or_binary" class="anchor"></a><code><span><span class="keyword">type</span> text_or_binary</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-text_or_binary.Text" class="anchored">
    <td class="def constructor">
     <a href="#type-text_or_binary.Text" class="anchor"></a><code><span>| </span></code><code><span>`Text</span></code>
    </td>
   </tr>
   <tr id="type-text_or_binary.Binary" class="anchored">
    <td class="def constructor">
     <a href="#type-text_or_binary.Binary" class="anchor"></a><code><span>| </span></code><code><span>`Binary</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let text_or_binary_replacement = {|
<pre class="compact"><span class="keyword">type</span> text_or_binary = [ `Text | `Binary ]</pre>
|}

let end_of_message_expected = {|<div class="spec type" id="type-end_of_message">
 <a href="#type-end_of_message" class="anchor"></a><code><span><span class="keyword">type</span> end_of_message</span><span> = </span><span>[ </span></code>
 <table>
  <tbody>
   <tr id="type-end_of_message.End_of_message" class="anchored">
    <td class="def constructor">
     <a href="#type-end_of_message.End_of_message" class="anchor"></a><code><span>| </span></code><code><span>`End_of_message</span></code>
    </td>
   </tr>
   <tr id="type-end_of_message.Continues" class="anchored">
    <td class="def constructor">
     <a href="#type-end_of_message.Continues" class="anchor"></a><code><span>| </span></code><code><span>`Continues</span></code>
    </td>
   </tr>
  </tbody>
 </table>
 <code><span> ]</span></code>
</div>
|}

let end_of_message_replacement = {|
<pre class="compact"><span class="keyword">type</span> end_of_message = [ `End_of_message | `Continues ]</pre>
|}

let send_expected = {|<div class="spec value" id="val-send">
 <a href="#val-send" class="anchor"></a><code><span><span class="keyword">val</span> send : <span>?text_or_binary:<span>[&lt; <a href="#type-text_or_binary">text_or_binary</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?end_of_message:<span>[&lt; <a href="#type-end_of_message">end_of_message</a> ]</span> <span class="arrow">-&gt;</span></span> <span><a href="#type-websocket">websocket</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let send_replacement = {|
<pre><span class="keyword">val</span> send :
  ?text_or_binary:[&lt; <a href="#type-text_or_binary">text_or_binary</a> ] ->
  ?end_of_message:[&lt; <a href="#type-end_of_message">end_of_message</a> ] ->
    <a href="#type-websocket">websocket</a> -> string -> unit <a href="#type-promise">promise</a>
</pre>
|}

let receive_fragment_expected = {|<div class="spec value" id="val-receive_fragment">
 <a href="#val-receive_fragment" class="anchor"></a><code><span><span class="keyword">val</span> receive_fragment : <span><a href="#type-websocket">websocket</a> <span class="arrow">-&gt;</span></span> <span><span><span>(string * <a href="#type-text_or_binary">text_or_binary</a> * <a href="#type-end_of_message">end_of_message</a>)</span> option</span> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let receive_fragment_replacement = {|
<pre><span class="keyword">val</span> receive_fragment :
  <a href="#type-websocket">websocket</a> ->
    (string * <a href="#type-text_or_binary">text_or_binary</a> * <a href="#type-end_of_message">end_of_message</a>) option <a href="#type-promise">promise</a>
</pre>
|}

let close_websocket_expected = {|<div class="spec value" id="val-close_websocket">
 <a href="#val-close_websocket" class="anchor"></a><code><span><span class="keyword">val</span> close_websocket : <span>?code:int <span class="arrow">-&gt;</span></span> <span><a href="#type-websocket">websocket</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let close_websocket_replacement = {|
<pre><span class="keyword">val</span> close_websocket :
  ?code:int -> <a href="#type-websocket">websocket</a> -> unit <a href="#type-promise">promise</a>
</pre>
|}

let graphql_expected = {|<div class="spec value" id="val-graphql">
 <a href="#val-graphql" class="anchor"></a><code><span><span class="keyword">val</span> graphql : <span><span>(<span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span><span class="type-var">'a</span> <a href="#type-promise">promise</a></span>)</span> <span class="arrow">-&gt;</span></span> <span><span><span class="type-var">'a</span> <span class="xref-unresolved">Graphql_lwt</span>.Schema.schema</span> <span class="arrow">-&gt;</span></span> <a href="#type-handler">handler</a></span></code>
</div>
|}

let graphql_replacement = {|
<pre><span class="keyword">val</span> graphql :
  (<a href="#type-request">request</a> -> 'a <a href="#type-promise">promise</a>) ->
  'a Graphql_lwt.Schema.schema ->
    <a href="#type-handler">handler</a>
</pre>
|}

let sql_expected = {|<div class="spec value" id="val-sql">
 <a href="#val-sql" class="anchor"></a><code><span><span class="keyword">val</span> sql : <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span><span>(<span><span class="xref-unresolved">Caqti_lwt</span>.connection <span class="arrow">-&gt;</span></span> <span><span class="type-var">'a</span> <a href="#type-promise">promise</a></span>)</span> <span class="arrow">-&gt;</span></span> <span><span class="type-var">'a</span> <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let sql_replacement = {|
<pre><span class="keyword">val</span> sql :
  <a href="#type-request">request</a> -> (Caqti_lwt.connection -> 'a <a href="#type-promise">promise</a>) ->
    'a <a href="#type-promise">promise</a>
</pre>
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

let val_error_expected = {|<div class="spec value" id="val-error">
 <a href="#val-error" class="anchor"></a><code><span><span class="keyword">val</span> error : <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
</div>
|}

let val_error_replacement = {|
<code><span><span class="keyword">val</span> error &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
|}

let warning_expected = {|<div class="spec value" id="val-warning">
 <a href="#val-warning" class="anchor"></a><code><span><span class="keyword">val</span> warning : <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
</div>
|}

let warning_replacement = {|
<code><span><span class="keyword">val</span> warning &nbsp;&nbsp;&nbsp;: <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
|}

let info_expected = {|<div class="spec value" id="val-info">
 <a href="#val-info" class="anchor"></a><code><span><span class="keyword">val</span> info : <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
</div>
|}

let info_replacement = {|
<code><span><span class="keyword">val</span> info &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
|}

let debug_expected = {|<div class="spec value" id="val-debug">
 <a href="#val-debug" class="anchor"></a><code><span><span class="keyword">val</span> debug : <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
</div>
|}

let debug_replacement = {|
<code><span><span class="keyword">val</span> debug &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <span><span>(<span class="type-var">'a</span>,&nbsp;unit)</span> <a href="#type-conditional_log">conditional_log</a></span></span></code>
|}

let initialize_log_expected = {|<div class="spec value" id="val-initialize_log">
 <a href="#val-initialize_log" class="anchor"></a><code><span><span class="keyword">val</span> initialize_log : <span>?backtraces:bool <span class="arrow">-&gt;</span></span> <span>?async_exception_hook:bool <span class="arrow">-&gt;</span></span>
<span>?level:<span>[&lt; <a href="#type-log_level">log_level</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?enable:bool <span class="arrow">-&gt;</span></span> <span>unit <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let initialize_log_replacement = {|
<pre><span class="keyword">val</span> initialize_log :
  <span class="optional">?backtraces:bool ->
  ?async_exception_hook:bool ->
  ?level:[&lt; <a href="#type-log_level">log_level</a> ] ->
  ?enable:bool -></span>
    unit -> unit
</pre>|}

let error_template_expected = {|<div class="spec value" id="val-error_template">
 <a href="#val-error_template" class="anchor"></a><code><span><span class="keyword">val</span> error_template : <span><span>(<span><a href="#type-error">error</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <span class="arrow">-&gt;</span></span> <span><a href="#type-response">response</a> <a href="#type-promise">promise</a></span>)</span> <span class="arrow">-&gt;</span></span> <a href="#type-error_handler">error_handler</a></span></code>
</div>
|}

let error_template_replacement = {|
<pre><span class="keyword">val</span> error_template :
  (<a href="#type-error">error</a> -> string -> <a href="#val-response">response</a> -> <a href="#val-response">response</a> <a href="#type-promise">promise</a>) ->
    <a href="#type-error_handler">error_handler</a>
</pre>
|}

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
     <a href="#type-error.layer" class="anchor"></a><code><span>layer : <span>[ `App <span>| `HTTP</span> <span>| `HTTP2</span> <span>| `TLS</span> <span>| `WebSocket</span> ]</span>;</span></code>
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
  condition <span class="of">:</span> [
    | `Response of <a href="#type-response">response</a>
    | `String of string
    | `Exn of exn
  ];
  layer     <span class="of">:</span> [ `App | `HTTP | `HTTP2 | `TLS | `WebSocket ];
  caused_by <span class="of">:</span> [ `Server | `Client ];
  request   <span class="of">:</span> <a href="#type-request">request</a>  option;
  response  <span class="of">:</span> <a href="#type-response">response</a> option;
  client    <span class="of">:</span> string   option;
  severity  <span class="of">:</span> <a href="#type-log_level">log_level</a>;
  will_send_response <span class="of">:</span> bool;
}
</pre>|}

let new_field_expected = {|<div class="spec value" id="val-new_field">
 <a href="#val-new_field" class="anchor"></a><code><span><span class="keyword">val</span> new_field : <span>?name:string <span class="arrow">-&gt;</span></span> <span>?show_value:<span>(<span><span class="type-var">'a</span> <span class="arrow">-&gt;</span></span> string)</span> <span class="arrow">-&gt;</span></span> <span>unit <span class="arrow">-&gt;</span></span> <span><span class="type-var">'a</span> <a href="#type-field">field</a></span></span></code>
</div>
|}

let new_field_replacement = {|
<pre><span class="keyword">val</span> new_field :
  ?name:string ->
  ?show_value:('a -> string) ->
    unit -> 'a <a href="#type-field">field</a>
</pre>
|}

let new_global_expected = {|<div class="spec value" id="val-new_global">
 <a href="#val-new_global" class="anchor"></a><code><span><span class="keyword">val</span> new_global : <span>?name:string <span class="arrow">-&gt;</span></span> <span>?show_value:<span>(<span><span class="type-var">'a</span> <span class="arrow">-&gt;</span></span> string)</span> <span class="arrow">-&gt;</span></span> <span><span>(<span>unit <span class="arrow">-&gt;</span></span> <span class="type-var">'a</span>)</span> <span class="arrow">-&gt;</span></span> <span><span class="type-var">'a</span> <a href="#type-global">global</a></span></span></code>
</div>
|}

let new_global_replacement = {|
<pre><span class="keyword">val</span> new_global :
  ?name:string ->
  ?show_value:('a -> string) ->
    (unit -> 'a) -> 'a <a href="#type-global">global</a>
|}

let run_expected = {|<div class="spec value" id="val-run">
 <a href="#val-run" class="anchor"></a><code><span><span class="keyword">val</span> run : <span>?interface:string <span class="arrow">-&gt;</span></span> <span>?port:int <span class="arrow">-&gt;</span></span> <span>?stop:<span>unit <a href="#type-promise">promise</a></span> <span class="arrow">-&gt;</span></span> <span>?error_handler:<a href="#type-error_handler">error_handler</a> <span class="arrow">-&gt;</span></span>
<span>?tls:bool <span class="arrow">-&gt;</span></span> <span>?certificate_file:string <span class="arrow">-&gt;</span></span> <span>?key_file:string <span class="arrow">-&gt;</span></span> <span>?builtins:bool <span class="arrow">-&gt;</span></span>
<span>?greeting:bool <span class="arrow">-&gt;</span></span> <span>?adjust_terminal:bool <span class="arrow">-&gt;</span></span> <span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> unit</span></code>
</div>
|}

let run_replacement = {|
<pre><span class="keyword">val</span> run :
  <span class="optional">?interface:string ->
  ?port:int ->
  ?stop:unit <a href="#type-promise">promise</a> ->
  ?error_handler:<a href="#type-error_handler">error_handler</a> ->
  ?secret:string ->
  ?old_secrets:string list ->
  ?prefix:string ->
  ?tls:bool ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?builtins:bool ->
  ?greeting:bool ->
  ?adjust_terminal:bool -></span>
    <a href="#type-handler">handler</a> -> unit
</pre>|}

let serve_expected = {|<div class="spec value" id="val-serve">
 <a href="#val-serve" class="anchor"></a><code><span><span class="keyword">val</span> serve : <span>?interface:string <span class="arrow">-&gt;</span></span> <span>?port:int <span class="arrow">-&gt;</span></span> <span>?stop:<span>unit <a href="#type-promise">promise</a></span> <span class="arrow">-&gt;</span></span> <span>?error_handler:<a href="#type-error_handler">error_handler</a> <span class="arrow">-&gt;</span></span>
<span>?tls:bool <span class="arrow">-&gt;</span></span> <span>?certificate_file:string <span class="arrow">-&gt;</span></span> <span>?key_file:string <span class="arrow">-&gt;</span></span> <span>?builtins:bool <span class="arrow">-&gt;</span></span>
<span><a href="#type-handler">handler</a> <span class="arrow">-&gt;</span></span> <span>unit <a href="#type-promise">promise</a></span></span></code>
</div>
|}

let serve_replacement = {|
<pre><span class="keyword">val</span> serve :
  <span class="optional">?interface:string ->
  ?port:int ->
  ?stop:unit <a href="#type-promise">promise</a> ->
  ?error_handler:<a href="#type-error_handler">error_handler</a> ->
  ?secret:string ->
  ?old_secrets:string list ->
  ?prefix:string ->
  ?tls:bool ->
  ?certificate_file:string ->
  ?key_string:string ->
  ?builtins:bool -></span>
    <a href="#type-handler">handler</a> -> unit <a href="#type-promise">promise</a>
</pre>|}

let to_percent_encoded_expected = {|<div class="spec value" id="val-to_percent_encoded">
 <a href="#val-to_percent_encoded" class="anchor"></a><code><span><span class="keyword">val</span> to_percent_encoded : <span>?international:bool <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> string</span></code>
</div>
|}

let to_percent_encoded_replacement = {|
<pre><span class="keyword">val</span> to_percent_encoded :
  ?international:bool -> string -> string
</pre>
|}

let to_set_cookie_expected = {|<div class="spec value" id="val-to_set_cookie">
 <a href="#val-to_set_cookie" class="anchor"></a><code><span><span class="keyword">val</span> to_set_cookie : <span>?expires:float <span class="arrow">-&gt;</span></span> <span>?max_age:float <span class="arrow">-&gt;</span></span> <span>?domain:string <span class="arrow">-&gt;</span></span>
<span>?path:string <span class="arrow">-&gt;</span></span> <span>?secure:bool <span class="arrow">-&gt;</span></span> <span>?http_only:bool <span class="arrow">-&gt;</span></span>
<span>?same_site:<span>[ `Strict <span>| `Lax</span> <span>| `None</span> ]</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> string</span></code>
</div>
|}

let to_set_cookie_replacement = {|
<pre><span class="keyword">val</span> to_set_cookie :
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[ `Strict | `Lax | `None ] ->
    string -> string -> string
</pre>
|}

let to_path_expected = {|<div class="spec value" id="val-to_path">
 <a href="#val-to_path" class="anchor"></a><code><span><span class="keyword">val</span> to_path : <span>?relative:bool <span class="arrow">-&gt;</span></span> <span>?international:bool <span class="arrow">-&gt;</span></span> <span><span>string list</span> <span class="arrow">-&gt;</span></span> string</span></code>
</div>
|}

let to_path_replacement = {|
<pre><span class="keyword">val</span> to_path :
  ?relative:bool ->
  ?international:bool ->
    string list -> string
</pre>
|}

let encrypt_expected = {|<div class="spec value" id="val-encrypt">
 <a href="#val-encrypt" class="anchor"></a><code><span><span class="keyword">val</span> encrypt : <span>?associated_data:string <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> string</span></code>
</div>
|}

let encrypt_replacement = {|
<pre><span class="keyword">val</span> encrypt :
  ?associated_data:string ->
    <a href="#type-request">request</a> -> string -> string
</pre>
|}

let decrypt_expected = {|<div class="spec value" id="val-decrypt">
 <a href="#val-decrypt" class="anchor"></a><code><span><span class="keyword">val</span> decrypt : <span>?associated_data:string <span class="arrow">-&gt;</span></span> <span><a href="#type-request">request</a> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <span>string option</span></span></code>
</div>
|}

let decrypt_replacement = {|
<pre><span class="keyword">val</span> decrypt :
  ?associated_data:string ->
    <a href="#type-request">request</a> -> string -> string option
</pre>
|}

let request_expected = {|<div class="spec value" id="val-request">
 <a href="#val-request" class="anchor"></a><code><span><span class="keyword">val</span> request : <span>?method_:<span>[&lt; <a href="#type-method_">method_</a> ]</span> <span class="arrow">-&gt;</span></span> <span>?target:string <span class="arrow">-&gt;</span></span> <span>?headers:<span><span>(string * string)</span> list</span>
<span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-request">request</a></span></code>
</div>
|}

let request_replacement = {|
<pre><span class="keyword">val</span> request :
  <span class="optional">?method_:[&lt; <a href="#type-method_">method_</a> ] ->
  ?target:string ->
  ?headers:(string * string) list -></span>
    string -> <a href="#type-request">request</a>
</pre>|}

let sort_headers_expected = {|<div class="spec value" id="val-sort_headers">
 <a href="#val-sort_headers" class="anchor"></a><code><span><span class="keyword">val</span> sort_headers : <span><span><span>(string * string)</span> list</span> <span class="arrow">-&gt;</span></span> <span><span>(string * string)</span> list</span></span></code>
</div>
|}

let sort_headers_replacement = {|
<pre><span class="keyword">val</span> sort_headers :
  (string * string) list -> (string * string) list
</pre>|}

let message_expected = {|<div class="spec type" id="type-message">
 <a href="#type-message" class="anchor"></a><code><span><span class="keyword">and</span> <span>'a message</span></span><span> = <span><span class="type-var">'a</span> <a href="../../dream-pure/Dream_pure/Message/index.html#type-message">Dream_pure.Message.message</a></span></span></code>
</div>
|}

let message_replacement = {|
<code><span><span class="keyword">and</span> 'a message</span></code>
|}

let client_expected' = {|<div class="spec type" id="type-client">
 <a href="#type-client" class="anchor"></a><code><span><span class="keyword">and</span> client</span><span> = <a href="../../dream-pure/Dream_pure/Message/index.html#type-client">Dream_pure.Message.client</a></span></code>
</div>
|}

let client_replacement' = {|
<code><span><span class="keyword">and</span> client</span></code>
|}

let server_expected' = {|<div class="spec type" id="type-server">
 <a href="#type-server" class="anchor"></a><code><span><span class="keyword">and</span> server</span><span> = <a href="../../dream-pure/Dream_pure/Message/index.html#type-server">Dream_pure.Message.server</a></span></code>
</div>
|}

let server_replacement' = {|
<code><span><span class="keyword">and</span> server</span></code>
|}

let set_secret_expected = {|<div class="spec value" id="val-set_secret">
 <a href="#val-set_secret" class="anchor"></a><code><span><span class="keyword">val</span> set_secret : <span>?old_secrets:<span>string list</span> <span class="arrow">-&gt;</span></span> <span>string <span class="arrow">-&gt;</span></span> <a href="#type-middleware">middleware</a></span></code>
</div>
|}

let set_secret_replacement = {|
<pre><span class="keyword">val</span> set_secret :
  ?old_secrets:string list -> string -> <a href="#type-middleware">middleware</a>
</pre>|}

let pretty_print_signatures soup =
  let method_ = soup $ "#type-method_" in
  if_expected
    method_expected
    (fun () -> pretty_print method_)
    (fun () ->
      method_ $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (method_ $ "> table") (Soup.parse method_replacement);
      Soup.add_class "multiline" method_);

  let rewrite_status_group ?(multiline = true) id expected replacement =
    let group = soup $ id in
    if_expected
      expected
      (fun () -> pretty_print group)
      (fun () ->
        group $$ "> code" |> Soup.iter Soup.delete;
        Soup.replace (group $ "> table") (Soup.parse replacement);
        if multiline then
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
      Soup.add_class "multiline" status);

  let multiline selector expected replacement =
    let element = soup $ selector in
    if_expected
      expected
      (fun () -> pretty_print element)
      (fun () ->
        Soup.replace (element $ "> code") (Soup.parse replacement);
        Soup.add_class "multiline" element)
  in

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

  multiline "#val-html" html_expected html_replacement;
  multiline "#val-json" json_expected json_replacement;
  multiline "#val-redirect" val_redirect_expected val_redirect_replacement;

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

  let replace selector expected replacement =
    let element = soup $ selector in
    if_expected
      expected
      (fun () -> pretty_print element)
      (fun () ->
        Soup.replace (element $ "> code") (Soup.parse replacement))
  in

  replace "#val-add_header" add_header_expected add_header_replacement;
  multiline "#val-set_header" set_header_expected set_header_replacement;

  let add_set_cookie = soup $ "#val-set_cookie" in
  if_expected
    add_set_cookie_expected
    (fun () -> pretty_print add_set_cookie)
    (fun () ->
      Soup.replace
        (add_set_cookie $ "> code")
        (Soup.parse add_set_cookie_replacement);
      Soup.add_class "multiline" add_set_cookie);

  let drop_cookie = soup $ "#val-drop_cookie" in
  if_expected
    drop_cookie_expected
    (fun () -> pretty_print drop_cookie)
    (fun () ->
      Soup.replace
        (drop_cookie $ "> code")
        (Soup.parse drop_cookie_replacement);
      Soup.add_class "multiline" drop_cookie);

  multiline "#val-cookie" cookie_expected cookie_replacement;

  let bigstring = soup $ "#type-buffer" in
  if_expected
    bigstring_expected
    (fun () -> pretty_print bigstring)
    (fun () ->
      Soup.replace (bigstring $ "> code") (Soup.parse bigstring_replacement);
      Soup.add_class "multiline" bigstring);

  let form = soup $ "#type-form_result" in
  if_expected
    form_expected
    (fun () -> pretty_print form)
    (fun () ->
      form $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (form $ "> table") (Soup.parse form_replacement);
      Soup.add_class "multiline" form);

  multiline "#val-form" form'_expected form'_replacement;

  (* let type_table selector expected replacement =
    let element = soup $ selector in
    if_expected
      expected
      (fun () -> pretty_print element)
      (fun () ->
        element $$ "> code" |> Soup.iter Soup.delete;
        Soup.replace (element $ "> table") (Soup.parse replacement);
        Soup.add_class "multiline" element)
  in *)

  multiline
    "#type-multipart_form" multipart_form_expected multipart_form_replacement;
  multiline "#val-multipart" multipart_expected multipart_replacement;
  multiline "#type-part" part_expected part_replacement;

  let csrf_result = soup $ "#type-csrf_result" in
  if_expected
    csrf_result_expected
    (fun () -> pretty_print csrf_result)
    (fun () ->
      csrf_result $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (csrf_result $ "> table")
        (Soup.parse csrf_result_replacement);
      Soup.add_class "multiline" csrf_result);

  multiline
    "#val-verify_csrf_token"
    verify_csrf_token_expected
    verify_csrf_token_replacement;

  multiline "#val-scope" scope_expected scope_replacement;
  replace "#val-get" get_expected get_replacement;
  replace "#val-post" post_expected post_replacement;
  replace "#val-put" put_expected put_replacement;
  replace "#val-delete" delete_expected delete_replacement;
  replace "#val-head" head_expected head_replacement;
  replace "#val-trace" trace_expected trace_replacement;
  replace "#val-patch" patch_expected patch_replacement;
  replace "#val-any" any_expected any_replacement;
  multiline "#val-static" static_expected static_replacement;
  multiline "#val-set_session_field"
    set_session_expected set_session_replacement;
  multiline "#val-websocket" websocket_expected websocket_replacement;
  multiline "#val-send" send_expected send_replacement;
  multiline "#val-close_websocket"
    close_websocket_expected close_websocket_replacement;
  multiline "#val-graphql" graphql_expected graphql_replacement;
  multiline "#val-sql" sql_expected sql_replacement;

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

  replace "#val-error" val_error_expected val_error_replacement;
  replace "#val-warning" warning_expected warning_replacement;
  replace "#val-info" info_expected info_replacement;
  replace "#val-debug" debug_expected debug_replacement;

  let initialize_log = soup $ "#val-initialize_log" in
  if_expected
    initialize_log_expected
    (fun () -> pretty_print initialize_log)
    (fun () ->
      Soup.replace
        (initialize_log $ "> code")
        (Soup.parse initialize_log_replacement);
      Soup.add_class "multiline" initialize_log);

  multiline
    "#val-error_template" error_template_expected error_template_replacement;

  let error = soup $ "#type-error" in
  if_expected
    error_expected
    (fun () -> pretty_print error)
    (fun () ->
      error $$ "> code" |> Soup.iter Soup.delete;
      Soup.replace (error $ "> table") (Soup.parse error_replacement);
      Soup.add_class "multiline" error);

  multiline "#val-new_field" new_field_expected new_field_replacement;

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

  multiline "#val-to_percent_encoded"
    to_percent_encoded_expected to_percent_encoded_replacement;
  multiline
    "#val-to_set_cookie" to_set_cookie_expected to_set_cookie_replacement;
  multiline "#val-to_path" to_path_expected to_path_replacement;
  multiline "#val-encrypt" encrypt_expected encrypt_replacement;
  multiline "#val-decrypt" decrypt_expected decrypt_replacement;

  let request = soup $ "#val-request" in
  if_expected
    request_expected
    (fun () -> pretty_print request)
    (fun () ->
      Soup.replace (request $ "> code") (Soup.parse request_replacement);
      Soup.add_class "multiline" request);

  multiline "#val-sort_headers" sort_headers_expected sort_headers_replacement;

  replace "#type-message" message_expected message_replacement;
  replace "#type-client" client_expected' client_replacement';
  replace "#type-server" server_expected' server_replacement';

  multiline "#val-read_stream" read_stream_expected read_stream_replacement;
  multiline "#val-write_stream" write_stream_expected write_stream_replacement;
  multiline "#val-flush_stream" flush_stream_expected flush_stream_replacement;
  multiline "#val-ping_stream" ping_stream_expected ping_stream_replacement;
  multiline "#val-pong_stream" pong_stream_expected pong_stream_replacement;

  rewrite_status_group ~multiline:false
    "#type-text_or_binary" text_or_binary_expected text_or_binary_replacement;
  rewrite_status_group ~multiline:false
    "#type-end_of_message" end_of_message_expected end_of_message_replacement;

  multiline
    "#val-receive_fragment"
    receive_fragment_expected receive_fragment_replacement;

  multiline "#val-set_secret" set_secret_expected set_secret_replacement

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
    delete element)

let retarget_status soup =
  soup $$ "a[href=#type-status]"
  |> Soup.(iter (set_attribute "href" "#status_codes"))

let links_new_tabs soup =
  soup $$ "a[href^=http]"
  |> Soup.(iter (fun a ->
    set_attribute "target" "_blank" a;
    set_attribute "rel" "noreferrer noopener" a))

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
  (* remove_specs soup; *)

  let error_template = soup $ "#val-error_template" |> Soup.R.parent in
  let error = soup $ "#type-error" |> Soup.R.parent in
  Soup.prepend_child error error_template;

  Common.add_backing_lines soup;

  remove_stdlib content;
  retarget_status content;
  links_new_tabs content;

  Soup.(to_string content |> write_file destination)
