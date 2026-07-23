Class {
	#name : 'OTNoopMetricExemplarReservoir',
	#superclass : 'OTMetricExemplarReservoir',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTNoopMetricExemplarReservoir >> collectForPointAttributes: aCollection [

	^ #(  )
]

{ #category : 'offering' }
OTNoopMetricExemplarReservoir >> offerMeasurement: anOTMetricMeasurement [

	^ self
]
