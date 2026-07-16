"
A no-op synchronous Counter instrument.
"
Class {
	#name : 'OTCounter',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTCounter >> add: aNumber [

	^ self add: aNumber attributes: #()
]

{ #category : 'recording' }
OTCounter >> add: aNumber attributes: aCollection [

	meter ifNil: [ ^ self ].
	meter provider
		ifNotNil: [
			meter provider
				recordMeasurementFor: self
				value: aNumber
				attributes: aCollection ].
	self
]

{ #category : 'aggregating' }
OTCounter >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			OTNumberDataPoint
				attributes: each key
				value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ])
				startTimestamp: (anOTMetricAggregationContext startTimestamp
					ifNil: [ each value first timestamp ])
				timestamp: anOTMetricAggregationContext collectedAt ].
	^ (OTSumMetricData
		instrument: self
		points: points
		monotonic: true)
		temporality: anOTMetricAggregationContext temporality;
		yourself
]

{ #category : 'accessing' }
OTCounter >> instrumentType [

	^ #counter
]

{ #category : 'aggregating' }
OTCounter >> otlpTemporalityForDeltaPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTCounter >> otlpTemporalityForLowMemoryPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol)
		or: [ aSymbol = #sum ]
]
