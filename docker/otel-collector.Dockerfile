FROM golang:1.25 AS builder

RUN go install go.opentelemetry.io/collector/cmd/builder@v0.150.0

COPY otel-collector-builder.yaml /build/manifest.yaml
WORKDIR /build
RUN mkdir -p ./build/otel-collector && builder --config=manifest.yaml

FROM gcr.io/distroless/base-debian12
COPY --from=builder /build/build/otel-collector/otel-collector /otel-collector
ENTRYPOINT ["/otel-collector"]
