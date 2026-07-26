Class {
	#name : 'OTOtlpJsonLineLogRecordExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpJsonLineLogRecordExporterTest >> sampleLogRecord [

	| record |
	record := OTLogRecord new.
	record
		timestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		observedTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 2);
		severityNumber: OTSeverity info;
		severityText: 'INFO';
		body: 'stdout payload';
		attributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself);
		resource: (OTResource attributes: (Dictionary new
					  at: 'service.name' put: 'demo';
					  yourself));
		instrumentationScope: (OTInstrumentationScope named: 'demo.scope').
	^ record
]

{ #category : 'running' }
OTOtlpJsonLineLogRecordExporterTest >> setUp [

	super setUp.
	exporter := OTRecordingOtlpJsonLineLogRecordExporter new
]

{ #category : 'tests' }
OTOtlpJsonLineLogRecordExporterTest >> testFileExporterAppendsOneJsonLinePerExport [

	| fileExporter lines outputFile |
	outputFile := FileLocator temp / ('otlp-json-lines-logs-' , UUID new asString36 , '.jsonl').
	[
		fileExporter := OTOtlpJsonFileLogRecordExporter new.
		fileExporter fileReference: outputFile.
		self assert: (fileExporter export: { self sampleLogRecord }).
		self assert: (fileExporter export: { self sampleLogRecord }).
		lines := outputFile contents lines.
		self assert: lines size equals: 2.
		self assert: ((STONJSON fromString: lines first) at: 'resourceLogs') size equals: 1 ] ensure: [ outputFile ensureDelete ]
]

{ #category : 'tests' }
OTOtlpJsonLineLogRecordExporterTest >> testJsonLineExporterRejectsExportAfterShutdown [

	self assert: exporter shutdown.
	self deny: (exporter export: { self sampleLogRecord }).
	self deny: exporter forceFlush.
	self deny: exporter shutdown.
	self assert: exporter writtenLines isEmpty
]

{ #category : 'tests' }
OTOtlpJsonLineLogRecordExporterTest >> testJsonLineExporterWritesOneValidJsonLinePerExport [

	| line payload |
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: exporter writtenLines size equals: 1.
	line := exporter writtenLines first.
	self assert: line last equals: Character lf.
	payload := STONJSON fromString: line allButLast.
	self assert: (payload at: 'resourceLogs') size equals: 1
]
