local app = import '../../../base/iperf/application.libsonnet';

app.withChartValues(|||
  service:
    main:
      annotations:
        tailscale.com/hostname: "iperf-sb"
|||)
