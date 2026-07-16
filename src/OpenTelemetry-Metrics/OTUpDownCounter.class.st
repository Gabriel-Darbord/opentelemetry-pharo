"
A no-op synchronous UpDownCounter instrument.
"
Class {
	#name : 'OTUpDownCounter',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTUpDownCounter >> add: aNumber [

	^ self add: aNumber attributes: #()
]

{ #category : 'recording' }
OTUpDownCounter >> add: aNumber attributes: aCollection [

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
OTUpDownCounter >> metricDataFromMeasurements: someMeasurements [

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
