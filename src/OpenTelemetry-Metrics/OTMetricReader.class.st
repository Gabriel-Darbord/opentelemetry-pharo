Class {
	#name : 'OTMetricReader',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'shutdown'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTMetricReader >> collect [

	self subclassResponsibility
]

{ #category : 'lifecycle' }
OTMetricReader >> forceFlush [

	^ true
]

{ #category : 'initialization' }
OTMetricReader >> initialize [

	super initialize.
	shutdown := false
]

{ #category : 'testing' }
OTMetricReader >> isShutdown [

	^ shutdown
]

{ #category : 'accessing' }
OTMetricReader >> provider [

	^ provider
]

{ #category : 'accessing' }
OTMetricReader >> provider: anOTMeterProvider [

	provider := anOTMeterProvider
]

{ #category : 'lifecycle' }
OTMetricReader >> shutdown [

	shutdown := true.
	^ true
]
