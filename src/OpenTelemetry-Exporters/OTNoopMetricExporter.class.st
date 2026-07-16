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
