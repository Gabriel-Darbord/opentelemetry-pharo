Class {
	#name : 'OTOtlpGrpcMetricExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'configuration',
		'exporter'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTOtlpGrpcMetricExporterTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpGrpcMetricExporterTest >> sampleSnapshot [

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
OTOtlpGrpcMetricExporterTest >> setUp [

	super setUp.
	OTGrpcTestSupport installFakeGrpcResolvers.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS' relativePath: 'v1/metrics'.
	configuration
		endpoint: 'http://collector:4317';
		protocol: 'grpc';
		timeoutMillis: 1234;
		headers: (OrderedDictionary new
				 at: 'authorization' put: 'Bearer 123';
				 yourself);
		compression: 'none';
		userAgent: 'OTel-OTLP-Exporter-Pharo/test'.
	exporter := OTOtlpGrpcMetricExporter configuration: configuration
]

{ #category : 'private' }
OTOtlpGrpcMetricExporterTest >> successResponseWithRejectedDataPoints: aCount message: aString [

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

{ #category : 'running' }
OTOtlpGrpcMetricExporterTest >> tearDown [

	[ OTGrpcTestSupport removeFakeGrpcResolvers ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTOtlpGrpcMetricExporterTest >> testExportBuildsGrpcRequestFromConfiguration [

	| capturedRequest reader resourceMetrics |
	exporter requestExecutor: [ :request |
			capturedRequest := request.
			OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[  ] ].
	self assert: (exporter export: self sampleSnapshot).
	self assert: capturedRequest serviceName equals: 'opentelemetry.proto.collector.metrics.v1.MetricsService'.
	self assert: capturedRequest methodName equals: 'Export'.
	self assert: capturedRequest timeoutNanos equals: 1234000000.
	self assert: (capturedRequest metadata valueAt: 'authorization' ifAbsent: [ nil ]) equals: 'Bearer 123'.
	self assert: capturedRequest userAgent equals: 'OTel-OTLP-Exporter-Pharo/test'.
	reader := OTProtobufReader on: capturedRequest payload.
	self assertReader: reader readsField: 1 wireType: 2.
	resourceMetrics := reader readBytes.
	self assert: resourceMetrics notEmpty.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTOtlpGrpcMetricExporterTest >> testExportCompressesPayloadWhenConfigured [

	| capturedRequest reader |
	configuration compression: 'gzip'.
	exporter requestExecutor: [ :request |
			capturedRequest := request.
			OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[  ] ].
	self assert: (exporter export: self sampleSnapshot).
	self assert: capturedRequest messageEncoding equals: 'gzip'.
	reader := OTProtobufReader on: (GZipReadStream on: capturedRequest payload readStream) upToEnd.
	self assertReader: reader readsField: 1 wireType: 2
]

{ #category : 'tests' }
OTOtlpGrpcMetricExporterTest >> testExportReturnsFalseAfterShutdown [

	| executed |
	executed := false.
	exporter requestExecutor: [ :request |
			executed := true.
			OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[  ] ].
	self assert: exporter shutdown.
	self deny: (exporter export: self sampleSnapshot).
	self deny: executed
]

{ #category : 'tests' }
OTOtlpGrpcMetricExporterTest >> testExportUsesDefaultTimeoutWhenConfigurationTimeoutIsNil [

	| capturedRequest |
	configuration timeoutMillis: nil.
	exporter requestExecutor: [ :request |
			capturedRequest := request.
			OTFakeGRPCResponse status: OTFakeGRPCStatus ok payload: #[  ] ].
	self assert: (exporter export: self sampleSnapshot).
	self assert: capturedRequest timeoutNanos equals: 10000000000
]

{ #category : 'tests' }
OTOtlpGrpcMetricExporterTest >> testExportWarnsOnPartialSuccessResponse [

	| warnings |
	warnings := OrderedCollection new.
	exporter
		warningSink: [ :message | warnings add: message ];
		requestExecutor: [ :request |
				OTFakeGRPCResponse
					status: OTFakeGRPCStatus ok
					payload: (self successResponseWithRejectedDataPoints: 2 message: 'collector dropped data points') ].
	self assert: (exporter export: self sampleSnapshot).
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'partial success')
]
