// Autoplay inline demo clips when they scroll into view, pause them when they
// leave. Clips are muted + loop + playsinline so browser autoplay policies
// allow programmatic play(). Posts without `.demo-video` elements are a no-op.
(function () {
  "use strict";

  function init() {
    var videos = document.querySelectorAll(".demo-video video");
    if (!videos.length) return;

    if (!("IntersectionObserver" in window)) {
      // No observer support: fall back to playing everything once.
      videos.forEach(function (video) {
        var p = video.play();
        if (p && p.catch) p.catch(function () {});
      });
      return;
    }

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          var video = entry.target;
          if (entry.isIntersecting) {
            var p = video.play();
            // Swallow autoplay-policy rejections so they don't hit the console.
            if (p && p.catch) p.catch(function () {});
          } else {
            video.pause();
          }
        });
      },
      { threshold: 0.4 }
    );

    videos.forEach(function (video) {
      observer.observe(video);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
