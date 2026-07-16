Class {
	#name : 'OTMetricAggregationContext',
	#superclass : 'Object',
	#instVars : [
		'collectedAt',
		'startTimestamp',
		'temporality'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricAggregationContext class >> collectedAt: aCollectedAt startTimestamp: aStartTimestamp temporality: aTemporalitySymbol [

	| context |
	context := self new.
	context
		collectedAt: aCollectedAt;
		startTimestamp: aStartTimestamp;
		temporality: aTemporalitySymbol.
	^ context
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
