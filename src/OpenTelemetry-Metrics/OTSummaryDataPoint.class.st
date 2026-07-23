Class {
	#name : 'OTSummaryDataPoint',
	#superclass : 'Object',
	#instVars : [
		'attributes',
		'count',
		'sum',
		'quantileValues',
		'startTimestamp',
		'timestamp'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSummaryDataPoint class >> attributes: aCollection count: aCount sum: aSum quantileValues: someQuantileValues startTimestamp: aStartDateAndTime timestamp: anEndDateAndTime [

	| point |
	point := self new.
	point
		attributes: aCollection;
		count: aCount;
		sum: aSum;
		quantileValues: someQuantileValues;
		startTimestamp: aStartDateAndTime;
		timestamp: anEndDateAndTime.
	^ point
]

{ #category : 'accessing' }
OTSummaryDataPoint >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTSummaryDataPoint >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTSummaryDataPoint >> count [

	^ count ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSummaryDataPoint >> count: anInteger [

	count := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'accessing' }
OTSummaryDataPoint >> quantileValues [

	^ quantileValues ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTSummaryDataPoint >> quantileValues: aCollection [

	quantileValues := ((aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]) asSortedCollection: [ :left :right |
		                   left quantile <= right quantile ]) asArray
]

{ #category : 'accessing' }
OTSummaryDataPoint >> startTimestamp [

	^ startTimestamp
]

{ #category : 'accessing' }
OTSummaryDataPoint >> startTimestamp: aDateAndTime [

	startTimestamp := aDateAndTime
]

{ #category : 'accessing' }
OTSummaryDataPoint >> sum [

	^ sum ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSummaryDataPoint >> sum: aNumber [

	sum := aNumber ifNil: [ 0 ] ifNotNil: [ aNumber ]
]

{ #category : 'accessing' }
OTSummaryDataPoint >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTSummaryDataPoint >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]
