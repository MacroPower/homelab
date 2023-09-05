local app = import '../../../base/authentik/application.libsonnet';

app.withBasePath('applications/environments/seedbox/authentik').withChartParams({
  'postgresql.persistence.existingClaim': 'ak-pgdb',
  'redis.master.persistence.existingClaim': 'ak-redis',
})
