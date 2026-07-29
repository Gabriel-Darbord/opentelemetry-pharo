Class {
	#name : 'OTExponentialHistogramTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'tests' }
OTExponentialHistogramTest >> testReaderCanAggregateHistogramMeasurementsAsExponentialHistogram [

	| histogramMetric point provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader aggregationSelector: [ :instrument | #base2ExponentialBucketHistogram ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 0.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 5.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		15 negated.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 25.
	snapshot := reader collectSnapshot.
	histogramMetric := snapshot metrics first.
	self assert: histogramMetric class identicalTo: OTExponentialHistogramMetricData.
	self assert: histogramMetric temporality equals: #cumulative.
	point := histogramMetric points first.
	self assert: point count equals: 4.
	self assert: point sum equals: 15.
	self assert: point min equals: 15 negated.
	self assert: point max equals: 25.
	self assert: point zeroCount equals: 1.
	self assert: (point positiveBuckets bucketCounts inject: 0 into: [ :sum :each | sum + each ]) equals: 2.
	self assert: (point negativeBuckets bucketCounts inject: 0 into: [ :sum :each | sum + each ]) equals: 1.
	self assert: point timestamp equals: snapshot collectedAt
]

{ #category : 'tests' }
OTExponentialHistogramTest >> testReaderChoosesHighestExponentialHistogramScaleThatFitsMaxSize [

	| histogramMetric point provider reader |
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
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 1.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 2.
	histogramMetric := reader collectSnapshot metrics first.
	point := histogramMetric points first.
	self assert: histogramMetric class identicalTo: OTExponentialHistogramMetricData.
	self assert: point count equals: 2.
	self assert: point scale equals: 1
]

{ #category : 'tests' }
OTExponentialHistogramTest >> testReaderDropsAllNonFiniteValuesFromExponentialHistogram [

	| provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader aggregationSelector: [ :instrument | #base2ExponentialBucketHistogram ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		Float nan.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		Float infinity.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		Float negativeInfinity.
	snapshot := reader collectSnapshot.
	self assert: snapshot metrics isEmpty
]

{ #category : 'tests' }
OTExponentialHistogramTest >> testReaderIgnoresNonFiniteValuesWhenAggregatingExponentialHistogram [

	| histogramMetric point provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader aggregationSelector: [ :instrument | #base2ExponentialBucketHistogram ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 0.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 5.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		Float nan.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		Float infinity.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		Float negativeInfinity.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record:
		15 negated.
	snapshot := reader collectSnapshot.
	histogramMetric := snapshot metrics first.
	self assert: histogramMetric class identicalTo: OTExponentialHistogramMetricData.
	point := histogramMetric points first.
	self assert: point count equals: 3.
	self assert: point sum equals: 10 negated.
	self assert: point min equals: 15 negated.
	self assert: point max equals: 5.
	self assert: point zeroCount equals: 1.
	self assert: (point positiveBuckets bucketCounts inject: 0 into: [ :sum :each | sum + each ]) equals: 1.
	self assert: (point negativeBuckets bucketCounts inject: 0 into: [ :sum :each | sum + each ]) equals: 1
]

{ #category : 'tests' }
OTExponentialHistogramTest >> testReaderUsesConfiguredMaxScaleWhenExponentialHistogramHasAtMostOnePositiveAndNegativeValue [

	| histogramMetric point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'request.duration')
				 aggregation: #base2ExponentialBucketHistogram;
				 aggregationParameters: { ('max_scale' -> 7) } asDictionary;
				 yourself).
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 0.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 1.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: -2.
	histogramMetric := reader collectSnapshot metrics first.
	point := histogramMetric points first.
	self assert: histogramMetric class identicalTo: OTExponentialHistogramMetricData.
	self assert: point count equals: 3.
	self assert: point scale equals: 7
]
