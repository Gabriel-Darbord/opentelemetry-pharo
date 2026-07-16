Class {
	#name : 'OTOtlpJsonMetricEncoderTest',
	#superclass : 'TestCase',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTOtlpJsonMetricEncoderTest >> attributeValuesByKeyFrom: someKeyValueDictionaries [

	| valuesByKey |
	valuesByKey := Dictionary new.
	someKeyValueDictionaries do: [ :each |
		valuesByKey at: (each at: 'key') put: (each at: 'value') ].
	^ valuesByKey
]

{ #category : 'private' }
OTOtlpJsonMetricEncoderTest >> sampleSnapshot [

	| gaugePoint gaugeMetric histogramMetric histogramPoint resource scope sumMetric sumPoint |
	resource := OTResource
		attributes: { 'service.name' -> 'demo'. 'resource-attr' -> 'resource-value' }
		schemaUrl: 'https://resource.example/schema'.
	scope := OTInstrumentationScope
		named: 'instrumentation'
		version: '1.0.0'
		schemaUrl: 'https://scope.example/schema'
		attributes: { 'scope-key' -> 'scope-value' }.
	sumPoint := OTNumberDataPoint
		attributes: { 'method' -> 'GET' }
		value: 4
		startTimestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 1))
		timestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 2)).
	sumMetric := OTSumMetricData new.
	sumMetric
		instrumentationScope: scope;
		name: 'requests.total';
		description: 'Request count';
		unit: '1';
		points: { sumPoint };
		monotonic: true;
		temporality: #cumulative.
	gaugePoint := OTNumberDataPoint
		attributes: { 'queue' -> 'main' }
		value: 7.5
		startTimestamp: nil
		timestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 3)).
	gaugeMetric := OTGaugeMetricData new.
	gaugeMetric
		instrumentationScope: scope;
		name: 'queue.depth';
		description: 'Queue depth';
		unit: '1';
		points: { gaugePoint }.
	histogramPoint := OTHistogramDataPoint
		attributes: { 'route' -> '/home' }
		count: 3
		sum: 45
		min: 5
		max: 25
		explicitBounds: #( 10 20 )
		bucketCounts: #( 1 1 1 )
		startTimestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 4))
		timestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 5)).
	histogramMetric := OTHistogramMetricData new.
	histogramMetric
		instrumentationScope: scope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { histogramPoint };
		temporality: #delta.
	^ OTMetricSnapshot
		resource: resource
		measurements: #()
		metrics: { sumMetric. gaugeMetric. histogramMetric }
		collectedAt: (DateAndTime unixEpoch + (Duration nanoSeconds: 5))
]

{ #category : 'running' }
OTOtlpJsonMetricEncoderTest >> setUp [

	super setUp.
	encoder := OTOtlpJsonMetricEncoder new
]

{ #category : 'tests' }
OTOtlpJsonMetricEncoderTest >> testEncodeSnapshotProducesSpecShapedOtlpJsonPayload [

	| attributesByKey gauge histogram metricPayload payload resourceMetrics scopeMetrics sum |
	payload := encoder encodeSnapshot: self sampleSnapshot.
	self assert: (payload keys asArray) equals: #( 'resourceMetrics' ).
	resourceMetrics := (payload at: 'resourceMetrics') first.
	self assert: (resourceMetrics at: 'schemaUrl') equals: 'https://resource.example/schema'.
	attributesByKey := self attributeValuesByKeyFrom: ((resourceMetrics at: 'resource') at: 'attributes').
	self assert: ((attributesByKey at: 'service.name') at: 'stringValue') equals: 'demo'.
	scopeMetrics := (resourceMetrics at: 'scopeMetrics') first.
	self assert: (scopeMetrics at: 'schemaUrl') equals: 'https://scope.example/schema'.
	self assert: ((scopeMetrics at: 'scope') at: 'name') equals: 'instrumentation'.
	self assert: ((scopeMetrics at: 'metrics') size) equals: 3.
	sum := (scopeMetrics at: 'metrics') first.
	self assert: (sum at: 'name') equals: 'requests.total'.
	metricPayload := sum at: 'sum'.
	self assert: (metricPayload at: 'aggregationTemporality') equals: 2.
	self assert: (metricPayload at: 'isMonotonic').
	self assert: ((((metricPayload at: 'dataPoints') first) at: 'asInt')) equals: '4'.
	gauge := (scopeMetrics at: 'metrics') second.
	self assert: (((gauge at: 'gauge') at: 'dataPoints') first at: 'asDouble') equals: 7.5.
	histogram := (scopeMetrics at: 'metrics') third.
	self assert: (((histogram at: 'histogram') at: 'aggregationTemporality')) equals: 1.
	self assert: ((((histogram at: 'histogram') at: 'dataPoints') first at: 'count')) equals: '3'.
	self assert: ((((histogram at: 'histogram') at: 'dataPoints') first at: 'bucketCounts')) equals: #( '1' '1' '1' )
]
