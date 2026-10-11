const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');

function harness() {
  const state = { scripts: [], requests: [], locations: [], events: [], status: 'complete' };
  const point = (lat, lng) => ({ getLat: () => lat, getLng: () => lng });
  const result = { routes: [{ distance: 100, time: 80, steps: [{ path: [point(30, 120), point(31, 121)] }] }] };
  class Driving {
    constructor(options) { this.options = options; }
    search(origin, destination, options, callback) {
      state.requests.push({ origin, destination, options, policy: this.options.policy });
      if (!state.stall) callback(state.status, state.status === 'complete' ? result : { info: 'INVALID_USER_KEY' });
    }
  }
  class Walking {
    search(origin, destination, callback) {
      state.requests.push({ origin, destination, walking: true });
      callback(state.status, result);
    }
  }
  class Geolocation {
    constructor(options) { state.locations.push(options); }
    getCurrentPosition(callback) { callback('complete', { position: point(30, 120) }); }
  }
  class TestMap {
    constructor(host) { this.host = host; state.map = this; }
    remove() {}
    add(overlays) { state.overlays = overlays; }
    destroy() { state.destroyed = true; }
  }
  class Marker {
    constructor(options) { this.options = options; }
    on(name, callback) { this.click = callback; }
  }
  const sdk = { Driving, Walking, Geolocation, Map: TestMap, Marker,
    DrivingPolicy: { LEAST_DISTANCE: 2, LEAST_TIME: 0 },
    Pixel: class {}, Polyline: class {}, InfoWindow: class {} };
  const window = { isSecureContext: true, dispatchEvent: e => state.events.push(e.type) };
  const document = {
    createElement: () => ({ dataset: {}, style: {}, remove() {} }),
    querySelectorAll: () => state.scripts,
    head: { appendChild(script) {
      state.scripts.push(script);
      queueMicrotask(() => {
        if (state.failLoad) script.onerror();
        else { window.AMap = sdk; context.AMap = sdk; script.onload(); }
      });
    } },
  };
  const context = vm.createContext({ window, document, Map, Event,
    ResizeObserver: class { constructor(callback) { state.resize = callback; } observe() {} disconnect() { state.disconnected = true; } },
    setTimeout: (callback, ms) => setTimeout(callback, Math.min(ms, 25)), clearTimeout });
  vm.runInContext(readFileSync('web/sage_maps.js', 'utf8'), context);
  return { state, window, api: window.sageMaps, host: { isConnected: true, style: {} } };
}
const config = { key: 'test-web-key', securityJsCode: 'public-test-code' };
const request = { config, origin: [120, 30], destination: [121, 31], waypoints: [], transport: 'driving', preference: 'shortest' };

test('one SDK load serves maps and routing, but never requests location implicitly', async () => {
  const { api, state, host, window } = harness();
  await Promise.all([api.create(host, { config, center: request.origin, zoom: 12 }, () => {}), api.route(request)]);
  assert.equal(state.scripts.length, 1);
  assert.equal(state.locations.length, 0);
  assert.equal(window._AMapSecurityConfig.securityJsCode, config.securityJsCode);
  state.resize();
  assert.deepEqual(state.events, ['resize']);
});
test('distance strategy, walking and JS LngLat normalization preserve the contract', async () => {
  const { api, state } = harness();
  const route = await api.route(request);
  assert.equal(state.requests[0].policy, 2);
  assert.equal(route.distance, 100);
  assert.equal(route.duration, 80);
  assert.equal(JSON.stringify(route.polyline), '[[30,120],[31,121]]');
  await api.route({ ...request, preference: 'default' });
  assert.equal(state.requests[1].policy, 0);
  await api.route({ ...request, transport: 'walking' });
  assert.equal(state.requests[2].walking, true);
});
test('no route, authorization and timeouts stay errors instead of mock routes', async () => {
  const { api, state } = harness();
  state.status = 'no_data';
  await assert.rejects(api.route(request), /没有可用路线/);
  state.status = 'error';
  await assert.rejects(api.route(request), /INVALID_USER_KEY/);
  state.stall = true;
  await assert.rejects(api.route(request), /超时/);
});
test('SDK failure can retry; a missing key does not start any SDK request', async () => {
  const { api, state, host } = harness();
  await assert.rejects(api.create(host, { config: { key: '' } }, () => {}), /Web Key/);
  assert.equal(state.scripts.length, 0);
  state.failLoad = true;
  await assert.rejects(api.route(request), /无法加载/);
  state.failLoad = false;
  await api.route(request);
  assert.equal(state.scripts.length, 2);
});
test('location converts to GCJ-02 only on explicit request; popup and disposal work', async () => {
  const { api, state, host } = harness();
  api.block(true);
  const id = await api.create(host, { config, center: request.origin, zoom: 12 }, () => {});
  assert.equal(host.style.pointerEvents, 'none');
  api.block(false);
  assert.equal(host.style.pointerEvents, 'auto');
  const result = await api.locate(config);
  assert.equal(state.locations[0].convert, true);
  assert.equal(result.coordinateSystem, 'gcj02');
  assert.equal(result.latitude, 30);
  api.destroy(id);
  assert.equal(state.destroyed, true);
  assert.equal(state.disconnected, true);
});
