Class {
	#name : 'OTOtlpGrpcSpanExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'configuration',
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpGrpcSpanExporterTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterTest >> sampleSpan [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator traceIdHex: '12345678876543211234567887654321' spanIdHex: '8765432112345678' random: false).
	tracer := provider tracerNamed: 'exporter.test'.
	span := (tracer spanBuilderNamed: 'operation')
		        kind: OTSpan client;
		        startTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		        startSpan.
	span
		restoreAttributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself);
		restoreEvents: #(  );
		restoreLinks: #(  );
		end: DateAndTime unixEpoch + (Duration milliSeconds: 2).
	^ span
]

{ #category : 'running' }
OTOtlpGrpcSpanExporterTest >> setUp [

	super setUp.
	configuration := OTOtlpExporterConfiguration
		forSignalNamed: 'TRACES'
		relativePath: 'v1/traces'.
	configuration
		endpoint: 'http://collector:4317';
		protocol: 'grpc';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new at: 'authorization' put: 'Bearer 123'; yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpGrpcSpanExporter configuration: configuration
]

{ #category : 'private' }
OTOtlpGrpcSpanExporterTest >> successResponseWithRejectedSpans: aCount message: aString [

	| writer |
	writer := OTProtobufWriter withBytes.
	writer
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :partialSuccess |
			partialSuccess
				writeTag: 1 wireType: 0;
				writeVarint: aCount.
			aString ifNotEmpty: [
				partialSuccess
					writeTag: 2 wireType: 2;
					writeString: aString ] ].
	^ writer contents
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterTest >> testExportBuildsGrpcRequestFromConfiguration [

	| capturedRequest reader resourceSpans |
	exporter requestExecutor: [ :request |
		capturedRequest := request.
		OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[ ] ].
	self assert: (exporter export: { self sampleSpan }).
	self assert: capturedRequest serviceName equals: 'opentelemetry.proto.collector.trace.v1.TraceService'.
	self assert: capturedRequest methodName equals: 'Export'.
	self assert: capturedRequest timeoutNanos equals: 1234000000.
	self assert: (capturedRequest metadata valueAt: 'authorization' ifAbsent: [ nil ]) equals: 'Bearer 123'.
	self assert: capturedRequest userAgent equals: 'OTel-OTLP-Exporter-Pharo/test'.
	reader := OTProtobufReader on: capturedRequest payload.
	self assertReader: reader readsField: 1 wireType: 2.
	resourceSpans := reader readBytes.
	self assert: resourceSpans notEmpty.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterTest >> testExportCompressesPayloadWhenConfigured [

	| capturedRequest reader |
	configuration compression: 'gzip'.
	exporter requestExecutor: [ :request |
		capturedRequest := request.
		OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[ ] ].
	self assert: (exporter export: { self sampleSpan }).
	self assert: capturedRequest messageEncoding equals: 'gzip'.
	reader := OTProtobufReader
		on: ((GZipReadStream on: capturedRequest payload readStream) upToEnd).
	self assertReader: reader readsField: 1 wireType: 2
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterTest >> testExportDoesNotOverrideExplicitUserAgentHeader [

	| capturedRequest |
	configuration headers: (OrderedDictionary new
			at: 'User-Agent' put: 'CustomAgent/1.0';
			yourself).
	exporter requestExecutor: [ :request |
		capturedRequest := request.
		OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[ ] ].
	self assert: (exporter export: { self sampleSpan }).
	self assert: capturedRequest userAgent isNil.
	self assert: (capturedRequest metadata valueAt: 'user-agent' ifAbsent: [ nil ]) equals: 'CustomAgent/1.0'
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterTest >> testExportRetriesRetryableGrpcStatusesUntilSuccess [

	| executionCount |
	executionCount := 0.
	exporter
		sleepStrategy: [ :delayMillis | self assert: delayMillis equals: 1000 ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | self fail: message ];
		requestExecutor: [ :request |
			executionCount := executionCount + 1.
			executionCount = 1
				ifTrue: [
					OTFakeGRPCResponse
						status: (OTFakeGRPCStatus code: 14 message: 'busy')
						payload: nil ]
				ifFalse: [
					OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[ ] ] ].
	self assert: (exporter export: { self sampleSpan }).
	self assert: executionCount equals: 2
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterTest >> testExportReturnsFalseOnNonRetryableGrpcStatus [

	| executionCount |
	executionCount := 0.
	exporter
		maxExportAttempts: 3;
		sleepStrategy: [ :delayMillis | self fail ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | self fail: message ];
		requestExecutor: [ :request |
			executionCount := executionCount + 1.
			OTFakeGRPCResponse
				status: (OTFakeGRPCStatus code: 3 message: 'bad request')
				payload: nil ].
	self deny: (exporter export: { self sampleSpan }).
	self assert: executionCount equals: 1
]

{ #category : 'tests' }
OTOtlpGrpcSpanExporterTest >> testExportWarnsOnPartialSuccessResponse [

	| warnings |
	warnings := OrderedCollection new.
	exporter
		warningSink: [ :message | warnings add: message ];
		requestExecutor: [ :request |
			OTFakeGRPCResponse
				status: OTFakeGRPCStatus ok
				payload: (self successResponseWithRejectedSpans: 2 message: 'collector dropped spans') ].
	self assert: (exporter export: { self sampleSpan }).
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'partial success')
]
