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
	(client headers at: 'Content-Encoding' ifAbsent: [ 'identity' ]) = 'gzip' ifTrue: [
		contents := (GZipReadStream on: contents readStream) upToEnd ].
	^ STONJSON fromString: contents asString
]

{ #category : 'private' }
OTOtlpHttpJsonSpanExporterTest >> sampleSpan [

	| parentContext provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: (OTSimpleSpanProcessor new
				 exporter: OTNoopSpanExporter new;
				 yourself);
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
		restoreAttributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself);
		restoreEvents: #(  );
		restoreLinks: #(  );
		end: DateAndTime unixEpoch + (Duration milliSeconds: 2).
	^ span
]

{ #category : 'running' }
OTOtlpHttpJsonSpanExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES' relativePath: 'v1/traces'.
	configuration
		endpoint: 'http://collector:4318/v1/traces';
		protocol: 'http/json';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new
				 at: 'authorization' put: 'Bearer 123';
				 yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpJsonSpanExporter configuration: configuration.
	exporter httpClient: client
]

{ #category : 'running' }
OTOtlpHttpJsonSpanExporterTest >> tearDown [

	OTExporterConnections startUp: false.
	OTOtlpHttpJsonSpanExporter warningSink: nil.
	super tearDown
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAFailedExportDropsTheNextOnesWithoutARequestUntilTheBackoffPasses [

	| now |
	now := 0.
	exporter exportBackoff clock: [ now ].
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			client shouldRaiseOnExecute: true.
			self deny: (exporter export: { self sampleSpan }).
			self assert: client executionCount equals: exporter maxExportAttempts.
			self deny: (exporter export: { self sampleSpan }).
			self assert: client executionCount equals: exporter maxExportAttempts.
			self assert: warnings size equals: 1.
			now := exporter exportBackoff waitMillis.
			client shouldRaiseOnExecute: false.
			self assert: (exporter export: { self sampleSpan }).
			self assert: client executionCount equals: exporter maxExportAttempts + 1 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAFailedExportPrintsItsWarningAtTheConfiguredLogLevel [
	"Through the default logger, which flushes what it writes: the VM's standard output going to a file holds it until its buffer fills or the VM exits."

	| environment previous |
	environment := OSEnvironment current.
	previous := environment at: 'OTEL_LOG_LEVEL' ifAbsent: [ nil ].
	[
		#( 'warn' 'info' 'debug' 'none' 'error' ) do: [ :level |
				| output |
				self setUp.
				output := OTRecordingStandardOutput new.
				environment at: 'OTEL_LOG_LEVEL' put: level.
				OTDiagnosticLogger
					reset;
					tinyLoggerClassResolver: [ nil ];
					standardOutput: output.
				client responseCode: 400.
				self deny: (exporter export: { self sampleSpan }).
				self
					assert:
					(output flushedContents includesSubstring:
						 'OpenTelemetry warning: OpenTelemetry OTLP trace export failed with HTTP status 400')
					equals: (#( 'warn' 'info' 'debug' ) includes: level) ] ] ensure: [
			previous
				ifNil: [ (environment includesKey: 'OTEL_LOG_LEVEL') ifTrue: [ environment removeKey: 'OTEL_LOG_LEVEL' ] ]
				ifNotNil: [ environment at: 'OTEL_LOG_LEVEL' put: previous ].
			OTDiagnosticLogger reset ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAFailedStatusAfterARetryHoldsTheNextExportsBack [

	client
		queueResponseCode: 503 headers: OrderedDictionary new contents: '';
		queueResponseCode: 400 headers: OrderedDictionary new contents: ''.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { self sampleSpan }).
			self assert: client executionCount equals: 2.
			self assert: exporter exportBackoff isWaiting ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAFailedStatusIsLeftAloneAsLongAsItsRetryAfterAsks [

	client
		queueResponseCode: 413
		headers: (OrderedDictionary new
				 at: 'Retry-After' put: '30';
				 yourself)
		contents: ''.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { self sampleSpan }).
			self assert: exporter exportBackoff waitMillis equals: 30000 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testARetryAfterLongerThanARetryEndsTheBatchAndHoldsTheNextOnesBack [

	client
		queueResponseCode: 503
		headers: (OrderedDictionary new
				 at: 'Retry-After' put: '60';
				 yourself)
		contents: '{"message":"busy"}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { self sampleSpan }).
			self assert: client executionCount equals: 1.
			self assert: retrySleeps isEmpty.
			self assert: exporter exportBackoff waitMillis equals: 60000.
			self deny: (exporter export: { self sampleSpan }).
			self assert: client executionCount equals: 1 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testARetryableStatusHoldsTheNextExportsBackOnceItsRetriesAreSpent [

	#( 429 502 503 504 ) do: [ :code |
			self setUp.
			client responseCode: code.
			self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
					self deny: (exporter export: { self sampleSpan }).
					self assert: client executionCount equals: exporter maxExportAttempts.
					self assert: exporter exportBackoff isWaiting description: code printString.
					self assert: warnings size equals: 1.
					self assert: (warnings first includesSubstring: 'exhausted retries after HTTP status ' , code printString).
					self deny: (exporter export: { self sampleSpan }).
					self assert: client executionCount equals: exporter maxExportAttempts ] ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAStatusARetryWouldNotChangeHoldsTheNextExportsBackAtOnce [
	"Redirects included, since they are not followed."

	#( 300 301 302 303 307 308 400 401 403 404 405 413 415 500 501 505 ) do: [ :code |
			self setUp.
			client responseCode: code.
			self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
					self deny: (exporter export: { self sampleSpan }).
					self assert: client executionCount equals: 1.
					self assert: retrySleeps isEmpty.
					self assert: exporter exportBackoff isWaiting description: code printString.
					self assert: exporter exportBackoff waitMillis equals: OTExportBackoff initialDelayMillis.
					self assert: warnings size equals: 1.
					self assert: (warnings first includesSubstring: 'failed with HTTP status ' , code printString).
					self deny: (exporter export: { self sampleSpan }).
					self assert: client executionCount equals: 1 ] ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testASuccessfulExportResetsTheBackoff [

	| now |
	now := 0.
	exporter exportBackoff clock: [ now ].
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			client shouldRaiseOnExecute: true.
			self deny: (exporter export: { self sampleSpan }).
			now := now + exporter exportBackoff waitMillis.
			self deny: (exporter export: { self sampleSpan }).
			self assert: exporter exportBackoff waitMillis > OTExportBackoff initialDelayMillis.
			now := now + exporter exportBackoff waitMillis.
			client shouldRaiseOnExecute: false.
			self assert: (exporter export: { self sampleSpan }).
			client shouldRaiseOnExecute: true.
			self deny: (exporter export: { self sampleSpan }).
			self assert: exporter exportBackoff waitMillis equals: OTExportBackoff initialDelayMillis ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAnExportThatTimesOutHoldsTheNextOnesBack [

	configuration timeoutMillis: 50.
	exporter
		sleepStrategy: [ :delayMillis | (Delay forMilliseconds: 1000) wait ];
		warningSink: [ :message |  ].
	client responseCode: 503.
	self deny: (exporter export: { self sampleSpan }).
	self assert: exporter exportBackoff isWaiting.
	self deny: (exporter export: { self sampleSpan }).
	self assert: client executionCount equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAnUnreadableAnswerToAFailedExportHoldsTheNextOnesBack [

	configuration maxResponseSize: 8.
	client
		responseCode: 500;
		responseContents: '{"message":"a body past the limit"}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { self sampleSpan }).
			self assert: (warnings first includesSubstring: 'maximum response size exceeded').
			self assert: exporter exportBackoff isWaiting ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testAny2xxStatusIsAnAcceptedExport [

	#( 201 202 204 ) do: [ :code |
			self setUp.
			client
				responseCode: code;
				responseContents: ''.
			self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
					self assert: (exporter export: { self sampleSpan }) description: code printString.
					self deny: exporter exportBackoff isWaiting.
					self assert: warnings isEmpty ] ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testEachFailedStatusDoublesTheWait [

	| now |
	now := 0.
	exporter exportBackoff clock: [ now ].
	client responseCode: 404.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { self sampleSpan }).
			now := now + exporter exportBackoff waitMillis.
			self deny: (exporter export: { self sampleSpan }).
			self assert: exporter exportBackoff waitMillis equals: 2 * OTExportBackoff initialDelayMillis.
			self assert: client executionCount equals: 2 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportAppliesHttpJsonConfigurationAndSendsPayload [

	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			| payload |
			self assert: (exporter export: { self sampleSpan }) description: warnings printString.
			self assert: client url = 'http://collector:4318/v1/traces' description: 'endpoint was not applied'.
			self assert: client method = #POST description: 'request method was not POST'.
			self assert: client timeout = 1.234 description: 'timeout was not applied'.
			self assert: (client headers at: 'authorization') = 'Bearer 123' description: 'authorization header missing'.
			self assert: (client headers at: 'User-Agent') = 'OTel-OTLP-Exporter-Pharo/test' description: 'default user-agent missing'.
			self assert: (client headers at: 'Content-Type') = 'application/json' description: 'content type missing'.
			self assert: (client headers at: 'Accept-Encoding') = 'gzip' description: 'accept-encoding missing'.
			self deny: (client headers includesKey: 'Content-Encoding') description: 'request should not be gzip encoded by default'.
			self assert: client entity contentType asString = 'application/json' description: 'entity content type missing'.
			payload := self payloadFromClientEntity.
			self assert: retrySleeps isEmpty.
			self assert: warnings isEmpty.
			self assert: (payload at: 'resourceSpans') size = 1 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportAppliesTlsFilesDuringHttpsExportOnUnixLikeRuntime [

	self withTemporaryTlsFilesDo: [ :caPath :certificatePath :keyPath |
			| tlsExporter |
			configuration
				endpoint: 'https://collector:4318/v1/traces';
				certificateFile: caPath;
				clientCertificateFile: certificatePath;
				clientKeyFile: keyPath.
			tlsExporter := OTTestableOtlpHttpJsonSpanExporter configuration: configuration.
			tlsExporter
				operatingSystemName: 'linux';
				httpClient: client.
			self assert: (tlsExporter export: { self sampleSpan }).
			self assert: client sslCertFileDuringExecute equals: caPath.
			self assert: client certificateDuringExecute notNil.
			self deny: client certificateDuringExecute asFileReference exists ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportClosesTheConnectionWhenARequestFails [

	exporter
		maxExportAttempts: 1;
		warningSink: [ :message |  ].
	client shouldRaiseOnExecute: true.
	self deny: (exporter export: { self sampleSpan }).
	self assert: client closeCount equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportCompressesPayloadWhenConfigured [

	configuration compression: 'gzip'.
	self assert: (exporter export: { self sampleSpan }) description: 'gzip export should succeed'.
	self assert: (client headers at: 'Content-Encoding') = 'gzip' description: 'request should advertise gzip content encoding'.
	self assert: (self payloadFromClientEntity at: 'resourceSpans') size = 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportDoesNotFollowRedirects [

	self assert: (exporter export: { self sampleSpan }).
	self deny: client followRedirects
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportDoesNotOverrideExplicitUserAgentHeader [

	configuration headers: (OrderedDictionary new
			 at: 'User-Agent' put: 'CustomAgent/1.0';
			 yourself).
	self assert: (exporter export: { self sampleSpan }) description: 'custom user-agent export should succeed'.
	self assert: (client headers at: 'User-Agent') = 'CustomAgent/1.0' description: 'explicit user-agent should win'
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportDropsSpansThatFailToEncode [

	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self deny: (exporter export: { Object new }).
			self assert: client executionCount equals: 0.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'failed to encode') ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportLeavesHttpClientTimeoutUnsetForNoLimit [

	configuration timeoutMillis: OTOtlpExporterConfiguration noTimeoutMillis.
	self assert: (exporter export: { self sampleSpan }).
	self assert: client timeout isNil
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportRetriesRetryableHttpResponsesUntilSuccess [

	client
		queueResponseCode: 503 headers: (OrderedDictionary new
				 at: 'Retry-After' put: '2';
				 yourself)
		contents: '{"message":"busy"}';
		queueResponseCode: 200 headers: (OrderedDictionary new
				 at: 'Content-Type' put: 'application/json';
				 yourself)
		contents: '{}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: { self sampleSpan }) description: 'retryable response should eventually succeed'.
			self assert: client executionCount = 2 description: 'expected one retry after 503'.
			self assert: retrySleeps asArray = #( 2000 ) description: 'retry-after should be honored in milliseconds'.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testExportRetriesTransportFailuresUntilSuccess [

	client
		queueExecutionFailure;
		queueResponseCode: 200 headers: (OrderedDictionary new
				 at: 'Content-Type' put: 'application/json';
				 yourself)
		contents: '{}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: { self sampleSpan }) description: 'retryable transport failure should eventually succeed'.
			self assert: client executionCount = 2 description: 'expected one retry after transport failure'.
			self assert: retrySleeps asArray = #( 1000 ) description: 'first backoff delay should be used'.
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
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
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

	client responseContents: '{"partialSuccess":{"rejectedSpans":2,"errorMessage":"collector dropped spans"}}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: { self sampleSpan }) description: 'partial success should still count as success'.
			self assert: retrySleeps isEmpty.
			self assert: warnings size = 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testNoRequestGoesOutWhileTheImageIsSaved [

	OTExporterConnections prepareForSnapshot.
	self deny: (exporter export: { self sampleSpan }).
	self assert: client executionCount equals: 0.
	OTExporterConnections startUp: false.
	self assert: (exporter export: { self sampleSpan }).
	self assert: client executionCount equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testPreparingForASnapshotClosesTheConnection [

	self assert: (exporter export: { self sampleSpan }).
	OTExporterConnections prepareForSnapshot.
	self assert: client closeCount equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testValidateConfiguredTlsOverridesRejectsUnsupportedPlatform [

	self withTemporaryTlsFilesDo: [ :caPath :certificatePath :keyPath |
			| tlsExporter |
			configuration
				endpoint: 'https://collector:4318/v1/traces';
				certificateFile: caPath.
			tlsExporter := OTTestableOtlpHttpJsonSpanExporter configuration: configuration.
			tlsExporter operatingSystemName: 'Mac OS'.
			self should: [ tlsExporter validateConfiguredTlsOverrides ] raise: Error ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testValidateConfiguredTlsOverridesRequiresSecureEndpoint [

	self withTemporaryTlsFilesDo: [ :caPath :certificatePath :keyPath |
			| tlsExporter |
			configuration
				endpoint: 'http://collector:4318/v1/traces';
				certificateFile: caPath.
			tlsExporter := OTTestableOtlpHttpJsonSpanExporter configuration: configuration.
			tlsExporter operatingSystemName: 'linux'.
			self should: [ tlsExporter validateConfiguredTlsOverrides ] raise: Error ]
]

{ #category : 'tests' }
OTOtlpHttpJsonSpanExporterTest >> testWithConfiguredTlsClientCertificateNameDoBuildsCombinedPemOnUnixLikeRuntime [

	self withTemporaryTlsFilesDo: [ :caPath :certificatePath :keyPath |
			| combinedContents combinedPath tlsExporter |
			configuration
				endpoint: 'https://collector:4318/v1/traces';
				clientCertificateFile: certificatePath;
				clientKeyFile: keyPath.
			tlsExporter := OTTestableOtlpHttpJsonSpanExporter configuration: configuration.
			tlsExporter operatingSystemName: 'linux'.
			tlsExporter withConfiguredTlsClientCertificateNameDo: [ :temporaryPath |
					combinedPath := temporaryPath.
					combinedContents := temporaryPath asFileReference contents ].
			self assert: (combinedContents includesSubstring: 'CLIENT').
			self assert: (combinedContents includesSubstring: 'KEY').
			self deny: combinedPath asFileReference exists ]
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

{ #category : 'private' }
OTOtlpHttpJsonSpanExporterTest >> withTemporaryTlsFilesDo: aBlock [

	| caFile certificateFile keyFile |
	caFile := FileReference newTempFilePrefix: 'otel-ca-' suffix: '.pem'.
	certificateFile := FileReference newTempFilePrefix: 'otel-client-cert-' suffix: '.pem'.
	keyFile := FileReference newTempFilePrefix: 'otel-client-key-' suffix: '.pem'.
	caFile writeStreamDo: [ :stream |
			stream
				nextPutAll: '-----BEGIN CERTIFICATE-----';
				lf;
				nextPutAll: 'CA';
				lf;
				nextPutAll: '-----END CERTIFICATE-----';
				lf ].
	certificateFile writeStreamDo: [ :stream |
			stream
				nextPutAll: '-----BEGIN CERTIFICATE-----';
				lf;
				nextPutAll: 'CLIENT';
				lf;
				nextPutAll: '-----END CERTIFICATE-----';
				lf ].
	keyFile writeStreamDo: [ :stream |
			stream
				nextPutAll: '-----BEGIN PRIVATE KEY-----';
				lf;
				nextPutAll: 'KEY';
				lf;
				nextPutAll: '-----END PRIVATE KEY-----';
				lf ].
	[ ^ aBlock value: caFile pathString value: certificateFile pathString value: keyFile pathString ] ensure: [
			caFile ensureDelete.
			certificateFile ensureDelete.
			keyFile ensureDelete ]
]
