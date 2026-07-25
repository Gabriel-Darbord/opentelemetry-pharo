"
An OTLP traces exporter that writes JSON-line OTLP payloads to standard output.
"
Class {
	#name : 'OTOtlpStdoutSpanExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'private' }
OTOtlpStdoutSpanExporter >> outputStream [

	^ Stdio stdout
]

{ #category : 'processing' }
OTOtlpStdoutSpanExporter >> prefersSimpleSpanProcessor [

	^ true
]

{ #category : 'private' }
OTOtlpStdoutSpanExporter >> writeJsonLine: aString [

	self outputStream nextPutAll: aString
]
