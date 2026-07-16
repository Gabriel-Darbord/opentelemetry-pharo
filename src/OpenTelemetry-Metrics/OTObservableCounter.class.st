"
A no-op asynchronous Counter instrument.
"
Class {
	#name : 'OTObservableCounter',
	#superclass : 'OTAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'aggregating' }
OTObservableCounter >> metricDataFromMeasurements: someMeasurements [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			OTNumberDataPoint
				attributes: each key
				value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ]) ].
	^ OTSumMetricData
		instrument: self
		points: points
		monotonic: true
]
