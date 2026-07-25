"
I disable exemplar capture for metric streams.
No measurement is eligible when I am active.
"
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
