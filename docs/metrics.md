# Metrics API

This guide covers the current Pharo-facing metrics API.

The current implementation gives you the global entry points, meters,
instrument objects, provider-owned measurements, reader-owned metric
aggregation, OTLP metric exporters, callback-driven asynchronous collection,
views, exemplars, and Prometheus pull export.

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
- `OTNoopMetricExporter`, `OTConsoleMetricExporter`, `OTOtlpStdoutMetricExporter`, `OTOtlpJsonFileMetricExporter`
- OTLP metric exporters over HTTP JSON, HTTP protobuf, and gRPC
- legacy summary metric data objects for compatibility surfaces:
  `OTSummaryMetricData`, `OTSummaryDataPoint`, and `OTSummaryQuantileValue`
- metric-level metadata on `OTMetricData`, including OTLP `metadata` encoding
- Prometheus pull export over HTTP on `/metrics`
- Prometheus pull exporter configuration for `host`, `port`,
  `default_aggregation`, `translation_strategy`,
  `resource_constant_labels`, `scope_info_enabled`, and
  `target_info_enabled`
- OTLP metric auto-configuration through `OTEL_METRICS_EXPORTER`,
  `OTEL_EXPORTER_OTLP_METRICS_PROTOCOL`, `OTEL_METRIC_EXPORT_INTERVAL`,
  `OTEL_METRIC_EXPORT_TIMEOUT`, and `OTEL_METRIC_EXPORT_MAX_BATCH_SIZE`, plus
  `OTEL_METRICS_EXEMPLAR_FILTER`
- invalid meter-name normalization with diagnostic warnings
- provider lifecycle behavior for `shutdown` and `forceFlush`

The current metrics implementation does not yet provide:

- Prometheus native histogram output, so exponential histograms are currently dropped from Prometheus scrapes

Deferred Prometheus `MAY` and development-status follow-up work is tracked in
[Prometheus Future Work](prometheus-future-work.md).

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
OSEnvironment current
	at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
	at: 'OTEL_EXPORTER_OTLP_METRICS_PROTOCOL' put: 'grpc'.

meter := OpenTelemetry meterNamed: 'MyApp'.
```

To expose a Prometheus scrape endpoint instead:

```smalltalk
OSEnvironment current
	at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
	at: 'OTEL_EXPORTER_PROMETHEUS_HOST' put: 'localhost';
	at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '9464'.

meter := OpenTelemetry meterNamed: 'MyApp'.
```

`OTEL_METRICS_EXPORTER=logging` is also accepted as the deprecated
console-exporter alias.

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
	callbacks: { [ :observer | observer observe: 1234 ] }
	unit: 'By'
	description: 'Runtime memory'
	advice: Dictionary new.
```

## Current Behavior

Current metric behavior:

- provider-backed synchronous instruments answer `true` for `enabled`, unless all resolved matching views are `#drop` or disabled, or no view matches and the instrument's advice is `OptIn`
- no-op instruments and asynchronous instruments answer `false` for `enabled`
- synchronous recording messages append `OTMetricMeasurement` entries to the provider-owned measurement store, which keeps each one until every registered reader has collected it, and keeps none when the provider has no reader
- a reader is handed each synchronous measurement once, at its first collection after the measurement was recorded; a reader added later collects only the measurements recorded after it was added, and one shut down holds none back
- a cumulative stream of a synchronous instrument adds the measurements of each collection to the points it kept from the last, one per attribute set, and keeps nothing else; a delta stream keeps nothing between collections
- a cumulative point that saw no measurement since the last collection is reported again with its value and no exemplar
- `OTInMemoryMetricReader>>collect` returns the synchronous measurements recorded since its last collection plus fresh asynchronous callback observations for that reader
- `OTMetricReader>>collectSnapshot` answers aggregated `OTMetricSnapshot` metric data grouped per instrument
- matching views are applied independently, so a single instrument may emit multiple streams
- overlapping views that produce the same metric identity emit a diagnostic warning once per reader
- `OTPeriodicExportingMetricReader` exports those snapshots through its configured exporter on collection and background intervals, leaving out the metrics without a data point, and exports nothing when none has one
- `OTMetricReader` applies a default per-instrument cardinality limit of `2000`, and you can override it with `cardinalityLimitSelector:`
- matching views can override the reader default cardinality limit per stream
- matching views take precedence over instrument attribute advice for `attribute_keys`
- exemplar sampling preserves measurement attributes dropped by view filtering or by the instrument's `Attributes` advice
- `OTEL_METRICS_EXEMPLAR_FILTER` accepts `always_on`, `always_off`, and `trace_based`
- matching views can override the exemplar reservoir factory per stream
- asynchronous callback blocks may accept either zero arguments or one observer argument
- observer-driven asynchronous observations are collected only during reader collection
- timed-out or failing asynchronous callbacks are isolated from the rest of collection and emit diagnostic warnings
- direct asynchronous `observe:` sends outside registered callbacks are ignored
- synchronous `bind:` returns an `OTBoundMetricInstrument` that retains pre-bound attributes
- `OTMeterProvider>>shutdown` makes future meter requests return scoped no-op meters and shuts down registered readers
- `OTMeterProvider>>forceFlush` delegates to registered readers
- periodic-reader shutdown performs a final collection, exports its batches in
  order, and flushes the exporter before shutting it down; export failure or
  timeout is reported while exporter shutdown is still attempted
- an image that quits waits a second at most for its providers' readers to
  export what they collect; one that goes on after saving keeps its
  measurements
- an image started from its saved file drops the measurements it was saved
  with, rather than export them at every start of the saved file: a cumulative
  sum starts again from its first measurement after the start, a delta starts
  with the start, and a periodic reader ends the export it was saved in the
  middle of and starts its interval again
- `OTPeriodicExportingMetricReader>>maxExportBatchSize:` limits each batch by
  metric data-point count, which `OTEL_METRIC_EXPORT_MAX_BATCH_SIZE` and the
  declarative `max_export_batch_size` set; `exportTimeoutMillis:` applies to
  each batch export
- later batches are still attempted after an earlier batch fails or times out;
  force-flush reports the combined unsuccessful result and still flushes the exporter
- an OTLP metric exporter whose export failed drops the batches that follow,
  without a request, until its back-off passes, as described for OTLP exporters
  in [`tracing.md`](tracing.md)
- OTLP metric exporters accept gzip compression, signal-specific headers, and per-reader temporality
- OTLP/gRPC metric exporters also accept bare `host[:port]` authorities and the shared or metrics-specific `OTEL_EXPORTER_OTLP_*_INSECURE` switches
- OTLP exporters also read the shared or metrics-specific TLS file options for trusted server certificates and client key/certificate pairs when the runtime can honor them
- OTLP metric exporters can encode legacy summary data points for compatibility-oriented pipelines
- OTLP metric exporters also encode metric-level metadata
- the Prometheus reader serves cumulative metric snapshots over HTTP and uses cumulative temporality for every instrument kind
- Prometheus-exported metric family names include translated unit suffixes when the OpenTelemetry unit maps cleanly to Prometheus unit words
- Prometheus 1.0 and OpenMetrics 1.0 scrapes include `# UNIT` metadata when a translated unit is available
- Prometheus scrapes export summary quantiles on the base metric name plus `_sum` and `_count` companion samples
- a histogram point without a sum, which only another producer can make, has no `_sum` sample in a Prometheus scrape and no `sum` field in OTLP
- OpenMetrics scrapes now emit exemplars for monotonic counter samples and histogram bucket samples, including trace/span identifiers when present and respecting the OpenMetrics exemplar label budget
- gauge-like metrics with `prometheus.type` metadata now preserve `unknown`, `info`, and `stateset` compatibility hints during Prometheus export, using the negotiated format's closest supported representation
- conflicting Prometheus family `TYPE` metadata drops the whole exported family with a diagnostic warning, while conflicting `HELP` or `UNIT` metadata keeps the samples and emits only one metadata line
- Prometheus samples that collapse to the same final sample identity after name and label normalization are dropped with a diagnostic warning rather than emitted as duplicate samples

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

## Callbacks And Concurrency

Callback guidance for instrumentation authors:

- callback blocks should be reentrant-safe because each `OTMetricReader` may evaluate them independently
- callback blocks should finish in bounded time; a reader may time them out and ignore that callback's observations for the current collection
- callback blocks should avoid duplicate observations with the same attributes across all registered callbacks for one instrument set
- all observations emitted by one callback invocation are recorded with one shared timestamp

Concurrency guarantees in the current API:

- `OTMeterProvider` meter creation messages, `forceFlush`, and `shutdown` are safe to call from concurrent Pharo processes
- `OTMeter` instrument creation messages are safe to call concurrently
- synchronous instrument messages such as `enabled`, `bind:`, `add:`, and `record:` are safe to call concurrently
- asynchronous instrument creation is safe to call concurrently, and registered callbacks are collected once per reader collection
- no-op meter providers, meters, and instruments remain safe to call concurrently while discarding all work

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
- `enabled:` (development)

An instrument whose advice holds `OptIn` set to `true` produces no metric
data unless a view enables it. `enabled: true` on a matching view enables its
stream, `enabled: false` disables it, and a view that leaves `enabled` unset
follows the advice. Both are development-status in the specification, as is
the declarative `enabled/development` stream setting that sets `enabled:`.

```smalltalk
provider addView: ((OTMetricView named: 'db.client.connection.wait_time') enabled: true).
```

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
OSEnvironment current
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
