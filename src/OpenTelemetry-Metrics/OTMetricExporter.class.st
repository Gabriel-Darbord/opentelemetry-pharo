"
I am the abstract base class for metric exporters.
I define lifecycle, shutdown, temporality selection, and aggregation selection for metric export.
"
Class {
	#name : 'OTMetricExporter',
	#superclass : 'Object',
	#instVars : [
		'shutdown',
		'temporalitySelector',
		'aggregationSelector'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTMetricExporter >> aggregationSelector [

	^ aggregationSelector ifNil: [ aggregationSelector := [ :instrument | #default ] ]
]

{ #category : 'accessing' }
OTMetricExporter >> aggregationSelector: aBlockOrNil [

	aggregationSelector := aBlockOrNil ifNil: [ [ :instrument | #default ] ] ifNotNil: [ aBlockOrNil ]
]

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
	temporalitySelector := [ :instrument | #cumulative ].
	aggregationSelector := [ :instrument | #default ]
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

{ #category : 'accessing' }
OTMetricExporter >> temporalitySelector [

	^ temporalitySelector ifNil: [ temporalitySelector := [ :instrument | #cumulative ] ]
]

{ #category : 'accessing' }
OTMetricExporter >> temporalitySelector: aBlockOrNil [

	temporalitySelector := aBlockOrNil ifNil: [ [ :instrument | #cumulative ] ] ifNotNil: [ aBlockOrNil ]
]
