set dotenv-load := true

collector_name := "otel-collector"
config_path    := "otel-collector-config.yaml"
rendered_path  := justfile_directory() / ".rendered-config.yaml"

default:
    @just --list

_render:
    rm -rf {{rendered_path}}
    envsubst < {{config_path}} > {{rendered_path}}

start: _render
    docker run -d \
        --name {{collector_name}} \
        --restart unless-stopped \
        -v {{rendered_path}}:/etc/otel/config.yaml:ro \
        -p 4318:4318 \
        otel/opentelemetry-collector-contrib \
        --config /etc/otel/config.yaml;

stop:
    docker stop {{collector_name}} || true
    docker rm -f {{collector_name}} || true
    rm -rf {{rendered_path}} || true

restart: stop start

logs:
    docker logs -f {{collector_name}}

status:
    docker ps --filter name={{collector_name}}
