Class {
	#name : 'OTOtlpGrpcLogRecordExporterIntegrationTest',
	#superclass : 'OTOtlpGrpcIntegrationTest',
	#category : 'OpenTelemetry-Logs-IntegrationTests',
	#package : 'OpenTelemetry-Logs-IntegrationTests'
}

{ #category : 'private' }
OTOtlpGrpcLogRecordExporterIntegrationTest >> sampleLogRecordBody: aString [

	| record |
	record := OTLogRecord new.
	record
		timestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		observedTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 2);
		severityNumber: OTSeverity info;
		severityText: 'INFO';
		body: aString;
		attributes: {
				('integration.case' -> 'otlp-grpc-real-collector').
				('integration.id' -> aString) } asDictionary;
		resource: (OTResource attributes: {
						 ('service.name' -> 'otlp-grpc-logs-integration').
						 ('service.instance.id' -> aString) });
		instrumentationScope: (OTInstrumentationScope
				 named: 'otlp.grpc.integration'
				 version: '1.0.0'
				 schemaUrl: ''
				 attributes: #(  )).
	^ record
]

{ #category : 'tests' }
OTOtlpGrpcLogRecordExporterIntegrationTest >> testExportSucceedsAgainstRealCollectorUsingOtlpGrpc [

	| configuration exporter logBody outputFile record |
	(self integrationEnabled and: [ (self collectorOutputFileForSignalNamed: 'LOGS') notNil ]) ifFalse: [ self skip ].
	outputFile := self collectorOutputFileForSignalNamed: 'LOGS'.
	logBody := 'pharo.otlp.grpc.log.' , UUID new asString36.
	record := self sampleLogRecordBody: logBody.
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'LOGS' relativePath: 'v1/logs'.
	configuration
		endpoint: self collectorEndpoint;
		protocol: 'grpc';
		timeoutMillis: 5000;
		compression: 'none'.
	exporter := OTOtlpGrpcLogRecordExporter configuration: configuration.
	self assert: (exporter export: { record }).
	self assert: (self
			 waitForCollectorOutputFile: outputFile
			 toContainAll: {
					 logBody.
					 'otlp-grpc-logs-integration' }
			 timeoutSeconds: 10)
]
