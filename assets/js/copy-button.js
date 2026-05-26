// Copy-to-clipboard buttons. A button with class `copy-btn` and a
// `data-copy-target="<id>"` copies the textContent of that element and
// briefly flips its label to "Copied!". No alerts.
(function () {
  "use strict";

  function flash(btn) {
    btn.classList.add("copied");
    setTimeout(function () {
      btn.classList.remove("copied");
    }, 1500);
  }

  function copyText(text, btn) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () { flash(btn); }).catch(function () {});
      return;
    }
    // Fallback for older browsers / insecure contexts.
    var ta = document.createElement("textarea");
    ta.value = text;
    ta.setAttribute("readonly", "");
    ta.style.position = "absolute";
    ta.style.left = "-9999px";
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand("copy"); flash(btn); } catch (e) { /* no-op */ }
    document.body.removeChild(ta);
  }

  function init() {
    var buttons = document.querySelectorAll(".copy-btn[data-copy-target]");
    if (!buttons.length) return;
    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        var target = document.getElementById(btn.getAttribute("data-copy-target"));
        if (target) copyText(target.textContent, btn);
      });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
