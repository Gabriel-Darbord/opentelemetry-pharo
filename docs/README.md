# OpenTelemetry-Pharo Documentation

This folder documents the Pharo API exposed by `opentelemetry-pharo`.

It is intentionally about this library's objects, protocols, and usage
patterns. It is not a general introduction to OpenTelemetry concepts.

Start here:

- [Tracing API](tracing.md): create spans, configure providers, work with
  current context and baggage, and choose exporters/processors.
- [Instrumentation API](instrumentation.md): build reusable Pharo
  instrumentations and choose an installation backend.

Current scope:

- traces: supported
- baggage and text-map propagation: supported
- metrics: not implemented yet
- logs: not implemented yet

Supported Pharo range in the baseline:

- Pharo 12
- Pharo 13
- Pharo 14

The CI currently exercises Pharo 12 and Pharo 13.
