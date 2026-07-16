Class {
	#name : 'OTOtlpGrpcLogRecordExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'configuration',
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpGrpcLogRecordExporterTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpGrpcLogRecordExporterTest >> sampleLogRecord [

	| record |
	record := OTLogRecord new.
	record
		timestamp: (DateAndTime unixEpoch + (Duration milliSeconds: 1));
		observedTimestamp: (DateAndTime unixEpoch + (Duration milliSeconds: 2));
		severityNumber: OTSeverity error;
		severityText: 'ERROR';
		body: 'collector payload';
		attributes: (Dictionary new at: 'service.name' put: 'demo'; yourself);
		traceId: '12345678876543211234567887654321';
		spanId: '8765432112345678';
		traceFlags: '01';
		eventName: 'exception';
		resource:
			(OTResource attributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself));
		instrumentationScope: (OTInstrumentationScope
				 named: 'demo.scope'
				 version: '1.2.3'
				 schemaUrl: ''
				 attributes: #()).
	^ record
]

{ #category : 'running' }
OTOtlpGrpcLogRecordExporterTest >> setUp [

	super setUp.
	configuration := OTOtlpExporterConfiguration
		forSignalNamed: 'LOGS'
		relativePath: 'v1/logs'.
	configuration
		endpoint: 'http://collector:4317';
		protocol: 'grpc';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new at: 'authorization' put: 'Bearer 123'; yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpGrpcLogRecordExporter configuration: configuration
]

{ #category : 'private' }
OTOtlpGrpcLogRecordExporterTest >> successResponseWithRejectedLogRecords: aCount message: aString [

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
OTOtlpGrpcLogRecordExporterTest >> testExportBuildsGrpcRequestFromConfiguration [

	| capturedRequest reader resourceLogs |
	exporter requestExecutor: [ :request |
		capturedRequest := request.
		OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[ ] ].
	self assert: (exporter export: { self sampleLogRecord }).
	self
		assert: capturedRequest serviceName
		equals: 'opentelemetry.proto.collector.logs.v1.LogsService'.
	self assert: capturedRequest methodName equals: 'Export'.
	self assert: capturedRequest timeoutNanos equals: 1234000000.
	self
		assert: (capturedRequest metadata valueAt: 'authorization' ifAbsent: [ nil ])
		equals: 'Bearer 123'.
	self assert: capturedRequest userAgent equals: 'OTel-OTLP-Exporter-Pharo/test'.
	reader := OTProtobufReader on: capturedRequest payload.
	self assertReader: reader readsField: 1 wireType: 2.
	resourceLogs := reader readBytes.
	self assert: resourceLogs notEmpty.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTOtlpGrpcLogRecordExporterTest >> testExportWarnsOnPartialSuccessResponse [

	| warnings |
	warnings := OrderedCollection new.
	exporter
		warningSink: [ :message | warnings add: message ];
		requestExecutor: [ :request |
			OTFakeGRPCResponse
				status: OTFakeGRPCStatus ok
				payload:
					(self
						successResponseWithRejectedLogRecords: 2
						message: 'collector dropped logs') ].
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'partial success')
]
