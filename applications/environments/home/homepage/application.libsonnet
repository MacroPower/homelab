local app = import '../../../base/homepage/application.libsonnet';

app.withChartParams({
  'config.widgets[1].greeting.text': 'Home',
  'config.settings.background.image': 'https://images.unsplash.com/photo-1509226704106-8a5a71ffbfa4?auto=format&fit=crop&w=2560&q=80',
})
