"
A no-op exporter used when trace exporting is explicitly disabled.
"
Class {
	#name : 'OTNoopSpanExporter',
	#superclass : 'OTSpanExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTNoopSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  true ]
]
