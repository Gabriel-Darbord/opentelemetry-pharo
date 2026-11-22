# Changelog

## v1.3.1

- Every failed OTLP export holds the exporter back, whatever its status. A
  400, 401, 404, 413, 500 or a redirect, which is not followed, made a request
  for every batch and held nothing back; such a status is not retried, and now
  warns. Any 2xx status is a successful export, and a wait ends with the
  session of the image it began in.
- Trace and span identifiers come from the SDK's own generator, seeded at its
  first use in each session of the image from the operating system's random
  device where there is one, the clock and where the image is. Pharo's shared
  generator is seeded at each start from the milliseconds since the VM started
  and an identity hash, both nearly the same at every start of a saved image,
  so an image started again from the same file repeated its identifiers.
- The default diagnostic logger is built again in each session of the image,
  at the `OTEL_LOG_LEVEL` the image starts with: one saved with the image kept
  the level of the session that built it, and printed what `none` silences.
- Spans or log records that end at once in several processes start one flush
  process: each could start its own, and those not kept outlived their
  processor.

## v1.3.0

- A failed OTLP export holds the exporter back: the batches that follow are
  dropped at once, without a request, for 5 s, doubling with each further
  failure up to 2 min, or as long as a `Retry-After` asks within that; a
  successful export resets it. A batch retries at most three times, not six.
- An error in a batch processor's or the periodic metric reader's background
  loop drops that batch instead of ending the loop, which in a headless image
  quit the image. Spans that fail to encode are dropped.
- HTTP exporters no longer follow redirects, which carried the configured
  headers, `Authorization` included, to wherever the redirect pointed.
- The batch span processor keeps its instances in a weak registry, so saving
  and starting the image no longer walk the heap.
- The gRPC exporters make no request while the image is saved.

## v1.2.2

- Close an exporter's connection when a request fails, and every exporter's
  connection before the image is saved, holding requests back until it runs
  again. A connection saved in the image kept a TLS session whose handle was
  stale once the image started again; finalizing it failed, which stopped a
  headless image as it started.
- An image that quits waits a second at most for its queued spans, and drops
  the rest; one that goes on after saving keeps its queue for after. Saving
  waited for every queued batch, retries included, up to the export timeout.
- An image started from its saved file stops the export it was saved in the
  middle of and drops the spans it was saved with. They were exported at its
  next start, under whatever settings it had then, and the start waited for it.

## v1.2.1

- Read the environment through `OSEnvironment current`, since Pharo 14
  deprecates `Smalltalk os environment` and the Deprecation could stop the code
  reading a variable, such as a configured provider's first span.
- Report the SDK's version as `telemetry.sdk.version` and in the OTLP
  exporter's User-Agent; both said `dev`.

## v1.2.0

- Support Pharo 10 and 11, through compatibility packages that backport what
  the code uses from Pharo 11 and 12.
- Read system attributes with `Smalltalk vm getSystemAttribute:`, since Pharo 14
  deprecates `Smalltalk getSystemAttribute:` and the Deprecation could fail the
  code starting a span.
- Apply the Zipkin exporter's timeout in milliseconds, as
  `OTEL_EXPORTER_ZIPKIN_TIMEOUT` and the declarative `timeout` give it; it was
  handed to the HTTP client as seconds.

## OpenTelemetry specification v1.62.0

Advances the v1.58.0 baseline through the v1.59.0, v1.60.0,
v1.61.0, and v1.62.0 specification changes for the features this SDK ships.
This does not add profiles, entity startup, composable view matching, or
Prometheus native histogram protocols.

### Pharo support

- Support Pharo 12, 13, 14, and 15; develop and collect coverage on Pharo 14.
- Keep the pinned MethodProxies dependency working with the checked-in trap
  methods and correct removal of hidden method aliases.
- Load PharoBackwardCompatibility for APIs introduced after Pharo 13, including
  exception stack trace printing.
- Temporarily carry the localized Reflectivity sender fix from Pharo
  [#20118](https://github.com/pharo-project/pharo/pull/20118) and
  [#20119](https://github.com/pharo-project/pharo/pull/20119) on Pharo 14/15.
  Remove that compatibility package when supported images contain the fix.

### v1.59.0

- Restrict environment propagation names to normalized ASCII names. Document
  initialization-time extraction and per-child environment copies.
- Check the existing composable sampler implementation against the amended
  specification and reference vectors.

### v1.60.0

- Add programmatic OTLP request and response limits, defaulting to 64 MiB and
  4 MiB, across traces, logs, and metrics over HTTP JSON, HTTP protobuf, and
  gRPC. Check requests before sending and reject oversized responses without
  retry, including while reading/decompressing HTTP bodies and reading gRPC DATA.

### v1.61.0

- Add `attributeValueDepthLimit:` to `OTSpanLimits` and `OTLogRecordLimits`,
  defaulting to 64. Replace nested arrays/maps beyond the limit with `nil`.
  Apply span limits to events and links; log bodies, resources, and metrics
  retain their separate semantics.
- Verify ordered metric batching, independent per-batch deadlines, and
  continued processing after an earlier batch fails or times out.

### v1.62.0

- Make sampler cleanup idempotent under repeated/concurrent shutdown and stop
  built-in samplers from executing sampling logic once shutdown begins.
- Skip processor `onEnding:` calls after the processor starts shutdown.
- Flush pending metric batches and the exporter before periodic-reader shutdown,
  combining failure/timeout results while still attempting exporter shutdown.
- Bound the entire OTLP batch export, including encoding, lock acquisition,
  attempts, and retry delays, while respecting earlier caller deadlines.
  A zero timeout disables the overall deadline; native I/O timeouts still apply.
- Convert HTTP timeout units to Zinc seconds and use one-shot connections so
  Zinc connection recovery cannot swallow timeout notifications. This disables
  HTTP keep-alive reuse until the underlying recovery behavior is corrected.
- Encode non-OTLP nested values and attribute collections as JSON, preserving
  scalar types and escaping strings in Zipkin annotations and Prometheus labels.
- Warn and skip unrecognized declarative resource detectors; missing exporter
  and other plugin components remain errors.
