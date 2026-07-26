"
A no-op up-down counter that accepts adds without emitting measurements.
"
Class {
	#name : 'OTNoopUpDownCounter',
	#superclass : 'OTNoopSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTNoopUpDownCounter >> add: aNumber [

	^ self
]

{ #category : 'recording' }
OTNoopUpDownCounter >> add: aNumber attributes: aCollection [

	^ self
]

{ #category : 'accessing' }
OTNoopUpDownCounter >> instrumentType [

	^ #upDownCounter
]

{ #category : 'aggregating' }
OTNoopUpDownCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
