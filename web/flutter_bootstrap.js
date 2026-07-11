// Custom Flutter web bootstrap.
// Pins the CanvasKit renderer for pixel-consistency with the future mobile
// build, and clears the splash once the app is running.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    renderer: "canvaskit",
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById("splash");
    if (splash) splash.remove();
  },
});
