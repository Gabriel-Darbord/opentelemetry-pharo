"
An OTLP traces exporter that appends JSON-line OTLP payloads to a local file.
"
Class {
	#name : 'OTOtlpJsonFileSpanExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#instVars : [
		'fileReference'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTOtlpJsonFileSpanExporter >> fileReference [

	^ fileReference ifNil: [
		  fileReference := FileLocator imageDirectory
			                   / 'pharo-local'
			                   / 'OpenTelemetry'
			                   / 'traces'
			                   / 'traces.jsonl' ]
]

{ #category : 'accessing' }
OTOtlpJsonFileSpanExporter >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : 'private' }
OTOtlpJsonFileSpanExporter >> writeJsonLine: aString [

	self fileReference parent ensureCreateDirectory.
	self fileReference ensureCreateFile.
	self fileReference writeStreamDo: [ :stream |
		stream setToEnd.
		stream nextPutAll: aString ]
]
