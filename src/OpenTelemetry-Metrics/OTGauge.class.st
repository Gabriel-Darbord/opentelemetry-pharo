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
OTGauge >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

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
OTGauge >> instrumentType [

	^ #gauge
]

{ #category : 'aggregating' }
OTGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol)
		or: [ aSymbol = #lastValue ]
]
