import base

# The application configuration in stack will overwrite
# the configuration with the same attribute in base.
appConfiguration = base.appConfiguration | {
    environment = "home"
}
