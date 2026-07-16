Class {
	#name : 'OTMetricCardinalityLimitTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricCardinalityLimitTest >> overflowPointFrom: somePoints [

	^ somePoints
		detect: [ :each |
			(each attributes at: 'otel.metric.overflow' ifAbsent: [ false ]) = true ]
		ifNone: [ self fail: 'Expected an overflow point' ]
]

{ #category : 'private' }
OTMetricCardinalityLimitTest >> pointWithAttribute: aValue named: aKey in: somePoints [

	^ somePoints
		detect: [ :each | (each attributes at: aKey ifAbsent: [ nil ]) = aValue ]
		ifNone: [ self fail: 'Expected a point for ', aKey printString, '=', aValue printString ]
]

{ #category : 'tests' }
OTMetricCardinalityLimitTest >> testAsynchronousMetricsPreferFirstObservedAttributesWhenLimitingCardinality [

	| firstPoint metric overflowPoint provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader cardinalityLimitSelector: [ :instrument | 1 ].
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableCounterNamed: 'runtime.page_faults'
		callbacks: {
			[ :observer |
			observer observe: 5 attributes: { 'pid' -> '1001' }.
			observer observe: 7 attributes: { 'pid' -> '1002' } ] }
		unit: '1'
		description: 'Page faults'
		advice: Dictionary new.
	metric := reader collectSnapshot metrics first.
	self assert: metric points size equals: 2.
	firstPoint := self pointWithAttribute: '1001' named: 'pid' in: metric points.
	overflowPoint := self overflowPointFrom: metric points.
	self assert: firstPoint value equals: 5.
	self assert: overflowPoint value equals: 7
]

{ #category : 'tests' }
OTMetricCardinalityLimitTest >> testCardinalityLimitIsAppliedAfterAttributeFiltering [

	| metric point provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader cardinalityLimitSelector: [ :instrument | 1 ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics')
		counterNamed: 'requests.total'
		unit: '1'
		description: 'Request count'
		advice: { 'attributes' -> #( 'route' ) } asDictionary)
		add: 2
		attributes: { 'route' -> '/home'. 'user' -> 'alice' }.
	((provider meterNamed: 'demo.metrics')
		counterNamed: 'requests.total'
		unit: '1'
		description: 'Request count'
		advice: { 'attributes' -> #( 'route' ) } asDictionary)
		add: 3
		attributes: { 'route' -> '/home'. 'user' -> 'bob' }.
	metric := reader collectSnapshot metrics first.
	self assert: metric points size equals: 1.
	point := metric points first.
	self assert: (point attributes at: 'route') equals: '/home'.
	self assert: (point attributes includesKey: 'otel.metric.overflow') not.
	self assert: point value equals: 5
]

{ #category : 'tests' }
OTMetricCardinalityLimitTest >> testSynchronousCumulativeMetricsUseOverflowPointAfterCardinalityLimit [

	| metric overflowPoint provider reader secondMetric secondOverflowPoint secondStablePoint stablePoint |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader cardinalityLimitSelector: [ :instrument | 1 ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics')
		counterNamed: 'requests.total')
		add: 1
		attributes: { 'route' -> '/home' }.
	((provider meterNamed: 'demo.metrics')
		counterNamed: 'requests.total')
		add: 2
		attributes: { 'route' -> '/checkout' }.
	metric := reader collectSnapshot metrics first.
	stablePoint := self pointWithAttribute: '/home' named: 'route' in: metric points.
	overflowPoint := self overflowPointFrom: metric points.
	self assert: stablePoint value equals: 1.
	self assert: overflowPoint value equals: 2.
	((provider meterNamed: 'demo.metrics')
		counterNamed: 'requests.total')
		add: 3
		attributes: { 'route' -> '/home' }.
	((provider meterNamed: 'demo.metrics')
		counterNamed: 'requests.total')
		add: 4
		attributes: { 'route' -> '/products' }.
	secondMetric := reader collectSnapshot metrics first.
	secondStablePoint := self
		pointWithAttribute: '/home'
		named: 'route'
		in: secondMetric points.
	secondOverflowPoint := self overflowPointFrom: secondMetric points.
	self assert: secondStablePoint value equals: 4.
	self assert: secondOverflowPoint value equals: 6
]
