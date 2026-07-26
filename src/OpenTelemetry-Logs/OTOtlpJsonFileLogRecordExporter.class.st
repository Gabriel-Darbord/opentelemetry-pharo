"
An OTLP logs exporter that appends JSON-line OTLP payloads to a local file.

It inherits per-instance export serialization from the JSON-line exporter so file appends are not performed concurrently by the SDK on the same exporter.
"
Class {
	#name : 'OTOtlpJsonFileLogRecordExporter',
	#superclass : 'OTOtlpJsonLineLogRecordExporter',
	#instVars : [
		'fileReference'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTOtlpJsonFileLogRecordExporter >> fileReference [

	^ fileReference ifNil: [ fileReference := FileLocator imageDirectory / 'pharo-local' / 'OpenTelemetry' / 'logs' / 'logs.jsonl' ]
]

{ #category : 'accessing' }
OTOtlpJsonFileLogRecordExporter >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : 'private' }
OTOtlpJsonFileLogRecordExporter >> writeJsonLine: aString [

	self fileReference parent ensureCreateDirectory.
	self fileReference ensureCreateFile.
	self fileReference writeStreamDo: [ :stream |
			stream setToEnd.
			stream nextPutAll: aString ]
]
