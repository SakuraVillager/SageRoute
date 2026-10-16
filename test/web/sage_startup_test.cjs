const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');

function harness(reducedMotion = false) {
  let nextId = 0;
  let time = 0;
  const timers = new Map();
  const frames = new Map();
  const listeners = new Map();
  const nodes = new Map();
  const state = { reloads: 0 };
  function node(id) {
    const classes = new Set();
    const result = { style: {}, hidden: true, textContent: '',
      classList: { add: c => classes.add(c), remove: c => classes.delete(c), contains: c => classes.has(c) },
      setAttribute(name, value) { this[name] = value; },
      addEventListener(name, callback) { this[name] = callback; },
      remove() { this.removed = true; } };
    nodes.set(id, result);
    return result;
  }
  const outlines = Array.from({length: 9}, (_, index) => node(`outline-${index}`));
  for (const id of ['sage-startup', 'sage-startup-status',
    'sage-startup-recovery', 'sage-startup-message', 'sage-startup-retry']) node(id);
  const body = node('body');
  body.classList.add('sage-starting');
  const document = { title: 'SageRoute', body, head: {}, getElementById: id => nodes.get(id),
    querySelectorAll: () => outlines };
  const window = { matchMedia: () => ({ matches: reducedMotion }),
    location: { reload: () => state.reloads++ },
    addEventListener: (name, callback) => listeners.set(name, callback) };
  vm.runInNewContext(readFileSync('web/sage_startup.js', 'utf8'), {
    window, document,
    MutationObserver: class { constructor(callback) { state.titleChanged = callback; } observe() {} },
    requestAnimationFrame(callback) { frames.set(++nextId, { callback, due: time + 16 }); return nextId; },
    cancelAnimationFrame(id) { frames.delete(id); },
    setTimeout(callback, delay) { timers.set(++nextId, { callback, due: time + delay }); return nextId; },
    clearTimeout(id) { timers.delete(id); },
  });
  function advance(ms) {
    const end = time + ms;
    while (true) {
      const next = [...timers.entries(), ...frames.entries()].filter(([, timer]) => timer.due <= end)
        .sort((a, b) => a[1].due - b[1].due)[0];
      if (!next) break;
      time = next[1].due;
      timers.delete(next[0]);
      frames.delete(next[0]);
      next[1].callback(time);
    }
    time = end;
  }
  const shown = () => outlines.reduce((sum, outline) =>
    sum + 1 - Number(outline.style.strokeDashoffset ?? 1), 0) / outlines.length;
  return { api: window.sageStartup, nodes, state, document, listeners, advance, shown,
    activeFrames: () => frames.size };
}

test('actual progress ahead of the drawing is followed at a bounded maximum speed', () => {
  const { api, advance, shown, nodes } = harness();
  api.progress(0.9, '引擎');
  advance(1000);
  assert.ok(shown() > 0.27 && shown() <= 0.28);
  advance(1000);
  assert.ok(shown() > 0.55 && shown() <= 0.56);
  assert.equal(nodes.get('outline-0').style.strokeDashoffset, '0');
  assert.equal(nodes.get('outline-8').style.strokeDashoffset, '1');
});

test('stalled actual progress keeps drawing at minimum speed and later accelerates smoothly', () => {
  const { api, advance, shown, activeFrames } = harness();
  advance(3000);
  const before = shown();
  assert.ok(before > 0.33 && before < 0.35);
  advance(1000);
  const slowDistance = shown() - before;
  assert.ok(slowDistance >= 0.099 && slowDistance <= 0.102);
  assert.equal(activeFrames(), 1);
  const caughtUp = shown();
  api.progress(0.96, '引擎');
  advance(1000);
  assert.ok(shown() - caughtUp > 0.27 && shown() - caughtUp <= 0.283);
  api.progress(0.12, '旧阶段');
  advance(100);
  assert.ok(shown() > caughtUp);
});

test('a complete outline loops the double blink while waiting and only readiness fills it', () => {
  const { api, advance, nodes, shown, activeFrames } = harness();
  advance(12000);
  const screen = nodes.get('sage-startup');
  assert.equal(shown(), 1);
  assert.equal(screen.classList.contains('is-waiting'), true);
  assert.equal(screen.classList.contains('is-ready'), false);
  assert.equal(activeFrames(), 0, 'CSS owns the waiting loop without unnecessary frames');
  advance(20000);
  assert.equal(screen.classList.contains('is-waiting'), true);
  assert.equal(screen.removed, undefined);
  assert.equal(nodes.get('sage-startup-recovery').hidden, false);
  api.ready();
  assert.equal(screen.classList.contains('is-waiting'), false);
  assert.equal(screen.classList.contains('is-ready'), true);
  advance(740);
  assert.equal(screen.removed, true);
});

for (const readyAfter of [5000, 9000]) {
  test(`${readyAfter / 1000}s loading stays animated and completes at the capped speed`, () => {
    const { api, nodes, advance, shown, activeFrames } = harness();
    api.progress(0.12);
    advance(1600);
    api.progress(0.66);
    advance(readyAfter - 2100);
    api.progress(0.9);
    advance(500);
    const before = shown();
    const screen = nodes.get('sage-startup');
    assert.equal(screen.classList.contains('is-ready'), false);
    assert.ok(activeFrames() > 0 || screen.classList.contains('is-waiting'));
    api.ready();
    advance(100);
    assert.ok(shown() >= before && shown() - before <= 0.032);
    advance(Math.ceil((1 - before) / 0.28 * 1000) + 800);
    assert.equal(screen.removed, true);
  });
}

test('readiness finishes the outline, fills, then fades and removes the overlay once', () => {
  const { api, nodes, advance } = harness();
  api.ready();
  api.ready();
  advance(3600);
  assert.equal(nodes.get('outline-8').style.strokeDashoffset, '0');
  assert.equal(nodes.get('sage-startup').classList.contains('is-ready'), true);
  assert.equal(nodes.get('body').classList.contains('sage-starting'), true);
  advance(320);
  assert.equal(nodes.get('body').classList.contains('sage-starting'), false);
  assert.equal(nodes.get('sage-startup').classList.contains('is-leaving'), true);
  advance(420);
  assert.equal(nodes.get('sage-startup').removed, true);
});

test('script failure stops all loading motion and retains a working retry', () => {
  const { api, nodes, state, listeners, advance, activeFrames } = harness();
  advance(12000);
  listeners.get('error')({ target: { src: 'https://example.com/main.dart.js' } });
  api.ready();
  advance(1000);
  assert.equal(nodes.get('sage-startup-recovery').hidden, false);
  assert.equal(nodes.get('sage-startup-status').textContent, '加载失败');
  assert.equal(nodes.get('sage-startup').classList.contains('is-ready'), false);
  assert.equal(nodes.get('sage-startup').classList.contains('is-waiting'), false);
  assert.equal(activeFrames(), 0);
  nodes.get('sage-startup-retry').click();
  assert.equal(state.reloads, 1);
});

test('reduced motion skips drawing and transitions but still waits for readiness', () => {
  const { api, nodes, advance } = harness(true);
  api.progress(0.9);
  assert.equal(nodes.get('sage-startup').classList.contains('is-ready'), false);
  api.ready();
  advance(0);
  assert.equal(nodes.get('sage-startup').removed, true);
});

test('a blank or changed title is restored during startup and later navigation', () => {
  const { document, state, api, advance } = harness();
  document.title = '';
  state.titleChanged();
  assert.equal(document.title, 'SageRoute');
  api.ready(); advance(5000);
  document.title = 'example.com';
  state.titleChanged();
  assert.equal(document.title, 'SageRoute');
});
