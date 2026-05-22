# otel-collector-config

A local OpenTelemetry Collector setup that fans out telemetry data (metrics and logs) from Claude Code to multiple OTLP backends.

## How it works

The collector exposes an OTLP/HTTP receiver on port `4318` and forwards data to two configurable backends:

- **boss** — receives metrics only (e.g. a Grafana Cloud endpoint)
- **mine** — receives both metrics and logs (e.g. a personal/secondary OTLP backend)

The pipeline uses a batch processor to improve throughput, and both exporters have sending queue and retry-on-failure enabled for reliability.

## Requirements

| Tool | Purpose |
|------|---------|
| [Docker](https://docs.docker.com/get-docker/) | Runs the collector container (`otel/opentelemetry-collector-contrib`) |
| [just](https://github.com/casey/just) | Task runner for managing the collector lifecycle |
| [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) | Renders environment variables into the config before starting (usually pre-installed on Linux/macOS) |

## Setup

1. Copy the example env file and fill in your credentials:

   ```bash
   cp .env-example .env
   ```

2. Edit `.env` with your actual endpoints and tokens:

   ```env
   BOSS_ENDPOINT="https://otlp-gateway-prod-eu-west-6.grafana.net/otlp"
   BOSS_TOKEN="Basic <base64-encoded-credentials>"

   MY_ENDPOINT="https://your-second-server/otlp"
   MY_TOKEN="Basic <base64-encoded-credentials>"
   ```

## Usage

```bash
just            # list available commands
just start      # render config and start the collector container
just stop       # stop and remove the container
just restart    # stop then start
just logs       # tail container logs
just status     # show container status
```

## Configuration

The collector config is in [otel-collector-config.yaml](otel-collector-config.yaml). Environment variables from `.env` are substituted at startup via `envsubst` before being mounted into the container.

## Claude Code settings

For Claude Code to emit telemetry to the local collector, add the following to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4318",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE": "cumulative",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_METRICS_EXPORTER": "otlp"
  }
}
```

- `CLAUDE_CODE_ENABLE_TELEMETRY` — enables telemetry export in Claude Code
- `OTEL_EXPORTER_OTLP_ENDPOINT` — points to the local collector receiver (`http://localhost:4318`)
- `OTEL_EXPORTER_OTLP_PROTOCOL` — uses the protobuf encoding over HTTP
- `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` — sets cumulative temporality, required by most backends (including Grafana)
- `OTEL_LOGS_EXPORTER` / `OTEL_METRICS_EXPORTER` — enables both logs and metrics export via OTLP

## Claude Code dashboard on Grafana

By signing up for a free [Grafana Cloud](https://grafana.com/auth/sign-up/create-user) account you get an OTLP endpoint and credentials that you can use as `mine` backend. Once your collector is forwarding data to Grafana, you can import or build a dashboard tailored to Claude Code metrics (token usage, request latency, error rates, etc.).

Steps:
1. Create a Grafana Cloud account and navigate to **Home → Connections → Add new connection → OpenTelemetry**.
2. Copy the generated OTLP endpoint URL and the Basic auth token.
3. Paste them into your `.env` as `BOSS_ENDPOINT` / `BOSS_TOKEN` (or `MY_ENDPOINT` / `MY_TOKEN`).
4. Run `just start` and verify data is arriving under **Explore → Metrics**.
