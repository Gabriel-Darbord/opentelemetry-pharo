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
OTSimpleFixedSizeMetricExemplarReservoir >> collectForPointAttributesUnlocked: aCollection [

	| exemplars |
	exemplars := OrderedCollection new: self sizeUnlocked.
	self measurementsUnlocked do: [ :each |
		each ifNotNil: [ exemplars add: (OTMetricExemplar measurement: each normalizedPointAttributes: aCollection) ] ].
	self resetUnlocked.
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

	^ self stateLock critical: [ self measurementsUnlocked copy ]
]

{ #category : 'private' }
OTSimpleFixedSizeMetricExemplarReservoir >> measurementsUnlocked [

	^ measurements ifNil: [ measurements := Array new: self sizeUnlocked withAll: nil ]
]

{ #category : 'offering' }
OTSimpleFixedSizeMetricExemplarReservoir >> offerMeasurementUnlocked: anOTMetricMeasurement [

	| bucket |
	(anOTMetricMeasurement exemplarEligible not or: [ self sizeUnlocked <= 0 ]) ifTrue: [ ^ self ].
	measurementsSeen := measurementsSeen + 1.
	measurementsSeen <= self sizeUnlocked
		ifTrue: [ measurements at: measurementsSeen put: anOTMetricMeasurement ]
		ifFalse: [
				bucket := SharedRandom globalGenerator nextInteger: measurementsSeen.
				bucket <= self sizeUnlocked ifTrue: [ measurements at: bucket put: anOTMetricMeasurement ] ].
	self
]

{ #category : 'private' }
OTSimpleFixedSizeMetricExemplarReservoir >> reset [

	^ self stateLock critical: [ self resetUnlocked ]
]

{ #category : 'private' }
OTSimpleFixedSizeMetricExemplarReservoir >> resetUnlocked [

	measurementsSeen := 0.
	measurements := Array new: self sizeUnlocked withAll: nil
]

{ #category : 'accessing' }
OTSimpleFixedSizeMetricExemplarReservoir >> size [

	^ self stateLock critical: [ self sizeUnlocked ]
]

{ #category : 'accessing' }
OTSimpleFixedSizeMetricExemplarReservoir >> size: anInteger [

	^ self stateLock critical: [
			  size := (anInteger isInteger and: [ anInteger > 0 ])
				          ifTrue: [ anInteger ]
				          ifFalse: [ 1 ].
			  self resetUnlocked.
			  size ]
]

{ #category : 'private' }
OTSimpleFixedSizeMetricExemplarReservoir >> sizeUnlocked [

	^ size ifNil: [ 1 ]
]
