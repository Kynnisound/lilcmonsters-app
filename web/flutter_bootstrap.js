{{flutter_js}}
{{flutter_build_config}}

// BUG-022 : rien depuis un CDN. CanvasKit est local (build avec
// --no-web-resources-cdn, "useLocalCanvasKit":true) et Roboto est embarquee
// (assets/fonts/fallback/, FontManifest). Les polices de secours Noto, en
// cas de caractere absent de nos polices, seraient cherchees ici et non sur
// le CDN de polices de Google (aucune requete vers un tiers).
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    fontFallbackBaseUrl: "assets/fonts/fallback/",
  },
});
