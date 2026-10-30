schema Target:
    """Target selects what an action, a purpose-specific trigger, or a
    purpose-specific condition applies to.
    More info: https://www.home-assistant.io/docs/automation/targets/

    Attributes
    ----------
    entity_id: str | [str], default is Undefined, optional.
        EntityId is one entity id or entity registry id, or a list of them.
        Actions also accept `all` and `none`. A template is allowed.
    device_id: str | [str], default is Undefined, optional.
        DeviceId is one device registry id or a list of them.
    area_id: str | [str], default is Undefined, optional.
        AreaId is one area id or a list of them.
    floor_id: str | [str], default is Undefined, optional.
        FloorId is one floor id or a list of them.
    label_id: str | [str], default is Undefined, optional.
        LabelId is one label id or a list of them.

    Examples
    --------
    target = common.Target {
        entity_id = ["light.hallway", "light.stairs"]
    }
    """
    entity_id?: EntityIds
    device_id?: EntityIds
    area_id?: EntityIds
    floor_id?: EntityIds
    label_id?: EntityIds

    check:
        entity_id is Undefined or isEntityIds(entity_id), "target `entity_id` must be entity ids, `all`, `none` or a template, got `${entity_id}`"
