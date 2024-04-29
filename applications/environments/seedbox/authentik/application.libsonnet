local app = import '../../../base/authentik/application.libsonnet';

app.withBasePath('applications/environments/seedbox/authentik').withChartParams({
  'redis.master.persistence.existingClaim': 'ak-redis',
})
