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

```smalltalk
tracer := OTTracerProvider current
  tracerNamed: 'my-http-client'
  version: '1.2.3'
  schemaUrl: 'https://opentelemetry.io/schemas/1.37.0'
  attributes: {
    'scope.answer' -> 42.
    'scope.role' -> 'client' }.
```

That selector keys tracer identity by the full instrumentation scope tuple
`(name, version, schemaUrl, attributes)`.

## Checking Whether A Tracer Is Enabled

`OTTracer` exposes `enabled` as a fast boolean check that instrumentation code
can use before doing expensive work to prepare span creation arguments.

```smalltalk
tracer enabled ifTrue: [
  attributes := self expensiveSpanAttributes.
  span := (tracer spanBuilderNamed: 'request')
    attributes: attributes;
    startSpan.
  [ self handleRequest ]
    ensure: [ span end ] ]
```

Call `enabled` each time before creating a span when the guarded work is
expensive. The answer is not guaranteed to stay fixed for the lifetime of the
tracer because tracer configuration can change while the image is running.

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

`inContext:` expects a full `OTContext`. If you have a parent span, wrap it
first:

```smalltalk
parentContext := OTContext new withSpan: parentSpan.
span := (tracer spanBuilderNamed: 'child')
  inContext: parentContext;
  startSpan.
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
- `noParent`
- `attributeAt:put:`
- `attributes:`
- `addLink:`
- `addLinkSpan:`
- `addLinkSpanContext:`
- `startTimestamp:`
- `startSpan`

Prefer setting attributes on the builder before `startSpan`. Samplers can only
see attributes that are already present during span creation.

You can also add links directly to a started `OTSpan` with the same
`addLink...` messages. Builder-time links are still preferred when the linked
context is already known, because head sampling can consider them during span
creation.

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
- `OpenTelemetry attachContext:`
- `OpenTelemetry detachContext:`
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

If you need explicit attach/detach semantics, use the token-based API:

```smalltalk
| previousToken |
previousToken := OpenTelemetry attachContext: context.
[
  "run work with context installed"
] ensure: [
  OpenTelemetry detachContext: previousToken ]
```

`detachContext:` answers a boolean so callers can detect wrong-order or
wrong-process detach attempts.

When no span is active, `OpenTelemetry currentSpan` answers an empty
non-recording span with an invalid `SpanContext` rather than `nil`. This keeps
context extraction and no-op flows aligned with the OpenTelemetry API rules.

## Generic Context Values

`OTContext` also provides a generic immutable key/value API for execution-local
state that does not belong in baggage or span state.

Create opaque keys with:

- `OTContext createKeyNamed:`
- `OTContext keyNamed:`

Read and update values with:

- `valueAt:`
- `valueAt:ifAbsent:`
- `withValueAt:put:`
- `withoutValueAt:`

Example:

```smalltalk
| context requestKey updated |
requestKey := OTContext createKeyNamed: 'request-id'.
context := OTContext new.
updated := context withValueAt: requestKey put: 'req-42'.

self assert: (updated valueAt: requestKey) equals: 'req-42'.
self assert: (context valueAt: requestKey ifAbsent: [ #missing ]) equals: #missing.
```

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

- `OTOtlpGrpcSpanExporter`
- `OTOtlpHttpProtobufSpanExporter` (default autoconfigured exporter)
- `OTOtlpHttpJsonSpanExporter`
- `OTConsoleSpanExporter`
- `OTZipkinSpanExporter`
- `OTOtlpJsonFileSpanExporter`
- `OTJSONFileSpanExporter`
- `OTSTONFileSpanExporter`
- `OTNoopSpanExporter`
- `OTOtlpStdoutSpanExporter`

Set one explicitly:

```smalltalk
OTSpanExporter current: OTConsoleSpanExporter new.
```

Or let the library read environment configuration:

- `OTEL_TRACES_EXPORTER`
- OTLP exporter variables through `OTOtlpExporterConfiguration`
- `OTEL_EXPORTER_ZIPKIN_ENDPOINT`
- `OTEL_EXPORTER_ZIPKIN_TIMEOUT`

`OTEL_TRACES_EXPORTER` defaults to `otlp`. This implementation also accepts a
comma-separated list of exporters and installs exporter-specific processors for
each configured exporter. Console export and `otlp/stdout` use
`OTSimpleSpanProcessor`; the other built-in exporters use
`OTBatchSpanProcessor`. `OTEL_TRACES_EXPORTER=logging` is accepted as the
deprecated console-exporter alias.

For OTLP/gRPC, `OTOtlpExporterConfiguration` accepts both full `http(s)` URLs
and bare `host[:port]` authorities. Bare authorities default to a secure
`https` connection unless `OTEL_EXPORTER_OTLP_INSECURE=true` or
`OTEL_EXPORTER_OTLP_TRACES_INSECURE=true` is set.

OTLP exporters also read the TLS file options from the OpenTelemetry exporter
specification:

- `OTEL_EXPORTER_OTLP_CERTIFICATE`
- `OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE`
- `OTEL_EXPORTER_OTLP_CLIENT_KEY`
- `OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY`
- `OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE`
- `OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE`

These file-backed TLS options require a secure `https` endpoint. Client
certificate authentication also requires both the client key and client
certificate files together. The current Pharo TLS runtime supports these
file-based overrides on Unix-like runtimes; unsupported runtimes fail the
export attempt instead of silently ignoring the configuration.

For OTLP trace exporters, invalid scalar environment values are ignored with a
diagnostic warning. Signal-specific values fall back to the shared OTLP value
before falling back to the trace exporter defaults. `OTEL_EXPORTER_OTLP_TIMEOUT=0`
and `OTEL_EXPORTER_OTLP_TRACES_TIMEOUT=0` mean "no timeout".

Zipkin trace export uses the same timeout interpretation:
`OTEL_EXPORTER_ZIPKIN_TIMEOUT=0` means "no timeout", while invalid values fall
back to the default timeout with a diagnostic warning.

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
`OTEL_BSP_EXPORT_TIMEOUT`; zero timeout means "no export timeout". When the
batch processor finishes exporting a batch and still has a partial batch
queued, it starts a fresh `scheduledDelayMillis` window from that export
completion before exporting the partial batch.

## Lifecycle Operations

The shortest lifecycle API is still boolean:

```smalltalk
provider forceFlush.
provider shutdown.
processor forceFlush.
processor shutdown.
exporter forceFlush.
exporter shutdown.
```

Those selectors answer `true` on success and `false` on any unsuccessful
outcome, including timeout.

When caller code needs to distinguish timeout from ordinary failure, use the
result variants:

- `forceFlushResult`
- `shutdownResult`
- `flushResult` on span processors

Those selectors answer an `OTLifecycleResult`. Query it with:

- `isSuccess`
- `isFailure`
- `isTimeout`

Example:

```smalltalk
result := provider forceFlushResult.
result isTimeout ifTrue: [
  "react to timeout without confusing it with a hard failure" ].
```

## Concurrency

In this guide, "concurrent" means shared across multiple Pharo `Process`
instances.

- `OTTracerProvider` supports concurrent tracer lookup, `forceFlush`, and
  `shutdown`.
- `OTTracer` instances are safe to reuse across concurrent callers. Tracer
  configurator updates are meant to become visible without reacquiring the
  tracer.
- Built-in `OTSampler` implementations, including `OTParentBasedSampler`,
  `OTTraceIdRatioBasedSampler`, `OTProbabilisticSampler`,
  `OTCompositeSampler`, `OTJaegerRemoteSampler`, and `OTXRayRemoteSampler`,
  make `shouldSampleIn:traceId:name:kind:attributes:links:` and `description`
  safe under concurrent calls.
- `OTSpan` instances are safe to mutate from concurrent callers. Once `end`
  starts, only the synchronous `onEnding:` span-processor callbacks are
  allowed to keep mutating that span; other concurrent mutations become no-ops.
- `OTSpanEvent` values are immutable snapshots once created and are safe to
  share across concurrent readers.
- `OTSpanLink` values are immutable after creation and are safe to share across
  concurrent readers.
- `OTSpanProcessor` implementations are expected to be concurrency-safe. The
  built-in simple and batch processors serialize calls into their exporter so
  `export:` is not invoked concurrently by one processor instance.
- `OTSpanExporter` implementations must make `forceFlush` and `shutdown` safe
  under concurrent calls. Built-in exporters treat post-shutdown exports as
  unsuccessful and are designed to cooperate with the processor-side export
  serialization above.
- Built-in trace exporters also serialize `export:`, `forceFlush`, and
  `shutdown` per exporter instance. Sharing one exporter instance across
  multiple Pharo processes is supported, but one instance will not run two
  exports at the same time.
- `OTOtlpGrpcSpanExporter`, `OTOtlpHttpJsonSpanExporter`,
  `OTOtlpHttpProtobufSpanExporter`, and `OTZipkinSpanExporter` perform
  synchronous network I/O. They return `false` after shutdown, on transport
  failure, on timeout, and on non-success responses. OTLP timeouts come from
  `OTOtlpExporterConfiguration`; Zipkin timeout comes from
  `OTEL_EXPORTER_ZIPKIN_TIMEOUT`.
- `OTConsoleSpanExporter`, `OTJSONFileSpanExporter`,
  `OTSTONFileSpanExporter`, `OTOtlpJsonFileSpanExporter`, and
  `OTOtlpStdoutSpanExporter` perform synchronous local writes. They return
  `false` after shutdown or when the underlying write fails.
- `OTNoopSpanExporter` is concurrency-safe and always reports success until it
  is shut down.

## Sampling

Sampling is configured through `OTTracerProvider`.

Useful entry points:

- `OTTracerProvider current`
- `OTTracerProvider current:`
- `OTTracerProvider reset`

Supported environment variables include:

- `OTEL_TRACES_SAMPLER`
- `OTEL_TRACES_SAMPLER_ARG`

The current implementation supports the standard built-in head samplers:

- `always_on`
- `always_off`
- `traceidratio`
- `parentbased_always_on`
- `parentbased_always_off`
- `parentbased_traceidratio`
- `jaeger_remote`
- `parentbased_jaeger_remote`
- `xray`

Remote sampler lifecycle is provider-managed. Installing a
`OTJaegerRemoteSampler` or `OTXRayRemoteSampler` on an `OTTracerProvider`
starts its background polling worker automatically, and provider shutdown stops
that worker. When a remote sampler is used standalone before `start`, it still
falls back to lazy refresh on demand.

The X-Ray remote sampler reads `OTEL_TRACES_SAMPLER_ARG` as a comma-separated
set of `key=value` options. The supported options are:

- `endpoint=http://host:port`
- `polling_interval=<seconds>`

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
