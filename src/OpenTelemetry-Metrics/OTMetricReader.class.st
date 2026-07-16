Class {
	#name : 'OTMetricReader',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'shutdown',
		'temporalitySelector',
		'aggregationSelector',
		'callbackTimeoutMillis',
		'lastCollectionTimestampByInstrument',
		'lastAsynchronousValuesByInstrument'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'private - logging' }
OTMetricReader class >> callbackWarningSink [

	^ OTClassStateStore
		valueAt: #otMetricCallbackWarningSink
		forClass: self
		ifAbsent: [ self defaultCallbackWarningSink ]
]

{ #category : 'private - logging' }
OTMetricReader class >> callbackWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otMetricCallbackWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otMetricCallbackWarningSink
				forClass: self
				put: aBlock ].
	^ self callbackWarningSink
]

{ #category : 'private - logging' }
OTMetricReader class >> defaultCallbackWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'accessing' }
OTMetricReader >> aggregationFor: anOTMetricInstrument [

	| selected |
	selected := self aggregationSelector value: anOTMetricInstrument.
	^ selected = #base2ExponentialBucketHistogram
		ifTrue: [ #base2ExponentialBucketHistogram ]
		ifFalse: [ #default ]
]

{ #category : 'accessing' }
OTMetricReader >> aggregationSelector [

	^ aggregationSelector
		ifNil: [ self defaultAggregationSelector ]
]

{ #category : 'accessing' }
OTMetricReader >> aggregationSelector: aBlockOrNil [

	aggregationSelector := aBlockOrNil
]

{ #category : 'collecting' }
OTMetricReader >> collectAsynchronousCallback: aBlock for: anOTAsynchronousMetricInstrument into: aCollection [

	| callbackMeasurements status |
	callbackMeasurements := OrderedCollection new.
	status := self
		invokeAsynchronousCallback: aBlock
		for: anOTAsynchronousMetricInstrument
		observer: (anOTAsynchronousMetricInstrument newObserverOn: callbackMeasurements).
	status = #completed ifTrue: [ aCollection addAll: callbackMeasurements ]
]

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

{ #category : 'accessing' }
OTMetricReader >> defaultAggregationSelector [

	^ [ :instrument | #default ]
]

{ #category : 'accessing' }
OTMetricReader >> callbackTimeoutMillis [

	^ callbackTimeoutMillis ifNil: [ 30000 ]
]

{ #category : 'accessing' }
OTMetricReader >> callbackTimeoutMillis: anInteger [

	callbackTimeoutMillis := anInteger
		ifNil: [ 30000 ]
		ifNotNil: [ anInteger max: 1 ].
	^ self callbackTimeoutMillis
]

{ #category : 'private - logging' }
OTMetricReader >> callbackWarningSink [

	^ OTMetricReader callbackWarningSink
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
	lastAsynchronousValuesByInstrument := WeakIdentityKeyDictionary new.
	temporalitySelector := nil.
	aggregationSelector := nil.
	callbackTimeoutMillis := 30000
]

{ #category : 'collecting' }
OTMetricReader >> invokeAsynchronousCallback: aBlock for: anOTAsynchronousMetricInstrument observer: anOTAsynchronousMetricObserver [

	| error process semaphore timedOut |
	error := nil.
	semaphore := Semaphore new.
	process := [
		[ anOTAsynchronousMetricInstrument
			invokeCallback: aBlock
			with: anOTAsynchronousMetricObserver ]
			on: Error
			do: [ :anError | error := anError ].
		semaphore signal ]
		forkAt: Processor userBackgroundPriority.
	timedOut := semaphore waitTimeoutMilliseconds: self callbackTimeoutMillis.
	timedOut ifTrue: [
		process terminate.
		self noteAsynchronousCallbackTimeoutFor: anOTAsynchronousMetricInstrument.
		^ #timedOut ].
	error ifNotNil: [
		self
			noteAsynchronousCallbackError: error
			for: anOTAsynchronousMetricInstrument.
		^ #failed ].
	^ #completed
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
OTMetricReader >> lastAsynchronousValuesByInstrument [

	^ lastAsynchronousValuesByInstrument
		ifNil: [ lastAsynchronousValuesByInstrument := WeakIdentityKeyDictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> lastAsynchronousValuesFor: anOTMetricInstrument [

	^ self lastAsynchronousValuesByInstrument
		at: anOTMetricInstrument
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> markCollectedAt: aDateAndTime forInstruments: someInstruments [

	someInstruments do: [ :each |
	self lastCollectionTimestampByInstrument at: each put: aDateAndTime ]
]

{ #category : 'private - logging' }
OTMetricReader >> noteAsynchronousCallbackError: anError for: anOTAsynchronousMetricInstrument [

	self callbackWarningSink value:
		'OpenTelemetry asynchronous metric callback failed for instrument '
			, anOTAsynchronousMetricInstrument name printString
			, ': '
			, anError messageText
]

{ #category : 'private - logging' }
OTMetricReader >> noteAsynchronousCallbackTimeoutFor: anOTAsynchronousMetricInstrument [

	self callbackWarningSink value:
		'OpenTelemetry asynchronous metric callback timed out for instrument '
			, anOTAsynchronousMetricInstrument name printString
			, ' after '
			, self callbackTimeoutMillis asString
			, ' ms'
]

{ #category : 'collecting' }
OTMetricReader >> metricAggregationContextFor: anOTMetricInstrument collectedAt: aDateAndTime [

	| previousCollection startTimestamp temporality |
	temporality := self temporalityFor: anOTMetricInstrument.
	previousCollection := self lastCollectionTimestampFor: anOTMetricInstrument.
	startTimestamp := anOTMetricInstrument
		startTimestampForPreviousCollection: previousCollection
		temporality: temporality.
	^ OTMetricAggregationContext
		collectedAt: aDateAndTime
		startTimestamp: startTimestamp
		temporality: temporality
		aggregation: (self aggregationFor: anOTMetricInstrument)
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
		| context instrumentMeasurements preparedMeasurements selectedMeasurements |
		instrumentMeasurements := grouped at: each ifAbsent: [ #() ].
		context := self
			metricAggregationContextFor: each
			collectedAt: aDateAndTime.
		preparedMeasurements := each
			preparedMeasurementsFrom: instrumentMeasurements
			forReader: self
			using: context.
		selectedMeasurements := self
			selectedMeasurementsFrom: preparedMeasurements
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
