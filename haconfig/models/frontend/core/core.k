schema Core:
    """Core is the `homeassistant:` block of `configuration.yaml`. HA makes every
    field set here read-only in the UI. Core has no `packages` field, because the
    backend sets it. Numeric fields also accept a string, so a `tags.secret()`
    reference type-checks.
    More info: https://www.home-assistant.io/integrations/homeassistant/

    Attributes
    ----------
    name: str, default is Undefined, optional.
        Name is the name of the location.
    latitude: float | str, default is Undefined, optional.
        Latitude is the location's latitude, used for sun and weather.
    longitude: float | str, default is Undefined, optional.
        Longitude is the location's longitude.
    elevation: int | str, default is Undefined, optional.
        Elevation is the altitude in meters, used for sunrise and sunset.
    radius: int | str, default is Undefined, optional.
        Radius is the home zone's radius in meters.
    unit_system: "metric" | "us_customary", default is Undefined, optional.
        UnitSystem selects the unit system.
    time_zone: str, default is Undefined, optional.
        TimeZone is an IANA time zone name, such as `Europe/Berlin`.
    currency: str, default is Undefined, optional.
        Currency is an ISO 4217 currency code.
    country: str, default is Undefined, optional.
        Country is an ISO 3166-1 alpha-2 country code.
    language: str, default is Undefined, optional.
        Language is the default language, such as `en`.
    internal_url: str, default is Undefined, optional.
        InternalUrl is the URL that reaches HA from the local network.
    external_url: str, default is Undefined, optional.
        ExternalUrl is the URL that reaches HA from the internet.
    allowlist_external_dirs: [str], default is Undefined, optional.
        AllowlistExternalDirs lists the folders that integrations may read from.
    allowlist_external_urls: [str], default is Undefined, optional.
        AllowlistExternalUrls lists the URLs that integrations may fetch.
    media_dirs: {str:str}, default is Undefined, optional.
        MediaDirs maps a media source name to a folder.
    debug: bool, default is Undefined, optional.
        Debug enables asyncio debug mode.
    customize: {str:{str:any}}, default is Undefined, optional.
        Customize overrides attributes per entity id.
    customize_domain: {str:{str:any}}, default is Undefined, optional.
        CustomizeDomain overrides attributes per domain.
    customize_glob: {str:{str:any}}, default is Undefined, optional.
        CustomizeGlob overrides attributes per entity id pattern.
    auth_providers: [{str:any}], default is Undefined, optional.
        AuthProviders lists the authentication providers.
    auth_mfa_modules: [{str:any}], default is Undefined, optional.
        AuthMfaModules lists the multi-factor authentication modules.

    Examples
    --------
    core = core.Core {
        name = "Home"
        unit_system = "metric"
        latitude = tags.secret("home_latitude")
    }
    """
    name?: str
    latitude?: float | str
    longitude?: float | str
    elevation?: int | str
    radius?: int | str
    unit_system?: "metric" | "us_customary"
    time_zone?: str
    currency?: str
    country?: str
    language?: str
    internal_url?: str
    external_url?: str
    allowlist_external_dirs?: [str]
    allowlist_external_urls?: [str]
    media_dirs?: {str:str}
    debug?: bool
    customize?: {str:{str:any}}
    customize_domain?: {str:{str:any}}
    customize_glob?: {str:{str:any}}
    auth_providers?: [{str:any}]
    auth_mfa_modules?: [{str:any}]
