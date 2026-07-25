"
A no-op asynchronous Gauge instrument.
"
Class {
	#name : 'OTObservableGauge',
	#superclass : 'OTAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTObservableGauge >> instrumentType [

	^ #observableGauge
]

{ #category : 'aggregating' }
OTObservableGauge >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          | lastMeasurement point |
			          lastMeasurement := each value last.
			          point := OTNumberDataPoint
				                   attributes: each key
				                   value: lastMeasurement value
				                   startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ each value first timestamp ])
				                   timestamp: lastMeasurement timestamp.
			          point
				          exemplars:
					          (self exemplarsFromMeasurements: each value pointAttributes: each key using: anOTMetricAggregationContext);
				          yourself ].
	^ OTGaugeMetricData instrument: self points: points
]

{ #category : 'aggregating' }
OTObservableGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #lastValue ]
]
