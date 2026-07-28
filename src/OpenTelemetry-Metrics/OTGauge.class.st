"
A no-op synchronous Gauge instrument.
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
				                   timestamp: lastMeasurement timestamp.
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

	| value |
	meter ifNil: [ ^ self ].
	value := self recordableMeasurementValueFrom: aNumber.
	value ifNil: [ ^ self ].
	meter provider ifNotNil: [ meter provider recordMeasurementFor: self value: value attributes: aCollection ].
	self
]

{ #category : 'aggregating' }
OTGauge >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #lastValue ]
]
