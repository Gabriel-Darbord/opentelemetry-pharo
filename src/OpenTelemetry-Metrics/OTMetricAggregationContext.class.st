Class {
	#name : 'OTMetricAggregationContext',
	#superclass : 'Object',
	#instVars : [
		'collectedAt',
		'startTimestamp',
		'temporality',
		'aggregation',
		'retainedAttributeKeys',
		'cardinalityLimit',
		'aggregationParameters',
		'exemplarFilter',
		'exemplarReservoirFactory'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol [

	^ self
		collectedAt: aCollectedAt
		startTimestamp: aStartTimestamp
		temporality: aTemporalitySymbol
		aggregation: #default
		retainedAttributeKeys: nil
		cardinalityLimit: 2000
		aggregationParameters: nil
		exemplarFilter: OTMetricExemplarFilter traceBased
		exemplarReservoirFactory: nil
]

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol aggregation: anAggregationSymbol [

	^ self
		collectedAt: aCollectedAt
		startTimestamp: aStartTimestamp
		temporality: aTemporalitySymbol
		aggregation: anAggregationSymbol
		retainedAttributeKeys: nil
		cardinalityLimit: 2000
		aggregationParameters: nil
		exemplarFilter: OTMetricExemplarFilter traceBased
		exemplarReservoirFactory: nil
]

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol aggregation: anAggregationSymbol retainedAttributeKeys: someAttributeKeys cardinalityLimit: anInteger [

	^ self
		collectedAt: aCollectedAt
		startTimestamp: aStartTimestamp
		temporality: aTemporalitySymbol
		aggregation: anAggregationSymbol
		retainedAttributeKeys: someAttributeKeys
		cardinalityLimit: anInteger
		aggregationParameters: nil
		exemplarFilter: OTMetricExemplarFilter traceBased
		exemplarReservoirFactory: nil
]

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol aggregation: anAggregationSymbol retainedAttributeKeys: someAttributeKeys cardinalityLimit: anInteger aggregationParameters: someAggregationParameters exemplarFilter: anOTMetricExemplarFilter exemplarReservoirFactory: aBlockClosure [

	| context |
	context := self new.
	context
		collectedAt: aCollectedAt;
		startTimestamp: aStartTimestamp;
		temporality: aTemporalitySymbol;
		aggregation: anAggregationSymbol;
		retainedAttributeKeys: someAttributeKeys;
		cardinalityLimit: anInteger;
		aggregationParameters: someAggregationParameters;
		exemplarFilter: anOTMetricExemplarFilter;
		exemplarReservoirFactory: aBlockClosure.
	^ context
]

{ #category : 'accessing' }
OTMetricAggregationContext >> aggregation [

	^ aggregation ifNil: [ #default ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> aggregation: aSymbol [

	aggregation := aSymbol ifNil: [ #default ] ifNotNil: [ aSymbol ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> aggregationParameterAt: aSymbol ifAbsent: aBlock [

	^ self aggregationParameters
		at: aSymbol
		ifAbsent: aBlock
]

{ #category : 'accessing' }
OTMetricAggregationContext >> aggregationParameters [

	^ aggregationParameters ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> aggregationParameters: aCollection [

	aggregationParameters := aCollection
		ifNil: [ OrderedDictionary new ]
		ifNotNil: [ aCollection asOrderedDictionary ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> exemplarFilter [

	^ exemplarFilter ifNil: [ OTMetricExemplarFilter traceBased ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> exemplarFilter: anOTMetricExemplarFilter [

	exemplarFilter := anOTMetricExemplarFilter
		ifNil: [ OTMetricExemplarFilter traceBased ]
		ifNotNil: [ anOTMetricExemplarFilter ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> exemplarReservoirFactory [

	^ exemplarReservoirFactory
]

{ #category : 'accessing' }
OTMetricAggregationContext >> exemplarReservoirFactory: aBlockClosure [

	exemplarReservoirFactory := aBlockClosure
]

{ #category : 'exemplars' }
OTMetricAggregationContext >> newExemplarReservoirForInstrument: anOTMetricInstrument pointAttributes: aCollection [

	| usesExplicitHistogram |
	exemplarFilter capturesMeasurements ifFalse: [
		^ OTNoopMetricExemplarReservoir new ].
	exemplarReservoirFactory ifNotNil: [
		^ exemplarReservoirFactory
			value: self
			value: anOTMetricInstrument
			value: aCollection ].
	usesExplicitHistogram := self aggregation = #explicitBucketHistogram
		or: [ self aggregation = #default
			and: [ anOTMetricInstrument instrumentType = #histogram ] ].
	usesExplicitHistogram ifTrue: [
		| boundaries |
		boundaries := self aggregationParameters
			at: #boundaries
			ifAbsent: [ anOTMetricInstrument explicitBucketBoundaries ].
		boundaries size > 1 ifTrue: [
			^ OTAlignedHistogramBucketMetricExemplarReservoir boundaries: boundaries ] ].
	self aggregation = #base2ExponentialBucketHistogram ifTrue: [
		| maxSize |
		maxSize := self aggregationParameters
			at: #maxSize
			ifAbsent: [ anOTMetricInstrument exponentialHistogramMaxSize ].
		^ OTSimpleFixedSizeMetricExemplarReservoir size: (20 min: maxSize) ].
	^ OTSimpleFixedSizeMetricExemplarReservoir size: 1
]

{ #category : 'accessing' }
OTMetricAggregationContext >> collectedAt [

	^ collectedAt ifNil: [ DateAndTime now asUTC ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> collectedAt: aDateAndTime [

	collectedAt := aDateAndTime ifNil: [ DateAndTime now asUTC ] ifNotNil: [ aDateAndTime ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> cardinalityLimit [

	^ cardinalityLimit ifNil: [ 2000 ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> cardinalityLimit: anInteger [

	cardinalityLimit := (anInteger isInteger and: [ anInteger > 0 ])
		ifTrue: [ anInteger ]
		ifFalse: [ 2000 ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> retainedAttributeKeys [

	^ retainedAttributeKeys
]

{ #category : 'accessing' }
OTMetricAggregationContext >> retainedAttributeKeys: aCollection [

	retainedAttributeKeys := aCollection
]

{ #category : 'accessing' }
OTMetricAggregationContext >> startTimestamp [

	^ startTimestamp
]

{ #category : 'accessing' }
OTMetricAggregationContext >> startTimestamp: aDateAndTime [

	startTimestamp := aDateAndTime
]

{ #category : 'accessing' }
OTMetricAggregationContext >> temporality [

	^ temporality ifNil: [ #cumulative ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> temporality: aSymbol [

	temporality := aSymbol ifNil: [ #cumulative ] ifNotNil: [ aSymbol ]
]
