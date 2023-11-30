{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    nix-php-shell = {
      url = "github:loophp/nix-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opentelemetry-nix = {
      url = "github:FriendsOfOpenTelemetry/opentelemetry-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, systems, nix-php-shell, opentelemetry-nix, nix2container }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      perSystem = { self', system, pkgs, lib, ... }:
        let
          php = pkgs.api.buildPhpFromComposer { src = self; };
          nix2containerPkgs = nix2container.packages.${system};
          otelCollectorContribVersion = "v0.115.0";
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              nix-php-shell.overlays.default
              opentelemetry-nix.overlays.default
            ];
          };
          formatter = pkgs.nixpkgs-fmt;
          packages = {
            otel-collector = pkgs.buildOtelCollector {
              pname = "otel-collector";
              version = "1.0.0";
              config = {
                receivers = [
                  { gomod = "go.opentelemetry.io/collector/receiver/otlpreceiver ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/lokireceiver ${otelCollectorContribVersion}"; }
                ];
                exporters = [
                  { gomod = "go.opentelemetry.io/collector/exporter/otlpexporter ${otelCollectorContribVersion}"; }
                  { gomod = "go.opentelemetry.io/collector/exporter/debugexporter ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/exporter/lokiexporter ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/exporter/prometheusexporter ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/exporter/prometheusremotewriteexporter ${otelCollectorContribVersion}"; }
                ];
                processors = [
                  { gomod = "go.opentelemetry.io/collector/processor/batchprocessor ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/processor/cumulativetodeltaprocessor ${otelCollectorContribVersion}"; }
                ];
                extensions = [
                  { gomod = "go.opentelemetry.io/collector/extension/zpagesextension ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/extension/healthcheckextension ${otelCollectorContribVersion}"; }
                  { gomod = "github.com/open-telemetry/opentelemetry-collector-contrib/extension/pprofextension ${otelCollectorContribVersion}"; }
                ];
              };
              vendorHash = "sha256-ZiUfRo4PfOQZPcDWcqHxuFAh4rhm7+RddCBSef/LM5M=";
            };
            otel-collector-image = nix2containerPkgs.nix2container.buildImage {
              name = "otel-collector";
              tag = "latest";
              config = {
                entrypoint = ["${self'.packages.otel-collector}/bin/otel-collector"];
              };
            };
          };
          devShells = {
            default = pkgs.mkShell {
              packages = [
                pkgs.yamlfmt
                pkgs.symfony-cli
                pkgs.sqlite
                pkgs.dart-sass

                self'.packages.otel-collector

                php
                php.packages.composer
              ];
            };
          };
        };
    };
}
