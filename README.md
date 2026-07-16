[![Pharo version](https://img.shields.io/badge/Pharo-12-%23aac9ff.svg)](https://github.com/pharo-project/pharo)
[![Pharo version](https://img.shields.io/badge/Pharo-13-%23aac9ff.svg)](https://github.com/pharo-project/pharo)
![Build Info](https://github.com/Gabriel-Darbord/opentelemetry-pharo/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/opentelemetry-pharo/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/opentelemetry-pharo?branch=main)

# OpenTelemetry-Pharo

[OpenTelemetry](https://opentelemetry.io/) SDK and instrumentations for [Pharo](https://pharo.org/).  
Use it to instrument, generate, collect, and export telemetry data (<s>metrics, logs, and </s>traces) to help you analyze your software’s performance and behavior.

Disclaimer: This is still in early development!

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

### Examples

See an [example instrumentation](https://github.com/Gabriel-Darbord/opentelemetry-pharo/tree/main/src/OpenTelemetry-Agents-Shout) that generates traces for [Shout](https://github.com/pharo-project/pharo/tree/1270cd5a5617ceb1d2bbc2c72c5d3ad1f44921d1/src/Shout).

## Contributing

Contributions are welcome!
If you find any issues, have suggestions, or want to contribute new features, please create an issue or submit a pull request.
