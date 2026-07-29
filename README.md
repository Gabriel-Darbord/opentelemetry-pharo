[![Pharo version](https://img.shields.io/badge/Pharo-12-%23aac9ff.svg)](https://github.com/pharo-project/pharo)
[![Pharo version](https://img.shields.io/badge/Pharo-13-%23aac9ff.svg)](https://github.com/pharo-project/pharo)
![Build Info](https://github.com/Gabriel-Darbord/opentelemetry-pharo/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/opentelemetry-pharo/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/opentelemetry-pharo?branch=main)

# OpenTelemetry-Pharo

[OpenTelemetry](https://opentelemetry.io/) SDK and instrumentation building
blocks for [Pharo](https://pharo.org/).

The repository currently ships:

- instrumentation building blocks
- tracing API and SDK
- logging API and SDK
- metrics API and SDK
- baggage and text-map propagation
- OTLP exporters over HTTP JSON, HTTP protobuf, and gRPC
- Zipkin export

## Specification Compliance

`opentelemetry-pharo` is developed spec-first.

For the repository features currently shipped, the audited applicable
OpenTelemetry `MUST`, `MUST NOT`, `SHOULD`, and `SHOULD NOT` requirements are
implemented against OpenTelemetry Specification `v1.58.0`.

The remaining known gaps are optional Prometheus native histogram `MAY` items.

## Installation

```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'opentelemetry-pharo' commitish: 'main' path: 'src';
  baseline: 'OpenTelemetry';
  load
```

## Documentation

The user manual now lives in [`docs/`](docs/README.md).

Start with:

- [`docs/tracing.md`](docs/tracing.md) for the tracing, baggage, propagation,
  exporter, and processor APIs
- [`docs/metrics.md`](docs/metrics.md) for meters, instruments, views, OTLP
  export, and the Prometheus scrape endpoint
- [`docs/logging.md`](docs/logging.md) for logger providers, builders,
  processors, and OTLP log export
- [`docs/instrumentation.md`](docs/instrumentation.md) for defining and
  installing Pharo instrumentations, including MetaLink and MethodProxy
  backends

## Contributing

Contributions are welcome!
If you find any issues, have suggestions, or want to contribute new features, please create an issue or submit a pull request.
