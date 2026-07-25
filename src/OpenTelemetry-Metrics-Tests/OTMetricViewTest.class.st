Class {
	#name : 'OTMetricViewTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricViewTest >> overflowPointFrom: somePoints [

	^ somePoints
		  detect: [ :each | (each attributes at: 'otel.metric.overflow' ifAbsent: [ false ]) = true ]
		  ifNone: [ self fail: 'Expected an overflow point' ]
]

{ #category : 'private' }
OTMetricViewTest >> pointWithAttribute: aValue named: aKey in: somePoints [

	^ somePoints
		  detect: [ :each | (each attributes at: aKey ifAbsent: [ nil ]) = aValue ]
		  ifNone: [ self fail: 'Expected a point for ' , aKey printString , '=' , aValue printString ]
]

{ #category : 'tests' }
OTMetricViewTest >> testIncompatibleViewAggregationFallsBackToDefaultMetric [

	| metric provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'requests.total')
				 aggregation: #lastValue;
				 yourself).
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 4.
	metric := reader collectSnapshot metrics first.
	self assert: metric class identicalTo: OTSumMetricData.
	self assert: metric name equals: 'requests.total'.
	self assert: metric points first value equals: 4
]

{ #category : 'tests' }
OTMetricViewTest >> testViewCanAggregateHistogramAsSum [

	| metric provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'request.duration')
				 aggregation: #sum;
				 yourself).
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 2.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 3.
	metric := reader collectSnapshot metrics first.
	self assert: metric class identicalTo: OTSumMetricData.
	self assert: metric points first value equals: 5.
	self assert: metric temporality equals: #cumulative
]

{ #category : 'tests' }
OTMetricViewTest >> testViewCanConfigureExponentialHistogramAggregationParameters [

	| metric point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'request.duration')
				 aggregation: #base2ExponentialBucketHistogram;
				 aggregationParameters: {
						 ('max_scale' -> 3).
						 ('record_min_max' -> false) } asDictionary;
				 yourself).
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration') record: 42.
	metric := reader collectSnapshot metrics first.
	point := metric points first.
	self assert: metric class identicalTo: OTExponentialHistogramMetricData.
	self assert: point scale equals: 3.
	self assert: point min isNil.
	self assert: point max isNil
]

{ #category : 'tests' }
OTMetricViewTest >> testViewCanDropAllInstrumentsByDefault [

	| provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: (OTMetricView all
				 aggregation: #drop;
				 yourself).
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	((provider meterNamed: 'demo.metrics') gaugeNamed: 'queue.depth') record: 2.
	snapshot := reader collectSnapshot.
	self assert: snapshot metrics isEmpty
]

{ #category : 'tests' }
OTMetricViewTest >> testViewCanExcludeAttributesWithoutExplicitIncludeList [

	| metric point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'requests.total')
				 excludedAttributeKeys: #( 'user' );
				 yourself).
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2 attributes: {
			('status' -> '200').
			('user' -> 'alice').
			('region' -> 'eu') }.
	metric := reader collectSnapshot metrics first.
	point := metric points first.
	self assert: (point attributes at: 'status') equals: '200'.
	self assert: (point attributes at: 'region') equals: 'eu'.
	self deny: (point attributes includesKey: 'user')
]

{ #category : 'tests' }
OTMetricViewTest >> testViewCanOverrideExplicitHistogramBoundariesAndMinMax [

	| metric point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'request.duration')
				 aggregation: #explicitBucketHistogram;
				 aggregationParameters: {
						 ('Boundaries' -> #( 1 10 )).
						 ('RecordMinMax' -> false) } asDictionary;
				 yourself).
	((provider meterNamed: 'demo.metrics')
		 histogramNamed: 'request.duration'
		 unit: 'ms'
		 description: 'Request duration'
		 advice: { ('ExplicitBucketBoundaries' -> #( 100 )) } asDictionary) record: 0.
	((provider meterNamed: 'demo.metrics')
		 histogramNamed: 'request.duration'
		 unit: 'ms'
		 description: 'Request duration'
		 advice: { ('ExplicitBucketBoundaries' -> #( 100 )) } asDictionary) record: 5.
	((provider meterNamed: 'demo.metrics')
		 histogramNamed: 'request.duration'
		 unit: 'ms'
		 description: 'Request duration'
		 advice: { ('ExplicitBucketBoundaries' -> #( 100 )) } asDictionary) record: 15.
	metric := reader collectSnapshot metrics first.
	point := metric points first.
	self assert: metric class identicalTo: OTHistogramMetricData.
	self assert: point explicitBounds equals: #( 1.0 10.0 ).
	self assert: point bucketCounts equals: #( 1 1 1 ).
	self assert: point min isNil.
	self assert: point max isNil
]

{ #category : 'tests' }
OTMetricViewTest >> testViewCanRenameFilterAttributesAndOverrideCardinalityLimit [

	| metric overflowPoint point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider
		addMetricReader: reader;
		addView: ((OTMetricView named: 'requests.total')
				 streamName: 'requests.by_status';
				 streamDescription: 'Requests grouped by status';
				 attributeKeys: #( 'status' );
				 aggregationCardinalityLimit: 1;
				 yourself).
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2 attributes: {
			('status' -> '200').
			('user' -> 'alice') }.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 3 attributes: {
			('status' -> '500').
			('user' -> 'bob') }.
	metric := reader collectSnapshot metrics first.
	self assert: metric name equals: 'requests.by_status'.
	self assert: metric description equals: 'Requests grouped by status'.
	self assert: metric points size equals: 2.
	point := self pointWithAttribute: '200' named: 'status' in: metric points.
	overflowPoint := self overflowPointFrom: metric points.
	self assert: point value equals: 2.
	self assert: overflowPoint value equals: 3
]

{ #category : 'tests' }
OTMetricViewTest >> testViewConflictWarningsAreEmittedOncePerMetricIdentity [

	self withMetricWarningsDo: [ :warnings |
			| metrics provider reader |
			provider := OTMeterProvider new.
			reader := OTInMemoryMetricReader new.
			provider
				addMetricReader: reader;
				addView: (OTMetricView named: 'requests.total');
				addView: (OTMetricView all
						 attributeKeys: #( 'status' );
						 yourself).
			((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2 attributes: {
					('status' -> '200').
					('method' -> 'GET') }.
			metrics := reader collectSnapshot metrics.
			self assert: metrics size equals: 2.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'conflicting metric identities').
			reader collectSnapshot.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTMetricViewTest >> testViewSelectorsCanTargetSpecificMeterScope [

	| alphaMetric betaMetric provider reader snapshot view |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	view := OTMetricView named: 'requests.total'.
	view
		instrumentType: #counter;
		meterName: 'alpha.metrics';
		streamName: 'alpha.requests'.
	provider
		addMetricReader: reader;
		addView: view.
	((provider meterNamed: 'alpha.metrics') counterNamed: 'requests.total') add: 2.
	((provider meterNamed: 'beta.metrics') counterNamed: 'requests.total') add: 3.
	snapshot := reader collectSnapshot.
	alphaMetric := snapshot metrics
		               detect: [ :each | each name = 'alpha.requests' ]
		               ifNone: [ self fail: 'Expected renamed alpha metric' ].
	betaMetric := snapshot metrics
		              detect: [ :each | each name = 'requests.total' ]
		              ifNone: [ self fail: 'Expected default beta metric' ].
	self assert: alphaMetric points first value equals: 2.
	self assert: betaMetric points first value equals: 3
]

{ #category : 'private' }
OTMetricViewTest >> withMetricWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMetricReader metricWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTMetricReader metricWarningSink: nil ]
]
