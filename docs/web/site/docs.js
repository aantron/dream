// This file is part of Dream, released under the MIT license. See LICENSE.md
// for details, or visit https://github.com/aantron/dream.
//
// Copyright 2021 Anton Bachin *)


/* Scrolling */

function current_section() {
  var threshold = window.innerHeight / 2;
  var sections = document.querySelectorAll("h2");
  var latest;

  for (var counter = 0; counter < sections.length; ++counter) {
    var section = sections[counter];

    var offset = section.getBoundingClientRect().top;
    if (offset < threshold)
      latest = section;
  }

  var links = document.querySelectorAll("nav.odoc-toc li");
  for (counter = 0; counter < links.length; ++counter)
    links[counter].classList.remove("current-section");

  if (latest === undefined)
    return;

  for (counter = 0; counter < links.length; ++counter) {
    if (links[counter].innerText === latest.innerText)
      links[counter].classList.add("current-section");
  }
};

function sidebar_position() {
  var toc = document.querySelector(".odoc-toc");
  var header = document.querySelector("header");
  if (window.scrollY >= header.offsetHeight)
    toc.classList.add("fixed");
  else {
    toc.classList.remove("fixed");
  }
};

function scroll() {
  current_section();
  sidebar_position();
};

window.onscroll = scroll;


/* Theme mode */

var THEME_MODE_KEY = "dream-theme" 

function apply_theme(theme) {
  if (theme === "light") {
    document.body.setAttribute("data-theme", "light");
  } else {
    document.body.removeAttribute("data-theme");
  }
}

function toggle_theme() {
  var current_theme = localStorage.getItem(THEME_MODE_KEY);
  var new_theme = current_theme === "dark" ? "light" : "dark";
  localStorage.setItem(THEME_MODE_KEY, new_theme);
  apply_theme(new_theme);
}

function init_theme() {
  var default_theme = "dark";
  var stored_theme = localStorage.getItem(THEME_MODE_KEY) || default_theme;
  apply_theme(stored_theme);

  var theme_toggle_button = document.querySelector(".toggle-theme-btn");
  if (theme_toggle_button) {
    theme_toggle_button.addEventListener("click", toggle_theme);
  }
}

document.addEventListener("DOMContentLoaded", init_theme);
