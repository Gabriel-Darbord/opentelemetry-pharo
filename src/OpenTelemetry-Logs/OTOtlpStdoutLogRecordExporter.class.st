"
An OTLP logs exporter that writes JSON-line OTLP payloads to standard output.

It inherits per-instance export serialization from the JSON-line exporter so
stdout writes are not performed concurrently by the SDK on the same exporter.
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
