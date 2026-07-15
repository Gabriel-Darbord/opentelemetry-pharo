"
An OTLP traces exporter that writes JSON-line OTLP payloads to standard output.
"
Class {
	#name : 'OTOtlpStdoutSpanExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private' }
OTOtlpStdoutSpanExporter >> outputStream [

	^ Stdio stdout
]

{ #category : 'private' }
OTOtlpStdoutSpanExporter >> writeJsonLine: aString [

	self outputStream nextPutAll: aString
]
