Class {
	#name : 'OTRecordingMetricExemplarReservoir',
	#superclass : 'OTMetricExemplarReservoir',
	#instVars : [
		'pointAttributes',
		'offeredMeasurements',
		'collectArgument'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'accessing' }
OTRecordingMetricExemplarReservoir >> collectArgument [

	^ collectArgument
]

{ #category : 'collecting' }
OTRecordingMetricExemplarReservoir >> collectForPointAttributes: aCollection [

	collectArgument := aCollection.
	^ offeredMeasurements collect: [ :each | OTMetricExemplar measurement: each pointAttributes: aCollection ] as: Array
]

{ #category : 'initialization' }
OTRecordingMetricExemplarReservoir >> initialize [

	super initialize.
	offeredMeasurements := OrderedCollection new
]

{ #category : 'offering' }
OTRecordingMetricExemplarReservoir >> offerMeasurement: anOTMetricMeasurement [

	offeredMeasurements add: anOTMetricMeasurement.
	self
]

{ #category : 'accessing' }
OTRecordingMetricExemplarReservoir >> offeredMeasurements [

	^ offeredMeasurements
]

{ #category : 'accessing' }
OTRecordingMetricExemplarReservoir >> pointAttributes [

	^ pointAttributes
]

{ #category : 'accessing' }
OTRecordingMetricExemplarReservoir >> pointAttributes: aCollection [

	pointAttributes := aCollection
]
