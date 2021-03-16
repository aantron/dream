console.log("foo");

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

window.onscroll = current_section;
