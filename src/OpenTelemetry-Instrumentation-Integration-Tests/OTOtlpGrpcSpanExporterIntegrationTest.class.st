Class {
	#name : 'OTOtlpGrpcSpanExporterIntegrationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Integration-Tests',
	#package : 'OpenTelemetry-Instrumentation-Integration-Tests'
}

{ #category : 'private' }
OTOtlpGrpcSpanExporterIntegrationTest >> collectorEndpoint [

	^ self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_ENDPOINT' ifAbsent: [ 'http://127.0.0.1:4317' ]
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterIntegrationTest >> collectorOutputFile [

	^ (self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_OUTPUT_FILE' ifAbsent: [ ^ nil ]) asFileReference
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterIntegrationTest >> environmentValueAt: aKey ifAbsent: aBlock [

	| environment value |
	environment := Smalltalk os environment.
	value := environment at: aKey ifAbsent: [ ^ aBlock value ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ aBlock value ]
		  ifFalse: [ value ]
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterIntegrationTest >> integrationEnabled [

	| value |
	value := self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_ENABLED' ifAbsent: [ ^ false ].
	value := value asLowercase.
	^ #( '1' 'true' 'yes' 'on' ) includes: value
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterIntegrationTest >> sampleSpanNamed: aString [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: (OTSimpleSpanProcessor new
			 exporter: OTNoopSpanExporter new;
			 yourself).
	tracer := provider tracerNamed: 'otlp.grpc.integration'.
	span := (tracer spanBuilderNamed: aString)
		        kind: OTSpan client;
		        startTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		        startSpan.
	span
		attributeAt: 'integration.case' put: 'otlp-grpc-real-collector';
		end: DateAndTime unixEpoch + (Duration milliSeconds: 2).
	^ span
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterIntegrationTest >> testExportSucceedsAgainstRealCollectorUsingOtlpGrpc [

	| configuration exporter outputFile span spanName |
	(self integrationEnabled and: [ self collectorOutputFile notNil ]) ifFalse: [ self skip ].
	outputFile := self collectorOutputFile.
	spanName := 'pharo.otlp.grpc.integration.' , UUID new asString36.
	span := self sampleSpanNamed: spanName.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES' relativePath: 'v1/traces'.
	configuration
		endpoint: self collectorEndpoint;
		protocol: 'grpc';
		timeoutMillis: 5000;
		compression: 'none'.
	exporter := OTOtlpGrpcSpanExporter configuration: configuration.
	self assert: (exporter export: { span }).
	self assert: (self
			 waitForCollectorOutputFile: outputFile
			 toContainAll: {
					 spanName.
					 span traceId }
			 timeoutSeconds: 10)
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterIntegrationTest >> waitForCollectorOutputFile: aFileReference toContainAll: someStrings timeoutSeconds: anInteger [

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
