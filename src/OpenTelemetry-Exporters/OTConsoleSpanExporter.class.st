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

	^ Stdio stdout
]

{ #category : 'exporting' }
OTConsoleSpanExporter >> export: spans [

	| stream |
	self isShutdown ifTrue: [ ^ false ].
	stream := self outputStream.
	stream
		nextPutAll: spans printString;
		lf.
	^ true
]
