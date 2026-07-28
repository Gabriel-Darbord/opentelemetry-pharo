"
A no-op synchronous Counter instrument.
"
Class {
	#name : 'OTCounter',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTCounter class >> noop [

	^ OTNoopCounter instance
]

{ #category : 'recording' }
OTCounter >> add: aNumber [

	^ self add: aNumber attributes: #(  )
]

{ #category : 'recording' }
OTCounter >> add: aNumber attributes: aCollection [

	| value |
	meter ifNil: [ ^ self ].
	value := self recordableMeasurementValueFrom: aNumber.
	value ifNil: [ ^ self ].
	meter provider ifNotNil: [ meter provider recordMeasurementFor: self value: value attributes: aCollection ].
	self
]

{ #category : 'accessing' }
OTCounter >> instrumentType [

	^ #counter
]

{ #category : 'aggregating' }
OTCounter >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          | point |
			          point := OTNumberDataPoint
				                   attributes: each key
				                   value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ])
				                   startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ each value first timestamp ])
				                   timestamp: anOTMetricAggregationContext collectedAt.
			          point
				          exemplars:
					          (self exemplarsFromMeasurements: each value pointAttributes: each key using: anOTMetricAggregationContext);
				          yourself ].
	^ (OTSumMetricData instrument: self points: points monotonic: true)
		  temporality: anOTMetricAggregationContext temporality;
		  yourself
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

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
