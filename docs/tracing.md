# Tracing API

This guide covers the Pharo-facing tracing API:

- `OTTracerProvider`
- `OTTracer`
- `OTSpanBuilder`
- `OTSpan`
- `OpenTelemetry`
- `OTBaggage`
- `OTSpanExporter`
- `OTSpanProcessor`

## Loading The Library

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'opentelemetry-pharo' commitish: 'main' path: 'src';
  baseline: 'OpenTelemetry';
  load
```

## The Default Entry Points

Most applications can start from the current singleton objects:

```smalltalk
provider := OTTracerProvider current.
tracer := provider tracerNamed: 'my-app'.
```

`tracerNamed:` creates or reuses a tracer for one instrumentation scope name.
If you need version, schema URL, or scope attributes, use the richer tracer
creation API on `OTTracerProvider`.

## Starting And Ending A Span

The smallest useful flow is:

```smalltalk
| span tracer |
tracer := OTTracerProvider current tracerNamed: 'my-app'.
span := tracer startSpanNamed: 'startup'.
[
  span attributeAt: 'app.phase' put: 'boot'
] ensure: [
  span end
]
```

For a custom kind or explicit parent context:

```smalltalk
| context span tracer |
tracer := OTTracerProvider current tracerNamed: 'my-app'.
context := OpenTelemetry currentContext.
span := (tracer spanBuilderNamed: 'http.request')
  kind: OTSpan server;
  inContext: context;
  startSpan.
[
  span attributeAt: 'http.method' put: 'GET'
] ensure: [
  span end
]
```

For a root span that ignores the current parent span:

```smalltalk
rootSpan := (tracer spanBuilderNamed: 'batch.run')
  asRoot;
  startSpan.
```

## Using The Span Builder

`OTSpanBuilder` is the main API when span creation needs more than a name.

Useful messages include:

- `kind:`
- `inContext:`
- `inCurrentContext`
- `asRoot`
- `attributeAt:put:`
- `attributes:`
- `addLink:`
- `addLinkSpan:`
- `addLinkSpanContext:`
- `startSpan`

Example:

```smalltalk
span := (tracer spanBuilderNamed: 'db.query')
  kind: OTSpan client;
  attributeAt: 'db.system' put: 'sqlite';
  attributeAt: 'db.operation' put: 'select';
  inCurrentContext;
  startSpan.
```

## Working With Current Context

`OpenTelemetry` exposes the implicit current context API:

- `OpenTelemetry currentContext`
- `OpenTelemetry currentSpan`
- `OpenTelemetry currentBaggage`
- `OpenTelemetry useContext:during:`
- `OpenTelemetry useSpan:during:`
- `OpenTelemetry useBaggage:during:`

Example:

```smalltalk
OpenTelemetry
  useSpan: span
  during: [
    child := tracer startSpanNamed: 'child-operation'.
    [ child attributeAt: 'nested' put: true ]
      ensure: [ child end ] ]
```

Current context is process-local. A span or baggage value activated in one
Pharo process is not implicitly shared with another process.

## Baggage

Use `OTBaggage` and `OTBaggageBuilder` for context values that should travel
alongside traces:

```smalltalk
| baggage |
baggage := (OTBaggage builder)
  putEntryNamed: 'tenant.id' value: 'acme';
  putEntryNamed: 'request.id' value: '42';
  build.

OpenTelemetry
  useBaggage: baggage
  during: [
    tracer startSpanNamed: 'handle-request' ]
```

Useful entry points:

- `OTBaggage builder`
- `OTBaggage builderFromContext:`
- `OTBaggage current`
- `OTBaggage current:`
- `OTBaggage use:during:`

## Instrumenters

`OTInstrumenter` is a convenience object for request/response style tracing.
It helps with:

- span naming
- span kind extraction
- suppression decisions
- current-context lookup
- span start/end boilerplate

Minimal example:

```smalltalk
| error response span |
instrumenter := OTInstrumenter forInstrumentationNamed: 'my-http-client'.

span := instrumenter startRequest: request.
[
  "perform the request"
  response := self performRequest: request
] on: Error do: [ :caught |
  error := caught.
  caught pass
] ensure: [
  instrumenter end: span request: request response: response error: error
]
```

The exact request object is up to your code. The Pharo API is intentionally
flexible here.

## Exporters

`OTSpanExporter current` is the process-wide active exporter.

Available built-in exporters include:

- `OTOtlpHttpProtobufSpanExporter` (default autoconfigured exporter)
- `OTConsoleSpanExporter`
- `OTNoopSpanExporter`
- `OTZipkinSpanExporter`
- `OTOtlpHttpJsonSpanExporter`
- `OTOtlpJsonFileSpanExporter`
- `OTJSONFileSpanExporter`
- `OTOtlpStdoutSpanExporter`

Set one explicitly:

```smalltalk
OTSpanExporter current: OTConsoleSpanExporter new.
```

Or let the library read environment configuration:

- `OTEL_TRACES_EXPORTER`
- OTLP exporter variables through `OTOtlpExporterConfiguration`

`OTEL_TRACES_EXPORTER` defaults to `otlp`. This implementation also accepts a
comma-separated list of exporters and installs exporter-specific processors for
each configured exporter. Console export uses `OTSimpleSpanProcessor`; the
other built-in exporters use `OTBatchSpanProcessor`.

If you change exporter-related environment variables at runtime, reset the
singleton objects before reading them again:

```smalltalk
OTSpanExporter reset.
OTSpanProcessor reset.
OTTracerProvider reset.
```

## Diagnostic Output

Configuration warnings and other SDK diagnostic messages flow through
`OTDiagnosticLogger`.

The default logger writes to standard output. If `TinyLogger` is already loaded
in the image, the default logger uses it automatically instead. You can install
another backend explicitly:

```smalltalk
OTDiagnosticLogger current:
  (OTDiagnosticLogger onWarningDo: [ :message |
    Stdio stdout
      nextPutAll: 'OTel: ';
      nextPutAll: message;
      lf ]).
```

Reset it to the default behavior with:

```smalltalk
OTDiagnosticLogger reset.
```

The default logger also reads `OTEL_LOG_LEVEL` case-insensitively. Supported
values are `NONE`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `VERBOSE`, and `ALL`.
If the variable is absent or invalid, the logger falls back to `INFO`.

For suppressed internal SDK errors, you can also install a stricter handler:

```smalltalk
OTDiagnosticLogger current:
  (OTDiagnosticLogger default
    errorHandler: [ :error :message | error pass ];
    yourself).
```

## Span Processors

`OTSpanProcessor current` is the process-wide active processor.

Built-in processors:

- `OTSimpleSpanProcessor`
- `OTBatchSpanProcessor`

Set one explicitly:

```smalltalk
OTSpanProcessor current: OTSimpleSpanProcessor new.
```

Or rely on environment-driven configuration:

- `OTEL_BSP_MAX_QUEUE_SIZE`
- `OTEL_BSP_MAX_EXPORT_BATCH_SIZE`
- `OTEL_BSP_SCHEDULE_DELAY`
- `OTEL_BSP_EXPORT_TIMEOUT`

Invalid batch-processor values are ignored with a diagnostic warning. This
implementation also honors `0` for `OTEL_BSP_SCHEDULE_DELAY` and
`OTEL_BSP_EXPORT_TIMEOUT`; zero timeout means "no export timeout".

## Sampling

Sampling is configured through `OTTracerProvider`.

Useful entry points:

- `OTTracerProvider current`
- `OTTracerProvider current:`
- `OTTracerProvider reset`

Supported environment variables include:

- `OTEL_TRACES_SAMPLER`
- `OTEL_TRACES_SAMPLER_ARG`

The current implementation supports the standard built-in head samplers that
already exist in the codebase, such as always-on, always-off, trace-id-ratio,
and parent-based variants.

## Propagation

Global text-map propagation is available through `OpenTelemetry`:

- `OpenTelemetry textMapPropagator`
- `OpenTelemetry traceContextPropagator`
- `OpenTelemetry baggagePropagator`
- `OpenTelemetry b3TextMapPropagator`
- `OpenTelemetry b3MultiTextMapPropagator`
- `OpenTelemetry jaegerTextMapPropagator`
- `OpenTelemetry xrayTextMapPropagator`
- `OpenTelemetry otTraceTextMapPropagator`

The current global propagator can be configured with `OTEL_PROPAGATORS`.
Configured names are parsed case-insensitively, deduplicated in order, and
unknown values fall back to the default W3C composite with a diagnostic
warning. `none` selects `OTNoopTextMapPropagator`; mixing `none` with other
propagators is treated as invalid and falls back to the default composite.

## Practical Advice

- Use `OTTracer` and `OTSpanBuilder` directly in application code.
- Use `OTInstrumenter` when you are wrapping request/response style library
  operations.
- Use `OpenTelemetry useSpan:during:` or `useContext:during:` instead of
  manually mutating current state around nested work.
- Treat exporter and processor singletons as global process configuration.
