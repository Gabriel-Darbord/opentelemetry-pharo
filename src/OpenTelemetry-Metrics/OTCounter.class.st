"
A no-op synchronous Counter instrument.
"
Class {
	#name : 'OTCounter',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTCounter >> add: aNumber [

	^ self add: aNumber attributes: #()
]

{ #category : 'recording' }
OTCounter >> add: aNumber attributes: aCollection [

	self
]
