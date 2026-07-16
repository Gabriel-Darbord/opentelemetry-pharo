Class {
	#name : 'OTMetricAggregationContext',
	#superclass : 'Object',
	#instVars : [
		'collectedAt',
		'startTimestamp',
		'temporality',
		'aggregation'
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
]

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol aggregation: anAggregationSymbol [

	| context |
	context := self new.
	context
		collectedAt: aCollectedAt;
		startTimestamp: aStartTimestamp;
		temporality: aTemporalitySymbol;
		aggregation: anAggregationSymbol.
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
OTMetricAggregationContext >> collectedAt [

	^ collectedAt ifNil: [ DateAndTime now asUTC ]
]

{ #category : 'accessing' }
OTMetricAggregationContext >> collectedAt: aDateAndTime [

	collectedAt := aDateAndTime ifNil: [ DateAndTime now asUTC ] ifNotNil: [ aDateAndTime ]
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
