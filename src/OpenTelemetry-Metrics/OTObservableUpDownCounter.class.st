"
A no-op asynchronous UpDownCounter instrument.
"
Class {
	#name : 'OTObservableUpDownCounter',
	#superclass : 'OTAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'aggregating' }
OTObservableUpDownCounter >> metricDataFromMeasurements: someMeasurements [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			OTNumberDataPoint
				attributes: each key
				value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ]) ].
	^ OTSumMetricData
		instrument: self
		points: points
		monotonic: false
]
