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
	((provider meterNamed: 'demo.metrics')
		histogramNamed: 'request.duration'
		unit: 'ms'
		description: 'Request duration')
		record: 0.
	((provider meterNamed: 'demo.metrics')
		histogramNamed: 'request.duration'
		unit: 'ms'
		description: 'Request duration')
		record: 5.
	((provider meterNamed: 'demo.metrics')
		histogramNamed: 'request.duration'
		unit: 'ms'
		description: 'Request duration')
		record: (15 negated).
	((provider meterNamed: 'demo.metrics')
		histogramNamed: 'request.duration'
		unit: 'ms'
		description: 'Request duration')
		record: 25.
	snapshot := reader collectSnapshot.
	histogramMetric := snapshot metrics first.
	self assert: histogramMetric class identicalTo: OTExponentialHistogramMetricData.
	self assert: histogramMetric temporality equals: #cumulative.
	point := histogramMetric points first.
	self assert: point count equals: 4.
	self assert: point sum equals: 15.
	self assert: point min equals: (15 negated).
	self assert: point max equals: 25.
	self assert: point zeroCount equals: 1.
	self
		assert: (point positiveBuckets bucketCounts inject: 0 into: [ :sum :each | sum + each ])
		equals: 2.
	self
		assert: (point negativeBuckets bucketCounts inject: 0 into: [ :sum :each | sum + each ])
		equals: 1.
	self assert: point timestamp equals: snapshot collectedAt
]
