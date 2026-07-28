Class {
	#name : 'OTOtlpHttpJsonMetricExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'client',
		'configuration',
		'exporter'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTOtlpHttpJsonMetricExporterTest >> payloadFromClientEntity [

	| contents |
	contents := client entity contents.
	(client headers at: 'Content-Encoding' ifAbsent: [ 'identity' ]) = 'gzip' ifTrue: [
		contents := (GZipReadStream on: contents readStream) upToEnd ].
	^ STONJSON fromString: contents asString
]

{ #category : 'private' }
OTOtlpHttpJsonMetricExporterTest >> sampleSnapshot [

	| point resource scope sumMetric |
	resource := OTResource
		            attributes: {
				            ('service.name' -> 'demo').
				            ('service.instance.id' -> 'pharo-1') }
		            schemaUrl: 'https://resource.example/schema'.
	scope := OTInstrumentationScope
		         named: 'instrumentation'
		         version: '1.0.0'
		         schemaUrl: 'https://scope.example/schema'
		         attributes: { ('scope-key' -> 'scope-value') }.
	point := OTNumberDataPoint
		         attributes: { ('method' -> 'GET') }
		         value: 4
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
	sumMetric := OTSumMetricData new.
	sumMetric
		instrumentationScope: scope;
		name: 'requests.total';
		description: 'Request count';
		unit: '1';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	^ OTMetricSnapshot
		  resource: resource
		  measurements: #(  )
		  metrics: { sumMetric }
		  collectedAt: DateAndTime unixEpoch + (Duration nanoSeconds: 2)
]

{ #category : 'running' }
OTOtlpHttpJsonMetricExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS' relativePath: 'v1/metrics'.
	configuration
		endpoint: 'http://collector:4318/v1/metrics';
		protocol: 'http/json';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new
				 at: 'authorization' put: 'Bearer 123';
				 yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpJsonMetricExporter configuration: configuration.
	exporter httpClient: client
]

{ #category : 'running' }
OTOtlpHttpJsonMetricExporterTest >> tearDown [

	OTOtlpHttpJsonMetricExporter warningSink: nil.
	super tearDown
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportAppliesHttpJsonConfigurationAndSendsPayload [

	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			| payload resourceMetrics |
			self assert: (exporter export: self sampleSnapshot) description: warnings printString.
			self assert: client url equals: 'http://collector:4318/v1/metrics'.
			self assert: client method equals: #POST.
			self assert: client timeout equals: 1234.
			self assert: (client headers at: 'authorization') equals: 'Bearer 123'.
			self assert: (client headers at: 'User-Agent') equals: 'OTel-OTLP-Exporter-Pharo/test'.
			self assert: (client headers at: 'Content-Type') equals: 'application/json'.
			self assert: (client headers at: 'Accept-Encoding') equals: 'gzip'.
			self deny: (client headers includesKey: 'Content-Encoding').
			self assert: client entity contentType asString equals: 'application/json'.
			payload := self payloadFromClientEntity.
			resourceMetrics := (payload at: 'resourceMetrics') first.
			self assert: retrySleeps isEmpty.
			self assert: warnings isEmpty.
			self assert: ((resourceMetrics at: 'scopeMetrics') first at: 'metrics') size equals: 1 ]
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportCompressesPayloadWhenConfigured [

	configuration compression: 'gzip'.
	self assert: (exporter export: self sampleSnapshot) description: 'gzip export should succeed'.
	self assert: (client headers at: 'Content-Encoding') equals: 'gzip'.
	self assert: (self payloadFromClientEntity at: 'resourceMetrics') size equals: 1
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportEncodesNonFiniteNumbersAsJsonStrings [

	| payload point resourceMetrics scopeMetrics snapshot |
	snapshot := self sampleSnapshot.
	point := snapshot metrics first points first.
	point value: Float nan.
	snapshot metrics first metadata: { ('limit' -> Float negativeInfinity) }.
	self assert: (exporter export: snapshot).
	payload := self payloadFromClientEntity.
	resourceMetrics := (payload at: 'resourceMetrics') first.
	scopeMetrics := (resourceMetrics at: 'scopeMetrics') first.
	self assert: ((((scopeMetrics at: 'metrics') first at: 'sum') at: 'dataPoints') first at: 'asDouble') equals: 'NaN'.
	self assert: ((((scopeMetrics at: 'metrics') first at: 'metadata') first at: 'value') at: 'doubleValue') equals: '-Infinity'
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportRetriesRetryableHttpResponsesUntilSuccess [

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
			self assert: (exporter export: self sampleSnapshot) description: 'retryable response should eventually succeed'.
			self assert: client executionCount equals: 2.
			self assert: retrySleeps asArray equals: #( 2000 ).
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportReturnsFalseAfterShutdown [

	self assert: exporter shutdown.
	self deny: (exporter export: self sampleSnapshot).
	self assert: client executionCount equals: 0
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportUsesDefaultTimeoutWhenConfigurationTimeoutIsNil [

	configuration timeoutMillis: nil.
	self assert: (exporter export: self sampleSnapshot).
	self assert: client timeout equals: 10000
]

{ #category : 'tests' }
OTOtlpHttpJsonMetricExporterTest >> testExportWarnsOnPartialSuccessResponse [

	client responseContents: '{"partialSuccess":{"rejectedDataPoints":2,"errorMessage":"collector dropped data points"}}'.
	self withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: self sampleSnapshot) description: 'partial success should still count as success'.
			self assert: retrySleeps isEmpty.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]

{ #category : 'private' }
OTOtlpHttpJsonMetricExporterTest >> withRetrySleepsAndWarningsDo: aBlock [

	| retrySleeps warnings |
	retrySleeps := OrderedCollection new.
	warnings := OrderedCollection new.
	exporter
		sleepStrategy: [ :delayMillis | retrySleeps add: delayMillis ];
		retryJitterBlock: [ :delayMillis | delayMillis ];
		warningSink: [ :message | warnings add: message ].
	^ aBlock value: retrySleeps value: warnings
]
