"
I define the integration boundary for third-party aggregated metric sources.

Concrete producers answer an OTMetricSnapshot from #produce and can be
registered on an OTMetricReader.
"
Class {
	#name : 'OTMetricProducer',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTMetricProducer >> produce [

	self subclassResponsibility
]

{ #category : 'collecting' }
OTMetricProducer >> produceForReader: anOTMetricReader [

	^ self produce
]
