"
An OTLP logs exporter that writes JSON-line OTLP payloads to standard output.
"
Class {
	#name : 'OTOtlpStdoutLogRecordExporter',
	#superclass : 'OTOtlpJsonLineLogRecordExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private' }
OTOtlpStdoutLogRecordExporter >> outputStream [

	^ Stdio stdout
]

{ #category : 'private' }
OTOtlpStdoutLogRecordExporter >> writeJsonLine: aString [

	self outputStream nextPutAll: aString
]
