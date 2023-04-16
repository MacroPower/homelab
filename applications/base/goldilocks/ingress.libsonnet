{
    "apiVersion": "networking.k8s.io/v1",
    "kind": "Ingress",
    "metadata": {
        "name": "goldilocks-ingress",
        "namespace": "goldilocks",
        "annotations": std.parseYaml(std.extVar("ingressAnnotations")) {
            "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
        }
    },
    "spec": {
        "tls": [
            {
                "hosts": [
                    std.extVar("ingressHost"),
                ],
            }
        ],
        "rules": [
            {
                "host": std.extVar("ingressHost"),
                "http": {
                    "paths": [
                        {
                            "path": "/",
                            "pathType": "Prefix",
                            "backend": {
                                "service": {
                                    "name": "goldilocks-dashboard",
                                    "port": {
                                        "number": 80
                                    }
                                }
                            }
                        }
                    ]
                }
            }
        ]
    }
}
