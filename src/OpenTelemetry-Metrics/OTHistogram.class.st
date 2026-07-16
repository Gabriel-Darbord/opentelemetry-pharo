"
A no-op synchronous Histogram instrument.
"
Class {
	#name : 'OTHistogram',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTHistogram >> record: aNumber [

	^ self record: aNumber attributes: #()
]

{ #category : 'recording' }
OTHistogram >> record: aNumber attributes: aCollection [

	self
]
