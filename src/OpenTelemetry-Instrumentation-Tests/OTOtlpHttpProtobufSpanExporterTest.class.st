Class {
	#name : 'OTOtlpHttpProtobufSpanExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'configuration',
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpHttpProtobufSpanExporterTest >> sampleSpan [

	| span |
	span := OTSpan new.
	span
		traceId: '12345678876543211234567887654321';
		spanId: '8765432112345678';
		name: 'operation';
		kind: OTSpan client;
		startTime: (DateAndTime unixEpoch + (Duration milliSeconds: 1));
		endTime: (DateAndTime unixEpoch + (Duration milliSeconds: 2));
		traceFlags: '01';
		attributes: (Dictionary new at: 'service.name' put: 'demo'; yourself);
		events: #();
		links: #().
	^ span
]

{ #category : 'private' }
OTOtlpHttpProtobufSpanExporterTest >> successResponseWithRejectedSpans: aCount message: aString [

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

{ #category : 'private' }
OTOtlpHttpProtobufSpanExporterTest >> withRetrySleepsAndWarningsDo: aBlock [

	| retrySleeps warnings |
	retrySleeps := OrderedCollection new.
	warnings := OrderedCollection new.
	exporter
		sleepStrategy: [ :delayMillis | retrySleeps add: delayMillis ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | warnings add: message ].
	^ aBlock value: retrySleeps value: warnings
]

{ #category : 'running' }
OTOtlpHttpProtobufSpanExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration
		forSignalNamed: 'TRACES'
		relativePath: 'v1/traces'.
	configuration
		endpoint: 'http://collector:4318/v1/traces';
		protocol: 'http/protobuf';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new at: 'authorization' put: 'Bearer 123'; yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpProtobufSpanExporter configuration: configuration.
	exporter httpClient: client.
	client responseContents: #[]
]

{ #category : 'tests' }
OTOtlpHttpProtobufSpanExporterTest >> testExportAppliesHttpProtobufConfigurationAndSendsBinaryPayload [

	| reader resourceSpans |
	self assert: (exporter export: { self sampleSpan }).
	self assert: client url equals: 'http://collector:4318/v1/traces'.
	self assert: client method equals: #POST.
	self assert: client timeout equals: 1234.
	self assert: (client headers at: 'authorization') equals: 'Bearer 123'.
	self assert: (client headers at: 'User-Agent') equals: 'OTel-OTLP-Exporter-Pharo/test'.
	self assert: (client headers at: 'Content-Type') equals: 'application/x-protobuf'.
	self assert: (client headers at: 'Accept-Encoding') equals: 'gzip'.
	self assert: client entity contents class identicalTo: ByteArray.
	reader := OTProtobufReader on: client entity contents.
	self assertReader: reader readsField: 1 wireType: 2.
	resourceSpans := reader readBytes.
	self assert: resourceSpans notEmpty.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTOtlpHttpProtobufSpanExporterTest >> testExportWarnsOnPartialSuccessResponse [

	client responseContents:
		(self successResponseWithRejectedSpans: 2 message: 'collector dropped spans').
	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: { self sampleSpan }).
			self assert: retrySleeps isEmpty.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]

{ #category : 'private' }
OTOtlpHttpProtobufSpanExporterTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]
