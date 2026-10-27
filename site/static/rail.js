/* The bookmark in the right margin.
   A native scrollbar cannot do this: its track is painted before the thumb is
   placed and never learns where that is, so a cord drawn there runs on past the
   ribbon. A page element can be told, so the rail is a fixed 12px strip holding
   a cord whose height is exactly the ribbon's top edge, and a ribbon whose
   length is the share of the page still below the fold. */
(function () {
  var root = document.documentElement;
  if (!root.classList.contains("has-rail")) return;

  var rail = document.querySelector(".rail");
  if (!rail) return;

  var cord = rail.querySelector(".rail__cord");
  var thumb = rail.querySelector(".rail__thumb");
  if (!cord || !thumb) return;

  var SHORTEST = 48; // px; below this the ribbon stops looking like a ribbon

  var view = 0; // height of the window
  var max = 0; // how far the page can scroll
  var length = 0; // height of the ribbon
  var frame = 0;

  function measure() {
    view = root.clientHeight;
    max = root.scrollHeight - view;
    length = Math.max(SHORTEST, (view * view) / root.scrollHeight);
    rail.style.setProperty("--thumb-h", length.toFixed(1) + "px");
    // No scrollbar, no strip: a page that fits keeps the full width instead of
    // carrying an empty 12px margin where the bookmark would have been.
    rail.classList.toggle("is-idle", max <= 1);
    root.classList.toggle("rail-idle", max <= 1);
  }

  function paint() {
    frame = 0;
    var top = max > 0 ? (root.scrollTop / max) * (view - length) : 0;
    rail.style.setProperty("--thumb-y", top.toFixed(1) + "px");
    // The cord ends exactly where the ribbon begins. Both move, so the seam
    // never drifts; below the ribbon there is only paper.
    rail.style.setProperty("--cord-h", top.toFixed(1) + "px");
  }

  function schedule() {
    if (!frame) frame = window.requestAnimationFrame(paint);
  }

  // Dragging is not free any more, so it has to be given back.
  thumb.addEventListener("pointerdown", function (event) {
    if (max <= 1 || event.button !== 0) return;
    event.preventDefault();
    thumb.setPointerCapture(event.pointerId);
    thumb.classList.add("is-held");

    var fromY = event.clientY;
    var fromScroll = root.scrollTop;
    var span = Math.max(1, view - length);

    function move(moveEvent) {
      root.scrollTop = fromScroll + ((moveEvent.clientY - fromY) * max) / span;
    }

    function release() {
      thumb.classList.remove("is-held");
      thumb.removeEventListener("pointermove", move);
      thumb.removeEventListener("pointerup", release);
      thumb.removeEventListener("pointercancel", release);
    }

    thumb.addEventListener("pointermove", move);
    thumb.addEventListener("pointerup", release);
    thumb.addEventListener("pointercancel", release);
  });

  measure();
  paint();

  window.addEventListener("scroll", schedule, { passive: true });
  window.addEventListener("resize", function () {
    measure();
    paint();
  });
  // A back/forward restore hands the page a scroll position without a scroll
  // event, so measure again rather than trusting the numbers from last time.
  window.addEventListener("pageshow", function () {
    measure();
    paint();
  });

  if (window.ResizeObserver) {
    new ResizeObserver(function () {
      measure();
      paint();
    }).observe(document.body);
  }
})();
