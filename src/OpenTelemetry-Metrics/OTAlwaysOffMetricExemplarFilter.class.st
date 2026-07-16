Class {
	#name : 'OTAlwaysOffMetricExemplarFilter',
	#superclass : 'OTMetricExemplarFilter',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'testing' }
OTAlwaysOffMetricExemplarFilter >> capturesMeasurements [

	^ false
]

{ #category : 'testing' }
OTAlwaysOffMetricExemplarFilter >> isMeasurementEligibleWithSpanContext: anOTSpanContextOrNil [

	^ false
]
