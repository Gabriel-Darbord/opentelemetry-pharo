"
I am a metric exporter that accepts snapshots and drops them.
I satisfy the exporter protocol without producing side effects.
"
Class {
	#name : 'OTNoopMetricExporter',
	#superclass : 'OTMetricExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTNoopMetricExporter >> export: anOTMetricSnapshot [

	self isShutdown ifTrue: [ ^ false ].
	^ true
]
