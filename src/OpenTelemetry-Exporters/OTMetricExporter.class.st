Class {
	#name : 'OTMetricExporter',
	#superclass : 'Object',
	#instVars : [
		'shutdown',
		'temporalitySelector'
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
	shutdown := false.
	temporalitySelector := [ :instrument | #cumulative ]
]

{ #category : 'testing' }
OTMetricExporter >> isShutdown [

	^ shutdown
]

{ #category : 'accessing' }
OTMetricExporter >> temporalitySelector [

	^ temporalitySelector
		ifNil: [ temporalitySelector := [ :instrument | #cumulative ] ]
]

{ #category : 'accessing' }
OTMetricExporter >> temporalitySelector: aBlockOrNil [

	temporalitySelector := aBlockOrNil
		ifNil: [ [ :instrument | #cumulative ] ]
		ifNotNil: [ aBlockOrNil ]
]

{ #category : 'lifecycle' }
OTMetricExporter >> shutdown [

	shutdown := true.
	^ true
]
