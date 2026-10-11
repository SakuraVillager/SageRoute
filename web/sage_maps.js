/* High-level SDK bridge. The AMap SDK itself is loaded only on first use. */
(() => {
  'use strict';
  let loading;
  let blocked = false;
  const instances = new Map();
  let nextId = 0;
  const withTimeout = (promise, ms = 15000) => new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('地图服务超时，请重试')), ms);
    promise.then(value => { clearTimeout(timer); resolve(value); }, error => { clearTimeout(timer); reject(error); });
  });
  function load(config) {
    if (!config.key || config.key.startsWith('YOUR_')) return Promise.reject(new Error('尚未配置高德 Web Key'));
    if (!loading) {
      loading = withTimeout(new Promise((resolve, reject) => {
        window._AMapSecurityConfig = config.serviceHost
          ? { serviceHost: config.serviceHost } : { securityJsCode: config.securityJsCode };
        const script = document.createElement('script');
        script.src = `https://webapi.amap.com/maps?v=2.0&key=${encodeURIComponent(config.key)}&plugin=AMap.Driving,AMap.Walking,AMap.Geolocation`;
        script.async = true;
        script.onload = () => window.AMap ? resolve() : reject(new Error('高德地图加载失败'));
        script.onerror = () => reject(new Error('无法加载高德地图，请检查网络和域名配置'));
        script.dataset.sageMap = 'sdk';
        document.head.appendChild(script);
      })).catch(error => {
        loading = null;
        document.querySelectorAll('script[data-sage-map="sdk"]').forEach(script => script.remove());
        throw error;
      });
    }
    return loading;
  }
  function sdkError(status, result) {
    if (status === 'no_data') return new Error('该路段没有可用路线');
    const info = result?.info || result?.message || result || status;
    return new Error(`高德服务失败：${String(info)}`);
  }
  function destroy(id) {
    const item = instances.get(id);
    if (!item) return;
    item.observer.disconnect();
    item.map.destroy();
    instances.delete(id);
  }
  window.sageMaps = {
    async create(host, options, tap) {
      await load(options.config);
      if (!host.isConnected) throw new Error('地图容器已关闭');
      const id = ++nextId;
      const map = new AMap.Map(host, { center: options.center, zoom: options.zoom, resizeEnable: true });
      const observer = new ResizeObserver(() => {
        // JSAPI 2 observes window resizing; resize() is not a public 2.0 API.
        window.dispatchEvent(new Event('resize'));
      });
      observer.observe(host);
      instances.set(id, { map, host, observer, tap, overlays: [], info: null });
      host.style.pointerEvents = blocked ? 'none' : 'auto';
      return id;
    },
    update(id, data) {
      const item = instances.get(id);
      if (!item) return;
      item.info?.close();
      item.map.remove(item.overlays);
      item.overlays = [];
      data.markers.forEach(m => {
        const options = { position: m.position, title: m.title, clickable: m.clickable, zIndex: m.zIndex };
        if (m.icon) {
          const image = document.createElement('img');
          image.src = m.icon;
          image.style.cssText = 'width:42px;height:42px;display:block;';
          image.alt = m.title;
          options.content = image;
          options.offset = new AMap.Pixel(-42 * m.anchor[0], -42 * m.anchor[1]);
          options.anchor = 'top-left';
        }
        const marker = new AMap.Marker(options);
        if (m.clickable) marker.on('click', () => {
          if (m.infoWindowEnable && m.title) {
            const text = document.createElement('div');
            text.textContent = m.title;
            item.info?.close();
            item.info = new AMap.InfoWindow({ content: text });
            item.info.open(item.map, m.position);
          }
          item.tap(m.id);
        });
        item.overlays.push(marker);
      });
      data.polylines.forEach(p => item.overlays.push(new AMap.Polyline({
        path: p.points, strokeColor: p.color, strokeOpacity: p.opacity,
        strokeWeight: p.width, lineJoin: 'round', lineCap: 'round',
      })));
      item.map.add(item.overlays);
    },
    camera(id, options) {
      const item = instances.get(id);
      if (!item) return;
      if (options.bounds) {
        item.map.setBounds(new AMap.Bounds(options.bounds[0], options.bounds[1]), !options.animated,
          [options.padding, options.padding, options.padding, options.padding]);
      } else if (options.zoom != null) {
        item.map.setZoomAndCenter(options.zoom, options.target, !options.animated, options.duration);
      } else {
        item.map.setCenter(options.target, !options.animated, options.duration);
      }
    },
    destroy,
    block(value) {
      blocked = value;
      instances.forEach(item => { item.host.style.pointerEvents = value ? 'none' : 'auto'; });
    },
    async route(options) {
      await load(options.config);
      return withTimeout(new Promise((resolve, reject) => {
        const driving = options.transport === 'driving';
        const service = driving
          ? new AMap.Driving({ policy: options.preference === 'shortest'
              ? AMap.DrivingPolicy.LEAST_DISTANCE : AMap.DrivingPolicy.LEAST_TIME })
          : new AMap.Walking();
        const callback = (status, result) => {
          if (status !== 'complete') { reject(sdkError(status, result)); return; }
          const route = result.routes?.[0];
          if (!route) { reject(new Error('高德未返回可用路线')); return; }
          const polyline = [];
          for (const step of route.steps || []) {
            for (const p of step.path || []) {
              const lat = typeof p.getLat === 'function' ? p.getLat() : p.lat;
              const lng = typeof p.getLng === 'function' ? p.getLng() : p.lng;
              polyline.push([lat, lng]);
            }
          }
          resolve({ distance: route.distance, duration: route.time, polyline });
        };
        if (driving) service.search(options.origin, options.destination, { waypoints: options.waypoints }, callback);
        else service.search(options.origin, options.destination, callback);
      }));
    },
    async locate(config) {
      if (!window.isSecureContext) throw new Error('定位需要 HTTPS，请在安全站点使用');
      await load(config);
      return withTimeout(new Promise((resolve, reject) => {
        const service = new AMap.Geolocation({ enableHighAccuracy: true, timeout: 10000,
          convert: true, showButton: false, showMarker: false, showCircle: false });
        service.getCurrentPosition((status, result) => {
          if (status !== 'complete' || !result.position) { reject(sdkError(status, result)); return; }
          const p = result.position;
          resolve({ latitude: p.getLat(), longitude: p.getLng(), coordinateSystem: 'gcj02' });
        });
      }));
    },
  };
})();
