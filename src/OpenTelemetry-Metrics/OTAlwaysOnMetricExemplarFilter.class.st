Class {
	#name : 'OTAlwaysOnMetricExemplarFilter',
	#superclass : 'OTMetricExemplarFilter',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'testing' }
OTAlwaysOnMetricExemplarFilter >> isMeasurementEligibleWithSpanContext: anOTSpanContextOrNil [

	^ true
]
