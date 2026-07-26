"
A no-op synchronous UpDownCounter instrument.
"
Class {
	#name : 'OTUpDownCounter',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTUpDownCounter class >> noop [

	^ OTNoopUpDownCounter instance
]

{ #category : 'recording' }
OTUpDownCounter >> add: aNumber [

	^ self add: aNumber attributes: #(  )
]

{ #category : 'recording' }
OTUpDownCounter >> add: aNumber attributes: aCollection [

	meter ifNil: [ ^ self ].
	meter provider ifNotNil: [ meter provider recordMeasurementFor: self value: aNumber attributes: aCollection ].
	self
]

{ #category : 'accessing' }
OTUpDownCounter >> instrumentType [

	^ #upDownCounter
]

{ #category : 'aggregating' }
OTUpDownCounter >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

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
	^ (OTSumMetricData instrument: self points: points monotonic: false)
		  temporality: anOTMetricAggregationContext temporality;
		  yourself
]

{ #category : 'aggregating' }
OTUpDownCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
