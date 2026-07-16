Class {
	#name : 'OTMetricExporter',
	#superclass : 'Object',
	#instVars : [
		'shutdown'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTMetricExporter >> export: anOTMetricSnapshot [

	self subclassResponsibility
]

{ #category : 'exporting' }
OTMetricExporter >> forceFlush [

	^ self isShutdown not
]

{ #category : 'initialization' }
OTMetricExporter >> initialize [

	super initialize.
	shutdown := false
]

{ #category : 'testing' }
OTMetricExporter >> isShutdown [

	^ shutdown
]

{ #category : 'lifecycle' }
OTMetricExporter >> shutdown [

	shutdown := true.
	^ true
]
