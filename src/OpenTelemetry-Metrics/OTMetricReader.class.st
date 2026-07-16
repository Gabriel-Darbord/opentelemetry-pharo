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

{ #category : 'accessing' }
OTMetricReader >> attachToProvider: anOTMeterProvider [

	provider ifNil: [
		provider := anOTMeterProvider.
		^ provider ].
	provider == anOTMeterProvider ifTrue: [ ^ provider ].
	Error signal: 'OpenTelemetry metric readers cannot be registered on multiple meter providers'
]

{ #category : 'collecting' }
OTMetricReader >> collectSnapshot [

	| collectedAt |
	self isShutdown ifTrue: [ ^ OTMetricSnapshot empty ].
	collectedAt := DateAndTime now asUTC.
	^ self provider
		ifNil: [ OTMetricSnapshot empty ]
		ifNotNil: [ :aProvider |
			OTMetricSnapshot
				resource: aProvider resource
				measurements: (aProvider collectMeasurementsFor: self)
				collectedAt: collectedAt ]
]

{ #category : 'callbacks' }
OTMetricReader >> didRegisterWithProvider [

	self
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
