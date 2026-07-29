Class {
	#name : 'OTOtlpGrpcSpanExporterIntegrationTest',
	#superclass : 'OTOtlpGrpcIntegrationTest',
	#category : 'OpenTelemetry-Instrumentation-IntegrationTests',
	#package : 'OpenTelemetry-Instrumentation-IntegrationTests'
}

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
	(self integrationEnabled and: [ (self collectorOutputFileForSignalNamed: 'TRACES') notNil ]) ifFalse: [ self skip ].
	outputFile := self collectorOutputFileForSignalNamed: 'TRACES'.
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
