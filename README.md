# OpenTelemetry-Pharo
[OpenTelemetry](https://opentelemetry.io/) SDK and instrumentations for [Pharo](https://pharo.org/).  
Use it to instrument, generate, collect, and export telemetry data (<s>metrics, logs, and </s>traces) to help you analyze your software’s performance and behavior.

Disclaimer: This is still in early development!

## Installation

```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'opentelemetry-pharo' commitish: 'main' path: 'src';
  baseline: 'OpenTelemetry';
  load
```

## User Manual

**Warning:** The current implementation uses `MetaLink`s, so it is subject to all the problems that come with it, in particular:
- using the debugger on an instrumented method can lead to strange behavior
- It is not possible to instrument the same method multiple times (and this conflicts with other libraries that use metalinks)

### Defining an Instrumentation

The main instrumentation tools are in the [`OpenTelemetry-Instrumentation`](https://github.com/Gabriel-Darbord/opentelemetry-pharo/tree/main/src/OpenTelemetry-Instrumentation) package.
See the class comments for more details on each class.
Most of the API is class-side.
- To define a module that groups together instrumentations that target the same library, subclass [`OTInstrumentationModule`](src/OpenTelemetry-Instrumentation/OTInstrumentationModule.class.st) and implement the class methods `instrumentationName`, and `instrumentations` that returns the list of instrumentations contained in that module.
- To define an instrumentation, subclass [`OTInstrumentation`](src/OpenTelemetry-Instrumentation/OTInstrumentation.class.st) and implement the following methods:
  - `packageMatcher`, `classMatcher` and `methodMatcher`, which must return a kind of [`OTMatcher`](src/OpenTelemetry-Instrumentation/OTMatcher.class.st) to target the packages, classes and methods to be instrumented, respectively. When installing the instrumentation, the installer will go through the matching packages, then their matching classes, and finally install the instrumentation on the matching methods. See the `OTMatcher` class-side API for some predefined matchers.
  - `configure:` to configure the installation of the metalink using the instance-side API of [`OTAgentInstaller`](src/OpenTelemetry-Instrumentation/OTAgentInstaller.class.st). Here you can specify which arguments are passed to the instrumentation methods.
  - `onMethodEnter:` to execute code before an instrumented method, with the configured arguments.
  - `onMethodExit:withValue:` to execute code after an instrumented method, with the configured arguments plus the method result.

To handle the installation of instrumentation, the following classes (and their subclasses) respond to `install`, `uninstall` and `reinstall`:
- `OTAgentInstaller` handles every instrumentation loaded into the image.
- `OTInstrumentationModule` handles all of the instrumentations it groups.
- `OTInstrumentation` handles itself.

### Generating Traces using an Instrumenter

While an instrumentation can be implemented to do anything, it is usually used to generate traces.
To enable this, an [`OTInstrumenter`](src/OpenTelemetry-Instrumentation/OTInstrumenter.class.st) should be defined in the `defineInstrumenter` method of your `OTInstrumentation` subclass.
The simplest configuration is to just give it the instrumentation name, which should ideally match the instrumented library name in lower kebab-case, per OpenTelemetry standards:
```st
defineInstrumenter
  instrumenter := OTInstrumenter forInstrumentationNamed: 'instrumented-library-name'
```

Then, the instrumenter must be used to start a span:
```st
onMethodEnter: arguments
  "..."
  span := instrumenter startRequest: myRequest.
  "..." 
```
The content of the request is used to extract a name and [kind](https://opentelemetry.io/docs/concepts/signals/traces/#span-kind) for the span, or to suppress it.
It can be anything, and how it is used for naming can also be configured by giving a block to `OTInstrumenter>>#spanNameExtractor:`.

Finally, to end the span:
```st
onMethodExit: arguments withValue: returnValue
  "..."
  instrumenter end.
  "..."
```

See [`OTSpan`](src/OpenTelemetry-Instrumentation/OTSpan.class.st) for the reification of trace data into OpenTelemetry.
Adding custom data to a span can be done using the `attributeAt:put:` method.

### Exporting Traces

The tools for exporting traces can be found in the [`OpenTelemetry-Exporters`](https://github.com/Gabriel-Darbord/opentelemetry-pharo/tree/main/src/OpenTelemetry-Exporters) package.
The exporter configuration is currently defined globally, it affects all instrumentations in the image.
Using an instrumenter will automatically send spans through the export process.

The configured exporter is a singleton in `OTSpanExporter`.
The following exporters are available:
- `OTFileSpanExporter` exports to local JSON files, which by default go into the `pharo-local/OpenTelemetry/traces/` folder of the image. This is the default exporter.
- `OTZipkinSpanExporter` exports to a Zipkin platform. The HTTP client it uses can be accessed and configured through the `httpClient` method.

### Sampling

Currently, all sampling is head-based.
A sampler can be defined in the `defineSampler` method of your `OTInstrumentation` subclass.
See the [`OpenTelemetry-Sampling`](https://github.com/Gabriel-Darbord/opentelemetry-pharo/tree/main/src/OpenTelemetry-Sampling) package.

### Examples

See an [example instrumentation](https://github.com/Gabriel-Darbord/opentelemetry-pharo/tree/main/src/OpenTelemetry-Agents-Shout) that generates traces for [Shout](https://github.com/pharo-project/pharo/tree/1270cd5a5617ceb1d2bbc2c72c5d3ad1f44921d1/src/Shout).

## Contributing

Contributions are welcome!
If you find any issues, have suggestions, or want to contribute new features, please create an issue or submit a pull request.
