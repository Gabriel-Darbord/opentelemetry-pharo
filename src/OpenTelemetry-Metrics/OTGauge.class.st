"
A no-op synchronous Gauge instrument.
"
Class {
	#name : 'OTGauge',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTGauge >> record: aNumber [

	^ self record: aNumber attributes: #()
]

{ #category : 'recording' }
OTGauge >> record: aNumber attributes: aCollection [

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
OTGauge >> metricDataFromMeasurements: someMeasurements [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			OTNumberDataPoint
				attributes: each key
				value: each value last value ].
	^ OTGaugeMetricData instrument: self points: points
]
