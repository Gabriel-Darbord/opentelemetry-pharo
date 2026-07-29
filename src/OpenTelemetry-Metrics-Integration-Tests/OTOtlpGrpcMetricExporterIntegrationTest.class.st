Class {
	#name : 'OTOtlpGrpcMetricExporterIntegrationTest',
	#superclass : 'OTOtlpGrpcIntegrationTest',
	#category : 'OpenTelemetry-Metrics-Integration-Tests',
	#package : 'OpenTelemetry-Metrics-Integration-Tests'
}

{ #category : 'private' }
OTOtlpGrpcMetricExporterIntegrationTest >> sampleSnapshotWithResourceId: aString [

	| point resource scope sumMetric |
	resource := OTResource attributes: {
			            ('service.name' -> 'otlp-grpc-metrics-integration').
			            ('service.instance.id' -> aString) }.
	scope := OTInstrumentationScope
		         named: 'otlp.grpc.integration'
		         version: '1.0.0'
		         schemaUrl: ''
		         attributes: #(  ).
	point := OTNumberDataPoint
		         attributes: { ('integration.id' -> aString) }
		         value: 4
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
	sumMetric := OTSumMetricData new.
	sumMetric
		instrumentationScope: scope;
		name: 'integration.requests.total';
		description: 'Integration request count';
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

{ #category : 'tests' }
OTOtlpGrpcMetricExporterIntegrationTest >> testExportSucceedsAgainstRealCollectorUsingOtlpGrpc [

	| configuration exporter outputFile resourceId snapshot |
	(self integrationEnabled and: [ (self collectorOutputFileForSignalNamed: 'METRICS') notNil ]) ifFalse: [ self skip ].
	outputFile := self collectorOutputFileForSignalNamed: 'METRICS'.
	resourceId := 'pharo.otlp.grpc.metric.' , UUID new asString36.
	snapshot := self sampleSnapshotWithResourceId: resourceId.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS' relativePath: 'v1/metrics'.
	configuration
		endpoint: self collectorEndpoint;
		protocol: 'grpc';
		timeoutMillis: 5000;
		compression: 'none'.
	exporter := OTOtlpGrpcMetricExporter configuration: configuration.
	self assert: (exporter export: snapshot).
	self assert: (self
			 waitForCollectorOutputFile: outputFile
			 toContainAll: {
					 resourceId.
					 'integration.requests.total' }
			 timeoutSeconds: 10)
]
