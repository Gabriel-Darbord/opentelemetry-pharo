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
		'aggregationParameters'
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
]

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol aggregation: anAggregationSymbol retainedAttributeKeys: someAttributeKeys cardinalityLimit: anInteger aggregationParameters: someAggregationParameters [

	| context |
	context := self new.
	context
		collectedAt: aCollectedAt;
		startTimestamp: aStartTimestamp;
		temporality: aTemporalitySymbol;
		aggregation: anAggregationSymbol;
		retainedAttributeKeys: someAttributeKeys;
		cardinalityLimit: anInteger;
		aggregationParameters: someAggregationParameters.
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
