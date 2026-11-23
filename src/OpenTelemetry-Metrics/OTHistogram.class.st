"
A synchronous Histogram instrument.

I record sampled values that are aggregated into explicit-bucket or exponential
histogram streams.
"
Class {
	#name : 'OTHistogram',
	#superclass : 'OTSynchronousMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTHistogram class >> noop [

	^ OTNoopHistogram instance
]

{ #category : 'aggregating' }
OTHistogram >> aggregationForPreference: aSymbol [

	aSymbol = #base2ExponentialBucketHistogram ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	^ #explicitBucketHistogram
]

{ #category : 'aggregating' }
OTHistogram >> bucketCountsForMeasurements: someMeasurements boundaries: someBoundaries [

	| counts |
	counts := Array new: someBoundaries size + 1 withAll: 0.
	someMeasurements do: [ :each |
			| index value |
			value := each value.
			index := someBoundaries detectIndex: [ :boundary | value <= boundary ] ifNone: [ someBoundaries size + 1 ].
			counts at: index put: (counts at: index) + 1 ].
	^ counts
]

{ #category : 'aggregating' }
OTHistogram >> cumulativeExplicitHistogramPoint: anEarlierPoint followedBy: aLaterPoint [
	"Their counts, sums and buckets added, over the time since the stream started. Points bucketed differently, after the stream's boundaries changed, cannot be added: the later one starts again."

	anEarlierPoint explicitBounds = aLaterPoint explicitBounds ifFalse: [ ^ aLaterPoint ].
	^ aLaterPoint copy
		  startTimestamp: anEarlierPoint startTimestamp;
		  count: anEarlierPoint count + aLaterPoint count;
		  sum: anEarlierPoint sum + aLaterPoint sum;
		  min: (self cumulativeExtremeOf: anEarlierPoint min and: aLaterPoint min by: #min:);
		  max: (self cumulativeExtremeOf: anEarlierPoint max and: aLaterPoint max by: #max:);
		  bucketCounts: (anEarlierPoint bucketCounts with: aLaterPoint bucketCounts collect: [ :earlier :later | earlier + later ]);
		  yourself
]

{ #category : 'aggregating' }
OTHistogram >> cumulativeExponentialHistogramPoint: anEarlierPoint followedBy: aLaterPoint using: anOTMetricAggregationContext [
	"Their counts added, over the time since the stream started, at the finest scale both fit: the coarser of their scales, lowered while either range of buckets is wider than the aggregation allows."

	| maxSize negativeCounts positiveCounts scale |
	maxSize := self exponentialHistogramMaxSizeForAggregationContext: anOTMetricAggregationContext.
	scale := (anEarlierPoint scale min: aLaterPoint scale) + 1.
	[
		scale := scale - 1.
		positiveCounts := self exponentialCountsByIndexAtScale: scale from: {
				                  (anEarlierPoint positiveBuckets -> anEarlierPoint scale).
				                  (aLaterPoint positiveBuckets -> aLaterPoint scale) }.
		negativeCounts := self exponentialCountsByIndexAtScale: scale from: {
				                  (anEarlierPoint negativeBuckets -> anEarlierPoint scale).
				                  (aLaterPoint negativeBuckets -> aLaterPoint scale) }.
		scale > self exponentialHistogramMinScale and: [
				(self exponentialRangeWidthOfCountsByIndex: positiveCounts) > maxSize or: [
					(self exponentialRangeWidthOfCountsByIndex: negativeCounts) > maxSize ] ] ] whileTrue.
	^ aLaterPoint copy
		  startTimestamp: anEarlierPoint startTimestamp;
		  count: anEarlierPoint count + aLaterPoint count;
		  sum: anEarlierPoint sum + aLaterPoint sum;
		  zeroCount: anEarlierPoint zeroCount + aLaterPoint zeroCount;
		  scale: scale;
		  positiveBuckets: (self exponentialBucketRangeFromCountsByIndex: positiveCounts);
		  negativeBuckets: (self exponentialBucketRangeFromCountsByIndex: negativeCounts);
		  min: (self cumulativeExtremeOf: anEarlierPoint min and: aLaterPoint min by: #min:);
		  max: (self cumulativeExtremeOf: anEarlierPoint max and: aLaterPoint max by: #max:);
		  yourself
]

{ #category : 'aggregating' }
OTHistogram >> cumulativeExtremeOf: anEarlierValue and: aLaterValue by: aSelector [
	"The least or greatest of two values, either nil when the stream records neither."

	anEarlierValue ifNil: [ ^ aLaterValue ].
	aLaterValue ifNil: [ ^ anEarlierValue ].
	^ anEarlierValue perform: aSelector with: aLaterValue
]

{ #category : 'aggregating' }
OTHistogram >> cumulativePoint: anEarlierPoint followedBy: aLaterPoint using: anOTMetricAggregationContext [

	anOTMetricAggregationContext aggregation = #sum ifTrue: [ ^ self cumulativeSumPoint: anEarlierPoint followedBy: aLaterPoint ].
	anOTMetricAggregationContext aggregation = #base2ExponentialBucketHistogram ifTrue: [
		^ self cumulativeExponentialHistogramPoint: anEarlierPoint followedBy: aLaterPoint using: anOTMetricAggregationContext ].
	^ self cumulativeExplicitHistogramPoint: anEarlierPoint followedBy: aLaterPoint
]

{ #category : 'aggregating' }
OTHistogram >> defaultExplicitBucketBoundaries [

	^ #( 0 5 10 25 50 75 100 250 500 750 1000 2500 5000 7500 10000 )
]

{ #category : 'aggregating' }
OTHistogram >> explicitBucketBoundaries [

	| boundaries |
	boundaries := self advice at: 'ExplicitBucketBoundaries' ifAbsent: [ self defaultExplicitBucketBoundaries ].
	^ boundaries asArray collect: [ :each | each asFloat ]
]

{ #category : 'aggregating' }
OTHistogram >> explicitBucketBoundariesForAggregationContext: anOTMetricAggregationContext [

	| boundaries |
	boundaries := anOTMetricAggregationContext aggregationParameterAt: #boundaries ifAbsent: [ nil ].
	boundaries ifNil: [ ^ self explicitBucketBoundaries ].
	^ boundaries asArray collect: [ :each | each asFloat ]
]

{ #category : 'aggregating' }
OTHistogram >> explicitHistogramMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| boundaries points recordMinMax |
	boundaries := self explicitBucketBoundariesForAggregationContext: anOTMetricAggregationContext.
	recordMinMax := self recordMinMaxForAggregationContext: anOTMetricAggregationContext.
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          | point values |
			          values := each value collect: [ :measurement | measurement value ].
			          point := OTHistogramDataPoint
				                   attributes: each key
				                   count: values size
				                   sum: (values inject: 0 into: [ :sum :value | sum + value ])
				                   min: (recordMinMax
						                    ifTrue: [ values min ]
						                    ifFalse: [ nil ])
				                   max: (recordMinMax
						                    ifTrue: [ values max ]
						                    ifFalse: [ nil ])
				                   explicitBounds: boundaries
				                   bucketCounts: (self bucketCountsForMeasurements: each value boundaries: boundaries)
				                   startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ each value first timestamp ])
				                   timestamp: anOTMetricAggregationContext collectedAt.
			          point
				          exemplars:
					          (self exemplarsFromMeasurements: each value pointAttributes: each key using: anOTMetricAggregationContext);
				          yourself ].
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
	countsByIndex isEmpty ifTrue: [ ^ OTExponentialBucketRange offset: 0 bucketCounts: #(  ) ].
	firstIndex := countsByIndex keys min.
	lastIndex := countsByIndex keys max.
	bucketCounts := (firstIndex to: lastIndex) collect: [ :each | countsByIndex at: each ifAbsent: [ 0 ] ].
	^ OTExponentialBucketRange offset: firstIndex bucketCounts: bucketCounts
]

{ #category : 'aggregating' }
OTHistogram >> exponentialCountsByIndexAtScale: anInteger from: someRangesAtScales [
	"The counts of bucket ranges, each given with its scale, no coarser than anInteger, by their bucket index at scale anInteger: a bucket at a scale finer by k falls in the bucket whose index is its own shifted right by k."

	| countsByIndex |
	countsByIndex := Dictionary new.
	someRangesAtScales do: [ :each |
			| range shift |
			range := each key.
			shift := each value - anInteger.
			range bucketCounts withIndexDo: [ :count :position |
					count > 0 ifTrue: [
							| index |
							index := range offset + position - 1 bitShift: shift negated.
							countsByIndex at: index put: (countsByIndex at: index ifAbsent: [ 0 ]) + count ] ] ].
	^ countsByIndex
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramDataPointForMeasurements: someMeasurements attributes: someAttributes using: anOTMetricAggregationContext [

	| finiteMeasurements negativeCounts point positiveCounts recordMinMax scale values zeroCount |
	finiteMeasurements := self finiteMeasurementsFrom: someMeasurements.
	finiteMeasurements ifEmpty: [ ^ nil ].
	values := finiteMeasurements collect: [ :each | each value asFloat ].
	scale := self exponentialHistogramScaleForMeasurements: finiteMeasurements using: anOTMetricAggregationContext.
	recordMinMax := self recordMinMaxForAggregationContext: anOTMetricAggregationContext.
	positiveCounts := Dictionary new.
	negativeCounts := Dictionary new.
	zeroCount := 0.
	values do: [ :each |
			each isZero
				ifTrue: [ zeroCount := zeroCount + 1 ]
				ifFalse: [
						| absoluteValue bucketCounts bucketIndex |
						absoluteValue := each abs.
						bucketIndex := self exponentialBucketIndexFor: absoluteValue scale: scale.
						bucketCounts := each > 0
							                ifTrue: [ positiveCounts ]
							                ifFalse: [ negativeCounts ].
						bucketCounts at: bucketIndex put: (bucketCounts at: bucketIndex ifAbsent: [ 0 ]) + 1 ] ].
	point := OTExponentialHistogramDataPoint new.
	point
		attributes: someAttributes;
		count: values size;
		sum: (values inject: 0.0 into: [ :sum :value | sum + value ]);
		scale: scale;
		zeroCount: zeroCount;
		positiveBuckets: (self exponentialBucketRangeFromCountsByIndex: positiveCounts);
		negativeBuckets: (self exponentialBucketRangeFromCountsByIndex: negativeCounts);
		min: (recordMinMax
				 ifTrue: [ values min ]
				 ifFalse: [ nil ]);
		max: (recordMinMax
				 ifTrue: [ values max ]
				 ifFalse: [ nil ]);
		startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ finiteMeasurements first timestamp ]);
		timestamp: anOTMetricAggregationContext collectedAt;
		zeroThreshold: 0.0;
		exemplars:
			(self exemplarsFromMeasurements: finiteMeasurements pointAttributes: someAttributes using: anOTMetricAggregationContext).
	^ point
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMaxScale [

	^ 20
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMaxScaleForAggregationContext: anOTMetricAggregationContext [

	| maxScale |
	maxScale := anOTMetricAggregationContext aggregationParameterAt: #maxScale ifAbsent: [ nil ].
	(maxScale isInteger and: [ maxScale >= self exponentialHistogramMinScale ]) ifTrue: [ ^ maxScale ].
	^ self exponentialHistogramMaxScale
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMaxSize [

	^ 160
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMaxSizeForAggregationContext: anOTMetricAggregationContext [

	| maxSize |
	maxSize := anOTMetricAggregationContext aggregationParameterAt: #maxSize ifAbsent: [ nil ].
	(maxSize isInteger and: [ maxSize > 0 ]) ifTrue: [ ^ maxSize ].
	^ self exponentialHistogramMaxSize
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := ((self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
		           self
			           exponentialHistogramDataPointForMeasurements: each value
			           attributes: each key
			           using: anOTMetricAggregationContext ]) reject: [ :each | each isNil ].
	^ (OTExponentialHistogramMetricData instrument: self points: points)
		  temporality: anOTMetricAggregationContext temporality;
		  yourself
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramMinScale [

	^ -10
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramRangeWidthAtScale: anInteger forAbsoluteValues: someValues [

	| indexes |
	someValues ifEmpty: [ ^ 0 ].
	indexes := someValues collect: [ :each | self exponentialBucketIndexFor: each scale: anInteger ].
	^ indexes max - indexes min + 1
]

{ #category : 'aggregating' }
OTHistogram >> exponentialHistogramScaleForMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| maxScale maxSize negativeValues positiveValues |
	positiveValues := someMeasurements select: [ :each | each value > 0 ] thenCollect: [ :each | each value asFloat ].
	negativeValues := someMeasurements select: [ :each | each value < 0 ] thenCollect: [ :each | each value abs asFloat ].
	maxScale := self exponentialHistogramMaxScaleForAggregationContext: anOTMetricAggregationContext.
	maxSize := self exponentialHistogramMaxSizeForAggregationContext: anOTMetricAggregationContext.
	(positiveValues size <= 1 and: [ negativeValues size <= 1 ]) ifTrue: [ ^ maxScale ].
	maxScale to: self exponentialHistogramMinScale by: -1 do: [ :scale |
			((self exponentialHistogramRangeWidthAtScale: scale forAbsoluteValues: positiveValues) <= maxSize and: [
				 (self exponentialHistogramRangeWidthAtScale: scale forAbsoluteValues: negativeValues) <= maxSize ]) ifTrue: [ ^ scale ] ].
	^ self exponentialHistogramMinScale
]

{ #category : 'aggregating' }
OTHistogram >> exponentialRangeWidthOfCountsByIndex: countsByIndex [

	countsByIndex isEmpty ifTrue: [ ^ 0 ].
	^ countsByIndex keys max - countsByIndex keys min + 1
]

{ #category : 'aggregating' }
OTHistogram >> finiteMeasurementsFrom: someMeasurements [

	^ someMeasurements select: [ :each |
			  | value |
			  value := each value asFloat.
			  value isNaN not and: [ value isInfinite not ] ]
]

{ #category : 'accessing' }
OTHistogram >> instrumentType [

	^ #histogram
]

{ #category : 'aggregating' }
OTHistogram >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	anOTMetricAggregationContext aggregation = #sum ifTrue: [
		^ self sumMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext ].
	anOTMetricAggregationContext aggregation = #base2ExponentialBucketHistogram ifTrue: [
		^ self exponentialHistogramMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext ].
	^ self explicitHistogramMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext
]

{ #category : 'aggregating' }
OTHistogram >> otlpAggregationForPreference: aSymbol [

	^ self aggregationForPreference: aSymbol
]

{ #category : 'aggregating' }
OTHistogram >> otlpTemporalityForDeltaPreference [

	^ #delta
]

{ #category : 'aggregating' }
OTHistogram >> otlpTemporalityForLowMemoryPreference [

	^ #delta
]

{ #category : 'recording' }
OTHistogram >> record: aNumber [

	^ self record: aNumber attributes: #(  )
]

{ #category : 'recording' }
OTHistogram >> record: aNumber attributes: aCollection [

	^ self recordMeasurementValue: aNumber attributes: aCollection
]

{ #category : 'aggregating' }
OTHistogram >> recordMinMaxForAggregationContext: anOTMetricAggregationContext [

	| recordMinMax |
	recordMinMax := anOTMetricAggregationContext aggregationParameterAt: #recordMinMax ifAbsent: [ nil ].
	(recordMinMax isKindOf: Boolean) ifTrue: [ ^ recordMinMax ].
	^ true
]

{ #category : 'aggregating' }
OTHistogram >> sumMetricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	| points |
	points := (self groupedMeasurementsByAttributes: someMeasurements) associations collect: [ :each |
			          OTNumberDataPoint
				          attributes: each key
				          value: (each value inject: 0 into: [ :sum :measurement | sum + measurement value ])
				          startTimestamp: (anOTMetricAggregationContext startTimestamp ifNil: [ each value first timestamp ])
				          timestamp: anOTMetricAggregationContext collectedAt ].
	^ (OTSumMetricData instrument: self points: points monotonic: true)
		  temporality: anOTMetricAggregationContext temporality;
		  yourself
]

{ #category : 'aggregating' }
OTHistogram >> supportsAggregation: aSymbol [

	^ (super supportsAggregation: aSymbol) or: [ #( sum explicitBucketHistogram base2ExponentialBucketHistogram ) includes: aSymbol ]
]
