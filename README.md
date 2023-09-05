# OpenTelemetry-Pharo
[OpenTelemetry](https://opentelemetry.io/) SDK and instrumentations for [Pharo](https://pharo.org/).  
Use it to instrument, generate, collect, and export telemetry data (metrics, logs, and traces) to help you analyze your software’s performance and behavior.

## Installation

```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'opentelemetry-pharo' commitish: 'main' path: 'src';
  baseline: 'OpenTelemetry';
  load
```
