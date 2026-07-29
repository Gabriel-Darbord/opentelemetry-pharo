"
I am an exemplar reservoir that never retains measurements.
I satisfy the exemplar reservoir protocol without producing exemplars.
"
Class {
	#name : 'OTNoopMetricExemplarReservoir',
	#superclass : 'OTMetricExemplarReservoir',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTNoopMetricExemplarReservoir >> collectForPointAttributesUnlocked: aCollection [

	^ #(  )
]

{ #category : 'offering' }
OTNoopMetricExemplarReservoir >> offerMeasurementUnlocked: anOTMetricMeasurement [

	self
]
