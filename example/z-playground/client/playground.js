// This file is part of Dream, released under the MIT license. See LICENSE.md
// for details, or visit https://github.com/aantron/dream.
//
// Copyright 2021 Anton Bachin *)



var editor = document.querySelector("#textarea");
var run = document.querySelector("#run");
var refresh = document.querySelector("#refresh");
var address = document.querySelector("input");
var iframe = document.querySelector("iframe");
var pre = document.querySelector("pre");
var chview = document.querySelector("#chview");

var codemirror = CodeMirror(editor, {
  theme: "material dream",
  lineNumbers: true,
  tabSize: 2,
  extraKeys: {
    "Tab": function (editor) {
      if (editor.somethingSelected())
        editor.execCommand("indentMore");
      else
        editor.execCommand("insertSoftTab");
    }
  }
});

function colorizeLog(string) {
  return string
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
    .replace(/\033\[\?7l/g, "")
    .replace(/\033\[2m/g, "<span class='t-dim'>")
    .replace(/\033\[35m\033\[3m/g, "<span class='t-cyan'><i>")
    .replace(/\033\[36m\033\[3m/g, "<span class='t-magenta'><i>")
    .replace(/\033\[37m\033\[3m/g, "")
    .replace(/\033\[0;35m\033\[0m/g, "</i></span>")
    .replace(/\033\[0;36m\033\[0m/g, "</i></span>")
    .replace(/\033\[0;37m\033\[0m/g, "")
    .replace(/\033\[31m/g, "<span class='t-red'>")
    .replace(/\033\[32m/g, "<span class='t-green'>")
    .replace(/\033\[33m/g, "<span class='t-yellow'>")
    .replace(/\033\[34m/g, "<span class='t-blue'>")
    .replace(/\033\[35m/g, "<span class='t-magenta'>")
    .replace(/\033\[36m/g, "<span class='t-cyan'>")
    .replace(/\033\[37m/g, "<span class='t-white'>")
    .replace(/\033\[0m/g, "</span>")
    ;
};

var components = window.location.pathname.split("/");
var sandbox = components[1];
sandbox = sandbox || "ocaml";
var socket =
  new WebSocket("ws://" + window.location.host + "/socket?sandbox=" + sandbox);

var path = components.slice(2).join("/");
if (path !== "")
  path = "/" + path;

var firstStart = true;

socket.onmessage = function (e) {
  var message = JSON.parse(e.data);
  switch (message.kind) {
    case "content":
      codemirror.setValue(message.payload);
      pre.innerHTML += "Building image...\n";
      socket.send(codemirror.getValue());
      break;

    case "log":
      pre.innerHTML += colorizeLog(message.payload);
      pre.scrollTop = pre.scrollHeight;
      break;

    case "started": {
      var frame_location =
        window.location.protocol + "//" +
        window.location.hostname + ":" + message.port + path + location.search;
      iframe.src = frame_location;
      address.value = frame_location;
      history.replaceState(
        null, "", "/" + message.sandbox + path + location.search);
      if (firstStart)
        firstStart = false;
      else
        pre.scrollIntoView();
      break;
    }
  }
};

run.onclick = function () {
  pre.innerHTML += "Building image...\n";
  pre.scrollTop = pre.scrollHeight;
  socket.send(codemirror.getValue());
};

chview.onclick = function(){
  var body = document.body;
  body.classList.toggle("full-editor")
}

address.onkeyup = function (event) {
  if (event.keyCode === 13)
    iframe.src = this.value;
};
