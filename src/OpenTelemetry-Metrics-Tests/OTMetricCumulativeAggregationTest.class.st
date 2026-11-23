"
A reader is handed each measurement once, at the first collection after it was recorded. A cumulative stream of a synchronous instrument adds the measurements of each collection to the points it kept from the last, and keeps nothing else; a delta stream keeps nothing.
"
Class {
	#name : 'OTMetricCumulativeAggregationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricCumulativeAggregationTest >> exponentialHistogramPointRecording: someBatches [
	"The point of an exponential histogram of four buckets at most, collected once after each batch of values is recorded."

	| histogram provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'request.duration')
				 aggregation: #base2ExponentialBucketHistogram;
				 aggregationParameters: {
						 ('max_scale' -> 5).
						 ('max_size' -> 4) } asDictionary;
				 yourself).
	histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
	someBatches do: [ :each |
			each do: [ :value | histogram record: value ].
			snapshot := reader collectSnapshot ].
	^ self onlyPointIn: snapshot
]

{ #category : 'private' }
OTMetricCumulativeAggregationTest >> onlyPointIn: anOTMetricSnapshot [

	self assert: anOTMetricSnapshot metrics size equals: 1.
	self assert: anOTMetricSnapshot metrics first points size equals: 1.
	^ anOTMetricSnapshot metrics first points first
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testACumulativeExplicitHistogramAddsEachCollectionToTheLast [

	| histogram point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
	histogram
		record: 3;
		record: 30.
	reader collectSnapshot.
	histogram
		record: 300;
		record: 1.
	point := self onlyPointIn: reader collectSnapshot.
	self assert: point count equals: 4.
	self assert: point sum equals: 334.
	self assert: point min equals: 1.
	self assert: point max equals: 300.
	self assert: point bucketCounts equals: #( 0 2 0 0 1 0 0 0 1 0 0 0 0 0 0 0 )
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testACumulativeExponentialHistogramIsTheOneAllItsMeasurementsMake [
	"Values added across collections end in the buckets, at the scale, that collecting them all at once gives."

	| all byCollection values |
	values := #( #( 1 3 ) #( 100 ) #( 1000 0.5 -2 0 ) #( 7 ) ).
	byCollection := self exponentialHistogramPointRecording: values.
	all := self exponentialHistogramPointRecording: { (values inject: #(  ) into: [ :sum :each | sum , each ]) }.
	self assert: byCollection scale equals: all scale.
	self assert: byCollection scale < 5.
	self assert: byCollection count equals: all count.
	self assert: byCollection sum equals: all sum.
	self assert: byCollection zeroCount equals: all zeroCount.
	self assert: byCollection min equals: all min.
	self assert: byCollection max equals: all max.
	self assert: byCollection positiveBuckets offset equals: all positiveBuckets offset.
	self assert: byCollection positiveBuckets bucketCounts asArray equals: all positiveBuckets bucketCounts asArray.
	self assert: byCollection negativeBuckets offset equals: all negativeBuckets offset.
	self assert: byCollection negativeBuckets bucketCounts asArray equals: all negativeBuckets bucketCounts asArray
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testACumulativeGaugeKeepsTheLastValue [

	| gauge point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	gauge := (provider meterNamed: 'demo.metrics') gaugeNamed: 'temperature'.
	gauge
		record: 20 attributes: { ('room' -> 'a') };
		record: 10 attributes: { ('room' -> 'b') }.
	reader collectSnapshot.
	gauge record: 25 attributes: { ('room' -> 'a') }.
	point := reader collectSnapshot metrics first points detect: [ :each | (each attributes at: 'room') = 'a' ].
	self assert: point value equals: 25.
	point := reader collectSnapshot metrics first points detect: [ :each | (each attributes at: 'room') = 'b' ].
	self assert: point value equals: 10
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testACumulativeSumAddsEachCollectionToTheLast [

	| counter first provider reader second snapshot third |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter
		add: 1;
		add: 2.
	first := self onlyPointIn: reader collectSnapshot.
	counter add: 4.
	second := self onlyPointIn: reader collectSnapshot.
	snapshot := reader collectSnapshot.
	third := self onlyPointIn: snapshot.
	self assert: first value equals: 3.
	self assert: second value equals: 7.
	self assert: third value equals: 7.
	self assert: second startTimestamp equals: first startTimestamp.
	self assert: third startTimestamp equals: first startTimestamp.
	self assert: third timestamp equals: snapshot collectedAt
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testADeltaSumCountsEachMeasurementOnce [

	| counter provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter
		add: 1;
		add: 2.
	self assert: (self onlyPointIn: reader collectSnapshot) value equals: 3.
	counter add: 4.
	self assert: (self onlyPointIn: reader collectSnapshot) value equals: 4.
	self assert: reader collectSnapshot metrics isEmpty.
	self assert: reader cumulativePointsByStream isEmpty
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testAPointWithoutMeasurementsSinceIsReportedAgainWithoutExemplars [
	"An exemplar is one of the measurements collected, so a point that saw none since the last collection has none."

	| counter first provider reader second snapshot |
	provider := OTMeterProvider new.
	provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 5.
	first := self onlyPointIn: reader collectSnapshot.
	snapshot := reader collectSnapshot.
	second := self onlyPointIn: snapshot.
	self deny: first exemplars isEmpty.
	self assert: second exemplars isEmpty.
	self assert: second value equals: 5.
	self assert: second timestamp equals: snapshot collectedAt
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testForgettingAnEarlierSessionStartsTheSumsAgain [

	| counter first provider reader second |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 5.
	first := self onlyPointIn: reader collectSnapshot.
	provider forgetEarlierSession.
	counter add: 2.
	second := self onlyPointIn: reader collectSnapshot.
	self assert: second value equals: 2.
	self assert: second startTimestamp > first startTimestamp
]

{ #category : 'tests' }
OTMetricCumulativeAggregationTest >> testManyMeasurementsAcrossCollectionsKeepMemoryFlat [
	"However many measurements are recorded, the provider keeps none once its readers collected them, a cumulative stream keeps one point for each set of attributes, and a delta stream keeps none."

	| counter cumulative delta histogram provider |
	provider := OTMeterProvider new.
	cumulative := OTInMemoryMetricReader new.
	delta := OTInMemoryMetricReader new.
	delta temporalitySelector: [ :instrument | #delta ].
	provider
		addMetricReader: cumulative;
		addMetricReader: delta.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
	1 to: 20 do: [ :round |
			1 to: 500 do: [ :each |
					| attributes |
					attributes := { ('method' -> (#( 'GET' 'POST' 'PUT' ) at: each \\ 3 + 1)) }.
					counter add: 1 attributes: attributes.
					histogram record: each attributes: attributes ].
			self assert: provider measurements size equals: 1000.
			cumulative collectSnapshot.
			self assert: provider measurements size equals: 1000.
			delta collectSnapshot.
			self assert: provider measurements isEmpty.
			self assert: (cumulative cumulativePointsByStream inject: 0 into: [ :sum :each | sum + each size ]) equals: 6.
			self assert: delta cumulativePointsByStream isEmpty ].
	self
		assert: ((cumulative collectSnapshot metrics detect: [ :each | each name = 'requests.total' ]) points
				 inject: 0
				 into: [ :sum :each | sum + each value ])
		equals: 10000
]
