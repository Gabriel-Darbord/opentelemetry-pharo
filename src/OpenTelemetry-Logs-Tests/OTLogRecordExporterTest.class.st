Class {
	#name : 'OTLogRecordExporterTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'private' }
OTLogRecordExporterTest >> sampleLogRecord [

	^ OTLogRecord new
		  body: 'hello';
		  severityNumber: OTSeverity info;
		  yourself
]

{ #category : 'tests' }
OTLogRecordExporterTest >> testConsoleExporterRejectsExportAfterShutdown [

	| exporter stream |
	exporter := OTConsoleLogRecordExporter new.
	stream := String new writeStream.
	exporter outputStream: stream.
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: exporter shutdown.
	self deny: (exporter export: { self sampleLogRecord }).
	self deny: exporter forceFlush.
	self deny: exporter shutdown
]

{ #category : 'tests' }
OTLogRecordExporterTest >> testNoopExporterRejectsExportAfterShutdown [

	| exporter |
	exporter := OTNoopLogRecordExporter new.
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: exporter shutdown.
	self deny: (exporter export: { self sampleLogRecord }).
	self deny: exporter forceFlush.
	self deny: exporter shutdown
]

{ #category : 'tests' }
OTLogRecordExporterTest >> testRecordingExporterRejectsExportAfterShutdown [

	| exporter |
	exporter := OTRecordingLogRecordExporter new.
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: exporter forceFlush.
	self assert: exporter shutdown.
	self deny: (exporter export: { self sampleLogRecord }).
	self deny: exporter forceFlush.
	self deny: exporter shutdown.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1
]
