"
A synchronous Gauge instrument.

I record point-in-time values that are exported using last-value aggregation.
"
Class {
	#name : 'OTGauge',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTGauge class >> noop [

	^ OTNoopGauge instance
]

{ #category : 'accessing' }
OTGauge >> instrumentType [

	^ #gauge
]

{ #category : 'aggregating' }
OTGauge >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          | lastMeasurement point |
			          lastMeasurement := each value last.
			          point := OTNumberDataPoint
				                   attributes: each key
				                   value: lastMeasurement value
				                   startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ each value first timestamp ])
				                   timestamp: anOTMetricAggregationContext collectedAt.
			          point
				          exemplars:
					          (self exemplarsFromMeasurements: each value pointAttributes: each key using: anOTMetricAggregationContext);
				          yourself ].
	^ OTGaugeMetricData instrument: self points: points
]

{ #category : 'recording' }
OTGauge >> record: aNumber [

	^ self record: aNumber attributes: #(  )
]

{ #category : 'recording' }
OTGauge >> record: aNumber attributes: aCollection [

	^ self recordMeasurementValue: aNumber attributes: aCollection
]

{ #category : 'aggregating' }
OTGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #lastValue ]
]
