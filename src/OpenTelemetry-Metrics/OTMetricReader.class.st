Class {
	#name : 'OTMetricReader',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'shutdown',
		'temporalitySelector',
		'aggregationSelector',
		'cardinalityLimitSelector',
		'callbackTimeoutMillis',
		'selectedAttributeSetsByStream',
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
	selected := self normalizedAggregationSymbolFrom:
		(self aggregationSelector value: anOTMetricInstrument).
	selected = #explicitBucketHistogram ifTrue: [ ^ #default ].
	(anOTMetricInstrument supportsAggregation: selected) ifTrue: [ ^ selected ].
	self
		noteIncompatibleAggregation: selected
		for: anOTMetricInstrument.
	^ #default
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
OTMetricReader >> cardinalityLimitedMeasurementsFrom: someMeasurements for: anOTMetricInstrument using: anOTMetricAggregationContext stateKey: aStateKey [

	| limit limitedMeasurements overflowAttributes retainedKeys selectedAttributeSets |
	limit := anOTMetricAggregationContext cardinalityLimit.
	limitedMeasurements := OrderedCollection new: someMeasurements size.
	overflowAttributes := self overflowAttributes.
	retainedKeys := anOTMetricAggregationContext retainedAttributeKeys.
	selectedAttributeSets := self selectedAttributeSetsForStateKey: aStateKey.
	someMeasurements do: [ :each |
		| knownAttributes normalizedAttributes |
		normalizedAttributes := anOTMetricInstrument
			normalizedAttributesForMeasurement: each
			retainingKeys: retainedKeys.
		knownAttributes := self
			selectedAttributeSetMatching: normalizedAttributes
			within: selectedAttributeSets.
		knownAttributes ifNotNil: [
			limitedMeasurements add: (each withAttributes: knownAttributes) ]
		ifNil: [
			selectedAttributeSets size < limit
				ifTrue: [
					selectedAttributeSets add: normalizedAttributes.
					limitedMeasurements add: (each withAttributes: normalizedAttributes) ]
				ifFalse: [
					limitedMeasurements
						add: (each withAttributes: overflowAttributes) ] ] ].
	^ limitedMeasurements asArray
]

{ #category : 'accessing' }
OTMetricReader >> cardinalityLimitFor: anOTMetricInstrument [

	| selected |
	selected := self cardinalityLimitSelector value: anOTMetricInstrument.
	(selected isInteger and: [ selected > 0 ]) ifTrue: [ ^ selected ].
	^ 2000
]

{ #category : 'collecting' }
OTMetricReader >> cardinalityStateKeyFor: anOTMetricInstrument view: anOTMetricViewOrNil [

	anOTMetricViewOrNil ifNil: [ ^ anOTMetricInstrument ].
	^ { anOTMetricInstrument. anOTMetricViewOrNil }
]

{ #category : 'accessing' }
OTMetricReader >> cardinalityLimitSelector [

	^ cardinalityLimitSelector
		ifNil: [ self defaultCardinalityLimitSelector ]
]

{ #category : 'accessing' }
OTMetricReader >> cardinalityLimitSelector: aBlockOrNil [

	cardinalityLimitSelector := aBlockOrNil
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
OTMetricReader >> defaultCardinalityLimitSelector [

	^ [ :instrument | 2000 ]
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
	cardinalityLimitSelector := nil.
	callbackTimeoutMillis := 30000.
	selectedAttributeSetsByStream := Dictionary new
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
OTMetricReader >> overflowAttributes [

	^ OTAttributeNormalizer normalizeAttributes:
		{ 'otel.metric.overflow' -> true }
]

{ #category : 'collecting' }
OTMetricReader >> metricAggregationContextFor: anOTMetricInstrument collectedAt: aDateAndTime [

	^ self
		metricAggregationContextFor: anOTMetricInstrument
		view: nil
		collectedAt: aDateAndTime
]

{ #category : 'collecting' }
OTMetricReader >> metricAggregationContextFor: anOTMetricInstrument view: anOTMetricViewOrNil collectedAt: aDateAndTime [

	| aggregation previousCollection retainedAttributeKeys startTimestamp temporality |
	temporality := self temporalityFor: anOTMetricInstrument.
	previousCollection := self lastCollectionTimestampFor: anOTMetricInstrument.
	startTimestamp := anOTMetricInstrument
		startTimestampForPreviousCollection: previousCollection
		temporality: temporality.
	aggregation := anOTMetricViewOrNil
		ifNil: [ self aggregationFor: anOTMetricInstrument ]
		ifNotNil: [ anOTMetricViewOrNil resolvedAggregationFor: anOTMetricInstrument reader: self ].
	(anOTMetricInstrument supportsAggregation: aggregation) ifFalse: [ ^ nil ].
	retainedAttributeKeys := anOTMetricViewOrNil
		ifNil: [ anOTMetricInstrument retainedAttributeKeys ]
		ifNotNil: [ anOTMetricViewOrNil resolvedRetainedAttributeKeysFor: anOTMetricInstrument ].
	^ OTMetricAggregationContext
		collectedAt: aDateAndTime
		startTimestamp: startTimestamp
		temporality: temporality
		aggregation: aggregation
		retainedAttributeKeys: retainedAttributeKeys
		cardinalityLimit: (anOTMetricViewOrNil
				ifNil: [ self cardinalityLimitFor: anOTMetricInstrument ]
				ifNotNil: [
					anOTMetricViewOrNil
						resolvedCardinalityLimitFor: anOTMetricInstrument
						reader: self ])
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
		| instrumentMeasurements views |
		instrumentMeasurements := grouped at: each ifAbsent: [ #() ].
		views := self matchingViewsFor: each.
		views ifEmpty: [ views := { nil } ].
		views do: [ :view |
			| context metric preparedMeasurements selectedMeasurements |
			context := self
				metricAggregationContextFor: each
				view: view
				collectedAt: aDateAndTime.
			context ifNotNil: [
				context aggregation = #drop ifFalse: [
					preparedMeasurements := each
						preparedMeasurementsFrom: instrumentMeasurements
						forReader: self
						using: context.
					selectedMeasurements := self
						selectedMeasurementsFrom: preparedMeasurements
						for: each
						using: context.
					selectedMeasurements := self
						cardinalityLimitedMeasurementsFrom: selectedMeasurements
						for: each
						using: context
						stateKey: (self cardinalityStateKeyFor: each view: view).
					selectedMeasurements ifNotEmpty: [
						metric := each
							metricDataFromMeasurements: selectedMeasurements
							using: context.
						view ifNotNil: [ view applyToMetricData: metric ].
						metrics add: metric ] ] ] ] ].
	^ metrics asArray
]

{ #category : 'collecting' }
OTMetricReader >> matchingViewsFor: anOTMetricInstrument [

	| matchingViews validViews |
	self provider ifNil: [ ^ #() ].
	matchingViews := self provider matchingViewsFor: anOTMetricInstrument.
	matchingViews ifEmpty: [ ^ #() ].
	validViews := OrderedCollection new.
	matchingViews do: [ :each |
		| aggregation |
		aggregation := each resolvedAggregationFor: anOTMetricInstrument reader: self.
		(anOTMetricInstrument supportsAggregation: aggregation)
			ifTrue: [ validViews add: each ]
			ifFalse: [
				self
					noteIncompatibleViewAggregation: aggregation
					view: each
					for: anOTMetricInstrument ] ].
	^ validViews asArray
]

{ #category : 'private - logging' }
OTMetricReader >> noteIncompatibleAggregation: anAggregationSymbol for: anOTMetricInstrument [

	OTDiagnosticLogger defaultWarningSink value:
		'OpenTelemetry metric reader aggregation '
			, anAggregationSymbol printString
			, ' is incompatible with instrument '
			, anOTMetricInstrument name printString
			, ' of type '
			, anOTMetricInstrument instrumentType printString
			, ' and has fallen back to #default'
]

{ #category : 'private - logging' }
OTMetricReader >> noteIncompatibleViewAggregation: anAggregationSymbol view: anOTMetricView for: anOTMetricInstrument [

	OTDiagnosticLogger defaultWarningSink value:
		'OpenTelemetry metric view aggregation '
			, anAggregationSymbol printString
			, ' is incompatible with instrument '
			, anOTMetricInstrument name printString
			, ' of type '
			, anOTMetricInstrument instrumentType printString
			, ' and the view has been ignored'
]

{ #category : 'accessing' }
OTMetricReader >> normalizedAggregationSymbolFrom: anObject [

	^ OTMetricView normalizedAggregationFrom: anObject
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
OTMetricReader >> selectedAttributeSetMatching: someAttributes within: selectedAttributeSets [

	^ selectedAttributeSets
		detect: [ :each | each = someAttributes ]
		ifNone: [ nil ]
]

{ #category : 'collecting' }
OTMetricReader >> selectedAttributeSetsByStream [

	^ selectedAttributeSetsByStream
		ifNil: [ selectedAttributeSetsByStream := Dictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> selectedAttributeSetsForStateKey: aStateKey [

	^ self selectedAttributeSetsByStream
		at: aStateKey
		ifAbsentPut: [ OrderedCollection new ]
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
