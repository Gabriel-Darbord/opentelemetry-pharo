Class {
	#name : 'OTOtlpHttpProtobufLogRecordExporterTest',
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
OTOtlpHttpProtobufLogRecordExporterTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpHttpProtobufLogRecordExporterTest >> sampleLogRecord [

	| record |
	record := OTLogRecord new.
	record
		timestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		observedTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 2);
		severityNumber: OTSeverity error;
		severityText: 'ERROR';
		body: 'collector payload';
		attributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself);
		traceId: '12345678876543211234567887654321';
		spanId: '8765432112345678';
		traceFlags: '01';
		eventName: 'exception';
		resource: (OTResource attributes: (Dictionary new
					  at: 'service.name' put: 'demo';
					  yourself));
		instrumentationScope: (OTInstrumentationScope
				 named: 'demo.scope'
				 version: '1.2.3'
				 schemaUrl: ''
				 attributes: #(  )).
	^ record
]

{ #category : 'running' }
OTOtlpHttpProtobufLogRecordExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'LOGS' relativePath: 'v1/logs'.
	configuration
		endpoint: 'http://collector:4318/v1/logs';
		protocol: 'http/protobuf';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new
				 at: 'authorization' put: 'Bearer 123';
				 yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpProtobufLogRecordExporter configuration: configuration.
	exporter httpClient: client.
	client responseContents: #[  ]
]

{ #category : 'private' }
OTOtlpHttpProtobufLogRecordExporterTest >> successResponseWithRejectedLogRecords: aCount message: aString [

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
OTOtlpHttpProtobufLogRecordExporterTest >> testExportAppliesHttpProtobufConfigurationAndSendsBinaryPayload [

	| reader resourceLogs |
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: client url equals: 'http://collector:4318/v1/logs'.
	self assert: client method equals: #POST.
	self assert: client timeout equals: 1234.
	self assert: (client headers at: 'authorization') equals: 'Bearer 123'.
	self assert: (client headers at: 'User-Agent') equals: 'OTel-OTLP-Exporter-Pharo/test'.
	self assert: (client headers at: 'Content-Type') equals: 'application/x-protobuf'.
	self assert: (client headers at: 'Accept-Encoding') equals: 'gzip'.
	self assert: client entity contents class identicalTo: ByteArray.
	reader := OTProtobufReader on: client entity contents.
	self assertReader: reader readsField: 1 wireType: 2.
	resourceLogs := reader readBytes.
	self assert: resourceLogs notEmpty.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTOtlpHttpProtobufLogRecordExporterTest >> testExportWarnsOnPartialSuccessResponse [

	client responseContents: (self successResponseWithRejectedLogRecords: 2 message: 'collector dropped logs').
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: { self sampleLogRecord }).
			self assert: retrySleeps isEmpty.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]

{ #category : 'private' }
OTOtlpHttpProtobufLogRecordExporterTest >> withRetrySleepsAndWarningsDo: aBlock [

	| retrySleeps warnings |
	retrySleeps := OrderedCollection new.
	warnings := OrderedCollection new.
	exporter
		sleepStrategy: [ :delayMillis | retrySleeps add: delayMillis ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | warnings add: message ].
	^ aBlock value: retrySleeps value: warnings
]
