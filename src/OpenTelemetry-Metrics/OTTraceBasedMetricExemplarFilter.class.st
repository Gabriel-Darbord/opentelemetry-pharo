"
I only allow exemplar capture for measurements observed under a sampled valid span context.
I implement the OpenTelemetry trace-based exemplar policy.
"
Class {
	#name : 'OTTraceBasedMetricExemplarFilter',
	#superclass : 'OTMetricExemplarFilter',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'testing' }
OTTraceBasedMetricExemplarFilter >> isMeasurementEligibleWithSpanContext: anOTSpanContextOrNil [

	^ anOTSpanContextOrNil notNil and: [ anOTSpanContextOrNil isValid and: [ anOTSpanContextOrNil isSampled ] ]
]
