# Metrics API

This guide covers the current Pharo-facing metrics API.

The current implementation is an early SDK foundation. It gives you the global
entry points, meters, instrument objects, provider-owned measurements,
reader-owned metric aggregation, OTLP metric exporters, and callback-driven
asynchronous collection, plus a first view layer for reshaping metric streams.

## Current Scope

The current metrics implementation provides:

- `OTMeterProvider`
- `OTMeter`
- synchronous instruments:
  - `OTCounter`
  - `OTUpDownCounter`
  - `OTHistogram`
  - `OTGauge`
- asynchronous instruments:
  - `OTObservableCounter`
  - `OTObservableUpDownCounter`
  - `OTObservableGauge`
- `OpenTelemetry` entry points for the global meter provider
- meter caching by full instrumentation scope
- instrument caching by identifying fields `(name, kind, unit, description)`
- duplicate registration warnings for case-only name conflicts, conflicting metadata, and conflicting advisory parameters
- bound synchronous instrument wrappers via `bind:`
- `OTMeterConfig` plus provider-side `meterConfigurator` enablement hooks
- provider-owned `OTResource` values with meter-side delegation
- provider-owned synchronous measurement recording
- `OTMetricReader`, `OTInMemoryMetricReader`, and `OTPeriodicExportingMetricReader`
- reader-scoped asynchronous callback collection
- reader-scoped temporality selection for synchronous and asynchronous instruments
- provider-scoped metric views with instrument-name, type, unit, and meter-scope selection
- view stream overrides for metric name, description, attribute allow-lists, aggregation, and aggregation cardinality limits
- reader-scoped cardinality limits with synthetic overflow points
- exemplar sampling with `always_on`, `always_off`, and `trace_based` filters
- default exemplar reservoirs for sums, gauges, explicit histograms, and exponential histograms
- reader-scoped asynchronous callback timeout and failure isolation
- `OTNoopMetricExporter`, `OTConsoleMetricExporter`, `OTOtlpStdoutMetricExporter`
- OTLP metric exporters over HTTP JSON, HTTP protobuf, and gRPC
- Prometheus pull export over HTTP on `/metrics`
- OTLP metric auto-configuration through `OTEL_METRICS_EXPORTER`,
  `OTEL_EXPORTER_OTLP_METRICS_PROTOCOL`, `OTEL_METRIC_EXPORT_INTERVAL`, and
  `OTEL_METRIC_EXPORT_TIMEOUT`, plus `OTEL_METRICS_EXEMPLAR_FILTER`
- invalid meter-name normalization with diagnostic warnings
- provider lifecycle behavior for `shutdown` and `forceFlush`

The current metrics implementation does not yet provide:

- Prometheus native histogram output, so exponential histograms are currently dropped from Prometheus scrapes

## Getting A Meter

Use the global provider:

```smalltalk
meter := OpenTelemetry meterNamed: 'MyApp'.
```

Or configure and use an explicit provider:

```smalltalk
provider := OTMeterProvider new.
meter := provider
	meterNamed: 'MyApp'
	version: '1.0.0'
	schemaUrl: ''
	attributes: { 'component' -> 'worker' }.
```

Meter enablement can already be controlled per scope:

```smalltalk
provider meterConfigurator: [ :scope |
	scope name = 'disabled.scope'
		ifTrue: [ OTMeterConfig enabled: false ]
			ifFalse: [ OTMeterConfig enabled: true ] ].
```

Views can also be registered on the provider:

```smalltalk
provider addView:
	((OTMetricView named: 'http.server.duration')
		aggregation: #base2ExponentialBucketHistogram;
		attributeKeys: #( 'http.request.method' 'http.response.status_code' );
		yourself).
```

The global provider path also carries a configured resource:

```smalltalk
resource := OpenTelemetry meterProvider resource.
```

Explicit providers default to `OTResource empty`, and you can inject a resource
directly:

```smalltalk
provider resource: (OTResource attributes: { 'service.name' -> 'metrics-service' }).
```

To use the configured global provider, let `OTMeterProvider current` read the
metrics environment variables:

```smalltalk
Smalltalk os environment
	at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
	at: 'OTEL_EXPORTER_OTLP_METRICS_PROTOCOL' put: 'grpc'.

meter := OpenTelemetry meterNamed: 'MyApp'.
```

To expose a Prometheus scrape endpoint instead:

```smalltalk
Smalltalk os environment
	at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
	at: 'OTEL_EXPORTER_PROMETHEUS_HOST' put: 'localhost';
	at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '9464'.

meter := OpenTelemetry meterNamed: 'MyApp'.
```

Meters are cached by the full instrumentation-scope tuple
`(name, version, schemaUrl, attributes)`. Repeating the same request returns
the same meter object, while changing any of those values returns a distinct
meter.

## Creating Instruments

Synchronous instruments:

```smalltalk
counter := meter counterNamed: 'requests.total' unit: '1' description: 'Request count'.
histogram := meter histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration'.
gauge := meter gaugeNamed: 'queue.depth' unit: '1' description: 'Queue depth'.
```

Asynchronous instruments:

```smalltalk
memoryGauge := meter
	observableGaugeNamed: 'runtime.memory'
	callbacks: { [ "future SDK callback work will live here" ] }
	unit: 'By'
	description: 'Runtime memory'
	advice: Dictionary new.
```

## Current Behavior

Current metric behavior:

- provider-backed synchronous instruments answer `true` for `enabled`, unless all resolved matching views are `#drop`
- no-op instruments and asynchronous instruments answer `false` for `enabled`
- synchronous recording messages append `OTMetricMeasurement` entries to the provider-owned measurement store
- `OTInMemoryMetricReader>>collect` returns recorded synchronous measurements plus fresh asynchronous callback observations for that reader
- `OTMetricReader>>collectSnapshot` answers aggregated `OTMetricSnapshot` metric data grouped per instrument
- matching views are applied independently, so a single instrument may emit multiple streams
- overlapping views that produce the same metric identity emit a diagnostic warning once per reader
- `OTPeriodicExportingMetricReader` exports those snapshots through its configured exporter on collection and background intervals
- `OTMetricReader` applies a default per-instrument cardinality limit of `2000`, and you can override it with `cardinalityLimitSelector:`
- matching views can override the reader default cardinality limit per stream
- matching views take precedence over instrument attribute advice for `attribute_keys`
- exemplar sampling preserves measurement attributes dropped by view filtering
- `OTEL_METRICS_EXEMPLAR_FILTER` accepts `always_on`, `always_off`, and `trace_based`
- matching views can override the exemplar reservoir factory per stream
- asynchronous callback blocks may accept either zero arguments or one observer argument
- observer-driven asynchronous observations are collected only during reader collection
- timed-out or failing asynchronous callbacks are isolated from the rest of collection and emit diagnostic warnings
- direct asynchronous `observe:` sends outside registered callbacks are ignored
- synchronous `bind:` returns an `OTBoundMetricInstrument` that retains pre-bound attributes
- `OTMeterProvider>>shutdown` makes future meter requests return scoped no-op meters and shuts down registered readers
- `OTMeterProvider>>forceFlush` delegates to registered readers
- OTLP metric exporters accept gzip compression, signal-specific headers, and per-reader temporality
- the Prometheus reader serves cumulative metric snapshots over HTTP and uses cumulative temporality for every instrument kind

Meters do already preserve instrument registration identity:

- creating the same instrument twice with identical identifying fields returns the same instrument object
- creating the same instrument name with different casing returns the first-seen instrument and emits a warning
- creating the same instrument name with a different kind emits a warning and includes a view-based renaming hint
- creating the same instrument name/kind with different `unit` or `description` returns a distinct instrument and emits a warning
- creating identical instruments with different advisory parameters reuses the first-seen advisory parameters and emits a warning
- a matching `OTMetricView` with `streamDescription:` suppresses duplicate-registration warnings caused only by differing descriptions
- existing synchronous instruments reflect later `meterConfigurator` changes through `enabled`

That means you can start writing Pharo code against the metrics API now, and we
can evolve the implementation underneath it without redesigning the public
surface.

## Views

`OTMetricView` is the current provider-facing way to customize metric streams.
Selection criteria are additive: if you set more than one selector, all of them
must match for the view to apply.

Supported selectors:

- `namePattern:` with exact matches, `*`, and `?` wildcard matching
- `instrumentType:`
- `unit:`
- `meterName:`
- `meterVersion:`
- `meterSchemaUrl:`

Supported stream overrides:

- `streamName:`
- `streamDescription:`
- `attributeKeys:`
- `aggregation:`
- `aggregationParameters:`
- `aggregationCardinalityLimit:`
- `exemplarReservoirFactory:`

Supported aggregation symbols are:

- `#drop`
- `#default`
- `#sum`
- `#lastValue`
- `#explicitBucketHistogram`
- `#base2ExponentialBucketHistogram`

Supported aggregation parameters currently include:

- explicit histogram: `Boundaries`, `RecordMinMax`
- exponential histogram: `MaxSize`, `MaxScale`, `RecordMinMax`

Example: keep only one metric, drop everything else by default, and trim the
exported attributes:

```smalltalk
provider
	addView: (OTMetricView named: 'requests.total');
	addView: (OTMetricView all
		aggregation: #drop;
		yourself).

provider addView:
	((OTMetricView named: 'http.server.duration')
		streamName: 'http.server.duration.by_status';
		attributeKeys: #( 'http.response.status_code' );
		aggregation: #sum;
		aggregationCardinalityLimit: 50;
		yourself).
```

Exemplars are enabled by default through the `trace_based` filter. You can
change that provider-wide:

```smalltalk
provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
```

Or through environment configuration for `OTMeterProvider current`:

```smalltalk
Smalltalk os environment
	at: 'OTEL_METRICS_EXEMPLAR_FILTER' put: 'always_off'.
```

For custom instrumentation backends, a matching view can also supply a
stream-local exemplar reservoir factory:

```smalltalk
provider addView:
	((OTMetricView named: 'http.server.duration')
		exemplarReservoirFactory: [ :context :instrument :pointAttributes |
			OTSimpleFixedSizeMetricExemplarReservoir size: 4 ];
		yourself).
```

## Explicit Exporters

For manual wiring, attach a periodic reader to an explicit provider:

```smalltalk
configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS'.
configuration
	endpoint: 'http://collector:4318/v1/metrics';
	protocol: 'http/protobuf'.

reader := OTPeriodicExportingMetricReader exporter:
	(OTOtlpHttpProtobufMetricExporter configuration: configuration).

provider := OTMeterProvider new.
provider addMetricReader: reader.
```

To export over gRPC instead:

```smalltalk
configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS'.
configuration
	endpoint: 'http://collector:4317';
	protocol: 'grpc'.

reader := OTPeriodicExportingMetricReader exporter:
	(OTOtlpGrpcMetricExporter configuration: configuration).
```

For debugging-oriented output:

```smalltalk
provider addMetricReader:
	(OTPeriodicExportingMetricReader exporter: OTConsoleMetricExporter new).
```
