Class {
	#name : 'OTOtlpGrpcIntegrationTest',
	#superclass : 'TestCase',
	#instVars : [
		'otelEnvironmentSnapshot'
	],
	#category : 'OpenTelemetry-Instrumentation-IntegrationTests',
	#package : 'OpenTelemetry-Instrumentation-IntegrationTests'
}

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> clearNonIntegrationOtelEnvironmentValues [

	| environment |
	environment := Smalltalk os environment.
	environment keys
		select: [ :each | (each beginsWith: 'OTEL_') and: [ (each beginsWith: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_') not ] ]
		thenDo: [ :each | environment removeKey: each ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> collectorEndpoint [

	^ self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_ENDPOINT' ifAbsent: [ 'http://127.0.0.1:4317' ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> collectorOutputFileEnvironmentKeyForSignalNamed: aString [

	aString = 'TRACES' ifTrue: [ ^ 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_TRACE_OUTPUT_FILE' ].
	aString = 'LOGS' ifTrue: [ ^ 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_LOG_OUTPUT_FILE' ].
	aString = 'METRICS' ifTrue: [ ^ 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_METRIC_OUTPUT_FILE' ].
	self error: 'Unsupported OTLP/gRPC integration signal: ' , aString printString
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> collectorOutputFileForSignalNamed: aString [

	| path |
	path := self environmentValueAt: (self collectorOutputFileEnvironmentKeyForSignalNamed: aString) ifAbsent: [
			        aString = 'TRACES'
				        ifTrue: [ self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_OUTPUT_FILE' ifAbsent: [ nil ] ]
				        ifFalse: [ nil ] ].
	^ path ifNotNil: [ path asFileReference ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> environmentValueAt: aKey ifAbsent: aBlock [

	| environment value |
	environment := Smalltalk os environment.
	value := environment at: aKey ifAbsent: [ ^ aBlock value ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ aBlock value ]
		  ifFalse: [ value ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> integrationEnabled [

	| value |
	value := self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_ENABLED' ifAbsent: [ ^ false ].
	value := value asLowercase.
	^ #( '1' 'true' 'yes' 'on' ) includes: value
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> resetTelemetryConfiguration [

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
	OTTracerProvider resourceConfigurationWarningSink: nil.
	OTTracerProvider resourceDetectors: nil.
	OTTracerProvider samplerConfigurationWarningSink: nil.
	OTTracerProvider spanProcessorWarningSink: nil.
	OTTracerProvider tracerConfigurationWarningSink: nil.
	OTTracerProvider tracerNameWarningSink: nil.
	OTTracerProvider reset.
	OTTextMapPropagator reset.
	OTJaegerRemoteSampler grpcDependencyResolver: nil.
	OTOtlpGrpcSpanExporter grpcDependencyResolver: nil.
	OTSpan reset
]

{ #category : 'running' }
OTOtlpGrpcIntegrationTest >> setEnvironmentValue: aValue forKey: aKey [

	| currentValue environment |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'running' }
OTOtlpGrpcIntegrationTest >> setUp [

	super setUp.
	self snapshotOtelEnvironment.
	self clearNonIntegrationOtelEnvironmentValues.
	OTGrpcTestSupport removeFakeGrpcResolvers.
	self resetTelemetryConfiguration
]

{ #category : 'running' }
OTOtlpGrpcIntegrationTest >> snapshotOtelEnvironment [

	| environment |
	environment := Smalltalk os environment.
	otelEnvironmentSnapshot := Dictionary new.
	environment keys
		select: [ :each | each beginsWith: 'OTEL_' ]
		thenDo: [ :each | otelEnvironmentSnapshot at: each put: (environment at: each) ]
]

{ #category : 'running' }
OTOtlpGrpcIntegrationTest >> tearDown [

	[
		OTGrpcTestSupport removeFakeGrpcResolvers.
		self resetTelemetryConfiguration.
		self restoreOtelEnvironment ] ensure: [ super tearDown ]
]

{ #category : 'running' }
OTOtlpGrpcIntegrationTest >> restoreOtelEnvironment [

	| environment |
	environment := Smalltalk os environment.
	environment keys
		select: [ :each | each beginsWith: 'OTEL_' ]
		thenDo: [ :each | environment removeKey: each ].
	otelEnvironmentSnapshot associationsDo: [ :each | self setEnvironmentValue: each value forKey: each key ].
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> waitForCollectorOutputFile: aFileReference toContainAll: someStrings timeoutSeconds: anInteger [

	| deadlineMillis |
	deadlineMillis := Time millisecondClockValue + (anInteger * 1000).
	[ Time millisecondClockValue <= deadlineMillis ] whileTrue: [
			| contents |
			contents := aFileReference exists
				            ifTrue: [
						            [ aFileReference contents ]
							            on: Error
							            do: [ '' ] ]
				            ifFalse: [ '' ].
			(someStrings allSatisfy: [ :each | contents includesSubstring: each ]) ifTrue: [ ^ true ].
			(Delay forMilliseconds: 100) wait ].
	^ false
]
