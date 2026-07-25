"
A debugging-oriented span exporter that writes exported spans to the console.
The output format is intentionally unspecified.
"
Class {
	#name : 'OTConsoleSpanExporter',
	#superclass : 'OTSpanExporter',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'exporting' }
OTConsoleSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  | stream |
			  self isShutdown ifTrue: [ ^ false ].
			  self withOperationNamed: 'export' default: false do: [
					  stream := self outputStream.
					  stream
						  nextPutAll: spans printString;
						  lf.
					  true ] ]
]

{ #category : 'private' }
OTConsoleSpanExporter >> outputStream [

	^ Stdio stdout
]

{ #category : 'processing' }
OTConsoleSpanExporter >> prefersSimpleSpanProcessor [

	^ true
]
