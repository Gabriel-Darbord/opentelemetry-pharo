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
		timestamp: (DateAndTime unixEpoch + (Duration milliSeconds: 1));
		observedTimestamp: (DateAndTime unixEpoch + (Duration milliSeconds: 2));
		severityNumber: OTSeverity info;
		severityText: 'INFO';
		body: 'stdout payload';
		attributes: (Dictionary new at: 'service.name' put: 'demo'; yourself);
		resource:
			(OTResource attributes: (Dictionary new
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
OTOtlpJsonLineLogRecordExporterTest >> testJsonLineExporterWritesOneValidJsonLinePerExport [

	| line payload |
	self assert: (exporter export: { self sampleLogRecord }).
	self assert: exporter writtenLines size equals: 1.
	line := exporter writtenLines first.
	self assert: line last equals: Character lf.
	payload := STONJSON fromString: line allButLast.
	self assert: (payload at: 'resourceLogs') size equals: 1
]
