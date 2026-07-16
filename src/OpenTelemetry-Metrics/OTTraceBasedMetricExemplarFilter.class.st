Class {
	#name : 'OTTraceBasedMetricExemplarFilter',
	#superclass : 'OTMetricExemplarFilter',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'testing' }
OTTraceBasedMetricExemplarFilter >> isMeasurementEligibleWithSpanContext: anOTSpanContextOrNil [

	^ anOTSpanContextOrNil notNil
		and: [ anOTSpanContextOrNil isValid and: [ anOTSpanContextOrNil isSampled ] ]
]
