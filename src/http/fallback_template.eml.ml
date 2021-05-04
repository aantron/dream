(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Thibaut Mattio *)



module Dream =
struct
  include Dream__pure.Inmost
  include Dream__pure.Formats
end

let css = {|
/*! tailwindcss v2.1.2 | MIT License | https://tailwindcss.com *//*! modern-normalize v1.0.0 | MIT License | https://github.com/sindresorhus/modern-normalize */*,::after,::before{box-sizing:border-box}:root{-moz-tab-size:4;tab-size:4}html{line-height:1.15;-webkit-text-size-adjust:100%}body{margin:0}body{font-family:system-ui,-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif,'Apple Color Emoji','Segoe UI Emoji'}hr{height:0;color:inherit}abbr[title]{-webkit-text-decoration:underline dotted;text-decoration:underline dotted}b,strong{font-weight:bolder}code,kbd,pre,samp{font-family:ui-monospace,SFMono-Regular,Consolas,'Liberation Mono',Menlo,monospace;font-size:1em}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}table{text-indent:0;border-color:inherit}button,input,optgroup,select,textarea{font-family:inherit;font-size:100%;line-height:1.15;margin:0}button,select{text-transform:none}[type=button],[type=reset],[type=submit],button{-webkit-appearance:button}::-moz-focus-inner{border-style:none;padding:0}:-moz-focusring{outline:1px dotted ButtonText}:-moz-ui-invalid{box-shadow:none}legend{padding:0}progress{vertical-align:baseline}::-webkit-inner-spin-button,::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}summary{display:list-item}blockquote,dd,dl,figure,h1,h2,h3,h4,h5,h6,hr,p,pre{margin:0}button{background-color:transparent;background-image:none}button:focus{outline:1px dotted;outline:5px auto -webkit-focus-ring-color}fieldset{margin:0;padding:0}ol,ul{list-style:none;margin:0;padding:0}html{font-family:ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,"Noto Sans",sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol","Noto Color Emoji";line-height:1.5}body{font-family:inherit;line-height:inherit}*,::after,::before{box-sizing:border-box;border-width:0;border-style:solid;border-color:#e5e7eb}hr{border-top-width:1px}img{border-style:solid}textarea{resize:vertical}input::placeholder,textarea::placeholder{opacity:1;color:#9ca3af}[role=button],button{cursor:pointer}table{border-collapse:collapse}h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}a{color:inherit;text-decoration:inherit}button,input,optgroup,select,textarea{padding:0;line-height:inherit;color:inherit}code,kbd,pre,samp{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace}audio,canvas,embed,iframe,img,object,svg,video{display:block;vertical-align:middle}img,video{max-width:100%;height:auto}*{--tw-shadow:0 0 #0000;--tw-ring-inset:var(--tw-empty, );/*!*//*!*/--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59, 130, 246, 0.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000}.mb-4{margin-bottom:1rem}.mt-6{margin-top:1.5rem}.inline-block{display:inline-block}.flex{display:flex}.overflow-hidden{overflow:hidden}.overflow-auto{overflow:auto}.border-b{border-bottom-width:1px}.border-t{border-top-width:1px}.border-gray-200{--tw-border-opacity:1;border-color:rgba(229,231,235,var(--tw-border-opacity))}.bg-gray-800{--tw-bg-opacity:1;background-color:rgba(31,41,55,var(--tw-bg-opacity))}.p-4{padding:1rem}.py-4{padding-top:1rem;padding-bottom:1rem}.px-4{padding-left:1rem;padding-right:1rem}.py-2{padding-top:.5rem;padding-bottom:.5rem}.text-2xl{font-size:1.5rem;line-height:2rem}.font-semibold{font-weight:600}.text-gray-900{--tw-text-opacity:1;color:rgba(17,24,39,var(--tw-text-opacity))}.text-gray-600{--tw-text-opacity:1;color:rgba(75,85,99,var(--tw-text-opacity))}.text-white{--tw-text-opacity:1;color:rgba(255,255,255,var(--tw-text-opacity))}.antialiased{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}.subpixel-antialiased{-webkit-font-smoothing:auto;-moz-osx-font-smoothing:auto}@media (min-width:640px){.sm\:rounded-lg{border-radius:.5rem}.sm\:border{border-width:1px}.sm\:py-12{padding-top:3rem;padding-bottom:3rem}.sm\:px-6{padding-left:1.5rem;padding-right:1.5rem}.sm\:py-4{padding-top:1rem;padding-bottom:1rem}.sm\:text-3xl{font-size:1.875rem;line-height:2.25rem}}@media (min-width:1024px){.lg\:px-8{padding-left:2rem;padding-right:2rem}}
|}

let render ~debug_dump ~code ~reason =
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
      <style>
        <%s! css %>
      </style>
      <title><%i code %> <%s reason %></title>
    </head>

    <body class="antialiased">
      <div class="py-4 sm:py-12">
        <div class="px-4 sm:px-6 lg:px-8">
          <h2 class="text-2xl font-semibold text-gray-900 sm:text-3xl">Oops, an error occured!</h2>
          <div class="mb-4 text-gray-600"><%i code %> <%s reason %></div>
          <p>
            This error page has been generated by Dream's error handler.<br />
            Make sure to set the debugging mode off when deploying your application in production.
          </p>
        </div>
        <div class="mt-6 sm:px-6 lg:px-8">
          <div class="border-b border-t border-gray-200 sm:border sm:rounded-lg overflow-hidden">
            <div class="px-4 py-2 border-b border-gray-200 flex sm:py-4 sm:px-6">
              <h3>Debug Dump</h3>
            </div>
            <pre class="scrollbar-none overflow-auto text-white bg-gray-800"><code class="inline-block p-4 scrolling-touch subpixel-antialiased"><%s debug_dump %></code></pre>
          </div>
        </div>
      </div>
    </body>
  </html>
