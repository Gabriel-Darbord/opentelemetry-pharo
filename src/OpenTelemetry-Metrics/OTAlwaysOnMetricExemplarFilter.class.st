"
I mark every measurement as exemplar-eligible.
I am the simplest exemplar filter policy.
"
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
