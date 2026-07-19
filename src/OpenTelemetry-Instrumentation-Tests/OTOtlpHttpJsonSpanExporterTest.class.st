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

	| parentContext provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator traceIdHex: '12345678876543211234567887654321' spanIdHex: '8765432112345678' random: false).
	parentContext := OTContext new withSpan: (OTSpanContext
			                  traceId: '12345678876543211234567887654321'
			                  spanId: '1111111111111111'
			                  traceFlags: '01'
			                  traceState: 'vendor=value'
			                  remote: true) asNonRecordingSpan.
	tracer := provider tracerNamed: 'exporter.test'.
	span := (tracer spanBuilderNamed: 'operation')
		        kind: OTSpan client;
		        inContext: parentContext;
		        startTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		        startSpan.
	span
		attributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself);
		events: #(  );
		links: #(  );
		end: DateAndTime unixEpoch + (Duration milliSeconds: 2).
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

{ #category : 'running' }
OTOtlpHttpJsonSpanExporterTest >> tearDown [

	OTOtlpHttpJsonSpanExporter warningSink: nil.
	super tearDown
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportAppliesHttpJsonConfigurationAndSendsPayload [

	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings | | payload |
			self
				assert: (exporter export: { self sampleSpan })
				description: warnings printString.
			self
				assert: client url = 'http://collector:4318/v1/traces'
				description: 'endpoint was not applied'.
			self
				assert: client method = #POST
				description: 'request method was not POST'.
			self
				assert: client timeout = 1234
				description: 'timeout was not applied'.
			self
				assert: (client headers at: 'authorization') = 'Bearer 123'
				description: 'authorization header missing'.
			self
				assert: (client headers at: 'User-Agent') = 'OTel-OTLP-Exporter-Pharo/test'
				description: 'default user-agent missing'.
			self
				assert: (client headers at: 'Content-Type') = 'application/json'
				description: 'content type missing'.
			self
				assert: (client headers at: 'Accept-Encoding') = 'gzip'
				description: 'accept-encoding missing'.
			self
				deny: (client headers includesKey: 'Content-Encoding')
				description: 'request should not be gzip encoded by default'.
			self
				assert: client entity contentType asString = 'application/json'
				description: 'entity content type missing'.
			payload := self payloadFromClientEntity.
			self assert: retrySleeps isEmpty.
			self assert: warnings isEmpty.
			self assert: (payload at: 'resourceSpans') size = 1 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportCompressesPayloadWhenConfigured [

	configuration compression: 'gzip'.
	self
		assert: (exporter export: { self sampleSpan })
		description: 'gzip export should succeed'.
	self
		assert: (client headers at: 'Content-Encoding') = 'gzip'
		description: 'request should advertise gzip content encoding'.
	self assert: (self payloadFromClientEntity at: 'resourceSpans') size = 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportDoesNotOverrideExplicitUserAgentHeader [

	configuration headers: (OrderedDictionary new
			at: 'User-Agent' put: 'CustomAgent/1.0';
			yourself).
	self
		assert: (exporter export: { self sampleSpan })
		description: 'custom user-agent export should succeed'.
	self
		assert: (client headers at: 'User-Agent') = 'CustomAgent/1.0'
		description: 'explicit user-agent should win'
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportRetriesRetryableHttpResponsesUntilSuccess [

	client
		queueResponseCode: 503
		headers: (OrderedDictionary new at: 'Retry-After' put: '2'; yourself)
		contents: '{"message":"busy"}';
		queueResponseCode: 200
		headers: (OrderedDictionary new at: 'Content-Type' put: 'application/json'; yourself)
		contents: '{}'.
	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self
				assert: (exporter export: { self sampleSpan })
				description: 'retryable response should eventually succeed'.
			self
				assert: client executionCount = 2
				description: 'expected one retry after 503'.
			self
				assert: retrySleeps asArray = #( 2000 )
				description: 'retry-after should be honored in milliseconds'.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportRetriesTransportFailuresUntilSuccess [

	client
		queueExecutionFailure;
		queueResponseCode: 200
		headers: (OrderedDictionary new at: 'Content-Type' put: 'application/json'; yourself)
		contents: '{}'.
	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self
				assert: (exporter export: { self sampleSpan })
				description: 'retryable transport failure should eventually succeed'.
			self
				assert: client executionCount = 2
				description: 'expected one retry after transport failure'.
			self
				assert: retrySleeps asArray = #( 1000 )
				description: 'first backoff delay should be used'.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportReturnsFalseOnClientFailure [

	exporter
		maxExportAttempts: 1;
		warningSink: [ :message |  ].
	client shouldRaiseOnExecute: true.
	self deny: (exporter export: { self sampleSpan }).
	self assert: client executionCount = 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportReturnsFalseOnInvalidSuccessResponse [

	client responseContents: 'not-json'.
	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { self sampleSpan }).
			self assert: retrySleeps isEmpty.
			self assert: warnings size = 1 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportReturnsFalseOnNonSuccessResponse [

	exporter
		maxExportAttempts: 2;
		sleepStrategy: [ :delayMillis |  ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message |  ].
	client responseCode: 503.
	self deny: (exporter export: { self sampleSpan }).
	self assert: client executionCount = 2
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportWarnsOnPartialSuccessResponse [

	client responseContents:
		'{"partialSuccess":{"rejectedSpans":2,"errorMessage":"collector dropped spans"}}'.
	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self
				assert: (exporter export: { self sampleSpan })
				description: 'partial success should still count as success'.
			self assert: retrySleeps isEmpty.
			self assert: warnings size = 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]

{ #category : 'private' }
OTOtlpHttpJsonSpanExporterTest >> withRetrySleepsAndWarningsDo: aBlock [

	| retrySleeps warnings |
	retrySleeps := OrderedCollection new.
	warnings := OrderedCollection new.
	exporter
		sleepStrategy: [ :delayMillis | retrySleeps add: delayMillis ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | warnings add: message ].
	^ aBlock value: retrySleeps value: warnings
]
