# OpenTelemetry-Pharo Documentation

This folder documents the Pharo API exposed by `opentelemetry-pharo`.

It is intentionally about this library's objects, protocols, and usage
patterns. It is not a general introduction to OpenTelemetry concepts.

Start here:

- [Tracing API](tracing.md): create spans, configure providers, work with
  current context and baggage, and choose exporters/processors.
- [Logging API](logging.md): create loggers, emit log records, and configure
  processors and exporters.
- [Metrics API](metrics.md): get meters, create instruments, and understand the
  current metrics SDK, OTLP exporters, and Prometheus pull endpoint.
- [Prometheus Future Work](prometheus-future-work.md): optional and
  development-status Prometheus/OpenMetrics follow-up work that is intentionally
  deferred while strict spec compliance stays the priority.
- [Instrumentation API](instrumentation.md): build reusable Pharo
  instrumentations and choose an installation backend.

Current scope:

- traces: supported
- logs: API, batch processing, OTLP export, stdout export, and TinyLogger/Beacon bridging supported
- baggage and text-map propagation: supported
- metrics: synchronous/asynchronous instruments, views, OTLP export, and Prometheus pull export supported

Supported Pharo range in the baseline:

- Pharo 12
- Pharo 13
- Pharo 14

The CI currently exercises Pharo 12 and Pharo 13.

There is also a separate collector-backed integration job for OTLP/gRPC trace,
log, and metric export on Pharo 13. It runs outside the unit-test packages and
uses a real OpenTelemetry Collector fixture.

## Testing Note

The test suite intentionally exercises OpenTelemetry runtime reconfiguration.
It resets global providers and current context, installs and uninstalls
instrumentations, and starts and stops background readers, samplers, and local
HTTP endpoints.

Running the suite is therefore expected to disturb observability already active
in the same image, especially installed instrumentations and currently running
telemetry pipelines.

The suite also temporarily rewrites `OTEL_*` environment variables in the
running Pharo process when exercising autoconfiguration. Those changes are
restored by the tests. They are process-local runtime changes inside the image,
not persistent host configuration changes.
