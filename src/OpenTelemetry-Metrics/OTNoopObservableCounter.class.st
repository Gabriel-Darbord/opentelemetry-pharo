"
A no-op observable counter that discards callbacks and observations.
"
Class {
	#name : 'OTNoopObservableCounter',
	#superclass : 'OTNoopAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopObservableCounter >> instrumentType [

	^ #observableCounter
]

{ #category : 'aggregating' }
OTNoopObservableCounter >> otlpTemporalityForDeltaPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTNoopObservableCounter >> otlpTemporalityForLowMemoryPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTNoopObservableCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
