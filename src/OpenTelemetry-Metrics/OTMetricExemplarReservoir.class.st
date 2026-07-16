Class {
	#name : 'OTMetricExemplarReservoir',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTMetricExemplarReservoir >> collectForPointAttributes: aCollection [

	self subclassResponsibility
]

{ #category : 'offering' }
OTMetricExemplarReservoir >> offerMeasurement: anOTMetricMeasurement [

	self subclassResponsibility
]
