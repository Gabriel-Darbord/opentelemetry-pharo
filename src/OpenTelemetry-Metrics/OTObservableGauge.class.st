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
OTObservableGauge >> metricDataFromMeasurements: someMeasurements [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			OTNumberDataPoint
				attributes: each key
				value: each value last value ].
	^ OTGaugeMetricData instrument: self points: points
]
