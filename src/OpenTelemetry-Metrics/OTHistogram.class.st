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
OTHistogram >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	anOTMetricAggregationContext aggregation = #base2ExponentialBucketHistogram ifTrue: [
		^ self
			exponentialHistogramMetricDataFromMeasurements: someMeasurements
			using: anOTMetricAggregationContext ].
	^ self
		explicitHistogramMetricDataFromMeasurements: someMeasurements
		using: anOTMetricAggregationContext
]

{ #category : 'aggregating' }
OTHistogram >> explicitHistogramMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

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
				startTimestamp: (anOTMetricAggregationContext startTimestamp
					ifNil: [ each value first timestamp ])
				timestamp: anOTMetricAggregationContext collectedAt ].
	^ (OTHistogramMetricData instrument: self points: points)
		temporality: anOTMetricAggregationContext temporality;
		yourself
]

{ #category : 'aggregating' }
OTHistogram >> exponentialBucketIndexFor: aPositiveNumber scale: anInteger [

	| scaleFactor |
	scaleFactor := (2.0 raisedTo: anInteger) / 2.0 ln.
	^ ((aPositiveNumber asFloat ln * scaleFactor) ceiling - 1) asInteger
]

{ #category : 'aggregating' }
OTHistogram >> exponentialBucketRangeFromCountsByIndex: countsByIndex [

	| bucketCounts firstIndex lastIndex |
	countsByIndex isEmpty ifTrue: [ ^ OTExponentialBucketRange offset: 0 bucketCounts: #() ].
	firstIndex := countsByIndex keys min.
	lastIndex := countsByIndex keys max.
	bucketCounts := (firstIndex to: lastIndex)
		collect: [ :each | countsByIndex at: each ifAbsent: [ 0 ] ].
	^ OTExponentialBucketRange offset: firstIndex bucketCounts: bucketCounts
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramDataPointForMeasurements: someMeasurements attributes: someAttributes using: anOTMetricAggregationContext [

	| negativeCounts point positiveCounts scale values zeroCount |
	values := someMeasurements collect: [ :each | each value asFloat ].
	scale := self exponentialHistogramScaleForMeasurements: someMeasurements.
	positiveCounts := Dictionary new.
	negativeCounts := Dictionary new.
	zeroCount := 0.
	values do: [ :each |
		each = 0.0
			ifTrue: [ zeroCount := zeroCount + 1 ]
			ifFalse: [
				| absoluteValue bucketIndex bucketCounts |
				absoluteValue := each abs.
				bucketIndex := self
					exponentialBucketIndexFor: absoluteValue
					scale: scale.
				bucketCounts := each > 0
					ifTrue: [ positiveCounts ]
					ifFalse: [ negativeCounts ].
				bucketCounts
					at: bucketIndex
					put: ((bucketCounts at: bucketIndex ifAbsent: [ 0 ]) + 1) ] ].
	point := OTExponentialHistogramDataPoint new.
	point
		attributes: someAttributes;
		count: values size;
		sum: (values inject: 0.0 into: [ :sum :value | sum + value ]);
		scale: scale;
		zeroCount: zeroCount;
		positiveBuckets: (self exponentialBucketRangeFromCountsByIndex: positiveCounts);
		negativeBuckets: (self exponentialBucketRangeFromCountsByIndex: negativeCounts);
		min: values min;
		max: values max;
		startTimestamp: (anOTMetricAggregationContext startTimestamp
			ifNil: [ someMeasurements first timestamp ]);
		timestamp: anOTMetricAggregationContext collectedAt;
		zeroThreshold: 0.0.
	^ point
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations
		collect: [ :each |
			self
				exponentialHistogramDataPointForMeasurements: each value
				attributes: each key
				using: anOTMetricAggregationContext ].
	^ (OTExponentialHistogramMetricData instrument: self points: points)
		temporality: anOTMetricAggregationContext temporality;
		yourself
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMaxScale [

	^ 20
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMaxSize [

	^ 160
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMinScale [

	^ -10
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramRangeWidthAtScale: anInteger forAbsoluteValues: someValues [

	| indexes |
	someValues ifEmpty: [ ^ 0 ].
	indexes := someValues
		collect: [ :each | self exponentialBucketIndexFor: each scale: anInteger ].
	^ indexes max - indexes min + 1
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramScaleForMeasurements: someMeasurements [

	| negativeValues positiveValues |
	positiveValues := someMeasurements
		select: [ :each | each value > 0 ]
		thenCollect: [ :each | each value asFloat ].
	negativeValues := someMeasurements
		select: [ :each | each value < 0 ]
		thenCollect: [ :each | each value abs asFloat ].
	self exponentialHistogramMaxScale
		to: self exponentialHistogramMinScale
		by: -1
		do: [ :scale |
			((self
				exponentialHistogramRangeWidthAtScale: scale
				forAbsoluteValues: positiveValues) <= self exponentialHistogramMaxSize
				and: [
					(self
						exponentialHistogramRangeWidthAtScale: scale
						forAbsoluteValues: negativeValues) <= self exponentialHistogramMaxSize ]) ifTrue: [
				^ scale ] ].
	^ self exponentialHistogramMinScale
]

{ #category : 'aggregating' }
OTHistogram >> otlpAggregationForPreference: aSymbol [

	aSymbol = #base2ExponentialBucketHistogram ifTrue: [
		^ #base2ExponentialBucketHistogram ].
	^ #explicitBucketHistogram
]

{ #category : 'aggregating' }
OTHistogram >> otlpTemporalityForDeltaPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTHistogram >> otlpTemporalityForLowMemoryPreference [

	^ #delta
]
