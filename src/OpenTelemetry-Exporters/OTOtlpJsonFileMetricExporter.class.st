"
An OTLP metrics exporter that appends JSON-line OTLP payloads to a local file.
"
Class {
	#name : 'OTOtlpJsonFileMetricExporter',
	#superclass : 'OTOtlpJsonLineMetricExporter',
	#instVars : [
		'fileReference'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTOtlpJsonFileMetricExporter >> fileReference [

	^ fileReference ifNil: [
		  fileReference := FileLocator imageDirectory / 'pharo-local' / 'OpenTelemetry' / 'metrics' / 'metrics.jsonl' ]
]

{ #category : 'accessing' }
OTOtlpJsonFileMetricExporter >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : 'private' }
OTOtlpJsonFileMetricExporter >> writeJsonLine: aString [

	self fileReference parent ensureCreateDirectory.
	self fileReference ensureCreateFile.
	self fileReference writeStreamDo: [ :stream |
			stream setToEnd.
			stream nextPutAll: aString ]
]
