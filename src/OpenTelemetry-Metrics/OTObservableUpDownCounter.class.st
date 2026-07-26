"
A no-op asynchronous UpDownCounter instrument.
"
Class {
	#name : 'OTObservableUpDownCounter',
	#superclass : 'OTAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTObservableUpDownCounter class >> noop [

	^ OTNoopObservableUpDownCounter instance
]

{ #category : 'accessing' }
OTObservableUpDownCounter >> instrumentType [

	^ #observableUpDownCounter
]

{ #category : 'aggregating' }
OTObservableUpDownCounter >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          | point |
			          point := OTNumberDataPoint
				                   attributes: each key
				                   value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ])
				                   startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ each value first timestamp ])
				                   timestamp: anOTMetricAggregationContext collectedAt.
			          point
				          exemplars:
					          (self exemplarsFromMeasurements: each value pointAttributes: each key using: anOTMetricAggregationContext);
				          yourself ].
	^ (OTSumMetricData instrument: self points: points monotonic: false)
		  temporality: anOTMetricAggregationContext temporality;
		  yourself
]

{ #category : 'collecting' }
OTObservableUpDownCounter >> preparedMeasurementsFrom: someMeasurements forReader: anOTMetricReader using: anOTMetricAggregationContext [

	| currentValues deltaMeasurements previousValues |
	anOTMetricAggregationContext temporality = #delta ifFalse: [ ^ someMeasurements ].
	currentValues := Dictionary new.
	(self groupedMeasurementsByAttributes: someMeasurements) associations do: [ :each |
		currentValues at: each key put: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ]) ].
	previousValues := anOTMetricReader lastAsynchronousValuesFor: self.
	deltaMeasurements := OrderedCollection new.
	currentValues associations do: [ :each |
			| currentValue previousValue |
			currentValue := each value.
			previousValue := previousValues at: each key ifAbsent: [ nil ].
			deltaMeasurements add: ((OTMetricMeasurement
					  instrument: self
					  value: (previousValue ifNil: [ currentValue ] ifNotNil: [ currentValue - previousValue ])
					  attributes: each key)
					 timestamp: anOTMetricAggregationContext collectedAt;
					 yourself).
			previousValues at: each key put: currentValue ].
	^ deltaMeasurements asArray
]

{ #category : 'aggregating' }
OTObservableUpDownCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
