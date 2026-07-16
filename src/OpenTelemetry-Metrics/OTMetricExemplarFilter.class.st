Class {
	#name : 'OTMetricExemplarFilter',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricExemplarFilter class >> alwaysOff [

	^ OTAlwaysOffMetricExemplarFilter new
]

{ #category : 'instance creation' }
OTMetricExemplarFilter class >> alwaysOn [

	^ OTAlwaysOnMetricExemplarFilter new
]

{ #category : 'instance creation' }
OTMetricExemplarFilter class >> traceBased [

	^ OTTraceBasedMetricExemplarFilter new
]

{ #category : 'testing' }
OTMetricExemplarFilter >> capturesMeasurements [

	^ true
]

{ #category : 'testing' }
OTMetricExemplarFilter >> isMeasurementEligibleWithSpanContext: anOTSpanContextOrNil [

	self subclassResponsibility
]
