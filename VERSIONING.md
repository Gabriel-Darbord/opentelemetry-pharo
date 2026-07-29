# OpenTelemetry-Pharo Versioning and Stability

`opentelemetry-pharo` follows the OpenTelemetry versioning and stability model.
The OpenTelemetry specification is the source of truth for semantics and
compatibility.

## Stable And Development Surface

This repository may ship stable and development-status areas in the same
release.

- Stable public APIs and SDK behavior should remain backwards compatible across
  minor releases.
- Development-status areas may change when required by the specification.
- Deferred or optional work is documented explicitly in the repo docs.

## Compatibility Policy

For the repository features currently shipped, `opentelemetry-pharo` implements
the audited applicable OpenTelemetry `MUST`, `MUST NOT`, `SHOULD`, and
`SHOULD NOT` requirements against OpenTelemetry Specification `v1.58.0`.

Known remaining gaps are limited to optional Prometheus native histogram `MAY`
work.

## Pharo Version Support

The baseline currently supports:

- Pharo 12
- Pharo 13
- Pharo 14

The CI currently exercises:

- Pharo 12
- Pharo 13

Dropping support for a previously supported Pharo version is a breaking
compatibility change.

Adding support for a newer Pharo version is backwards compatible as long as the
existing supported versions keep working.

## Release Expectations

- Compatible fixes and feature additions should land in normal releases.
- Bug fixes may tighten behavior to match the specification more closely.
- Removing deprecated stable API should be rare and called out clearly.
