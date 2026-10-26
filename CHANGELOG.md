# Changelog

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
