"
Abstract no-op metric instrument foundation.
"
Class {
	#name : 'OTMetricInstrument',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'binding' }
OTMetricInstrument >> bind: aCollection [

	self
]

{ #category : 'testing' }
OTMetricInstrument >> enabled [

	^ false
]
