"
Shared asynchronous no-op metric instrument behavior.

Callbacks are always discarded so the no-op API never retains user blocks.
"
Class {
	#name : 'OTNoopAsynchronousMetricInstrument',
	#superclass : 'OTNoopMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopAsynchronousMetricInstrument >> callbacks [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopAsynchronousMetricInstrument >> callbacks: someCallbacks [

	^ self callbacks
]

{ #category : 'recording' }
OTNoopAsynchronousMetricInstrument >> observe: aNumber [

	
]

{ #category : 'recording' }
OTNoopAsynchronousMetricInstrument >> observe: aNumber attributes: aCollection [

	
]
