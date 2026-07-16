"
A no-op synchronous UpDownCounter instrument.
"
Class {
	#name : 'OTUpDownCounter',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTUpDownCounter >> add: aNumber [

	^ self add: aNumber attributes: #()
]

{ #category : 'recording' }
OTUpDownCounter >> add: aNumber attributes: aCollection [

	self
]
