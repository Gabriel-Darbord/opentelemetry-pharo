"
A no-op observable gauge that discards callbacks and observations.
"
Class {
	#name : 'OTNoopObservableGauge',
	#superclass : 'OTNoopAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopObservableGauge >> instrumentType [

	^ #observableGauge
]

{ #category : 'aggregating' }
OTNoopObservableGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #lastValue ]
]
