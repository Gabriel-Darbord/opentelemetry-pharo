"
I am the abstract storage policy for metric exemplars.
Concrete subclasses decide which eligible measurements are retained and later emitted.
"
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
