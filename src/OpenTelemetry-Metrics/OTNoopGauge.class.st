"
A no-op gauge that accepts records without emitting measurements.
"
Class {
	#name : 'OTNoopGauge',
	#superclass : 'OTNoopSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopGauge >> instrumentType [

	^ #gauge
]

{ #category : 'recording' }
OTNoopGauge >> record: aNumber [

	
]

{ #category : 'recording' }
OTNoopGauge >> record: aNumber attributes: aCollection [

	
]

{ #category : 'aggregating' }
OTNoopGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #lastValue ]
]
