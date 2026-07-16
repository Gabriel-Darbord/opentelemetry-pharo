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
OTOtlpJsonLineMetricExporterTest >> testJsonLineExporterWritesOneValidJsonLinePerExport [

	| line payload |
	self assert: (exporter export: self sampleSnapshot).
	self assert: exporter writtenLines size equals: 1.
	line := exporter writtenLines first.
	self assert: line last equals: Character lf.
	payload := STONJSON fromString: line allButLast.
	self assert: (payload at: 'resourceMetrics') size equals: 1
]
