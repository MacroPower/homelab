schema RenderContext:
    """RenderContext is the per-render context, materialized once per `kcl run`.

    Every default reproduces the production render, so a render with no `-D`
    options produces the files the Pi loads.

    Attributes
    ----------
    revision: str, default is "", optional.
        Revision is the Git revision stamped into each YAML file's header
        comment when set, for example `-D revision=$(git rev-parse HEAD)`.
    """
    revision: str = ""

context: RenderContext = RenderContext {
    revision = option("revision", type="str", default="")
}
