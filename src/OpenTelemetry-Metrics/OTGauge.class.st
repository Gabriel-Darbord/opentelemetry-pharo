"
A no-op synchronous Gauge instrument.
"
Class {
	#name : 'OTGauge',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTGauge >> record: aNumber [

	^ self record: aNumber attributes: #()
]

{ #category : 'recording' }
OTGauge >> record: aNumber attributes: aCollection [

	self
]
