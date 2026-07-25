# Prometheus Future Work

This note tracks Prometheus and OpenMetrics work that the OpenTelemetry
specification allows but does not require us to finish immediately for strict
baseline compliance.

The intent is to keep the main implementation effort focused on required
OpenTelemetry behavior while preserving a concrete backlog for later exporter
improvements.

## Deferred MAY-Level Work

### `resource_constant_labels` configuration

The Prometheus exporter specification allows an exporter to copy selected
resource attributes onto exported metric families as metric labels.

If we add this later, it should:

- default to disabled
- leave copied resource attributes present on `target_info`
- support selecting which resource attributes are included or excluded

### `translation_strategy` configuration

The specification allows the Prometheus exporter to expose a translation
strategy setting for metric and label naming.

If we add it later, it should support the spec-defined options:

- `UnderscoreEscapingWithSuffixes`
- `UnderscoreEscapingWithoutSuffixes`
- `NoUTF8EscapingWithSuffixes`
- `NoTranslation`

The current implementation already follows the default compatibility-oriented
translation path, but it does not yet expose the optional configuration
surface.

### `scope_info_enabled` configuration

The specification allows the exporter to expose a switch that controls whether
instrumentation scope labels are included on exported metric points.

If we add it later, it should:

- default to `true`
- disable the emitted `otel_scope_*` labels without changing unrelated
  translation behavior

### `target_info_enabled` configuration

The specification allows the exporter to expose a switch that controls whether
the `target_info` metric is emitted.

If we add it later, it should:

- default to `true`
- suppress only the `target_info` family, not other resource-handling logic

## Deferred Development-Status Format Work

These are also valid future Prometheus tasks, but they belong even less to the
strict baseline than the configuration items above.

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
