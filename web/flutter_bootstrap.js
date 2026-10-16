{{flutter_js}}
{{flutter_build_config}}

const sageEngineConfig = { canvasKitBaseUrl: '/canvaskit/' };
window.sageStartup?.progress(0.12, '正在加载应用');
_flutter.loader.load({
  config: sageEngineConfig,
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      window.sageStartup?.progress(0.66, '正在准备绘图引擎与字体');
      const appRunner = await engineInitializer.initializeEngine(sageEngineConfig);
      window.sageStartup?.progress(0.90, '正在恢复旅程');
      await appRunner.runApp();
      // The routed page reports readiness after its first frame, not runApp().
    } catch (_) {
      window.sageStartup?.fail();
    }
  },
}).catch(() => window.sageStartup?.fail());
