/* HTML-first loading screen. Display progress can lead completed startup
   stages to keep the drawing alive; only ready() can fill and dismiss it.
   No Flutter fonts are needed here. */
(() => {
  'use strict';
  const screen = document.getElementById('sage-startup');
  const outlines = [...document.querySelectorAll('.sage-startup-outline')];
  const status = document.getElementById('sage-startup-status');
  const recovery = document.getElementById('sage-startup-recovery');
  const message = document.getElementById('sage-startup-message');
  const retry = document.getElementById('sage-startup-retry');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  // One complete outline takes at least ~3.6s, or ~10s at the idle rate.
  const maxSpeed = 0.28;
  const minSpeed = 0.10;
  let target = 0;
  let drawn = 0;
  let previousTime;
  let frame;
  let finished = false;
  let failed = false;

  // Keep title changes from loading widgets or history updates from exposing
  // an empty browser tab label during startup or subsequent navigation.
  const keepTitle = () => {
    if (document.title !== 'SageRoute') document.title = 'SageRoute';
  };
  keepTitle();
  new MutationObserver(keepTitle).observe(document.head, {
    childList: true, subtree: true, characterData: true,
  });

  function paint(value) {
    // A compound path restarts dashes at every contour. Normalize each letter
    // separately so later letters wait for earlier ones instead of appearing
    // together as soon as the first short contour has finished.
    outlines.forEach((outline, index) => {
      const letterProgress = Math.max(0, Math.min(1, value * outlines.length - index));
      outline.style.strokeDashoffset = String(1 - letterProgress);
    });
  }

  function tick(time) {
    const elapsed = previousTime === undefined ? 16 : Math.min(time - previousTime, 64);
    previousTime = time;
    const seconds = elapsed / 1000;
    // Split a frame at the actual progress boundary so catching up never
    // pauses, reverses, or overshoots at a speed above the configured limit.
    const fastDistance = Math.min(Math.max(0, target - drawn), seconds * maxSpeed);
    const remainingSeconds = seconds - fastDistance / maxSpeed;
    drawn = Math.min(1, drawn + fastDistance + remainingSeconds * minSpeed);
    paint(drawn);
    if (drawn < 1) {
      frame = requestAnimationFrame(tick);
    } else {
      frame = undefined;
      previousTime = undefined;
      if (finished) {
        reveal();
      } else {
        screen.classList.add('is-waiting');
      }
    }
  }

  function progress(value, label) {
    if (finished || failed) return;
    target = Math.max(target, Math.min(0.96, value));
    if (label) status.textContent = label;
    if (reducedMotion) {
      drawn = target;
      paint(drawn);
    } else if (frame === undefined && drawn < 1) {
      frame = requestAnimationFrame(tick);
    }
  }

  function reveal() {
    screen.classList.add('is-ready');
    status.textContent = '旅程已准备好';
    // Only the brief fill and fade remain after the app is ready.
    setTimeout(() => {
      document.body.classList.remove('sage-starting');
      screen.classList.add('is-leaving');
      setTimeout(() => screen.remove(), reducedMotion ? 0 : 420);
    }, reducedMotion ? 0 : 320);
  }

  const slowTimer = setTimeout(() => {
    if (finished || failed) return;
    message.textContent = '加载较慢，请检查网络，或重新加载。';
    recovery.hidden = false;
  }, 20000);

  function fail() {
    if (finished || failed) return;
    failed = true;
    screen.classList.remove('is-waiting');
    clearTimeout(slowTimer);
    if (frame !== undefined) cancelAnimationFrame(frame);
    message.textContent = '暂时无法开启旅程，请检查网络后重试。';
    status.textContent = '加载失败';
    recovery.hidden = false;
    screen.setAttribute('aria-busy', 'false');
  }

  retry.addEventListener('click', () => window.location.reload());
  // A missing bootstrap or main script cannot reach Flutter's error handler.
  window.addEventListener('error', (event) => {
    const source = event.target?.src || event.filename || '';
    if (/\/(flutter_bootstrap|main\.dart|sage_maps)\.js(?:[?#]|$)/.test(source)) fail();
  }, true);
  window.sageStartup = {
    progress,
    fail,
    ready() {
      if (finished || failed) return;
      finished = true;
      screen.classList.remove('is-waiting');
      clearTimeout(slowTimer);
      recovery.hidden = true;
      screen.setAttribute('aria-busy', 'false');
      target = 1;
      if (reducedMotion) {
        paint(1);
        reveal();
      } else if (drawn >= 1) {
        reveal();
      } else if (frame === undefined) {
        frame = requestAnimationFrame(tick);
      }
    },
  };
  progress(0.06, '正在开启旅程');
})();
