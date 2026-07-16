Class {
	#name : 'OTHistogramDataPoint',
	#superclass : 'Object',
	#instVars : [
		'attributes',
		'count',
		'sum',
		'min',
		'max',
		'explicitBounds',
		'bucketCounts',
		'startTimestamp',
		'timestamp'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTHistogramDataPoint class >> attributes: aCollection count: aCount sum: aSum min: aMin max: aMax explicitBounds: someBounds bucketCounts: someBucketCounts startTimestamp: aStartDateAndTime timestamp: anEndDateAndTime [

	| point |
	point := self new.
	point
		attributes: aCollection;
		count: aCount;
		sum: aSum;
		min: aMin;
		max: aMax;
		explicitBounds: someBounds;
		bucketCounts: someBucketCounts;
		startTimestamp: aStartDateAndTime;
		timestamp: anEndDateAndTime.
	^ point
]

{ #category : 'accessing' }
OTHistogramDataPoint >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTHistogramDataPoint >> bucketCounts [

	^ bucketCounts ifNil: [ #() ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> bucketCounts: aCollection [

	bucketCounts := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> count [

	^ count ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> count: anInteger [

	count := anInteger
]

{ #category : 'accessing' }
OTHistogramDataPoint >> explicitBounds [

	^ explicitBounds ifNil: [ #() ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> explicitBounds: aCollection [

	explicitBounds := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> max [

	^ max
]

{ #category : 'accessing' }
OTHistogramDataPoint >> max: aNumber [

	max := aNumber
]

{ #category : 'accessing' }
OTHistogramDataPoint >> min [

	^ min
]

{ #category : 'accessing' }
OTHistogramDataPoint >> min: aNumber [

	min := aNumber
]

{ #category : 'accessing' }
OTHistogramDataPoint >> sum [

	^ sum ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTHistogramDataPoint >> sum: aNumber [

	sum := aNumber
]

{ #category : 'accessing' }
OTHistogramDataPoint >> startTimestamp [

	^ startTimestamp
]

{ #category : 'accessing' }
OTHistogramDataPoint >> startTimestamp: aDateAndTime [

	startTimestamp := aDateAndTime
]

{ #category : 'accessing' }
OTHistogramDataPoint >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTHistogramDataPoint >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
}
