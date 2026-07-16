# Metrics API

This guide covers the current Pharo-facing metrics API.

The current implementation is an early SDK foundation. It gives you the global
entry points, meters, instrument objects, provider-owned measurements, a simple
in-memory reader, and callback-driven asynchronous collection, but it does not
yet include views, aggregations, or exporters.

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
- `OTMetricReader` and `OTInMemoryMetricReader`
- reader-scoped asynchronous callback collection
- invalid meter-name normalization with diagnostic warnings
- provider lifecycle behavior for `shutdown` and `forceFlush`

The current metrics implementation does not yet provide:

- views or aggregations
- OTLP, Prometheus, or stdout metric exporters
- callback timeouts or isolation policies

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

The global provider path also carries a configured resource:

```smalltalk
resource := OpenTelemetry meterProvider resource.
```

Explicit providers default to `OTResource empty`, and you can inject a resource
directly:

```smalltalk
provider resource: (OTResource attributes: { 'service.name' -> 'metrics-service' }).
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

- provider-backed synchronous instruments answer `true` for `enabled`
- no-op instruments and asynchronous instruments answer `false` for `enabled`
- synchronous recording messages append `OTMetricMeasurement` entries to the provider-owned measurement store
- `OTInMemoryMetricReader>>collect` returns recorded synchronous measurements plus fresh asynchronous callback observations for that reader
- asynchronous callback blocks may accept either zero arguments or one observer argument
- observer-driven asynchronous observations are collected only during reader collection
- direct asynchronous `observe:` sends outside registered callbacks are ignored
- synchronous `bind:` returns an `OTBoundMetricInstrument` that retains pre-bound attributes
- `OTMeterProvider>>shutdown` makes future meter requests return scoped no-op meters and shuts down registered readers
- `OTMeterProvider>>forceFlush` delegates to registered readers

Meters do already preserve instrument registration identity:

- creating the same instrument twice with identical identifying fields returns the same instrument object
- creating the same instrument name with different casing returns the first-seen instrument and emits a warning
- creating the same instrument name/kind with different `unit` or `description` returns a distinct instrument and emits a warning
- creating identical instruments with different advisory parameters reuses the first-seen advisory parameters and emits a warning
- existing synchronous instruments reflect later `meterConfigurator` changes through `enabled`

That means you can start writing Pharo code against the metrics API now, and we
can evolve the implementation underneath it without redesigning the public
surface.
