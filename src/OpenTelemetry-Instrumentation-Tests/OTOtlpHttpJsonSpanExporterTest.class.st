Class {
	#name : 'OTOtlpHttpJsonSpanExporterTest',
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
OTOtlpHttpJsonSpanExporterTest >> payloadFromClientEntity [

	| contents |
	contents := client entity contents.
	(client headers at: 'Content-Encoding' ifAbsent: [ 'identity' ]) = 'gzip'
		ifTrue: [ contents := (GZipReadStream on: contents readStream) upToEnd ].
	^ STONJSON fromString: contents asString
]

{ #category : 'private' }
OTOtlpHttpJsonSpanExporterTest >> sampleSpan [

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
		traceState: 'vendor=value';
		attributes: (Dictionary new at: 'service.name' put: 'demo'; yourself);
		events: #();
		links: #().
	^ span
]

{ #category : 'running' }
OTOtlpHttpJsonSpanExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration
		forSignalNamed: 'TRACES'
		relativePath: 'v1/traces'.
	configuration
		endpoint: 'http://collector:4318/v1/traces';
		protocol: 'http/json';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new at: 'authorization' put: 'Bearer 123'; yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpJsonSpanExporter configuration: configuration.
	exporter httpClient: client
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportAppliesHttpJsonConfigurationAndSendsPayload [

	| payload |
	self assert: (exporter export: { self sampleSpan }).
	self assert: client url equals: 'http://collector:4318/v1/traces'.
	self assert: client method equals: #POST.
	self assert: client timeout equals: 1234.
	self assert: (client headers at: 'authorization') equals: 'Bearer 123'.
	self assert: (client headers at: 'User-Agent') equals: 'OTel-OTLP-Exporter-Pharo/test'.
	self assert: (client headers at: 'Content-Type') equals: 'application/json'.
	self deny: (client headers includesKey: 'Content-Encoding').
	self assert: client entity contentType asString equals: 'application/json'.
	payload := self payloadFromClientEntity.
	self assert: (payload at: 'resourceSpans') size equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportCompressesPayloadWhenConfigured [

	configuration compression: 'gzip'.
	self assert: (exporter export: { self sampleSpan }).
	self assert: (client headers at: 'Content-Encoding') equals: 'gzip'.
	self assert: (self payloadFromClientEntity at: 'resourceSpans') size equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportDoesNotOverrideExplicitUserAgentHeader [

	configuration headers: (OrderedDictionary new
			at: 'User-Agent' put: 'CustomAgent/1.0';
			yourself).
	self assert: (exporter export: { self sampleSpan }).
	self assert: (client headers at: 'User-Agent') equals: 'CustomAgent/1.0'
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportReturnsFalseOnClientFailure [

	client shouldRaiseOnExecute: true.
	self deny: (exporter export: { self sampleSpan })
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportReturnsFalseOnNonSuccessResponse [

	client responseCode: 503.
	self deny: (exporter export: { self sampleSpan })
]
