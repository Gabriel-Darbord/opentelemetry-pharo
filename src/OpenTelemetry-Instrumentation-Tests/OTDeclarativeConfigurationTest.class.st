Class {
	#name : 'OTDeclarativeConfigurationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTDeclarativeConfigurationTest >> resetTelemetryConfiguration [

	OTConfigurationSource reset.
	OTDiagnosticLogger reset.
	OTLoggerProvider configurationWarningSink: nil.
	OTLoggerProvider reset.
	OTMeterProvider configurationWarningSink: nil.
	OTMeterProvider reset.
	OTSpanExporter warningSink: nil.
	OTSpanExporter reset.
	OTSpanProcessor configurationWarningSink: nil.
	OTSpanProcessor reset.
	OTTracerProvider current: nil.
	OTTracerProvider resourceConfigurationWarningSink: nil.
	OTTracerProvider resourceDetectors: nil.
	OTTracerProvider samplerConfigurationWarningSink: nil.
	OTTracerProvider spanProcessorWarningSink: nil.
	OTTextMapPropagator reset.
	OTSpan reset
]

{ #category : 'running' }
OTDeclarativeConfigurationTest >> setUp [

	super setUp.
	self resetTelemetryConfiguration
]

{ #category : 'running' }
OTDeclarativeConfigurationTest >> tearDown [

	[
		self resetTelemetryConfiguration ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFilePerformsEnvironmentVariableSubstitutionWithoutRecursion [

	self
		withConfigurationFileContents:
'file_format: "1.1"
resource:
  attributes:
    - name: service.name
      value: ${OTEL_TEST_SERVICE_NAME:-fallback-service}
    - name: nested.value
      value: ${OTEL_TEST_NESTED}
'
		environmentValues: (Dictionary new
			at: 'OTEL_TEST_NESTED' put: '${DO_NOT_REPLACE_ME}';
			yourself)
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: resource serviceName equals: 'fallback-service'.
			self assert: (resource attributeAt: 'nested.value') equals: '${DO_NOT_REPLACE_ME}' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsDeclarativeResourceAttributesAndSchemaWithoutDetectionNode [

	self
		withConfigurationFileContents:
'file_format: "1.1"
resource:
  attributes:
    - name: service.name
      value: config-service
    - name: bool_key
      value: true
      type: bool
    - name: int_key
      value: 42
      type: int
    - name: double_key
      value: 1.5
      type: double
    - name: string_array_key
      value: [ one, two ]
      type: string_array
    - name: bool_array_key
      value: [ true, false ]
      type: bool_array
    - name: int_array_key
      value: [ 1, 2 ]
      type: int_array
    - name: double_array_key
      value: [ 1.1, 2.2 ]
      type: double_array
  attributes_list: service.namespace=config-namespace
  schema_url: https://opentelemetry.io/schemas/1.16.0
'
		environmentValues: Dictionary new
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: resource serviceName equals: 'config-service'.
			self assert: resource schemaUrl equals: 'https://opentelemetry.io/schemas/1.16.0'.
			self assert: (resource attributeAt: 'service.namespace') equals: 'config-namespace'.
			self assert: (resource attributeAt: 'bool_key') equals: true.
			self assert: (resource attributeAt: 'int_key') equals: 42.
			self assert: (resource attributeAt: 'double_key') equals: 1.5.
			self assert: (resource attributeAt: 'string_array_key') equals: #( 'one' 'two' ).
			self assert: (resource attributeAt: 'bool_array_key') equals: #( true false ).
			self assert: (resource attributeAt: 'int_array_key') equals: #( 1 2 ).
			self assert: (resource attributeAt: 'double_array_key') equals: #( 1.1 2.2 ) ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileIgnoresInvalidDeclarativeResourceAttributesListWithWarning [

	self
		withConfigurationFileContents:
'file_format: "1.1"
resource:
  attributes:
    - name: service.name
      value: config-service
  attributes_list: good=value,bad=%ZZ
'
		environmentValues: Dictionary new
		during: [
			self withResourceWarningsDo: [ :warnings |
				| resource |
				resource := OTTracerProvider current resource.
				self assert: resource serviceName equals: 'config-service'.
				self assert: (resource attributeAt: 'good') isNil.
				self assert: warnings size equals: 1.
				self
					assert: (warnings first includesSubstring: 'Failed to percent-decode resource.attributes_list entry') ] ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsDeclarativeEnvDetectorFromRawEnvironment [

	self
		withConfigurationFileContents:
'file_format: "1.1"
resource:
  attributes:
    - name: service.name
      value: config-service
  detection/development:
    detectors:
      - env:
'
		environmentValues: (Dictionary new
			at: 'OTEL_RESOURCE_ATTRIBUTES' put: 'deployment.environment.name=prod';
			yourself)
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: resource serviceName equals: 'config-service'.
			self
				assert: (resource attributeAt: 'deployment.environment.name')
				equals: 'prod' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsDeclarativeOsDetectorSeparatelyFromHostDetector [

	self
		withConfigurationFileContents:
'file_format: "1.1"
resource:
  detection/development:
    detectors:
      - os:
'
		environmentValues: Dictionary new
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: (resource attributeAt: 'os.type') notNil.
			self assert: (resource attributeAt: 'host.name') isNil ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsDeclarativeResourceDetectionAttributeFiltering [

	self
		withConfigurationFileContents:
'file_format: "1.1"
resource:
  attributes:
    - name: service.name
      value: config-service
  detection/development:
    attributes:
      included:
        - process.*
      excluded:
        - process.command_args
    detectors:
      - process:
      - service:
'
		environmentValues: Dictionary new
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: resource serviceName equals: 'config-service'.
			self assert: (resource attributeAt: 'process.runtime.name') equals: 'pharo'.
			self assert: (resource attributeAt: 'service.instance.id') isNil.
			self assert: (resource attributeAt: 'process.command_args') isNil ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsTracingMetricsAndLoggingSettings [

	self
		withConfigurationFileContents:
'file_format: "1.1"
log_level: debug
resource:
  attributes:
    - name: service.name
      value: config-service
tracer_provider:
  limits:
    attribute_count_limit: 12
    attribute_value_length_limit: 34
    event_count_limit: 5
    link_count_limit: 6
    event_attribute_count_limit: 7
    link_attribute_count_limit: 8
  processors:
    - batch:
        schedule_delay: 111
        export_timeout: 222
        max_queue_size: 333
        max_export_batch_size: 44
        exporter:
          otlp_http:
            endpoint: http://collector:4318/custom/traces
            compression: gzip
            timeout: 999
            headers_list:
              - name: authorization
                value: Bearer 123
meter_provider:
  exemplar_filter: always_off
  readers:
    - periodic:
        interval: 1001
        timeout: 1002
        exporter:
          otlp_http:
            endpoint: http://collector:4318/custom/metrics
            temporality_preference: delta
            default_histogram_aggregation: base2_exponential_bucket_histogram
logger_provider:
  limits:
    attribute_count_limit: 55
    attribute_value_length_limit: 66
  processors:
    - batch:
        schedule_delay: 2001
        export_timeout: 2002
        max_queue_size: 2003
        max_export_batch_size: 2004
        exporter:
          otlp_http:
            endpoint: http://collector:4318/custom/logs
            compression: gzip
'
		environmentValues: Dictionary new
		during: [
			| counter histogram logProcessor meterProvider reader traceProcessor tracerProvider |
			tracerProvider := OTTracerProvider current.
			traceProcessor := tracerProvider spanProcessors first.
			self assert: tracerProvider resource serviceName equals: 'config-service'.
			self assert: tracerProvider spanLimits attributeCountLimit equals: 12.
			self assert: tracerProvider spanLimits attributeValueLengthLimit equals: 34.
			self assert: tracerProvider spanLimits eventCountLimit equals: 5.
			self assert: tracerProvider spanLimits linkCountLimit equals: 6.
			self assert: tracerProvider spanLimits attributePerEventCountLimit equals: 7.
			self assert: tracerProvider spanLimits attributePerLinkCountLimit equals: 8.
			self assert: traceProcessor scheduledDelayMillis equals: 111.
			self assert: traceProcessor exportTimeoutMillis equals: 222.
			self assert: traceProcessor maxQueueSize equals: 333.
			self assert: traceProcessor batchSize equals: 44.
			self
				assert: traceProcessor exporter configuration endpoint
				equals: 'http://collector:4318/custom/traces'.
			self assert: traceProcessor exporter configuration compression equals: 'gzip'.
			self assert: (traceProcessor exporter configuration headers at: 'authorization') equals: 'Bearer 123'.

			meterProvider := OTMeterProvider current.
			reader := meterProvider metricReaders first.
			counter := (meterProvider meterNamed: 'config.metrics')
				counterNamed: 'requests.total'.
			histogram := (meterProvider meterNamed: 'config.metrics')
				histogramNamed: 'request.duration'.
			self assert: meterProvider exemplarFilter class identicalTo: OTAlwaysOffMetricExemplarFilter.
			self assert: reader exportIntervalMillis equals: 1001.
			self assert: reader exportTimeoutMillis equals: 1002.
			self
				assert: reader exporter configuration endpoint
				equals: 'http://collector:4318/custom/metrics'.
			self assert: (reader temporalityFor: counter) equals: #delta.
			self
				assert: (reader aggregationFor: histogram)
				equals: #base2ExponentialBucketHistogram.

			logProcessor := OTLoggerProvider current logRecordProcessors first.
			self assert: OTLoggerProvider current logRecordLimits attributeCountLimit equals: 55.
			self assert: OTLoggerProvider current logRecordLimits attributeValueLengthLimit equals: 66.
			self assert: logProcessor scheduledDelayMillis equals: 2001.
			self assert: logProcessor exportTimeoutMillis equals: 2002.
			self assert: logProcessor maxQueueSize equals: 2003.
			self assert: logProcessor maxExportBatchSize equals: 2003.
			self
				assert: logProcessor exporter configuration endpoint
				equals: 'http://collector:4318/custom/logs'.
			self assert: logProcessor exporter configuration compression equals: 'gzip' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsStructuredJaegerRemoteSamplerToEnvironmentSurface [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  sampler:
    jaeger_remote:
      endpoint: http://jaeger.example:14250
      interval: 5000
      initial_sampler:
        trace_id_ratio_based:
          ratio: 0.25
'
		environmentValues: Dictionary new
		during: [
			self
				assert: (OTConfigurationSource environmentValueAt: 'OTEL_TRACES_SAMPLER')
				equals: 'jaeger_remote'.
			self
				assert: (OTConfigurationSource environmentValueAt: 'OTEL_TRACES_SAMPLER_ARG')
				equals: 'endpoint=http://jaeger.example:14250,pollingIntervalMs=5000,initialSamplingRate=0.25' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsStructuredParentBasedSampler [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  sampler:
    parent_based:
      root:
        trace_id_ratio_based:
          ratio: 0.5
      remote_parent_sampled:
        always_on:
      remote_parent_not_sampled:
        always_off:
      local_parent_sampled:
        always_on:
      local_parent_not_sampled:
        always_off:
'
		environmentValues: Dictionary new
		during: [
			| rootSampler sampler |
			sampler := OTTracerProvider current sampler.
			self assert: sampler class identicalTo: OTParentBasedSampler.
			rootSampler := sampler rootSampler.
			self assert: rootSampler class identicalTo: OTTraceIdRatioBasedSampler.
			self assert: rootSampler probability equals: 0.5 ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsStructuredProbabilitySampler [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  sampler:
    trace_id_ratio_based:
      ratio: 0.25
'
		environmentValues: Dictionary new
		during: [
			| sampler |
			sampler := OTTracerProvider current sampler.
			self assert: sampler class identicalTo: OTTraceIdRatioBasedSampler.
			self assert: sampler probability equals: 0.25 ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsTraceProcessorSequenceWhenRepresentable [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  processors:
    - simple:
        exporter:
          console:
    - batch:
        schedule_delay: 123
        max_queue_size: 456
        exporter:
          zipkin:
            endpoint: http://zipkin.example:9411/api/v2/spans
            timeout: 789
'
		environmentValues: Dictionary new
		during: [
			| processors |
			processors := OTTracerProvider current spanProcessors.
			self
				assert: (OTConfigurationSource environmentValueAt: 'OTEL_TRACES_EXPORTER')
				equals: 'console,zipkin'.
			self assert: processors size equals: 2.
			self assert: processors first class identicalTo: OTSimpleSpanProcessor.
			self assert: processors second class identicalTo: OTBatchSpanProcessor.
			self assert: processors first exporter class identicalTo: OTConsoleSpanExporter.
			self assert: processors second exporter class identicalTo: OTZipkinSpanExporter.
			self assert: processors second scheduledDelayMillis equals: 123.
			self assert: processors second maxQueueSize equals: 456.
			self
				assert: processors second exporter httpClient request url asString
				equals: 'http://zipkin.example:9411/api/v2/spans'.
			self assert: processors second exporter httpClient timeout equals: 789 ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsLogProcessorSequenceWhenRepresentable [

	self
		withConfigurationFileContents:
'file_format: "1.1"
logger_provider:
  processors:
    - simple:
        exporter:
          console:
    - batch:
        export_timeout: 222
        max_export_batch_size: 33
        exporter:
          otlp_http:
            endpoint: http://collector:4318/custom/logs
'
		environmentValues: Dictionary new
		during: [
			| processors |
			processors := OTLoggerProvider current logRecordProcessors.
			self
				assert: (OTConfigurationSource environmentValueAt: 'OTEL_LOGS_EXPORTER')
				equals: 'console,otlp'.
			self assert: processors size equals: 2.
			self assert: processors first class identicalTo: OTSimpleLogRecordProcessor.
			self assert: processors second class identicalTo: OTBatchLogRecordProcessor.
			self assert: processors first exporter class identicalTo: OTConsoleLogRecordExporter.
			self
				assert: processors second exporter class
				identicalTo: OTOtlpHttpProtobufLogRecordExporter.
			self assert: processors second exportTimeoutMillis equals: 222.
			self assert: processors second maxExportBatchSize equals: 33.
			self
				assert: processors second exporter configuration endpoint
				equals: 'http://collector:4318/custom/logs' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsLoggerConfiguratorDefaultsAndExplicitRules [

	self
		withConfigurationFileContents:
'file_format: "1.1"
logger_provider:
  processors:
    - simple:
        exporter:
          console:
  logger_configurator/development:
    default_config:
      enabled: true
      minimum_severity: warn
    loggers:
      - name: io.opentelemetry.contrib.*
        config:
          enabled: false
      - name: spec.logs
        config:
          enabled: true
          minimum_severity: error
          trace_based: true
'
		environmentValues: Dictionary new
		during: [
			| context defaultLogger disabledLogger sampledContext spanContext tracedLogger |
			disabledLogger := OTLoggerProvider current
				loggerNamed: 'io.opentelemetry.contrib.library'.
			self deny: disabledLogger enabled.

			defaultLogger := OTLoggerProvider current loggerNamed: 'default.logs'.
			self deny: (defaultLogger enabledIn: nil severityNumber: OTSeverity info eventName: nil).
			self assert: (defaultLogger enabledIn: nil severityNumber: OTSeverity warn eventName: nil).

			spanContext := OTSpanContext
				traceId: '0123456789abcdef0123456789abcdef'
				spanId: '0123456789abcdef'
				traceFlags: '00'
				traceState: nil
				remote: false.
			context := OTContext new withSpan: spanContext asNonRecordingSpan.
			tracedLogger := OTLoggerProvider current loggerNamed: 'spec.logs'.
			self deny: (tracedLogger enabledIn: context severityNumber: OTSeverity error eventName: nil).

			sampledContext := OTContext new withSpan: (
				OTSpanContext
					traceId: 'fedcba9876543210fedcba9876543210'
					spanId: 'fedcba9876543210'
					traceFlags: '01'
					traceState: nil
					remote: false) asNonRecordingSpan.
			self assert: (tracedLogger enabledIn: sampledContext severityNumber: OTSeverity error eventName: nil).
			self deny: (tracedLogger enabledIn: sampledContext severityNumber: OTSeverity warn eventName: nil) ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsLoggerConfiguratorRulesInOrder [

	self
		withConfigurationFileContents:
'file_format: "1.1"
logger_provider:
  processors:
    - simple:
        exporter:
          console:
  logger_configurator/development:
    default_config:
      enabled: true
    loggers:
      - name: spec.*
        config:
          enabled: false
      - name: spec.logs
        config:
          enabled: true
'
		environmentValues: Dictionary new
		during: [
			| logger |
			logger := OTLoggerProvider current loggerNamed: 'spec.logs'.
			self deny: logger enabled ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsMeterConfiguratorDefaultsAndExplicitRules [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        exporter:
          console:
  meter_configurator/development:
    default_config:
      enabled: false
    meters:
      - name: config.enabled
        config:
          enabled: true
'
		environmentValues: Dictionary new
		during: [
			| defaultInstrument enabledInstrument provider |
			provider := OTMeterProvider current.
			defaultInstrument := (provider meterNamed: 'default.scope')
				counterNamed: 'requests.total'.
			enabledInstrument := (provider meterNamed: 'config.enabled')
				counterNamed: 'requests.total'.
			self deny: defaultInstrument enabled.
			self assert: enabledInstrument enabled ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsMeterConfiguratorRulesInOrder [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        exporter:
          console:
  meter_configurator/development:
    default_config:
      enabled: true
    meters:
      - name: spec.*
        config:
          enabled: false
      - name: spec.meter
        config:
          enabled: true
'
		environmentValues: Dictionary new
		during: [
			| instrument |
			instrument := (OTMeterProvider current meterNamed: 'spec.meter')
				counterNamed: 'requests.total'.
			self deny: instrument enabled ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsDeclarativeMetricViewAggregationParameters [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        exporter:
          console:
  views:
    - selector:
        instrument_name: request.duration
        instrument_type: histogram
      stream:
        aggregation:
          explicit_bucket_histogram:
            boundaries:
              - 1
              - 10
            record_min_max: false
'
		environmentValues: Dictionary new
		during: [
			| histogram metric point provider reader |
			provider := OTMeterProvider current.
			reader := provider metricReaders first.
			histogram := (provider meterNamed: 'demo.metrics')
				histogramNamed: 'request.duration'
				unit: 'ms'
				description: 'Request duration'.
			histogram record: 0.
			histogram record: 5.
			histogram record: 15.
			metric := reader collectSnapshot metrics first.
			point := metric points first.
			self assert: metric class identicalTo: OTHistogramMetricData.
			self assert: point explicitBounds equals: #( 1.0 10.0 ).
			self assert: point bucketCounts equals: #( 1 1 1 ).
			self assert: point min isNil.
			self assert: point max isNil ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsDeclarativeMetricViewSelectorsAndStreamOverrides [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        exporter:
          console:
  views:
    - selector:
        instrument_name: requests.total
        instrument_type: counter
        meter_name: alpha.metrics
      stream:
        name: alpha.requests
        description: Alpha requests grouped by status
        aggregation_cardinality_limit: 1
        attribute_keys:
          included:
            - status
            - user
          excluded:
            - user
'
		environmentValues: Dictionary new
		during: [
			| alphaMetric betaMetric overflowPoint point provider reader snapshot |
			provider := OTMeterProvider current.
			reader := provider metricReaders first.
			((provider meterNamed: 'alpha.metrics')
				counterNamed: 'requests.total')
				add: 2
				attributes: { 'status' -> '200'. 'user' -> 'alice' }.
			((provider meterNamed: 'alpha.metrics')
				counterNamed: 'requests.total')
				add: 3
				attributes: { 'status' -> '500'. 'user' -> 'bob' }.
			((provider meterNamed: 'beta.metrics')
				counterNamed: 'requests.total')
				add: 7
				attributes: { 'status' -> '201'. 'user' -> 'carol' }.
			snapshot := reader collectSnapshot.
			alphaMetric := snapshot metrics
				detect: [ :each | each name = 'alpha.requests' ]
				ifNone: [ self fail: 'Expected renamed alpha metric' ].
			betaMetric := snapshot metrics
				detect: [ :each | each name = 'requests.total' ]
				ifNone: [ self fail: 'Expected default beta metric' ].
			point := alphaMetric points
				detect: [ :each | (each attributes at: 'status' ifAbsent: [ nil ]) = '200' ]
				ifNone: [ self fail: 'Expected filtered alpha point' ].
			overflowPoint := alphaMetric points
				detect: [ :each |
					(each attributes at: 'otel.metric.overflow' ifAbsent: [ false ]) = true ]
				ifNone: [ self fail: 'Expected alpha overflow point' ].
			self assert: alphaMetric description equals: 'Alpha requests grouped by status'.
			self assert: point value equals: 2.
			self deny: (point attributes includesKey: 'user').
			self assert: overflowPoint value equals: 3.
			self assert: betaMetric points first value equals: 7 ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsMetricReaderSequenceWhenRepresentable [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - pull:
        exporter:
          prometheus:
            host: metrics.example
            port: 9564
    - periodic:
        interval: 2222
        timeout: 3333
        exporter:
          otlp_http:
            endpoint: http://collector:4318/custom/metrics
            temporality_preference: delta
            default_histogram_aggregation: base2_exponential_bucket_histogram
'
		environmentValues: Dictionary new
		during: [
			| counter histogram provider readers |
			provider := OTMeterProvider current.
			readers := provider metricReaders.
			counter := (provider meterNamed: 'config.metrics')
				counterNamed: 'requests.total'.
			histogram := (provider meterNamed: 'config.metrics')
				histogramNamed: 'request.duration'.
			self
				assert: (OTConfigurationSource environmentValueAt: 'OTEL_METRICS_EXPORTER')
				equals: 'prometheus,otlp'.
			self assert: readers size equals: 2.
			self assert: readers first class identicalTo: OTPrometheusMetricReader.
			self assert: readers first host equals: 'metrics.example'.
			self assert: readers first port equals: 9564.
			self assert: readers second class identicalTo: OTPeriodicExportingMetricReader.
			self
				assert: readers second exporter class
				identicalTo: OTOtlpHttpProtobufMetricExporter.
			self assert: readers second exportIntervalMillis equals: 2222.
			self assert: readers second exportTimeoutMillis equals: 3333.
			self
				assert: readers second exporter configuration endpoint
				equals: 'http://collector:4318/custom/metrics'.
			self assert: (readers second temporalityFor: counter) equals: #delta.
			self
				assert: (readers second aggregationFor: histogram)
				equals: #base2ExponentialBucketHistogram ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileSupportsDistinctPeriodicMetricReaderSettings [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        interval: 1111
        timeout: 2222
        exporter:
          console:
    - periodic:
        interval: 3333
        timeout: 4444
        exporter:
          otlp_http:
            endpoint: http://collector:4318/custom/metrics
            temporality_preference: delta
            default_histogram_aggregation: base2_exponential_bucket_histogram
'
		environmentValues: Dictionary new
		during: [
			| counter histogram readers provider |
			provider := OTMeterProvider current.
			readers := provider metricReaders.
			counter := (provider meterNamed: 'config.metrics')
				counterNamed: 'requests.total'.
			histogram := (provider meterNamed: 'config.metrics')
				histogramNamed: 'request.duration'.
			self assert: readers size equals: 2.
			self assert: readers first class identicalTo: OTPeriodicExportingMetricReader.
			self assert: readers first exporter class identicalTo: OTConsoleMetricExporter.
			self assert: readers first exportIntervalMillis equals: 1111.
			self assert: readers first exportTimeoutMillis equals: 2222.
			self assert: readers second class identicalTo: OTPeriodicExportingMetricReader.
			self
				assert: readers second exporter class
				identicalTo: OTOtlpHttpProtobufMetricExporter.
			self assert: readers second exportIntervalMillis equals: 3333.
			self assert: readers second exportTimeoutMillis equals: 4444.
			self
				assert: readers second exporter configuration endpoint
				equals: 'http://collector:4318/custom/metrics'.
			self assert: (readers second temporalityFor: counter) equals: #delta.
			self
				assert: (readers second aggregationFor: histogram)
				equals: #base2ExponentialBucketHistogram ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileSupportsMultipleOtlpMetricReadersWithDistinctSettings [

	self
		withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        interval: 1111
        exporter:
          otlp_http:
            endpoint: http://collector:4318/reader-a/metrics
            temporality_preference: cumulative
    - periodic:
        interval: 2222
        exporter:
          otlp_http:
            endpoint: http://collector:4318/reader-b/metrics
            temporality_preference: delta
'
		environmentValues: Dictionary new
		during: [
			| counter readers provider |
			provider := OTMeterProvider current.
			readers := provider metricReaders.
			counter := (provider meterNamed: 'config.metrics')
				counterNamed: 'requests.total'.
			self assert: readers size equals: 2.
			self
				assert: readers first exporter configuration endpoint
				equals: 'http://collector:4318/reader-a/metrics'.
			self
				assert: readers second exporter configuration endpoint
				equals: 'http://collector:4318/reader-b/metrics'.
			self assert: (readers first temporalityFor: counter) equals: #cumulative.
			self assert: (readers second temporalityFor: counter) equals: #delta ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileRejectsExcludedOnlyDeclarativeMetricViewAttributeKeys [

	self
		should: [
			self
				withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        exporter:
          console:
  views:
    - selector:
        instrument_name: requests.total
      stream:
        attribute_keys:
          excluded:
            - user
'
				environmentValues: Dictionary new
				during: [ OTMeterProvider current ] ]
		raise: Error
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsTracerConfiguratorDefaultsAndExplicitRules [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  processors:
    - simple:
        exporter:
          console:
  tracer_configurator/development:
    default_config:
      enabled: false
    tracers:
      - name: config.enabled
        config:
          enabled: true
'
		environmentValues: Dictionary new
		during: [
			| disabledSpan disabledTracer enabledTracer enabledSpan |
			disabledTracer := OTTracerProvider current tracerNamed: 'default.scope'.
			enabledTracer := OTTracerProvider current tracerNamed: 'config.enabled'.
			self deny: disabledTracer enabled.
			self assert: enabledTracer enabled.
			disabledSpan := (disabledTracer spanBuilderNamed: 'disabled') startSpan.
			enabledSpan := (enabledTracer spanBuilderNamed: 'enabled') startSpan.
			self assert: disabledSpan class identicalTo: OTNonRecordingSpan.
			self assert: enabledSpan isRecording ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileProjectsTracerConfiguratorRulesInOrder [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  processors:
    - simple:
        exporter:
          console:
  tracer_configurator/development:
    default_config:
      enabled: true
    tracers:
      - name: spec.*
        config:
          enabled: false
      - name: spec.tracer
        config:
          enabled: true
'
		environmentValues: Dictionary new
		during: [
			| tracer |
			tracer := OTTracerProvider current tracerNamed: 'spec.tracer'.
			self deny: tracer enabled ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileSupportsDistinctBatchTraceProcessorSettings [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  processors:
    - batch:
        schedule_delay: 111
        export_timeout: 333
        exporter:
          otlp_http:
            endpoint: http://collector:4318/v1/traces
    - batch:
        schedule_delay: 222
        export_timeout: 444
        exporter:
          zipkin:
            endpoint: http://zipkin.example:9411/api/v2/spans
'
		environmentValues: Dictionary new
		during: [
			| processors |
			processors := OTTracerProvider current spanProcessors.
			self assert: processors size equals: 2.
			self assert: processors first class identicalTo: OTBatchSpanProcessor.
			self assert: processors first scheduledDelayMillis equals: 111.
			self assert: processors first exportTimeoutMillis equals: 333.
			self
				assert: processors first exporter class
				identicalTo: OTOtlpHttpProtobufSpanExporter.
			self assert: processors second class identicalTo: OTBatchSpanProcessor.
			self assert: processors second scheduledDelayMillis equals: 222.
			self assert: processors second exportTimeoutMillis equals: 444.
			self assert: processors second exporter class identicalTo: OTZipkinSpanExporter ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileRejectsPeriodicPrometheusReader [

	self
		should: [
			self
				withConfigurationFileContents:
'file_format: "1.1"
meter_provider:
  readers:
    - periodic:
        exporter:
          prometheus:
            host: metrics.example
            port: 9564
'
				environmentValues: Dictionary new
				during: [ OTMeterProvider current ] ]
		raise: Error
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileSupportsSimpleTraceProcessorWithOtlpExporter [

	self
		withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  processors:
    - simple:
        exporter:
          otlp_http:
            endpoint: http://collector:4318/v1/traces
'
		environmentValues: Dictionary new
		during: [
			| processor |
			processor := OTTracerProvider current spanProcessors first.
			self assert: processor class identicalTo: OTSimpleSpanProcessor.
			self
				assert: processor exporter class
				identicalTo: OTOtlpHttpProtobufSpanExporter.
			self
				assert: processor exporter configuration endpoint
				equals: 'http://collector:4318/v1/traces' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileSupportsSimpleLogProcessorWithOtlpExporter [

	self
		withConfigurationFileContents:
'file_format: "1.1"
logger_provider:
  processors:
    - simple:
        exporter:
          otlp_http:
            endpoint: http://collector:4318/v1/logs
'
		environmentValues: Dictionary new
		during: [
			| processor |
			processor := OTLoggerProvider current logRecordProcessors first.
			self assert: processor class identicalTo: OTSimpleLogRecordProcessor.
			self
				assert: processor exporter class
				identicalTo: OTOtlpHttpProtobufLogRecordExporter.
			self
				assert: processor exporter configuration endpoint
				equals: 'http://collector:4318/v1/logs' ]
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileTakesPrecedenceOverEnvironmentVariables [

	self
		withConfigurationFileContents:
'file_format: "1.1"
disabled: false
resource:
  attributes:
    - name: service.name
      value: config-service
propagator:
  composite:
    - baggage:
'
		environmentValues: (Dictionary new
			at: 'OTEL_SDK_DISABLED' put: 'true';
			at: 'OTEL_SERVICE_NAME' put: 'env-service';
			at: 'OTEL_PROPAGATORS' put: 'tracecontext';
			yourself)
		during: [
			| provider |
			provider := OTTracerProvider current.
			self deny: provider spanProcessors isEmpty.
			self assert: provider resource serviceName equals: 'config-service'.
			self assert: OpenTelemetry textMapPropagator fields equals: #( 'baggage' ) ]
]

{ #category : 'private' }
OTDeclarativeConfigurationTest >> withResourceWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider resourceConfigurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider resourceConfigurationWarningSink: nil ]
]

{ #category : 'private' }
OTDeclarativeConfigurationTest >> withConfigurationFileContents: aString environmentValues: aDictionary during: aBlock [

	| configFile environment |
	configFile := FileLocator temp / ('otel-config-', UUID new asString36, '.yaml').
	configFile writeStreamDo: [ :stream | stream nextPutAll: aString ].
	environment := aDictionary copy.
	environment at: 'OTEL_CONFIG_FILE' put: configFile fullName.
	[
		self withEnvironmentValues: environment during: aBlock ]
		ensure: [ configFile ensureDelete ]
]

{ #category : 'private' }
OTDeclarativeConfigurationTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent environment snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	snapshot := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :value |
		snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
		value
			ifNil: [
				(environment at: key ifAbsent: [ absent ]) == absent ifFalse: [
					environment removeKey: key ] ]
			ifNotNil: [ environment at: key put: value ] ].
	[
		self resetTelemetryConfiguration.
		aBlock value ]
		ensure: [
			snapshot keysAndValuesDo: [ :key :value |
				value == absent
					ifTrue: [
						(environment at: key ifAbsent: [ absent ]) == absent ifFalse: [
							environment removeKey: key ] ]
					ifFalse: [ environment at: key put: value ] ].
			self resetTelemetryConfiguration ]
]
