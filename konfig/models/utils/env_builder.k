import models.frontend.container

EnvBuilder = lambda env: container.EnvMap -> [any] {
    [
        {
            name = k
            if typeof(v) == "EnvValueFrom":
                valueFrom = v
            else:
                value = v
        }
        for k, v in env
    ]
}
