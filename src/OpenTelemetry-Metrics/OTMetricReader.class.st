"
I am the abstract base class for metric readers.
I collect measurements from a provider, apply per-stream aggregation policy, and manage reader lifecycle state.
"
Class {
	#name : 'OTMetricReader',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'shutdown',
		'stateLock',
		'shutdownRequested',
		'temporalitySelector',
		'aggregationSelector',
		'cardinalityLimitSelector',
		'callbackTimeoutMillis',
		'selectedAttributeSetsByStream',
		'warnedMetricIdentityConflicts',
		'lastCollectionTimestampByInstrument',
		'lastAsynchronousValuesByInstrument'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'private - logging' }
OTMetricReader class >> callbackWarningSink [

	^ OTClassStateStore valueAt: #otMetricCallbackWarningSink forClass: self ifAbsent: [ self defaultCallbackWarningSink ]
]

{ #category : 'private - logging' }
OTMetricReader class >> callbackWarningSink: aBlock [

	aBlock
		ifNil: [ OTClassStateStore removeValueAt: #otMetricCallbackWarningSink forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otMetricCallbackWarningSink forClass: self put: aBlock ].
	^ self callbackWarningSink
]

{ #category : 'private - logging' }
OTMetricReader class >> defaultCallbackWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTMetricReader class >> defaultMetricWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTMetricReader class >> metricWarningSink [

	^ OTClassStateStore valueAt: #otMetricReaderWarningSink forClass: self ifAbsent: [ self defaultMetricWarningSink ]
]

{ #category : 'private - logging' }
OTMetricReader class >> metricWarningSink: aBlock [

	aBlock
		ifNil: [ OTClassStateStore removeValueAt: #otMetricReaderWarningSink forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otMetricReaderWarningSink forClass: self put: aBlock ].
	^ self metricWarningSink
]

{ #category : 'accessing' }
OTMetricReader >> aggregationFor: anOTMetricInstrument [

	| selected |
	selected := self normalizedAggregationSymbolFrom: (self aggregationSelector value: anOTMetricInstrument).
	selected = #explicitBucketHistogram ifTrue: [ ^ #default ].
	(anOTMetricInstrument supportsAggregation: selected) ifTrue: [ ^ selected ].
	self noteIncompatibleAggregation: selected for: anOTMetricInstrument.
	^ #default
]

{ #category : 'accessing' }
OTMetricReader >> aggregationSelector [

	^ stateLock critical: [ aggregationSelector ifNil: [ self defaultAggregationSelector ] ]
]

{ #category : 'accessing' }
OTMetricReader >> aggregationSelector: aBlockOrNil [

	stateLock critical: [
		self ensureOpenLocked.
		aggregationSelector := aBlockOrNil ]
]

{ #category : 'accessing' }
OTMetricReader >> attachToProvider: anOTMeterProvider [

	^ stateLock critical: [
			  self ensureOpenLocked.
			  provider ifNil: [
					  provider := anOTMeterProvider.
					  ^ provider ].
			  provider == anOTMeterProvider ifTrue: [ ^ provider ].
			  Error signal: 'OpenTelemetry metric readers cannot be registered on multiple meter providers' ]
]

{ #category : 'private - lifecycle' }
OTMetricReader >> beginShutdown [

	^ stateLock critical: [
			  (shutdownRequested or: [ shutdown ]) ifTrue: [ ^ false ].
			  shutdownRequested := true.
			  true ]
]

{ #category : 'accessing' }
OTMetricReader >> callbackTimeoutMillis [

	^ stateLock critical: [ callbackTimeoutMillis ifNil: [ 30000 ] ]
]

{ #category : 'accessing' }
OTMetricReader >> callbackTimeoutMillis: anInteger [

	^ stateLock critical: [
			  self ensureOpenLocked.
			  callbackTimeoutMillis := anInteger ifNil: [ 30000 ] ifNotNil: [ anInteger max: 1 ].
			  callbackTimeoutMillis ]
]

{ #category : 'private - logging' }
OTMetricReader >> callbackWarningSink [

	^ OTMetricReader callbackWarningSink
]

{ #category : 'accessing' }
OTMetricReader >> cardinalityLimitFor: anOTMetricInstrument [

	| selected |
	selected := self cardinalityLimitSelector value: anOTMetricInstrument.
	(selected isInteger and: [ selected > 0 ]) ifTrue: [ ^ selected ].
	^ 2000
]

{ #category : 'accessing' }
OTMetricReader >> cardinalityLimitSelector [

	^ stateLock critical: [ cardinalityLimitSelector ifNil: [ self defaultCardinalityLimitSelector ] ]
]

{ #category : 'accessing' }
OTMetricReader >> cardinalityLimitSelector: aBlockOrNil [

	stateLock critical: [
		self ensureOpenLocked.
		cardinalityLimitSelector := aBlockOrNil ]
]

{ #category : 'collecting' }
OTMetricReader >> cardinalityLimitedMeasurementsFrom: someMeasurements for: anOTMetricInstrument using: anOTMetricAggregationContext stateKey: aStateKey [

	| attributeFilter limit overflowAttributes |
	limit := anOTMetricAggregationContext cardinalityLimit.
	overflowAttributes := self overflowAttributes.
	attributeFilter := anOTMetricAggregationContext attributeFilter.
	^ self
		  withSelectedAttributeSetsForStateKey: aStateKey
		  do: [ :selectedAttributeSets |
				  | limitedMeasurements |
				  limitedMeasurements := OrderedCollection new: someMeasurements size.
				  someMeasurements do: [ :each |
						  | knownAttributes normalizedAttributes |
						  normalizedAttributes := anOTMetricInstrument normalizedAttributesForMeasurement: each usingAttributeFilter: attributeFilter.
						  knownAttributes := self selectedAttributeSetMatching: normalizedAttributes within: selectedAttributeSets.
						  knownAttributes
							  ifNotNil: [ limitedMeasurements add: (each withAttributes: knownAttributes) ]
							  ifNil: [
									  selectedAttributeSets size < limit
										  ifTrue: [
												  selectedAttributeSets add: normalizedAttributes.
												  limitedMeasurements add: (each withAttributes: normalizedAttributes) ]
										  ifFalse: [ limitedMeasurements add: (each withAttributes: overflowAttributes) ] ] ].
				  limitedMeasurements asArray ]
]

{ #category : 'collecting' }
OTMetricReader >> cardinalityStateKeyFor: anOTMetricInstrument view: anOTMetricViewOrNil [

	anOTMetricViewOrNil ifNil: [ ^ anOTMetricInstrument ].
	^ {
		  anOTMetricInstrument.
		  anOTMetricViewOrNil }
]

{ #category : 'collecting' }
OTMetricReader >> collect [

	self subclassResponsibility
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
OTMetricReader >> collectSnapshot [

	| collectedAt instruments measurements metrics |
	self isStopping ifTrue: [ ^ OTMetricSnapshot empty ].
	collectedAt := DateAndTime now asUTC.
	^ self provider ifNil: [ OTMetricSnapshot empty ] ifNotNil: [ :aProvider |
			  instruments := aProvider registeredMetricInstruments.
			  measurements := aProvider collectMeasurementsFor: self.
			  metrics := self metricDataFromMeasurements: measurements instruments: instruments collectedAt: collectedAt.
			  self markCollectedAt: collectedAt forInstruments: instruments.
			  OTMetricSnapshot
				  resource: aProvider resource
				  measurements: measurements
				  metrics: metrics
				  collectedAt: collectedAt ]
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
OTMetricReader >> defaultTemporalitySelector [

	^ [ :instrument | #cumulative ]
]

{ #category : 'callbacks' }
OTMetricReader >> didRegisterWithProvider [

	self
]

{ #category : 'private - lifecycle' }
OTMetricReader >> ensureOpenLocked [

	(shutdownRequested or: [ shutdown ]) ifTrue: [ Error signal: 'OpenTelemetry metric reader is shutdown' ]
]

{ #category : 'private - lifecycle' }
OTMetricReader >> finishShutdown [

	stateLock critical: [ shutdown := true ]
]

{ #category : 'lifecycle' }
OTMetricReader >> forceFlush [

	^ self isStopping not
]

{ #category : 'initialization' }
OTMetricReader >> initialize [

	super initialize.
	stateLock := Semaphore forMutualExclusion.
	shutdown := false.
	shutdownRequested := false.
	lastCollectionTimestampByInstrument := WeakIdentityKeyDictionary new.
	lastAsynchronousValuesByInstrument := WeakIdentityKeyDictionary new.
	temporalitySelector := nil.
	aggregationSelector := nil.
	cardinalityLimitSelector := nil.
	callbackTimeoutMillis := 30000.
	selectedAttributeSetsByStream := Dictionary new.
	warnedMetricIdentityConflicts := Set new
]

{ #category : 'collecting' }
OTMetricReader >> invokeAsynchronousCallback: aBlock for: anOTAsynchronousMetricInstrument observer: anOTAsynchronousMetricObserver [

	| error process semaphore timedOut timeoutMillis |
	error := nil.
	timeoutMillis := self callbackTimeoutMillis.
	semaphore := Semaphore new.
	process := [
		           [ anOTAsynchronousMetricInstrument invokeCallback: aBlock with: anOTAsynchronousMetricObserver ]
			           on: Error
			           do: [ :anError | error := anError ].
		           semaphore signal ] forkAt: Processor userBackgroundPriority.
	timedOut := semaphore waitTimeoutMilliseconds: timeoutMillis.
	timedOut ifTrue: [
			process terminate.
			self noteAsynchronousCallbackTimeoutFor: anOTAsynchronousMetricInstrument timeoutMillis: timeoutMillis.
			^ #timedOut ].
	error ifNotNil: [
			self noteAsynchronousCallbackError: error for: anOTAsynchronousMetricInstrument.
			^ #failed ].
	^ #completed
]

{ #category : 'testing' }
OTMetricReader >> isShutdown [

	^ stateLock critical: [ shutdown = true ]
]

{ #category : 'testing' }
OTMetricReader >> isStopping [

	^ stateLock critical: [ shutdownRequested = true ]
]

{ #category : 'collecting' }
OTMetricReader >> lastAsynchronousValuesByInstrument [

	^ lastAsynchronousValuesByInstrument ifNil: [ lastAsynchronousValuesByInstrument := WeakIdentityKeyDictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> lastAsynchronousValuesFor: anOTMetricInstrument [

	^ self withLastAsynchronousValuesFor: anOTMetricInstrument do: [ :values | values copy ]
]

{ #category : 'collecting' }
OTMetricReader >> lastCollectionTimestampByInstrument [

	^ lastCollectionTimestampByInstrument ifNil: [ lastCollectionTimestampByInstrument := WeakIdentityKeyDictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> lastCollectionTimestampFor: anOTMetricInstrument [

	^ stateLock critical: [ (self lastCollectionTimestampByInstrument at: anOTMetricInstrument ifAbsent: [ nil ]) ]
]

{ #category : 'collecting' }
OTMetricReader >> markCollectedAt: aDateAndTime forInstruments: someInstruments [

	stateLock critical: [ someInstruments do: [ :each | self lastCollectionTimestampByInstrument at: each put: aDateAndTime ] ]
]

{ #category : 'collecting' }
OTMetricReader >> matchingViewsFor: anOTMetricInstrument [

	| matchingViews validViews |
	self provider ifNil: [ ^ #(  ) ].
	matchingViews := self provider matchingViewsFor: anOTMetricInstrument.
	matchingViews ifEmpty: [ ^ #(  ) ].
	validViews := OrderedCollection new.
	matchingViews do: [ :each |
			| aggregation |
			aggregation := each resolvedAggregationFor: anOTMetricInstrument reader: self.
			(anOTMetricInstrument supportsAggregation: aggregation)
				ifTrue: [ validViews add: each ]
				ifFalse: [ self noteIncompatibleViewAggregation: aggregation view: each for: anOTMetricInstrument ] ].
	^ validViews asArray
]

{ #category : 'collecting' }
OTMetricReader >> metricAggregationContextFor: anOTMetricInstrument collectedAt: aDateAndTime [

	^ self metricAggregationContextFor: anOTMetricInstrument view: nil collectedAt: aDateAndTime
]

{ #category : 'collecting' }
OTMetricReader >> metricAggregationContextFor: anOTMetricInstrument view: anOTMetricViewOrNil collectedAt: aDateAndTime [

	| aggregation attributeFilter previousCollection startTimestamp temporality |
	temporality := self temporalityFor: anOTMetricInstrument.
	previousCollection := self lastCollectionTimestampFor: anOTMetricInstrument.
	startTimestamp := anOTMetricInstrument startTimestampForPreviousCollection: previousCollection temporality: temporality.
	aggregation := anOTMetricViewOrNil
		               ifNil: [ self aggregationFor: anOTMetricInstrument ]
		               ifNotNil: [ anOTMetricViewOrNil resolvedAggregationFor: anOTMetricInstrument reader: self ].
	(anOTMetricInstrument supportsAggregation: aggregation) ifFalse: [ ^ nil ].
	attributeFilter := anOTMetricViewOrNil
		                   ifNil: [ anOTMetricInstrument attributeFilter ]
		                   ifNotNil: [ anOTMetricViewOrNil resolvedAttributeFilterFor: anOTMetricInstrument ].
	^ OTMetricAggregationContext
		  collectedAt: aDateAndTime
		  startTimestamp: startTimestamp
		  temporality: temporality
		  aggregation: aggregation
		  retainedAttributeKeys: attributeFilter
		  cardinalityLimit: (anOTMetricViewOrNil
				   ifNil: [ self cardinalityLimitFor: anOTMetricInstrument ]
				   ifNotNil: [ anOTMetricViewOrNil resolvedCardinalityLimitFor: anOTMetricInstrument reader: self ])
		  aggregationParameters:
		  (anOTMetricViewOrNil ifNotNil: [ anOTMetricViewOrNil resolvedAggregationParametersFor: anOTMetricInstrument reader: self ])
		  exemplarFilter: self provider exemplarFilter
		  exemplarReservoirFactory:
		  (anOTMetricViewOrNil ifNotNil: [ anOTMetricViewOrNil resolvedExemplarReservoirFactoryFor: anOTMetricInstrument reader: self ])
]

{ #category : 'collecting' }
OTMetricReader >> metricDataFromMeasurements: someMeasurements instruments: someInstruments collectedAt: aDateAndTime [

	| grouped metrics |
	grouped := OrderedDictionary new.
	someMeasurements do: [ :each | (grouped at: each instrument ifAbsentPut: [ OrderedCollection new ]) add: each ].
	metrics := OrderedCollection new.
	someInstruments do: [ :each |
			| instrumentMeasurements views |
			instrumentMeasurements := grouped at: each ifAbsent: [ #(  ) ].
			views := self matchingViewsFor: each.
			views ifEmpty: [ views := { nil } ].
			views do: [ :view |
					| context metric preparedMeasurements selectedMeasurements |
					context := self metricAggregationContextFor: each view: view collectedAt: aDateAndTime.
					context ifNotNil: [
							context aggregation = #drop ifFalse: [
									preparedMeasurements := each preparedMeasurementsFrom: instrumentMeasurements forReader: self using: context.
									selectedMeasurements := self selectedMeasurementsFrom: preparedMeasurements for: each using: context.
									selectedMeasurements := self
										                        cardinalityLimitedMeasurementsFrom: selectedMeasurements
										                        for: each
										                        using: context
										                        stateKey: (self cardinalityStateKeyFor: each view: view).
									selectedMeasurements ifNotEmpty: [
											metric := each metricDataFromMeasurements: selectedMeasurements using: context.
											view ifNotNil: [ view applyToMetricData: metric ].
											metrics add: metric ] ] ] ] ].
	self noteConflictingMetricIdentitiesIn: metrics.
	^ metrics asArray
]

{ #category : 'private - logging' }
OTMetricReader >> metricIdentityKeyFor: anOTMetricData [

	^ {
		  anOTMetricData instrumentationScope.
		  anOTMetricData class.
		  anOTMetricData name.
		  anOTMetricData description.
		  anOTMetricData unit }
]

{ #category : 'private - logging' }
OTMetricReader >> metricWarningSink [

	^ OTMetricReader metricWarningSink
]

{ #category : 'accessing' }
OTMetricReader >> normalizedAggregationSymbolFrom: anObject [

	^ OTMetricView normalizedAggregationFrom: anObject
]

{ #category : 'private - logging' }
OTMetricReader >> noteAsynchronousCallbackError: anError for: anOTAsynchronousMetricInstrument [

	self callbackWarningSink value:
		'OpenTelemetry asynchronous metric callback failed for instrument ' , anOTAsynchronousMetricInstrument name printString , ': '
		, anError messageText
]

{ #category : 'private - logging' }
OTMetricReader >> noteAsynchronousCallbackTimeoutFor: anOTAsynchronousMetricInstrument [

	self noteAsynchronousCallbackTimeoutFor: anOTAsynchronousMetricInstrument timeoutMillis: self callbackTimeoutMillis
]

{ #category : 'private - logging' }
OTMetricReader >> noteAsynchronousCallbackTimeoutFor: anOTAsynchronousMetricInstrument timeoutMillis: anInteger [

	self callbackWarningSink value:
		'OpenTelemetry asynchronous metric callback timed out for instrument ' , anOTAsynchronousMetricInstrument name printString
		, ' after ' , anInteger asString , ' ms'
]

{ #category : 'private - logging' }
OTMetricReader >> noteConflictingMetricIdentitiesIn: someMetrics [

	| groupedMetrics |
	groupedMetrics := OrderedDictionary new.
	someMetrics do: [ :each |
		(groupedMetrics at: (self metricIdentityKeyFor: each) ifAbsentPut: [ OrderedCollection new ]) add: each ].
	groupedMetrics associationsDo: [ :each |
			(self shouldWarnAboutMetricIdentityConflictAt: each key whenMetricCountIs: each value size)
				ifTrue: [ self noteMetricIdentityConflictFor: each value ] ]
]

{ #category : 'private - logging' }
OTMetricReader >> noteIncompatibleAggregation: anAggregationSymbol for: anOTMetricInstrument [

	self metricWarningSink value:
		'OpenTelemetry metric reader aggregation ' , anAggregationSymbol printString , ' is incompatible with instrument '
		, anOTMetricInstrument name printString , ' of type ' , anOTMetricInstrument instrumentType printString
		, ' and has fallen back to #default'
]

{ #category : 'private - logging' }
OTMetricReader >> noteIncompatibleViewAggregation: anAggregationSymbol view: anOTMetricView for: anOTMetricInstrument [

	self metricWarningSink value:
		'OpenTelemetry metric view aggregation ' , anAggregationSymbol printString , ' is incompatible with instrument '
		, anOTMetricInstrument name printString , ' of type ' , anOTMetricInstrument instrumentType printString
		, ' and the view has been ignored'
]

{ #category : 'private - logging' }
OTMetricReader >> noteMetricIdentityConflictFor: someMetrics [

	| firstMetric |
	firstMetric := someMetrics first.
	self metricWarningSink value:
		'OpenTelemetry metric views produced conflicting metric identities for ' , firstMetric name printString , ' in meter '
		, firstMetric instrumentationScope name printString
		, '. Multiple streams with the same name, description, unit, and metric type will be exported.'
]

{ #category : 'collecting' }
OTMetricReader >> overflowAttributes [

	^ OTAttributeNormalizer normalizeAttributes: { ('otel.metric.overflow' -> true) }
]

{ #category : 'accessing' }
OTMetricReader >> provider [

	^ stateLock critical: [ provider ]
]

{ #category : 'accessing' }
OTMetricReader >> provider: anOTMeterProvider [

	stateLock critical: [ provider := anOTMeterProvider ]
]

{ #category : 'collecting' }
OTMetricReader >> selectedAttributeSetMatching: someAttributes within: selectedAttributeSets [

	^ selectedAttributeSets detect: [ :each | each = someAttributes ] ifNone: [ nil ]
]

{ #category : 'collecting' }
OTMetricReader >> selectedAttributeSetsByStream [

	^ selectedAttributeSetsByStream ifNil: [ selectedAttributeSetsByStream := Dictionary new ]
]

{ #category : 'collecting' }
OTMetricReader >> selectedAttributeSetsForStateKey: aStateKey [

	^ self withSelectedAttributeSetsForStateKey: aStateKey do: [ :selectedAttributeSets | selectedAttributeSets copy ]
]

{ #category : 'collecting' }
OTMetricReader >> selectedMeasurementsFrom: someMeasurements for: anOTMetricInstrument using: anOTMetricAggregationContext [

	| startTimestamp |
	anOTMetricAggregationContext temporality = #delta ifFalse: [ ^ someMeasurements ].
	startTimestamp := anOTMetricAggregationContext startTimestamp.
	startTimestamp ifNil: [ ^ someMeasurements ].
	^ someMeasurements select: [ :each |
		  each timestamp > startTimestamp and: [ each timestamp <= anOTMetricAggregationContext collectedAt ] ]
]

{ #category : 'lifecycle' }
OTMetricReader >> shutdown [

	(self beginShutdown) ifFalse: [ ^ false ].
	self finishShutdown.
	^ true
]

{ #category : 'private - logging' }
OTMetricReader >> shouldWarnAboutMetricIdentityConflictAt: aMetricIdentityKey whenMetricCountIs: anInteger [

	^ stateLock critical: [
			  anInteger <= 1 ifTrue: [ ^ false ].
			  (warnedMetricIdentityConflicts includes: aMetricIdentityKey) ifTrue: [ ^ false ].
			  warnedMetricIdentityConflicts add: aMetricIdentityKey.
			  true ]
]

{ #category : 'collecting' }
OTMetricReader >> temporalityFor: anOTMetricInstrument [

	| selected |
	selected := self temporalitySelector value: anOTMetricInstrument.
	^ selected = #delta
		  ifTrue: [ #delta ]
		  ifFalse: [ #cumulative ]
]

{ #category : 'accessing' }
OTMetricReader >> temporalitySelector [

	^ stateLock critical: [ temporalitySelector ifNil: [ self defaultTemporalitySelector ] ]
]

{ #category : 'accessing' }
OTMetricReader >> temporalitySelector: aBlockOrNil [

	stateLock critical: [
		self ensureOpenLocked.
		temporalitySelector := aBlockOrNil ]
]

{ #category : 'collecting' }
OTMetricReader >> withLastAsynchronousValuesFor: anOTMetricInstrument do: aBlock [

	^ stateLock critical: [
			  aBlock value: (self lastAsynchronousValuesByInstrument at: anOTMetricInstrument ifAbsentPut: [ Dictionary new ]) ]
]

{ #category : 'collecting' }
OTMetricReader >> withSelectedAttributeSetsForStateKey: aStateKey do: aBlock [

	^ stateLock critical: [
			  aBlock value: (self selectedAttributeSetsByStream at: aStateKey ifAbsentPut: [ OrderedCollection new ]) ]
]
