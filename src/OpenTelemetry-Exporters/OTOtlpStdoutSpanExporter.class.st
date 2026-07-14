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

	^ Smalltalk globals at: #Transcript ifAbsent: [ nil ]
]

{ #category : 'private' }
OTOtlpStdoutSpanExporter >> writeJsonLine: aString [

	self outputStream ifNotNil: [ :stream | stream nextPutAll: aString ]
]
