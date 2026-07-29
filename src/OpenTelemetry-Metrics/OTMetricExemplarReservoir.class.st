"
I am the abstract storage policy for metric exemplars.
Concrete subclasses decide which eligible measurements are retained and later emitted.
"
Class {
	#name : 'OTMetricExemplarReservoir',
	#superclass : 'Object',
	#instVars : [
		'stateLock'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTMetricExemplarReservoir >> collectForPointAttributes: aCollection [

	^ self stateLock critical: [ self collectForPointAttributesUnlocked: aCollection ]
]

{ #category : 'collecting' }
OTMetricExemplarReservoir >> collectForPointAttributesUnlocked: aCollection [

	self subclassResponsibility
]

{ #category : 'initialization' }
OTMetricExemplarReservoir >> initialize [

	super initialize.
	stateLock := Semaphore forMutualExclusion
]

{ #category : 'offering' }
OTMetricExemplarReservoir >> offerMeasurement: anOTMetricMeasurement [

	^ self stateLock critical: [ self offerMeasurementUnlocked: anOTMetricMeasurement ]
]

{ #category : 'offering' }
OTMetricExemplarReservoir >> offerMeasurementUnlocked: anOTMetricMeasurement [

	self subclassResponsibility
]

{ #category : 'private' }
OTMetricExemplarReservoir >> stateLock [

	^ stateLock ifNil: [ stateLock := Semaphore forMutualExclusion ]
]
