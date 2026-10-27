/* Theme switch and copy buttons for every page, including the generated API. */
(function () {
  var root = document.documentElement;
  var KEY = "moonuuid-theme";

  function paint(theme) {
    root.dataset.theme = theme;
    var buttons = document.querySelectorAll("[data-theme-toggle]");
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute(
        "aria-label",
        theme === "dark" ? "Switch to the light theme" : "Switch to the dark theme"
      );
    }
  }

  try {
    paint(root.dataset.theme || localStorage.getItem(KEY) || "light");
  } catch (e) {
    paint(root.dataset.theme || "light");
  }

  document.addEventListener("click", function (event) {
    var toggle = event.target.closest("[data-theme-toggle]");
    if (toggle) {
      var next = root.dataset.theme === "dark" ? "light" : "dark";
      paint(next);
      try {
        localStorage.setItem(KEY, next);
      } catch (e) {}
      return;
    }

    var copy = event.target.closest("[data-copy]");
    if (!copy) return;
    var selector = copy.getAttribute("data-copy");
    var el =
      selector === "snippet"
        ? copy.closest(".snippet").querySelector("code")
        : document.querySelector(selector);
    if (!el) return;
    var text = el.innerText;
    var done = function () {
      var old = copy.textContent;
      copy.textContent = "copied";
      setTimeout(function () {
        copy.textContent = old;
      }, 1200);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done, function () {});
    }
  });
})();
