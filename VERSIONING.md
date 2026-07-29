# OpenTelemetry-Pharo Versioning and Stability

This document defines how `opentelemetry-pharo` applies the OpenTelemetry
versioning and stability requirements.

The OpenTelemetry specification is the source of truth for semantics and
compatibility goals. This document states how those goals map onto this Pharo
implementation.

## Goals

`opentelemetry-pharo` aims to:

- keep stable public APIs and SDK behavior backwards compatible across minor
  releases;
- let users upgrade to newer minor releases without introducing compilation or
  runtime failures in supported Pharo versions;
- isolate development-status work so it does not destabilize stable signals.

## Stability Model

This repository may contain packages with different maturity levels in the same
release, as allowed by the OpenTelemetry specification.

- Stable surface area is documented in the user documentation under
  [`docs/`](docs/README.md).
- Work that is intentionally deferred or still exploratory is documented
  explicitly, for example in
  [`docs/prometheus-future-work.md`](docs/prometheus-future-work.md).

Breaking changes to development-status areas may occur when required by the
specification. Stable public APIs should remain backwards compatible unless a
major version explicitly states otherwise.

## Repository Scope

The repository currently ships:

- instrumentation building blocks;
- tracing API and SDK;
- logging API and SDK;
- metrics API and SDK;
- baggage and text-map propagation;
- OTLP exporters and related transport support.

Prebuilt application instrumentations are intentionally kept out of this
repository so their lifecycle can evolve without destabilizing the core SDK and
API packages.

## Pharo Version Support

The baseline currently supports:

- Pharo 12
- Pharo 13
- Pharo 14

The CI currently exercises:

- Pharo 12
- Pharo 13

Dropping support for a previously supported Pharo version is considered a
breaking compatibility change. Such a change should follow normal ecosystem
expectations for a breaking release and be called out explicitly in release
notes and repository documentation.

Adding support for a newer Pharo version is a backwards compatible change as
long as existing supported versions keep working.

## Compatibility Expectations

For stable public APIs:

- older user code should keep loading and running on newer minor releases;
- deprecations should be documented before removal;
- internal refactorings should not leak as user-visible breakage.

For SDK behavior:

- configuration and runtime defaults may improve over time;
- bug fixes may tighten behavior to match the specification more closely;
- spec-required corrections are allowed even when they expose incorrect
  assumptions in non-compliant user code.

## Versioning Practice

This project follows the OpenTelemetry compatibility intent rather than
promising semantic versioning beyond what the Pharo ecosystem tooling exposes
today.

In practice:

- compatible fixes and feature additions should land in normal ongoing releases;
- removals of deprecated stable API should be rare and announced clearly;
- support-policy changes, such as dropping a Pharo version, should be treated
  as breaking changes.
