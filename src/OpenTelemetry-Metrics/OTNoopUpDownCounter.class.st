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

	
]

{ #category : 'recording' }
OTNoopUpDownCounter >> add: aNumber attributes: aCollection [

	
]

{ #category : 'accessing' }
OTNoopUpDownCounter >> instrumentType [

	^ #upDownCounter
]

{ #category : 'aggregating' }
OTNoopUpDownCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
