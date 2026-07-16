Class {
	#name : 'OTOtlpHttpProtobufMetricExporterTest',
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
OTOtlpHttpProtobufMetricExporterTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpHttpProtobufMetricExporterTest >> sampleSnapshot [

	| point resource scope sumMetric |
	resource := OTResource
		attributes: { 'service.name' -> 'demo'. 'service.instance.id' -> 'pharo-1' }
		schemaUrl: 'https://resource.example/schema'.
	scope := OTInstrumentationScope
		named: 'instrumentation'
		version: '1.0.0'
		schemaUrl: 'https://scope.example/schema'
		attributes: { 'scope-key' -> 'scope-value' }.
	point := OTNumberDataPoint
		attributes: { 'method' -> 'GET' }
		value: 4
		startTimestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 1))
		timestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 2)).
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
		measurements: #()
		metrics: { sumMetric }
		collectedAt: (DateAndTime unixEpoch + (Duration nanoSeconds: 2))
]

{ #category : 'private' }
OTOtlpHttpProtobufMetricExporterTest >> successResponseWithRejectedDataPoints: aCount message: aString [

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
OTOtlpHttpProtobufMetricExporterTest >> withRetrySleepsAndWarningsDo: aBlock [

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
OTOtlpHttpProtobufMetricExporterTest >> setUp [

	super setUp.
	client := OTRecordingHttpClient new.
	configuration := OTOtlpExporterConfiguration
		forSignalNamed: 'METRICS'
		relativePath: 'v1/metrics'.
	configuration
		endpoint: 'http://collector:4318/v1/metrics';
		protocol: 'http/protobuf';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new at: 'authorization' put: 'Bearer 123'; yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpHttpProtobufMetricExporter configuration: configuration.
	exporter httpClient: client.
	client responseContents: #[]
]

{ #category : 'running' }
OTOtlpHttpProtobufMetricExporterTest >> tearDown [

	OTOtlpHttpJsonMetricExporter warningSink: nil.
	super tearDown
]

{ #category : 'tests' }
OTOtlpHttpProtobufMetricExporterTest >> testExportAppliesHttpProtobufConfigurationAndSendsBinaryPayload [

	| reader resourceMetrics |
	self assert: (exporter export: self sampleSnapshot).
	self assert: client url equals: 'http://collector:4318/v1/metrics'.
	self assert: client method equals: #POST.
	self assert: client timeout equals: 1234.
	self assert: (client headers at: 'authorization') equals: 'Bearer 123'.
	self assert: (client headers at: 'User-Agent') equals: 'OTel-OTLP-Exporter-Pharo/test'.
	self assert: (client headers at: 'Content-Type') equals: 'application/x-protobuf'.
	self assert: (client headers at: 'Accept-Encoding') equals: 'gzip'.
	self assert: client entity contents class identicalTo: ByteArray.
	reader := OTProtobufReader on: client entity contents.
	self assertReader: reader readsField: 1 wireType: 2.
	resourceMetrics := reader readBytes.
	self assert: resourceMetrics notEmpty.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTOtlpHttpProtobufMetricExporterTest >> testExportWarnsOnPartialSuccessResponse [

	client responseContents:
		(self
			successResponseWithRejectedDataPoints: 2
			message: 'collector dropped data points').
	self
		withRetrySleepsAndWarningsDo: [ :retrySleeps :warnings |
			self assert: (exporter export: self sampleSnapshot).
			self assert: retrySleeps isEmpty.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'partial success') ]
]
