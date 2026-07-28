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

	^ self stateLock critical: [ self boundariesUnlocked copy ]
]

{ #category : 'accessing' }
OTAlignedHistogramBucketMetricExemplarReservoir >> boundaries: aCollection [

	^ self stateLock critical: [
			  boundaries := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ].
			  measurementsByBucket := Array new: self boundariesUnlocked size + 1 withAll: nil.
			  boundaries copy ]
]

{ #category : 'private' }
OTAlignedHistogramBucketMetricExemplarReservoir >> boundariesUnlocked [

	^ boundaries ifNil: [ #(  ) ]
]

{ #category : 'private' }
OTAlignedHistogramBucketMetricExemplarReservoir >> bucketIndexForValue: aNumber [

	^ self boundariesUnlocked detectIndex: [ :boundary | aNumber <= boundary ] ifNone: [ self boundariesUnlocked size + 1 ]
]

{ #category : 'collecting' }
OTAlignedHistogramBucketMetricExemplarReservoir >> collectForPointAttributesUnlocked: aCollection [

	| exemplars |
	exemplars := self measurementsByBucketUnlocked
		             select: [ :each | each notNil ]
		             thenCollect: [ :each | OTMetricExemplar measurement: each pointAttributes: aCollection ].
	measurementsByBucket := Array new: self boundariesUnlocked size + 1 withAll: nil.
	^ exemplars asArray
]

{ #category : 'initialization' }
OTAlignedHistogramBucketMetricExemplarReservoir >> initialize [

	super initialize.
	self boundaries: #(  )
]

{ #category : 'accessing' }
OTAlignedHistogramBucketMetricExemplarReservoir >> measurementsByBucket [

	^ self stateLock critical: [ self measurementsByBucketUnlocked copy ]
]

{ #category : 'private' }
OTAlignedHistogramBucketMetricExemplarReservoir >> measurementsByBucketUnlocked [

	^ measurementsByBucket ifNil: [ measurementsByBucket := Array new: self boundariesUnlocked size + 1 withAll: nil ]
]

{ #category : 'offering' }
OTAlignedHistogramBucketMetricExemplarReservoir >> offerMeasurementUnlocked: anOTMetricMeasurement [

	| bucketIndex |
	anOTMetricMeasurement exemplarEligible ifTrue: [
			bucketIndex := self bucketIndexForValue: anOTMetricMeasurement value.
			measurementsByBucket at: bucketIndex put: anOTMetricMeasurement ].
	self
]
