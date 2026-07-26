Class {
	#name : 'OTOtlpHttpJsonLogRecordExporterTest',
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
OTOtlpHttpJsonLogRecordExporterTest >> payloadFromClientEntity [

	| contents |
	contents := client entity contents.
	(client headers at: 'Content-Encoding' ifAbsent: [ 'identity' ]) = 'gzip' ifTrue: [
		contents := (GZipReadStream on: contents readStream) upToEnd ].
	^ STONJSON fromString: contents asString
]

{ #category : 'private' }
OTOtlpHttpJsonLogRecordExporterTest >> sampleLogRecord [

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
OTOtlpHttpJsonLogRecordExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'LOGS' relativePath: 'v1/logs'.
	configuration
		endpoint: 'http://collector:4318/v1/logs';
		protocol: 'http/json';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new
				 at: 'authorization' put: 'Bearer 123';
				 yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpJsonLogRecordExporter configuration: configuration.
	exporter httpClient: client
]

{ #category : 'tests' }
OTOtlpHttpJsonLogRecordExporterTest >> testExportAppliesHttpJsonConfigurationAndSendsPayload [

	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			| payload resourceLogs scopeLogs logRecord |
			self assert: (exporter export: { self sampleLogRecord }).
			self assert: client url equals: 'http://collector:4318/v1/logs'.
			self assert: client method equals: #POST.
			self assert: client timeout equals: 1234.
			self assert: (client headers at: 'authorization') equals: 'Bearer 123'.
			self assert: (client headers at: 'User-Agent') equals: 'OTel-OTLP-Exporter-Pharo/test'.
			self assert: (client headers at: 'Content-Type') equals: 'application/json'.
			self assert: (client headers at: 'Accept-Encoding') equals: 'gzip'.
			self deny: (client headers includesKey: 'Content-Encoding').
			self assert: client entity contentType asString equals: 'application/json'.
			payload := self payloadFromClientEntity.
			resourceLogs := payload at: 'resourceLogs'.
			scopeLogs := resourceLogs first at: 'scopeLogs'.
			logRecord := (scopeLogs first at: 'logRecords') first.
			self assert: retrySleeps isEmpty.
			self assert: warnings isEmpty.
			self assert: resourceLogs size equals: 1.
			self assert: (logRecord at: 'severityNumber') equals: OTSeverity error.
			self assert: (logRecord at: 'severityText') equals: 'ERROR'.
			self assert: (logRecord at: 'traceId') equals: '12345678876543211234567887654321'.
			self assert: (logRecord at: 'spanId') equals: '8765432112345678'.
			self assert: (logRecord at: 'eventName') equals: 'exception' ]
]

{ #category : 'tests' }
OTOtlpHttpJsonLogRecordExporterTest >> testExportReturnsFailureAfterShutdownWithoutExecutingHttpRequest [

	self assert: exporter shutdown.
	self deny: (exporter export: { self sampleLogRecord }).
	self deny: exporter forceFlush.
	self deny: exporter shutdown.
	self assert: client executionCount equals: 0
]

{ #category : 'tests' }
OTOtlpHttpJsonLogRecordExporterTest >> testExportSucceedsAgainstLocalHttpServer [

	| receivedBody receivedContentEncoding receivedContentType receivedMethod receivedPath payload |
	ZnServer withOSAssignedPortDo: [ :server |
			server onRequestRespond: [ :request |
					receivedMethod := request method.
					receivedPath := request uri pathSegments asArray.
					receivedContentType := request contentType asString.
					receivedContentEncoding := request headers at: 'Content-Encoding' ifAbsent: [ nil ].
					receivedBody := request entity contents.
					ZnResponse ok: (ZnEntity json: '{}') ].
			configuration endpoint: (server localUrl
					 addPathSegment: 'v1';
					 addPathSegment: 'logs';
					 yourself) asString.
			exporter := OTOtlpHttpJsonLogRecordExporter configuration: configuration.
			self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
					self assert: (exporter export: { self sampleLogRecord }).
					self assert: retrySleeps isEmpty.
					self assert: warnings isEmpty ] ].
	self assert: receivedMethod equals: #POST.
	self assert: receivedPath equals: #( 'v1' 'logs' ).
	self assert: receivedContentType equals: 'application/json'.
	self assert: receivedContentEncoding isNil.
	payload := STONJSON fromString: receivedBody asString.
	self assert: (payload at: 'resourceLogs') size equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonLogRecordExporterTest >> testExportWarnsOnPartialSuccessResponse [

	client responseContents: '{"partialSuccess":{"rejectedLogRecords":2,"errorMessage":"collector dropped logs"}}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: { self sampleLogRecord }).
			self assert: retrySleeps isEmpty.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]

{ #category : 'private' }
OTOtlpHttpJsonLogRecordExporterTest >> withRetrySleepsAndWarningsDo: aBlock [

	| retrySleeps warnings |
	retrySleeps := OrderedCollection new.
	warnings := OrderedCollection new.
	exporter
		sleepStrategy: [ :delayMillis | retrySleeps add: delayMillis ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | warnings add: message ].
	^ aBlock value: retrySleeps value: warnings
]
