"
A no-op counter that accepts adds without emitting measurements.
"
Class {
	#name : 'OTNoopCounter',
	#superclass : 'OTNoopSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTNoopCounter >> add: aNumber [

	^ self
]

{ #category : 'recording' }
OTNoopCounter >> add: aNumber attributes: aCollection [

	^ self
]

{ #category : 'accessing' }
OTNoopCounter >> instrumentType [

	^ #counter
]

{ #category : 'aggregating' }
OTNoopCounter >> otlpTemporalityForDeltaPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTNoopCounter >> otlpTemporalityForLowMemoryPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTNoopCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
