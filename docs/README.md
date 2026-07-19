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
