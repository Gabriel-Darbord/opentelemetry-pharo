"
A no-op exporter used when trace exporting is explicitly disabled.
"
Class {
	#name : 'OTNoopSpanExporter',
	#superclass : 'OTSpanExporter',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'exporting' }
OTNoopSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  true ]
]
