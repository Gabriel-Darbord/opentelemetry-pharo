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
		OTTracerProvider resourceConfigurationWarningSink: nil.
		OTTracerProvider resourceDetectors: nil.
		OTTracerProvider samplerConfigurationWarningSink: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
]

{ #category : 'private' }
OTEnvironmentConfigurationTest >> withResourceWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider resourceConfigurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider resourceConfigurationWarningSink: nil ]
]

{ #category : 'private' }
OTEnvironmentConfigurationTest >> withSamplerWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider samplerConfigurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider samplerConfigurationWarningSink: nil ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentDiscardsMalformedResourceAttributesEnvironmentValue [

	self withResourceWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_RESOURCE_ATTRIBUTES' put: 'service.name=demo,bad%ZZ=value';
				yourself)
			during: [
				| provider |
				provider := OTTracerProvider current.
				self assert: provider resource serviceName equals: OTTracerProvider defaultServiceName.
				self assert: (provider resource attributeAt: 'telemetry.sdk.name') equals: 'opentelemetry'.
				self assert: (provider resource attributeAt: 'telemetry.sdk.language') equals: 'pharo'.
				self assert: (provider resource attributeAt: 'telemetry.sdk.version') equals: OTTracerProvider sdkVersion.
				self deny: provider resource isEmpty ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry resource attributes configuration was invalid and has been ignored: ''service.name=demo,bad%ZZ=value'' (Malformed percent encoding)' ]
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
OTEnvironmentConfigurationTest >> testCurrentDisabledSdkPreservesExistingNonRecordingParentSpan [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_SDK_DISABLED' put: 'TRUE';
			yourself)
		during: [
			| parentSpan provider returnedSpan |
			provider := OTTracerProvider current.
			parentSpan := (OTSpanContext
				traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
				spanId: '00f067aa0ba902b7'
				traceFlags: '01'
				traceState: 'rojo=one'
				remote: true) asNonRecordingSpan.
			returnedSpan := (provider tracerNamed: 'demo.scope')
				startSpanNamed: 'operation'
				in: (OTContext new withSpan: parentSpan).
			self assert: returnedSpan identicalTo: parentSpan ]
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
OTEnvironmentConfigurationTest >> testCurrentUsesOtlpStdoutExporterAndBatchProcessorForOtlpStdoutSelection [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_TRACES_EXPORTER' put: 'otlp/stdout';
			yourself)
		during: [
			self assert: OTSpanExporter current class identicalTo: OTOtlpStdoutSpanExporter.
			self assert: OTSpanProcessor current class identicalTo: OTBatchSpanProcessor.
			self assert: OTTracerProvider current spanProcessors first class identicalTo: OTBatchSpanProcessor ]
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
			self assert: (resource attributeAt: 'telemetry.sdk.name') equals: 'opentelemetry'.
			self assert: (resource attributeAt: 'telemetry.sdk.language') equals: 'pharo'.
			self assert: (resource attributeAt: 'telemetry.sdk.version') equals: OTTracerProvider sdkVersion.
			self assert: resource serviceName equals: 'override'.
			self assert: (resource attributeAt: 'host.name') equals: 'pharo'.
			self assert: (resource attributeAt: 'key=value') equals: 'some,thing' ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentProvidesDefaultSdkResourceAttributes [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: resource serviceName equals: OTTracerProvider defaultServiceName.
			self deny: (resource attributeAt: 'service.instance.id') isEmpty.
			self assert: (resource attributeAt: 'telemetry.sdk.name') equals: 'opentelemetry'.
			self assert: (resource attributeAt: 'telemetry.sdk.language') equals: 'pharo'.
			self assert: (resource attributeAt: 'telemetry.sdk.version') equals: OTTracerProvider sdkVersion ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentProvidesProcessRuntimeResourceAttributes [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| resource |
			resource := OTTracerProvider current resource.
			self assert: (resource attributeAt: 'process.executable.name') equals: OTTracerProvider defaultProcessExecutableName.
			self assert: (resource attributeAt: 'process.executable.path') equals: OTTracerProvider defaultProcessExecutablePath.
			self assert: (resource attributeAt: 'process.command') equals: OTTracerProvider currentImagePath.
			self assert: (resource attributeAt: 'process.runtime.name') equals: 'pharo'.
			self assert: (resource attributeAt: 'process.runtime.version') equals: OTTracerProvider runtimeVersion.
			self assert: (resource attributeAt: 'process.runtime.description') equals: OTTracerProvider runtimeDescription.
			self assert: (resource attributeAt: 'process.command_args') equals: OTTracerProvider processCommandArguments ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentReadsServiceNameFromResourceAttributesWhenDedicatedVariableIsAbsent [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_RESOURCE_ATTRIBUTES' put: 'service.name=resource-only';
			yourself)
		during: [
			self assert: OTTracerProvider current resource serviceName equals: 'resource-only' ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentKeepsStableDefaultServiceInstanceIdAcrossProviderReset [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| first second |
			first := OTTracerProvider current resource attributeAt: 'service.instance.id'.
			OTTracerProvider current: nil.
			second := OTTracerProvider current resource attributeAt: 'service.instance.id'.
			self assert: second equals: first ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentLetsResourceAttributesOverrideDefaultServiceInstanceId [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_RESOURCE_ATTRIBUTES' put: 'service.instance.id=instance-42';
			yourself)
		during: [
			self assert: (OTTracerProvider current resource attributeAt: 'service.instance.id') equals: 'instance-42' ]
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
OTEnvironmentConfigurationTest >> testCurrentLogsInvalidSamplerArgumentAndFallsBackToDefaultProbability [

	self
		withSamplerWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
					at: 'OTEL_TRACES_SAMPLER' put: 'traceidratio';
					at: 'OTEL_TRACES_SAMPLER_ARG' put: 'invalid';
					yourself)
				during: [
					| sampler |
					sampler := OTTracerProvider current sampler.
					self assert: sampler class identicalTo: OTTraceIdRatioBasedSampler.
					self assert: sampler probability equals: 1.
					self assert: warnings size equals: 1.
					self assert: warnings first equals:
						'OpenTelemetry sampler argument was invalid and has been ignored for ''traceidratio'': ''invalid''' ] ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentLogsUnknownSamplerNameAndFallsBackToDefaultSampler [

	self
		withSamplerWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
					at: 'OTEL_TRACES_SAMPLER' put: 'mystery';
					yourself)
				during: [
					self assert: OTTracerProvider current sampler class identicalTo: OTParentBasedSampler.
					self assert: warnings size equals: 1.
					self assert: warnings first equals:
						'OpenTelemetry sampler name was unrecognized and has been ignored: ''mystery''' ] ]
]

{ #category : 'tests' }
OTEnvironmentConfigurationTest >> testCurrentLogsUnsupportedJaegerRemoteSamplerNameAndFallsBackToDefaultSampler [

	self
		withSamplerWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
					at: 'OTEL_TRACES_SAMPLER' put: 'jaeger_remote';
					yourself)
				during: [
					self assert: OTTracerProvider current sampler class identicalTo: OTParentBasedSampler.
					self assert: warnings size equals: 1.
					self assert: warnings first equals:
						'OpenTelemetry sampler name is recognized but not supported by this SDK yet: ''jaeger_remote''' ] ]
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
