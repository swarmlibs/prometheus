variable "ALPINE_VERSION" { default = "latest" }
variable "PROMETHEUS_VERSION" { default = "main" }
variable "GOMPLATE_VERSION" { default = "alpine" }

target "docker-metadata-action" {}
target "github-metadata-action" {}

target "default" {
    inherits = [ "prometheus" ]
    platforms = [
        "linux/amd64",
        "linux/arm64"
    ]
}

target "local" {
    inherits = [ "prometheus" ]
    tags = [ "swarmlibs/prometheus:local" ]
}

target "prometheus" {
    context = "."
    dockerfile = "Dockerfile"
    inherits = [
        "docker-metadata-action",
        "github-metadata-action",
    ]
    args = {
        ALPINE_VERSION = "${ALPINE_VERSION}"
        PROMETHEUS_VERSION = "${PROMETHEUS_VERSION}"
        GOMPLATE_VERSION = "${GOMPLATE_VERSION}"
    }
}
