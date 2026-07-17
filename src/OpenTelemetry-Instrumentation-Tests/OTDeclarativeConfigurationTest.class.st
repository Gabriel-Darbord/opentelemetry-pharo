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
			self assert: logProcessor maxExportBatchSize equals: 2004.
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
OTDeclarativeConfigurationTest >> testConfigFileRejectsConflictingBatchProcessorSettingsForOneSignal [

	self
		should: [
			self
				withConfigurationFileContents:
'file_format: "1.1"
tracer_provider:
  processors:
    - batch:
        schedule_delay: 111
        exporter:
          otlp_http:
            endpoint: http://collector:4318/v1/traces
    - batch:
        schedule_delay: 222
        exporter:
          zipkin:
            endpoint: http://zipkin.example:9411/api/v2/spans
'
				environmentValues: Dictionary new
				during: [ OTConfigurationSource environmentValueAt: 'OTEL_TRACES_EXPORTER' ] ]
		raise: Error
]

{ #category : 'tests' }
OTDeclarativeConfigurationTest >> testConfigFileRejectsUnrepresentableSimpleTraceProcessor [

	self
		should: [
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
				during: [ OTTracerProvider current ] ]
		raise: Error
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
			ifNil: [ environment removeKey: key ifAbsent: [  ] ]
			ifNotNil: [ environment at: key put: value ] ].
	[
		self resetTelemetryConfiguration.
		aBlock value ]
		ensure: [
			snapshot keysAndValuesDo: [ :key :value |
				value == absent
					ifTrue: [ environment removeKey: key ifAbsent: [  ] ]
					ifFalse: [ environment at: key put: value ] ].
			self resetTelemetryConfiguration ]
]
