Class {
	#name : 'OTMetricReader',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'shutdown',
		'temporalitySelector',
		'lastCollectionTimestampByInstrument'
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

	| collectedAt instruments measurements metrics |
	self isShutdown ifTrue: [ ^ OTMetricSnapshot empty ].
	collectedAt := DateAndTime now asUTC.
	^ self provider
		ifNil: [ OTMetricSnapshot empty ]
		ifNotNil: [ :aProvider |
			instruments := aProvider registeredMetricInstruments.
			measurements := aProvider collectMeasurementsFor: self.
			metrics := self
				metricDataFromMeasurements: measurements
				instruments: instruments
				collectedAt: collectedAt.
			self markCollectedAt: collectedAt forInstruments: instruments.
			OTMetricSnapshot
				resource: aProvider resource
				measurements: measurements
				metrics: metrics
				collectedAt: collectedAt ]
]

{ #category : 'callbacks' }
OTMetricReader >> didRegisterWithProvider [

	self
]

{ #category : 'accessing' }
OTMetricReader >> defaultTemporalitySelector [

	^ [ :instrument | #cumulative ]
]

{ #category : 'lifecycle' }
OTMetricReader >> forceFlush [

	^ true
]

{ #category : 'initialization' }
OTMetricReader >> initialize [

	super initialize.
	shutdown := false.
	lastCollectionTimestampByInstrument := WeakIdentityKeyDictionary new.
	temporalitySelector := nil
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

{ #category : 'collecting' }
OTMetricReader >> lastCollectionTimestampByInstrument [

	^ lastCollectionTimestampByInstrument
		ifNil: [ lastCollectionTimestampByInstrument := WeakIdentityKeyDictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> lastCollectionTimestampFor: anOTMetricInstrument [

	^ self lastCollectionTimestampByInstrument
		at: anOTMetricInstrument
		ifAbsent: [ nil ]
]

{ #category : 'collecting' }
OTMetricReader >> markCollectedAt: aDateAndTime forInstruments: someInstruments [

	someInstruments do: [ :each |
		self lastCollectionTimestampByInstrument at: each put: aDateAndTime ]
]

{ #category : 'collecting' }
OTMetricReader >> metricAggregationContextFor: anOTMetricInstrument collectedAt: aDateAndTime [

	| previousCollection startTimestamp temporality |
	temporality := self temporalityFor: anOTMetricInstrument.
	previousCollection := self lastCollectionTimestampFor: anOTMetricInstrument.
	startTimestamp := temporality = #delta
		ifTrue: [ previousCollection ifNil: [ anOTMetricInstrument creationTimestamp ] ]
		ifFalse: [ nil ].
	^ OTMetricAggregationContext
		collectedAt: aDateAndTime
		startTimestamp: startTimestamp
		temporality: temporality
]

{ #category : 'collecting' }
OTMetricReader >> metricDataFromMeasurements: someMeasurements instruments: someInstruments collectedAt: aDateAndTime [

	| grouped metrics |
	grouped := OrderedDictionary new.
	someMeasurements do: [ :each |
		(grouped at: each instrument ifAbsentPut: [ OrderedCollection new ])
			add: each ].
	metrics := OrderedCollection new.
	someInstruments do: [ :each |
		| context instrumentMeasurements selectedMeasurements |
		instrumentMeasurements := grouped at: each ifAbsent: [ #() ].
		context := self
			metricAggregationContextFor: each
			collectedAt: aDateAndTime.
		selectedMeasurements := self
			selectedMeasurementsFrom: instrumentMeasurements
			for: each
			using: context.
		selectedMeasurements ifNotEmpty: [
			metrics add: (each metricDataFromMeasurements: selectedMeasurements using: context) ] ].
	^ metrics asArray
]

{ #category : 'collecting' }
OTMetricReader >> selectedMeasurementsFrom: someMeasurements for: anOTMetricInstrument using: anOTMetricAggregationContext [

	| startTimestamp |
	anOTMetricAggregationContext temporality = #delta ifFalse: [ ^ someMeasurements ].
	startTimestamp := anOTMetricAggregationContext startTimestamp.
	startTimestamp ifNil: [ ^ someMeasurements ].
	^ someMeasurements select: [ :each |
		each timestamp > startTimestamp
			and: [ each timestamp <= anOTMetricAggregationContext collectedAt ] ]
]

{ #category : 'collecting' }
OTMetricReader >> temporalityFor: anOTMetricInstrument [

	| selected |
	selected := self temporalitySelector value: anOTMetricInstrument.
	^ selected = #delta ifTrue: [ #delta ] ifFalse: [ #cumulative ]
]

{ #category : 'accessing' }
OTMetricReader >> temporalitySelector [

	^ temporalitySelector
		ifNil: [ self defaultTemporalitySelector ]
]

{ #category : 'accessing' }
OTMetricReader >> temporalitySelector: aBlockOrNil [

	temporalitySelector := aBlockOrNil
]

{ #category : 'lifecycle' }
OTMetricReader >> shutdown [

	shutdown := true.
	^ true
]
