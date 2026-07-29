"
A no-op observable up-down counter that discards callbacks and observations.
"
Class {
	#name : 'OTNoopObservableUpDownCounter',
	#superclass : 'OTNoopAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopObservableUpDownCounter >> instrumentType [

	^ #observableUpDownCounter
]

{ #category : 'aggregating' }
OTNoopObservableUpDownCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
