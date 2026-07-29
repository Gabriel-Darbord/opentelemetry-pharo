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

{ #category : 'accessing' }
OTMetricProducer >> instrumentationScope [

	^ OTInstrumentationScope named: self class name
]

{ #category : 'collecting' }
OTMetricProducer >> produce [

	self subclassResponsibility
]

{ #category : 'collecting' }
OTMetricProducer >> produceForReader: anOTMetricReader [

	^ self produce
]

{ #category : 'collecting' }
OTMetricProducer >> produceForReader: anOTMetricReader metricFilter: anOTMetricFilter [

	^ self produceForReader: anOTMetricReader
]

{ #category : 'collecting' }
OTMetricProducer >> produceResult [

	^ OTMetricBatchResult successSnapshot: self produce
]

{ #category : 'collecting' }
OTMetricProducer >> produceResultForReader: anOTMetricReader [

	^ self produceResult
]

{ #category : 'collecting' }
OTMetricProducer >> produceResultForReader: anOTMetricReader metricFilter: anOTMetricFilter [

	^ self produceResultForReader: anOTMetricReader
]

{ #category : 'collecting' }
OTMetricProducer >> produceResultForReader: anOTMetricReader resource: anOTResource metricFilter: anOTMetricFilter [

	^ self produceResultForReader: anOTMetricReader metricFilter: anOTMetricFilter
]
