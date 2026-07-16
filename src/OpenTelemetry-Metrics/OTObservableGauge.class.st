"
A no-op asynchronous Gauge instrument.
"
Class {
	#name : 'OTObservableGauge',
	#superclass : 'OTAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'aggregating' }
OTObservableGauge >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			| lastMeasurement |
			lastMeasurement := each value last.
			OTNumberDataPoint
				attributes: each key
				value: lastMeasurement value
				startTimestamp: (anOTMetricAggregationContext startTimestamp
					ifNil: [ each value first timestamp ])
				timestamp: lastMeasurement timestamp ].
	^ OTGaugeMetricData instrument: self points: points
]

{ #category : 'accessing' }
OTObservableGauge >> instrumentType [

	^ #observableGauge
]

{ #category : 'aggregating' }
OTObservableGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol)
		or: [ aSymbol = #lastValue ]
]
