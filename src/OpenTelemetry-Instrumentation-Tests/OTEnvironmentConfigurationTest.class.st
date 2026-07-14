Class {
	#name : 'OTEnvironmentConfigurationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTEnvironmentConfigurationTest >> setEnvironmentValue: aValue forKey: aKey [

	| environment currentValue |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'running' }
OTEnvironmentConfigurationTest >> setUp [

	super setUp.
	OTTracerProvider current: nil.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil.
	OTSpan reset
]

{ #category : 'running' }
OTEnvironmentConfigurationTest >> tearDown [

	[
		OTTracerProvider current: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentDiscardsMalformedResourceAttributesEnvironmentValue [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_RESOURCE_ATTRIBUTES' put: 'service.name=demo,bad%ZZ=value';
			yourself)
		during: [
			| provider |
			provider := OTTracerProvider current.
			self assert: provider resource isEmpty ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentDisablesSdkWhenConfigured [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_SDK_DISABLED' put: 'TRUE';
			yourself)
		during: [
			| provider span |
			provider := OTTracerProvider current.
			self assert: provider spanProcessors isEmpty.
			span := (provider tracerNamed: 'demo.scope')
				startSpanNamed: 'operation'
				in: OTContext new.
			self assert: span class identicalTo: OTNonRecordingSpan.
			self deny: span spanContext isValid ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentReadsAlwaysOffSamplerFromEnvironment [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_TRACES_SAMPLER' put: 'always_off';
			yourself)
		during: [
			self assert: OTTracerProvider current sampler class identicalTo: OTAlwaysOffSampler ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentUsesNoopExporterWhenTraceExportIsDisabled [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_TRACES_EXPORTER' put: 'none';
			yourself)
		during: [
			self assert: OTSpanExporter current class identicalTo: OTNoopSpanExporter.
			self assert: OTTracerProvider current spanProcessors isEmpty ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentReadsBatchProcessorSizingFromEnvironment [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_BSP_MAX_QUEUE_SIZE' put: '64';
			at: 'OTEL_BSP_MAX_EXPORT_BATCH_SIZE' put: '32';
			at: 'OTEL_BSP_SCHEDULE_DELAY' put: '200';
			at: 'OTEL_BSP_EXPORT_TIMEOUT' put: '300';
			yourself)
		during: [
			| processor |
			processor := OTSpanProcessor current.
			self assert: processor class identicalTo: OTBatchSpanProcessor.
			self assert: processor maxQueueSize equals: 64.
			self assert: processor batchSize equals: 32.
			self assert: processor scheduledDelayMillis equals: 200.
			self assert: processor exportTimeoutMillis equals: 300 ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentUsesConsoleExporterAndSimpleProcessorForConsoleSelection [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_TRACES_EXPORTER' put: 'console';
			yourself)
		during: [
			self assert: OTSpanExporter current class identicalTo: OTConsoleSpanExporter.
			self assert: OTSpanProcessor current class identicalTo: OTSimpleSpanProcessor.
			self assert: OTTracerProvider current spanProcessors first class identicalTo: OTSimpleSpanProcessor ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentReadsResourceAttributesAndServiceNameFromEnvironment [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_RESOURCE_ATTRIBUTES' put: 'service.name=resource,host.name=pharo,key%3Dvalue=some%2Cthing';
			at: 'OTEL_SERVICE_NAME' put: 'override';
			yourself)
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: resource serviceName equals: 'override'.
			self assert: (resource attributeAt: 'host.name') equals: 'pharo'.
			self assert: (resource attributeAt: 'key=value') equals: 'some,thing' ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentUsesZipkinExporterConfigurationFromEnvironment [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_TRACES_EXPORTER' put: 'zipkin';
			at: 'OTEL_EXPORTER_ZIPKIN_ENDPOINT' put: 'http://example.com:9999/custom/path';
			at: 'OTEL_EXPORTER_ZIPKIN_TIMEOUT' put: '1234';
			yourself)
		during: [
			| exporter |
			exporter := OTSpanExporter current.
			self assert: exporter class identicalTo: OTZipkinSpanExporter.
			self assert: exporter httpClient request url asString equals: 'http://example.com:9999/custom/path'.
			self assert: exporter httpClient timeout equals: 1234 ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentReadsZeroValuedSpanLimitsFromEnvironment [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_ATTRIBUTE_COUNT_LIMIT' put: '0';
			at: 'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' put: '0';
			at: 'OTEL_SPAN_EVENT_COUNT_LIMIT' put: '0';
			at: 'OTEL_SPAN_LINK_COUNT_LIMIT' put: '0';
			at: 'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' put: '0';
			at: 'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' put: '0';
			yourself)
		during: [
			| limits |
			limits := OTTracerProvider current spanLimits.
			self assert: limits attributeCountLimit equals: 0.
			self assert: limits attributeValueLengthLimit equals: 0.
			self assert: limits eventCountLimit equals: 0.
			self assert: limits linkCountLimit equals: 0.
			self assert: limits attributePerEventCountLimit equals: 0.
			self assert: limits attributePerLinkCountLimit equals: 0 ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentReadsTraceIdRatioSamplerCaseInsensitivelyAndIgnoresInvalidArgument [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_TRACES_SAMPLER' put: 'PARENTBASED_TRACEIDRATIO';
			at: 'OTEL_TRACES_SAMPLER_ARG' put: 'invalid';
			yourself)
		during: [
			| sampler rootSampler |
			sampler := OTTracerProvider current sampler.
			self assert: sampler class identicalTo: OTParentBasedSampler.
			rootSampler := sampler rootSampler.
			self assert: rootSampler class identicalTo: OTTraceIdRatioBasedSampler.
			self assert: rootSampler probability equals: 1 ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testSpanProcessorCurrentClampsBatchSizeToQueueSize [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_BSP_MAX_QUEUE_SIZE' put: '20';
			at: 'OTEL_BSP_MAX_EXPORT_BATCH_SIZE' put: '40';
			yourself)
		during: [
			self assert: OTSpanProcessor current batchSize equals: 20 ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testSpanProcessorCurrentIgnoresInvalidEnvironmentValues [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_BSP_MAX_QUEUE_SIZE' put: 'invalid';
			at: 'OTEL_BSP_MAX_EXPORT_BATCH_SIZE' put: '-10';
			at: 'OTEL_BSP_SCHEDULE_DELAY' put: '0';
			at: 'OTEL_BSP_EXPORT_TIMEOUT' put: '';
			yourself)
		during: [
			| processor |
			processor := OTSpanProcessor current.
			self assert: processor maxQueueSize equals: OTSpanProcessor defaultBatchSpanProcessorMaxQueueSize.
			self assert: processor batchSize equals: OTSpanProcessor defaultBatchSpanProcessorMaxExportBatchSize.
			self assert: processor scheduledDelayMillis equals: OTSpanProcessor defaultBatchSpanProcessorScheduledDelayMillis.
			self assert: processor exportTimeoutMillis equals: OTSpanProcessor defaultBatchSpanProcessorExportTimeoutMillis ]
]

{ #category : 'private' }
OTEnvironmentConfigurationTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent environment snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	snapshot := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :value |
		snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
		self setEnvironmentValue: value forKey: key ].
	[
		OTTracerProvider current: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		^ aBlock value ]
		ensure: [
			snapshot keysAndValuesDo: [ :key :value |
				self
					setEnvironmentValue: (value == absent ifTrue: [ nil ] ifFalse: [ value ])
					forKey: key ].
			OTTracerProvider current: nil.
			OTSpanProcessor current: nil.
			OTSpanExporter current: nil ]
]
