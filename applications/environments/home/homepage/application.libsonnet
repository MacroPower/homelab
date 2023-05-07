local app = import '../../../base/homepage/application.libsonnet';

app.withChartParams({
  'config.widgets[1].greeting.text': 'Home',
})
