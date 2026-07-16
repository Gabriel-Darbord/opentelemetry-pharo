Class {
	#name : 'OTExponentialHistogramDataPoint',
	#superclass : 'Object',
	#instVars : [
		'attributes',
		'count',
		'sum',
		'scale',
		'zeroCount',
		'positiveBuckets',
		'negativeBuckets',
		'min',
		'max',
		'startTimestamp',
		'timestamp',
		'zeroThreshold',
		'exemplars'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> exemplars [

	^ exemplars ifNil: [ #() ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> exemplars: aCollection [

	exemplars := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> count [

	^ count ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> count: anInteger [

	count := anInteger
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> max [

	^ max
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> max: aNumber [

	max := aNumber
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> min [

	^ min
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> min: aNumber [

	min := aNumber
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> negativeBuckets [

	^ negativeBuckets ifNil: [ OTExponentialBucketRange offset: 0 bucketCounts: #() ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> negativeBuckets: anOTExponentialBucketRange [

	negativeBuckets := anOTExponentialBucketRange
		ifNil: [ OTExponentialBucketRange offset: 0 bucketCounts: #() ]
		ifNotNil: [ anOTExponentialBucketRange ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> positiveBuckets [

	^ positiveBuckets ifNil: [ OTExponentialBucketRange offset: 0 bucketCounts: #() ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> positiveBuckets: anOTExponentialBucketRange [

	positiveBuckets := anOTExponentialBucketRange
		ifNil: [ OTExponentialBucketRange offset: 0 bucketCounts: #() ]
		ifNotNil: [ anOTExponentialBucketRange ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> scale [

	^ scale ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> scale: anInteger [

	scale := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> startTimestamp [

	^ startTimestamp
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> startTimestamp: aDateAndTime [

	startTimestamp := aDateAndTime
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> sum [

	^ sum ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> sum: aNumber [

	sum := aNumber
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> zeroCount [

	^ zeroCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> zeroCount: anInteger [

	zeroCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> zeroThreshold [

	^ zeroThreshold ifNil: [ 0.0 ]
]

{ #category : 'accessing' }
OTExponentialHistogramDataPoint >> zeroThreshold: aNumber [

	zeroThreshold := aNumber ifNil: [ 0.0 ] ifNotNil: [ aNumber ]
]
