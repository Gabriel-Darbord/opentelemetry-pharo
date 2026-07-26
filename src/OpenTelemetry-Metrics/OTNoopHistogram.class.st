"
A no-op histogram that accepts records without emitting measurements.
"
Class {
	#name : 'OTNoopHistogram',
	#superclass : 'OTNoopSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopHistogram >> instrumentType [

	^ #histogram
]

{ #category : 'recording' }
OTNoopHistogram >> record: aNumber [

	^ self
]

{ #category : 'recording' }
OTNoopHistogram >> record: aNumber attributes: aCollection [

	^ self
]

{ #category : 'aggregating' }
OTNoopHistogram >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol)
		  or: [ #( sum explicitBucketHistogram base2ExponentialBucketHistogram ) includes: aSymbol ]
]
