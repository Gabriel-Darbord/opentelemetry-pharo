# Logging API

This document covers the Pharo logging API exposed by `opentelemetry-pharo`.

It focuses on the Pharo objects and usage patterns, not on OpenTelemetry
logging concepts in the abstract.

## Current Scope

The current logging implementation provides:

- `OTLoggerProvider`: global or explicit logger-provider entry point
- `OTLogger`: scope-bound logger objects
- `OTLogRecordBuilder`: ergonomic emit builder
- `OTLoggerConfig`: per-logger filtering configuration
- `OTLogRecord`: readable/writeable SDK log record
- `OTSimpleLogRecordProcessor`, `OTBatchLogRecordProcessor`, and `OTCompositeLogRecordProcessor`
- `OTConsoleLogRecordExporter`, `OTNoopLogRecordExporter`, and OTLP log exporters over HTTP JSON, HTTP protobuf, and gRPC

The current logging implementation does not yet provide:

- bridges to existing Pharo logging libraries

## Getting A Logger

Use the global provider:

```smalltalk
logger := OpenTelemetry loggerNamed: 'MyApp'.
```

Or configure and use an explicit provider:

```smalltalk
provider := OTLoggerProvider new.
provider addLogRecordProcessor:
	(OTSimpleLogRecordProcessor new
		exporter: OTConsoleLogRecordExporter new;
		yourself).

logger := provider loggerNamed: 'MyApp' version: '1.0.0' schemaUrl: '' attributes: {
	'component' -> 'worker' }.
```

## Emitting Log Records

For simple cases:

```smalltalk
logger emitBody: 'Started job'.
```

For spec-shaped emit parameters, use the builder:

```smalltalk
logger logRecordBuilder
	severityNumber: OTSeverity info;
	severityText: 'INFO';
	body: 'Started job';
	eventName: 'job.start';
	attributeNamed: 'job.id' put: '42';
	emit.
```

If no explicit context is provided, the current OpenTelemetry context is used.
That means active trace context is attached automatically when present.

## Configuring Filtering

Filtering is owned by the provider through `OTLoggerConfig`:

```smalltalk
config := OTLoggerConfig default
	minimumSeverity: OTSeverity warn;
	traceBased: true;
	yourself.

provider loggerConfigurator: [ :scope | config ].
```

This lets you:

- disable loggers entirely
- require a minimum severity
- drop logs associated with unsampled traces

Because loggers consult their provider at emit time, updating the configurator
affects already-created loggers too.

## Processors And Exporters

The built-in synchronous path is:

```smalltalk
provider addLogRecordProcessor:
	(OTSimpleLogRecordProcessor new
		exporter: OTConsoleLogRecordExporter new;
		yourself).
```

For asynchronous export, use the batch processor:

```smalltalk
provider addLogRecordProcessor:
	(OTBatchLogRecordProcessor new
		exporter: OTConsoleLogRecordExporter new;
		maxExportBatchSize: 512;
		maxQueueSize: 2048;
		scheduledDelayMillis: 1000;
		yourself).
```

`OTConsoleLogRecordExporter` is intended for debugging and learning. Its output
format is intentionally unspecified and may change.

To use OTLP explicitly:

```smalltalk
configuration := OTOtlpExporterConfiguration forSignalNamed: 'LOGS'.
configuration
	endpoint: 'http://collector:4318/v1/logs';
	protocol: 'http/protobuf'.

provider addLogRecordProcessor:
	(OTBatchLogRecordProcessor new
		exporter: (OTOtlpHttpProtobufLogRecordExporter configuration: configuration);
		yourself).
```

When using `OTLoggerProvider current`, `OTEL_LOGS_EXPORTER=otlp` now selects an
OTLP exporter and wraps it in a batch processor. `OTEL_LOGS_EXPORTER=logging`
is accepted as the console-exporter alias.

## Lifecycle

Providers support:

- `forceFlush`
- `shutdown`

After shutdown, the provider returns no-op loggers.
