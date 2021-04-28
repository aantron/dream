let css = Dream__asset.css

let favicon = Base64.encode Dream__asset.favicon |> Result.get_ok

let render =
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
      <link rel="icon" type="image/png" sizes="16x16" href="data:image/png;base64,<%s! favicon %>" />
      <link rel="stylesheet" href="https://rsms.me/inter/inter.css" />
      <style>
        <%s! css %>
      </style>
      <title>Welcome to Dream!</title>
    </head>

    <body class="antialiased">
      <div class="relative bg-gray-200">
        <div class="absolute inset-0 flex flex-col" aria-hidden="true">
          <div class="flex-1 bg-gray-100"></div>
          <div class="flex-1 bg-gray-200"></div>
        </div>
        <div class="relative max-w-5xl mx-auto">
          <div class="flex flex-col min-h-screen lg:flex-row lg:items-center lg:p-8">
            <div class="flex flex-col flex-grow bg-white lg:shadow-2xl lg:rounded-lg lg:overflow-hidden">
              <div class="flex-grow flex flex-col justify-center p-12">
                <div class="md:pl-16 pl-0">
                  <h1 class="sm:font-light text-2xl sm:text-3xl md:text-4xl text-gray-900 mt-6">Welcome to Dream!</h1>
                  <p class="sm:text-xl text-gray-600 mt-3 leading-relaxed">
                    Tidy Web framework for OCaml and ReasonML
                  </p>
                </div>
              </div>
              <div class="bg-gray-100 border-t-2 border-gray-200">
                <div class="flex flex-wrap">
                  <div class="flex flex-col px-12 py-10 w-full sm:w-1/2 sm:border-r sm:border-b border-gray-200">
                    <div class="flex flex-grow">
                      <div>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="h-8 w-8 md:h-10 md:w-10 md:-my-1">
                          <g>
                            <path class="fill-current text-gray-400" d="M12 21a2 2 0 0 1-1.41-.59l-.83-.82A2 2 0 0 0 8.34 19H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h4a5 5 0 0 1 4 2v16z" />
                            <path class="fill-current text-gray-700" d="M12 21V5a5 5 0 0 1 4-2h4a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-4.34a2 2 0 0 0-1.42.59l-.83.82A2 2 0 0 1 12 21z" />
                          </g>
                        </svg>
                      </div>
                      <div class="leading-relaxed flex flex-col ml-4 md:ml-6">
                        <h2 class="font-medium text-gray-800 text-lg">Documentation</h2>
                        <p class="text-gray-600 mt-1 text-sm md:text-base">Get familiar with Dream's API and start building awesome stuff.</p>
                        <div class="pt-1 mt-auto">
                          <a class="inline-flex items-center text-teal-600 hover:text-teal-800" href="https://aantron.github.io/dream/">
                            <span class="text-sm md:text-base font-semibold">Explore the docs</span>
                            <svg class="fill-current w-4 h-4 ml-2" viewBox="0 0 18 12" xmlns="http://www.w3.org/2000/svg">
                              <path fill-rule="evenodd" clip-rule="evenodd" d="M14.5858 7H1C0.447715 7 0 6.55228 0 6C0 5.44772 0.447715 5 1 5H14.5858L11.2929 1.70711C10.9024 1.31658 10.9024 0.683418 11.2929 0.292893C11.6834 -0.0976311 12.3166 -0.0976311 12.7071 0.292893L17.7071 5.29289C18.0976 5.68342 18.0976 6.31658 17.7071 6.70711L12.7071 11.7071C12.3166 12.0976 11.6834 12.0976 11.2929 11.7071C10.9024 11.3166 10.9024 10.6834 11.2929 10.2929L14.5858 7Z"></path>
                            </svg>
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="flex flex-col px-12 py-10 w-full sm:w-1/2 border-t-2 sm:border-t-0 sm:border-l sm:border-b border-gray-200">
                    <div class="flex flex-grow">
                      <div>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="h-8 w-8 md:h-10 md:w-10 md:-my-1">
                          <path class="fill-current text-gray-400" d="M3 6l9 4v12l-9-4V6zm14-3v2c0 1.1-2.24 2-5 2s-5-.9-5-2V3c0 1.1 2.24 2 5 2s5-.9 5-2z" />
                          <polygon class="fill-current text-gray-700" points="21 6 12 10 12 22 21 18" />
                        </svg>
                      </div>
                      <div class="flex flex-col leading-relaxed ml-4 md:ml-6">
                        <h2 class="font-medium text-gray-800 text-lg">Examples</h2>
                        <p class="text-gray-600 mt-1 text-sm md:text-base">Check out Dream tutorials and examplary applications.</p>
                        <div class="pt-1 mt-auto">
                          <a class="inline-flex items-center text-teal-600 hover:text-teal-800" href="https://github.com/aantron/dream/tree/master/example">
                            <span class="text-sm md:text-base font-semibold">Browse examples</span>
                            <svg class="fill-current w-4 h-4 ml-2" viewBox="0 0 18 12" xmlns="http://www.w3.org/2000/svg">
                              <path fill-rule="evenodd" clip-rule="evenodd" d="M14.5858 7H1C0.447715 7 0 6.55228 0 6C0 5.44772 0.447715 5 1 5H14.5858L11.2929 1.70711C10.9024 1.31658 10.9024 0.683418 11.2929 0.292893C11.6834 -0.0976311 12.3166 -0.0976311 12.7071 0.292893L17.7071 5.29289C18.0976 5.68342 18.0976 6.31658 17.7071 6.70711L12.7071 11.7071C12.3166 12.0976 11.6834 12.0976 11.2929 11.7071C10.9024 11.3166 10.9024 10.6834 11.2929 10.2929L14.5858 7Z"></path>
                            </svg>
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="flex flex-col px-12 py-10 w-full sm:w-1/2 border-t-2 sm:border-r sm:border-t border-gray-200">
                    <div class="flex flex-grow">
                      <div>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="h-8 w-8 md:h-10 md:w-10 md:-my-1">
                          <path class="fill-current text-gray-400" d="M9 22c.19-.14.37-.3.54-.46L17.07 14H20a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2H9zM4 2h4a2 2 0 0 1 2 2v14a4 4 0 1 1-8 0V4c0-1.1.9-2 2-2zm2 17.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z" />
                          <path class="fill-current text-gray-700" d="M11 18.66V7.34l2.07-2.07a2 2 0 0 1 2.83 0l2.83 2.83a2 2 0 0 1 0 2.83L11 18.66z" />
                        </svg>
                      </div>
                      <div class="flex flex-col leading-relaxed ml-4 md:ml-6">
                        <h2 class="font-medium text-gray-800 text-lg">Resources</h2>
                        <p class="text-gray-600 mt-1 text-sm md:text-base">A collection of resources to help you get up and runnning.</p>
                        <div class="pt-1 mt-auto">
                          <a class="inline-flex items-center text-teal-600 hover:text-teal-800" href="https://github.com/aantron/dream/wiki/References">
                            <span class="text-sm md:text-base font-semibold">Find resources</span>
                            <svg class="fill-current w-4 h-4 ml-2" viewBox="0 0 18 12" xmlns="http://www.w3.org/2000/svg">
                              <path fill-rule="evenodd" clip-rule="evenodd" d="M14.5858 7H1C0.447715 7 0 6.55228 0 6C0 5.44772 0.447715 5 1 5H14.5858L11.2929 1.70711C10.9024 1.31658 10.9024 0.683418 11.2929 0.292893C11.6834 -0.0976311 12.3166 -0.0976311 12.7071 0.292893L17.7071 5.29289C18.0976 5.68342 18.0976 6.31658 17.7071 6.70711L12.7071 11.7071C12.3166 12.0976 11.6834 12.0976 11.2929 11.7071C10.9024 11.3166 10.9024 10.6834 11.2929 10.2929L14.5858 7Z"></path>
                            </svg>
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="flex flex-col px-12 py-10 w-full sm:w-1/2 border-t-2 sm:border-l sm:border-t border-gray-200">
                    <div class="flex flex-grow">
                      <div>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="h-8 w-8 md:h-10 md:w-10 md:-my-1">
                          <path class="fill-current text-gray-400" d="M20.3 12.04l1.01 3a1 1 0 0 1-1.26 1.27l-3.01-1a7 7 0 1 1 3.27-3.27zM11 10a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" />
                          <path class="fill-current text-gray-700" d="M15.88 17.8a7 7 0 0 1-8.92 2.5l-3 1.01a1 1 0 0 1-1.27-1.26l1-3.01A6.97 6.97 0 0 1 5 9.1a9 9 0 0 0 10.88 8.7z" />
                        </svg>
                      </div>
                      <div class="flex flex-col leading-relaxed ml-4 md:ml-6">
                        <h2 class="font-medium text-gray-800 text-lg">Community</h2>
                        <p class="text-gray-600 mt-1 text-sm md:text-base">Connect and learn from other Dream users in the community.</p>
                        <div class="pt-1 mt-auto">
                          <a class="inline-flex items-center text-teal-600 hover:text-teal-800" href="https://discuss.ocaml.org/">
                            <span class="text-sm md:text-base font-semibold">Connect</span>
                            <svg class="fill-current w-4 h-4 ml-2" viewBox="0 0 18 12" xmlns="http://www.w3.org/2000/svg">
                              <path fill-rule="evenodd" clip-rule="evenodd" d="M14.5858 7H1C0.447715 7 0 6.55228 0 6C0 5.44772 0.447715 5 1 5H14.5858L11.2929 1.70711C10.9024 1.31658 10.9024 0.683418 11.2929 0.292893C11.6834 -0.0976311 12.3166 -0.0976311 12.7071 0.292893L17.7071 5.29289C18.0976 5.68342 18.0976 6.31658 17.7071 6.70711L12.7071 11.7071C12.3166 12.0976 11.6834 12.0976 11.2929 11.7071C10.9024 11.3166 10.9024 10.6834 11.2929 10.2929L14.5858 7Z"></path>
                            </svg>
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </body>
  </html>