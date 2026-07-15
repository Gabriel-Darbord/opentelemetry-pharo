# Instrumentation API

This guide is about writing Pharo instrumentations on top of
`opentelemetry-pharo`.

It is specifically about:

- selecting target packages, classes, and methods
- choosing an installation backend
- defining instrumentation modules
- generating spans from instrumentation hooks

## Choose A Backend First

Instrumentations share the same matching and installation model, but they do
not all subclass the same concrete class.

Choose one of these backend-specific base classes:

- `OTMetaLinkInstrumentation`
- `OTMethodProxyInstrumentation`

Both inherit the common matching/install lifecycle from `OTInstrumentation`.

### MetaLink Backend

Use `OTMetaLinkInstrumentation` when you want the mature MetaLink-based path.

Tradeoffs:

- richer and older integration path
- debugger interaction can still be surprising on instrumented methods
- one method cannot be instrumented multiple times in the same MetaLink-based
  style

### MethodProxy Backend

Use `OTMethodProxyInstrumentation` when you want a MethodProxy-based backend.

Tradeoffs:

- different hook shape
- useful when MetaLink is not the right fit
- now has exit-hook parity for abnormal exits, but it is still a separate
  backend with its own runtime behavior

## Organizing Instrumentations With Modules

Group related instrumentations in a subclass of `OTInstrumentationModule`.

Implement:

- `instrumentationName`
- `instrumentations`

Example:

```smalltalk
OTMyLibraryInstrumentationModule class >> instrumentationName

  ^ 'my-library'

OTMyLibraryInstrumentationModule class >> instrumentations

  ^ { OTMyLibraryRequestInstrumentation }
```

Enable and install a module:

```smalltalk
OTMyLibraryInstrumentationModule enabled: true.
OTMyLibraryInstrumentationModule install.
```

## Matching What To Instrument

All instrumentations define three matchers:

- `packageMatcher`
- `classMatcher`
- `methodMatcher`

These return `OTMatcher` instances.

Example:

```smalltalk
packageMatcher

  ^ OTMatcher name: #'MyLibrary-Core'

classMatcher

  ^ OTMatcher name: #MyLibraryClient

methodMatcher

  ^ OTMatcher name: #performRequest:
```

The installer iterates in this order:

1. matching packages
2. matching classes
3. matching methods on both instance side and class side

## Configuring Installation

Every instrumentation implements:

```smalltalk
configure: installer
```

That method configures the backend-specific installer instance.

### MetaLink Installer API

For `OTMetaLinkInstrumentation`, the installer is an `OTMetaLinkInstaller`.

Useful configuration messages include:

- `withObject`
- `withContext`
- `withSender`
- `beOneShot`

Example:

```smalltalk
configure: installer

  installer
    withObject;
    withSender
```

MetaLink hooks receive an argument array whose first element is always an
`RFMethodOperation`.

### MethodProxy Hook Shape

`OTMethodProxyInstrumentation` does not use the MetaLink event object shape.
Its hooks receive the receiver and method arguments directly.

That makes MethodProxy instrumentations simpler when you only need the runtime
receiver, argument list, and return value.

## Hook Protocol By Backend

### MetaLink Instrumentations

Subclass `OTMetaLinkInstrumentation` and implement:

- `onMethodEnter:`
- `onMethodExit:withValue:`

Typical shape:

```smalltalk
onMethodEnter: arguments

  "arguments first is the RFMethodOperation"

onMethodExit: arguments withValue: returnValue

  "run cleanup, add span attributes, end spans"
```

### MethodProxy Instrumentations

Subclass `OTMethodProxyInstrumentation` and implement:

- `beforeExecutionWithReceiver:arguments:`
- `afterExecutionWithReceiver:arguments:returnValue:`

Typical shape:

```smalltalk
beforeExecutionWithReceiver: receiver arguments: arguments

  "start work before the proxied method runs"

afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue

  "record data and answer the original return value"
  ^ returnValue
```

## Using OTInstrumenter Inside An Instrumentation

Most instrumentations should define an `OTInstrumenter` in
`defineInstrumenter`.

Example:

```smalltalk
defineInstrumenter

  instrumenter := OTInstrumenter forInstrumentationNamed: 'my-library'
```

You can then use it from your hooks:

```smalltalk
onMethodEnter: arguments

  span := instrumenter startRequest: arguments first method

onMethodExit: arguments withValue: returnValue

  span attributeAt: 'result.class' put: returnValue class name.
  instrumenter end: span
```

Useful customization points on `OTInstrumenter` include:

- `spanNameExtractor:`
- `spanKindExtractor:`
- `spanSuppressionStrategy:`
- `contextProducer:`
- `tracerProvider:`

## Installation Lifecycle

The following classes respond to `install`, `uninstall`, and `reinstall`:

- `OTAgentInstaller` for all enabled modules in the image
- `OTInstrumentationModule` for one module
- `OTInstrumentation` subclasses for one instrumentation

Examples:

```smalltalk
OTAgentInstaller install.
OTMyLibraryInstrumentationModule reinstall.
OTMyLibraryRequestInstrumentation uninstall.
```

## Backend Adaptability

If you expect multiple instrumentation backends to coexist over time:

- keep matching logic and span-generation policy in the shared instrumentation
  class-side protocol;
- isolate backend-specific argument handling inside the backend subclass hook
  methods;
- keep application-facing tracer, span, baggage, and exporter usage independent
  from the installation backend.

In practice, that means:

- your tracing model should talk to `OTInstrumenter`, `OTTracer`, `OTSpan`,
  and `OpenTelemetry`;
- only your installation wrapper should care whether the hook came from
  MetaLink or MethodProxy.

## Examples In This Repository

See these packages for concrete examples:

- `OpenTelemetry-Agents-Shout`
- `OpenTelemetry-Agents-SUnit`
- `OpenTelemetry-Agents-OpalCompiler`
- `OpenTelemetry-Instrumentation-MetaLink-Tests`
- `OpenTelemetry-Instrumentation-MethodProxy-Tests`
