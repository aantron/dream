// https://highlightjs.org/usage/

const fs = require("fs");
const html = fs.readFileSync(0).toString();

const hljs = require('highlight.js/lib/core');
hljs.registerLanguage('ocaml', require('highlight.js/lib/languages/ocaml'));
const highlightedCode = hljs.highlight(html, {language: 'ocaml'}).value;

process.stdout.write(highlightedCode);
