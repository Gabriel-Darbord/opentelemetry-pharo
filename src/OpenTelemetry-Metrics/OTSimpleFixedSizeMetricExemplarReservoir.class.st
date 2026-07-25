"
I keep a fixed-size sample of exemplar candidates using reservoir sampling.
Collection drains the stored measurements into exemplars and resets the reservoir.
"
Class {
	#name : 'OTSimpleFixedSizeMetricExemplarReservoir',
	#superclass : 'OTMetricExemplarReservoir',
	#instVars : [
		'size',
		'measurements',
		'measurementsSeen'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSimpleFixedSizeMetricExemplarReservoir class >> size: anInteger [

	^ self new
		  size: anInteger;
		  yourself
]

{ #category : 'collecting' }
OTSimpleFixedSizeMetricExemplarReservoir >> collectForPointAttributes: aCollection [

	| exemplars |
	exemplars := self measurements
		             select: [ :each | each notNil ]
		             thenCollect: [ :each | OTMetricExemplar measurement: each pointAttributes: aCollection ].
	self reset.
	^ exemplars asArray
]

{ #category : 'initialization' }
OTSimpleFixedSizeMetricExemplarReservoir >> initialize [

	super initialize.
	size := 1.
	self reset
]

{ #category : 'accessing' }
OTSimpleFixedSizeMetricExemplarReservoir >> measurements [

	^ measurements ifNil: [ measurements := Array new: self size withAll: nil ]
]

{ #category : 'offering' }
OTSimpleFixedSizeMetricExemplarReservoir >> offerMeasurement: anOTMetricMeasurement [

	| bucket |
	(anOTMetricMeasurement exemplarEligible not or: [ self size <= 0 ]) ifTrue: [ ^ self ].
	measurementsSeen := measurementsSeen + 1.
	measurementsSeen <= self size ifTrue: [
			measurements at: measurementsSeen put: anOTMetricMeasurement.
			^ self ].
	bucket := SharedRandom globalGenerator nextInteger: measurementsSeen.
	bucket <= self size ifTrue: [ measurements at: bucket put: anOTMetricMeasurement ].
	^ self
]

{ #category : 'private' }
OTSimpleFixedSizeMetricExemplarReservoir >> reset [

	measurementsSeen := 0.
	measurements := Array new: self size withAll: nil
]

{ #category : 'accessing' }
OTSimpleFixedSizeMetricExemplarReservoir >> size [

	^ size ifNil: [ 1 ]
]

{ #category : 'accessing' }
OTSimpleFixedSizeMetricExemplarReservoir >> size: anInteger [

	size := (anInteger isInteger and: [ anInteger > 0 ])
		        ifTrue: [ anInteger ]
		        ifFalse: [ 1 ].
	self reset
]
