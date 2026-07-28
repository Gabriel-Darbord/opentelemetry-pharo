"
A no-op asynchronous Counter instrument.
"
Class {
	#name : 'OTObservableCounter',
	#superclass : 'OTAsynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTObservableCounter class >> noop [

	^ OTNoopObservableCounter instance
]

{ #category : 'accessing' }
OTObservableCounter >> instrumentType [

	^ #observableCounter
]

{ #category : 'aggregating' }
OTObservableCounter >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          | point |
			          point := OTNumberDataPoint
				                   attributes: each key
				                   value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ])
				                   startTimestamp: (anOTMetricAggregationContext
						                    pointStartTimestampForInstrument: self
						                    pointAttributes: each key
						                    measurements: each value)
				                   timestamp: anOTMetricAggregationContext collectedAt.
			          point
				          exemplars:
					          (self exemplarsFromMeasurements: each value pointAttributes: each key using: anOTMetricAggregationContext);
				          yourself ].
	^ (OTSumMetricData instrument: self points: points monotonic: true)
		  temporality: anOTMetricAggregationContext temporality;
		  yourself
]

{ #category : 'aggregating' }
OTObservableCounter >> otlpTemporalityForDeltaPreference [

	^ #delta
]

{ #category : 'collecting' }
OTObservableCounter >> preparedMeasurementsFrom: someMeasurements forReader: anOTMetricReader using: anOTMetricAggregationContext [

	| currentValues |
	anOTMetricAggregationContext temporality = #delta ifFalse: [ ^ someMeasurements ].
	currentValues := Dictionary new.
	(self groupedMeasurementsByAttributes: someMeasurements) associations do: [ :each |
		currentValues at: each key put: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ]) ].
	^ anOTMetricReader withLastAsynchronousValuesFor: self do: [ :previousValues |
			  | deltaMeasurements |
			  deltaMeasurements := OrderedCollection new.
			  currentValues associations do: [ :each |
					  | currentValue deltaValue previousValue |
					  currentValue := each value.
					  previousValue := previousValues at: each key ifAbsent: [ nil ].
					  deltaValue := previousValue ifNil: [ currentValue ] ifNotNil: [
							                currentValue >= previousValue
								                ifTrue: [ currentValue - previousValue ]
								                ifFalse: [ currentValue ] ].
					  deltaMeasurements add: ((OTMetricMeasurement instrument: self value: deltaValue attributes: each key)
							   timestamp: anOTMetricAggregationContext collectedAt;
							   yourself).
					  previousValues at: each key put: currentValue ].
			  anOTMetricReader pruneMissingAsynchronousState: previousValues keepingOnly: currentValues.
			  deltaMeasurements asArray ]
]

{ #category : 'aggregating' }
OTObservableCounter >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ aSymbol = #sum ]
]
