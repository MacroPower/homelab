local app = import '../../../base/homepage/application.libsonnet';

app.withChartParams({
  'config.widgets[1].greeting.text': 'Seedbox',
  'config.settings.title': 'Seedbox',
  'config.settings.background.image': 'https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80',
})
