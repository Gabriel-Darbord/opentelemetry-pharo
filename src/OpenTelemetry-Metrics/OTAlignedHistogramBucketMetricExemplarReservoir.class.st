"
I keep at most one exemplar candidate per explicit histogram bucket.
I align exemplar storage with bucket boundaries so collection can emit bucket-local exemplars.
"
Class {
	#name : 'OTAlignedHistogramBucketMetricExemplarReservoir',
	#superclass : 'OTMetricExemplarReservoir',
	#instVars : [
		'boundaries',
		'measurementsByBucket'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTAlignedHistogramBucketMetricExemplarReservoir class >> boundaries: aCollection [

	^ self new
		  boundaries: aCollection;
		  yourself
]

{ #category : 'accessing' }
OTAlignedHistogramBucketMetricExemplarReservoir >> boundaries [

	^ boundaries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTAlignedHistogramBucketMetricExemplarReservoir >> boundaries: aCollection [

	boundaries := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ].
	measurementsByBucket := Array new: self boundaries size + 1 withAll: nil
]

{ #category : 'private' }
OTAlignedHistogramBucketMetricExemplarReservoir >> bucketIndexForValue: aNumber [

	^ self boundaries detectIndex: [ :boundary | aNumber <= boundary ] ifNone: [ self boundaries size + 1 ]
]

{ #category : 'collecting' }
OTAlignedHistogramBucketMetricExemplarReservoir >> collectForPointAttributes: aCollection [

	| exemplars |
	exemplars := self measurementsByBucket
		             select: [ :each | each notNil ]
		             thenCollect: [ :each | OTMetricExemplar measurement: each pointAttributes: aCollection ].
	measurementsByBucket := Array new: self boundaries size + 1 withAll: nil.
	^ exemplars asArray
]

{ #category : 'initialization' }
OTAlignedHistogramBucketMetricExemplarReservoir >> initialize [

	super initialize.
	self boundaries: #(  )
]

{ #category : 'accessing' }
OTAlignedHistogramBucketMetricExemplarReservoir >> measurementsByBucket [

	^ measurementsByBucket ifNil: [ measurementsByBucket := Array new: self boundaries size + 1 withAll: nil ]
]

{ #category : 'offering' }
OTAlignedHistogramBucketMetricExemplarReservoir >> offerMeasurement: anOTMetricMeasurement [

	| bucketIndex |
	anOTMetricMeasurement exemplarEligible ifTrue: [
			bucketIndex := self bucketIndexForValue: anOTMetricMeasurement value.
			measurementsByBucket at: bucketIndex put: anOTMetricMeasurement ].
	self
]
