# OpenTelemetry

This repository is based on Symfony's [demo](https://github.com/symfony/demo) application and integrates [opentelemetry-bundle](https://github.com/FriendsOfOpenTelemetry/opentelemetry-bundle).

To make things works with OpenTelemetry, this branch includes a Docker Composer file to configure and execute a functional OpenTelemetry environnement which includes:

- Tempo, to receive and store OpenTelemetry Traces
- Prometheus, to receive OpenTelemetry Metrics
- Loki, to receive OpenTelemetry Logs
- Grafana, to visualize everything with all data sources configured

Any issues regarding OpenTelemetry integration should be reported on the opentelemetry-bundle repository [issues](https://github.com/FriendsOfOpenTelemetry/opentelemetry-bundle/issues).

## Requirements

- Nix
- Docker

## Usage

Follow [ReadMe](./README.md#usage) to configure the application first.

Once the application is configured, you need to build a custom OpenTelemetry Collector using Nix:

```bash
nix build .#otel-collector-image.copyToDockerDaemon
./result/bin/copy-to-docker-daemon
```

You should see our **otel-collector:latest** image when list images with Docker.

You can now launch our services with Docker:

```bash
docker-compose up -d
```

All services should be up and running. If not inspect logs of exited services.

Now you can browse any application pages and open Grafana (http://localhost:3000).

The default data sources is Tempo, so you should see traces by search any traces.

Here is a little video to show how it should look like:

https://github.com/user-attachments/assets/619b9c9a-88ed-439c-a368-4efa8202a268
