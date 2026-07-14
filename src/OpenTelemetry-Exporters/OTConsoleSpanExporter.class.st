"
A debugging-oriented span exporter that writes exported spans to the console.
The output format is intentionally unspecified.
"
Class {
	#name : 'OTConsoleSpanExporter',
	#superclass : 'OTSpanExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private' }
OTConsoleSpanExporter >> outputStream [

	^ Smalltalk globals at: #Transcript ifAbsent: [ nil ]
]

{ #category : 'exporting' }
OTConsoleSpanExporter >> export: spans [

	| stream |
	self isShutdown ifTrue: [ ^ false ].
	stream := self outputStream.
	stream ifNotNil: [
		stream
			show: spans printString;
			cr ].
	^ true
]
