Class {
	#name : 'OTOtlpJsonLineMetricExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTOtlpJsonLineMetricExporterTest >> sampleSnapshot [

	^ OTOtlpJsonMetricEncoderTest new sampleSnapshot
]

{ #category : 'running' }
OTOtlpJsonLineMetricExporterTest >> setUp [

	super setUp.
	exporter := OTRecordingOtlpJsonLineMetricExporter new
]

{ #category : 'tests' }
OTOtlpJsonLineMetricExporterTest >> testFileExporterAppendsOneJsonLinePerExport [

	| fileExporter lines outputFile |
	outputFile := FileLocator temp / ('otlp-json-lines-metrics-' , UUID new asString36 , '.jsonl').
	[
		fileExporter := OTOtlpJsonFileMetricExporter new.
		fileExporter fileReference: outputFile.
		self assert: (fileExporter export: self sampleSnapshot).
		self assert: (fileExporter export: self sampleSnapshot).
		lines := outputFile contents lines.
		self assert: lines size equals: 2.
		self assert: ((STONJSON fromString: lines first) at: 'resourceMetrics') size equals: 1 ] ensure: [ outputFile ensureDelete ]
]

{ #category : 'tests' }
OTOtlpJsonLineMetricExporterTest >> testFileExporterReturnsFalseAfterShutdownAndDoesNotCreateFile [

	| fileExporter outputFile |
	outputFile := FileLocator temp / ('otlp-json-lines-metrics-' , UUID new asString36 , '.jsonl').
	[
		fileExporter := OTOtlpJsonFileMetricExporter new.
		fileExporter fileReference: outputFile.
		self assert: fileExporter shutdown.
		self deny: (fileExporter export: self sampleSnapshot).
		self deny: outputFile exists ] ensure: [ outputFile ensureDelete ]
]

{ #category : 'tests' }
OTOtlpJsonLineMetricExporterTest >> testJsonLineExporterEncodesNonFiniteNumbersAsJsonStrings [

	| line payload point scopeMetrics snapshot |
	snapshot := self sampleSnapshot.
	point := snapshot metrics second points first.
	point value: Float infinity.
	self assert: (exporter export: snapshot).
	line := exporter writtenLines first.
	payload := STONJSON fromString: line allButLast.
	scopeMetrics := ((payload at: 'resourceMetrics') first at: 'scopeMetrics') first.
	self assert: ((((scopeMetrics at: 'metrics') second at: 'gauge') at: 'dataPoints') first at: 'asDouble') equals: 'Infinity'
]

{ #category : 'tests' }
OTOtlpJsonLineMetricExporterTest >> testJsonLineExporterReturnsFalseAfterShutdown [

	self assert: exporter shutdown.
	self deny: (exporter export: self sampleSnapshot).
	self assert: exporter writtenLines isEmpty
]

{ #category : 'tests' }
OTOtlpJsonLineMetricExporterTest >> testJsonLineExporterWritesOneValidJsonLinePerExport [

	| line payload |
	self assert: (exporter export: self sampleSnapshot).
	self assert: exporter writtenLines size equals: 1.
	line := exporter writtenLines first.
	self assert: line last equals: Character lf.
	payload := STONJSON fromString: line allButLast.
	self assert: (payload at: 'resourceMetrics') size equals: 1
]
