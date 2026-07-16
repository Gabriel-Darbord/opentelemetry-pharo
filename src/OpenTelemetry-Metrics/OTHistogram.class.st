"
A no-op synchronous Histogram instrument.
"
Class {
	#name : 'OTHistogram',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'recording' }
OTHistogram >> record: aNumber [

	^ self record: aNumber attributes: #()
]

{ #category : 'recording' }
OTHistogram >> record: aNumber attributes: aCollection [

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
OTHistogram >> defaultExplicitBucketBoundaries [

	^ #( 0 5 10 25 50 75 100 250 500 750 1000 2500 5000 7500 10000 )
]

{ #category : 'aggregating' }
OTHistogram >> explicitBucketBoundaries [

	| boundaries |
	boundaries := self advice
		at: 'ExplicitBucketBoundaries'
		ifAbsent: [ self defaultExplicitBucketBoundaries ].
	^ boundaries asArray collect: [ :each | each asFloat ]
]

{ #category : 'aggregating' }
OTHistogram >> bucketCountsForMeasurements: someMeasurements boundaries: someBoundaries [

	| counts |
	counts := Array new: someBoundaries size + 1 withAll: 0.
	someMeasurements do: [ :each |
		| index value |
		value := each value.
		index := someBoundaries
			detectIndex: [ :boundary | value <= boundary ]
			ifNone: [ someBoundaries size + 1 ].
		counts at: index put: (counts at: index) + 1 ].
	^ counts
]

{ #category : 'aggregating' }
OTHistogram >> metricDataFromMeasurements: someMeasurements collectedAt: aDateAndTime [

	| boundaries points |
	boundaries := self explicitBucketBoundaries.
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			| values |
			values := each value collect: [ :measurement | measurement value ].
			OTHistogramDataPoint
				attributes: each key
				count: values size
				sum: (values inject: 0 into: [ :sum :value | sum + value ])
				min: values min
				max: values max
				explicitBounds: boundaries
				bucketCounts: (self bucketCountsForMeasurements: each value boundaries: boundaries)
				startTimestamp: (each value first timestamp)
				timestamp: aDateAndTime ].
	^ OTHistogramMetricData instrument: self points: points
]
