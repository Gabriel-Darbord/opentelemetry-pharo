# Prometheus Future Work

This note tracks Prometheus and OpenMetrics work that the OpenTelemetry
specification allows but does not require us to finish immediately for strict
baseline compliance.

The intent is to keep the main implementation effort focused on required
OpenTelemetry behavior while preserving a concrete backlog for later exporter
improvements.

## Deferred Development-Status Format Work

The remaining notable Prometheus work is now mostly about richer output
formats, not exporter configuration surface.

### Native histogram export for explicit histograms

The compatibility specification allows an OpenTelemetry Histogram to be
converted to a Prometheus Native Histogram with custom buckets when the chosen
Prometheus protocol supports it.

This would require:

- an explicit opt-in path
- protocol-aware emission rather than text-format-only assumptions
- sparse native histogram encoding instead of classic cumulative bucket output

### Exponential histogram export to Prometheus native histograms

The compatibility specification describes how cumulative OpenTelemetry
Exponential Histograms can be converted to Prometheus Native Histograms.

This remains deferred because it depends on native histogram protocol support,
downscaling behavior, and exporter formatting work that is broader than the
current Prometheus text/OpenMetrics pull path.

## Intentionally Not In This List

This document does not include strict remaining spec work. It is only for
optional or development-status Prometheus/OpenMetrics follow-up work that we
may choose to implement later.
