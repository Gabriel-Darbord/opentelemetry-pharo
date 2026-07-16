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
OTObservableGauge >> metricDataFromMeasurements: someMeasurements collectedAt: aDateAndTime [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			| lastMeasurement |
			lastMeasurement := each value last.
			OTNumberDataPoint
				attributes: each key
				value: lastMeasurement value
				startTimestamp: (each value first timestamp)
				timestamp: lastMeasurement timestamp ].
	^ OTGaugeMetricData instrument: self points: points
]
