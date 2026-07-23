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
	someKeyValueDictionaries do: [ :each | valuesByKey at: (each at: 'key') put: (each at: 'value') ].
	^ valuesByKey
]

{ #category : 'private' }
OTOtlpJsonMetricEncoderTest >> sampleExponentialHistogramSnapshot [

	| histogramMetric histogramPoint resource scope |
	resource := OTResource
		            attributes: {
				            ('service.name' -> 'demo').
				            ('resource-attr' -> 'resource-value') }
		            schemaUrl: 'https://resource.example/schema'.
	scope := OTInstrumentationScope
		         named: 'instrumentation'
		         version: '1.0.0'
		         schemaUrl: 'https://scope.example/schema'
		         attributes: { ('scope-key' -> 'scope-value') }.
	histogramPoint := OTExponentialHistogramDataPoint new.
	histogramPoint
		attributes: { ('route' -> '/checkout') };
		count: 8;
		sum: 120.0;
		scale: 3;
		zeroCount: 1;
		positiveBuckets: (OTExponentialBucketRange offset: 1 bucketCounts: #( 2 0 4 ));
		negativeBuckets: (OTExponentialBucketRange offset: -2 bucketCounts: #( 1 ));
		min: -3.0;
		max: 55.0;
		startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 4);
		timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 5);
		zeroThreshold: 0.25.
	histogramMetric := OTExponentialHistogramMetricData new.
	histogramMetric
		instrumentationScope: scope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { histogramPoint };
		temporality: #cumulative.
	^ OTMetricSnapshot
		  resource: resource
		  measurements: #(  )
		  metrics: { histogramMetric }
		  collectedAt: DateAndTime unixEpoch + (Duration nanoSeconds: 5)
]

{ #category : 'private' }
OTOtlpJsonMetricEncoderTest >> sampleSnapshot [

	| gaugePoint gaugeMetric histogramMetric histogramPoint resource scope sumMetric sumPoint |
	resource := OTResource
		            attributes: {
				            ('service.name' -> 'demo').
				            ('resource-attr' -> 'resource-value') }
		            schemaUrl: 'https://resource.example/schema'.
	scope := OTInstrumentationScope
		         named: 'instrumentation'
		         version: '1.0.0'
		         schemaUrl: 'https://scope.example/schema'
		         attributes: { ('scope-key' -> 'scope-value') }.
	sumPoint := OTNumberDataPoint
		            attributes: { ('method' -> 'GET') }
		            value: 4
		            startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		            timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
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
		              attributes: { ('queue' -> 'main') }
		              value: 7.5
		              startTimestamp: nil
		              timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 3).
	gaugeMetric := OTGaugeMetricData new.
	gaugeMetric
		instrumentationScope: scope;
		name: 'queue.depth';
		description: 'Queue depth';
		unit: '1';
		points: { gaugePoint }.
	histogramPoint := OTHistogramDataPoint
		                  attributes: { ('route' -> '/home') }
		                  count: 3
		                  sum: 45
		                  min: 5
		                  max: 25
		                  explicitBounds: #( 10 20 )
		                  bucketCounts: #( 1 1 1 )
		                  startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 4)
		                  timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 5).
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
		  measurements: #(  )
		  metrics: {
				  sumMetric.
				  gaugeMetric.
				  histogramMetric }
		  collectedAt: DateAndTime unixEpoch + (Duration nanoSeconds: 5)
]

{ #category : 'private' }
OTOtlpJsonMetricEncoderTest >> sampleSummarySnapshot [

	| point metric resource scope |
	resource := OTResource attributes: { ('service.name' -> 'demo') } schemaUrl: 'https://resource.example/schema'.
	scope := OTInstrumentationScope
		         named: 'instrumentation'
		         version: '1.0.0'
		         schemaUrl: 'https://scope.example/schema'
		         attributes: { ('scope-key' -> 'scope-value') }.
	point := OTSummaryDataPoint
		         attributes: { ('route' -> '/checkout') }
		         count: 2
		         sum: 3.0
		         quantileValues: {
				         (OTSummaryQuantileValue quantile: 0.5 value: 1.5).
				         (OTSummaryQuantileValue quantile: 0.9 value: 2.5) }
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 4)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 5).
	metric := OTSummaryMetricData new.
	metric
		instrumentationScope: scope;
		name: 'request.summary';
		description: 'Request summary';
		unit: 'ms';
		points: { point }.
	^ OTMetricSnapshot
		  resource: resource
		  measurements: #(  )
		  metrics: { metric }
		  collectedAt: DateAndTime unixEpoch + (Duration nanoSeconds: 5)
]

{ #category : 'running' }
OTOtlpJsonMetricEncoderTest >> setUp [

	super setUp.
	encoder := OTOtlpJsonMetricEncoder new
]

{ #category : 'tests' }
OTOtlpJsonMetricEncoderTest >> testEncodeSnapshotIncludesExemplars [

	| data exemplar point |
	exemplar := OTMetricExemplar new.
	exemplar
		value: 3;
		timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 6);
		filteredAttributes: { ('user' -> 'alice') };
		traceId: '1234567890abcdef1234567890abcdef';
		spanId: '1234567890abcdef'.
	data := encoder exemplarDataFor: exemplar.
	point := (data at: 'filteredAttributes') first at: 'value'.
	self assert: (data at: 'asInt') equals: '3'.
	self assert: (data at: 'traceId') equals: '1234567890abcdef1234567890abcdef'.
	self assert: (data at: 'spanId') equals: '1234567890abcdef'.
	self assert: (point at: 'stringValue') equals: 'alice'
]

{ #category : 'tests' }
OTOtlpJsonMetricEncoderTest >> testEncodeSnapshotIncludesMetricMetadata [

	| metric payload resourceMetrics scopeMetrics metadata valuesByKey |
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleSnapshot metrics first instrumentationScope;
		name: 'requests.total';
		description: 'Request count';
		unit: '1';
		points: { self sampleSnapshot metrics first points first };
		monotonic: true;
		temporality: #cumulative;
		metadata: {
				('prometheus.type' -> 'unknown').
				('legacy.source' -> 'bridge') }.
	payload := encoder encodeSnapshot: (OTMetricSnapshot
			            resource: self sampleSnapshot resource
			            measurements: #(  )
			            metrics: { metric }
			            collectedAt: DateAndTime unixEpoch).
	resourceMetrics := (payload at: 'resourceMetrics') first.
	scopeMetrics := (resourceMetrics at: 'scopeMetrics') first.
	metadata := (scopeMetrics at: 'metrics') first at: 'metadata'.
	valuesByKey := self attributeValuesByKeyFrom: metadata.
	self assert: ((valuesByKey at: 'prometheus.type') at: 'stringValue') equals: 'unknown'.
	self assert: ((valuesByKey at: 'legacy.source') at: 'stringValue') equals: 'bridge'
]

{ #category : 'tests' }
OTOtlpJsonMetricEncoderTest >> testEncodeSnapshotProducesExponentialHistogramJsonPayload [

	| dataPoint histogram payload resourceMetrics scopeMetrics |
	payload := encoder encodeSnapshot: self sampleExponentialHistogramSnapshot.
	resourceMetrics := (payload at: 'resourceMetrics') first.
	scopeMetrics := (resourceMetrics at: 'scopeMetrics') first.
	histogram := (scopeMetrics at: 'metrics') first at: 'exponentialHistogram'.
	self assert: (histogram at: 'aggregationTemporality') equals: 2.
	dataPoint := (histogram at: 'dataPoints') first.
	self assert: (dataPoint at: 'count') equals: '8'.
	self assert: (dataPoint at: 'scale') equals: 3.
	self assert: (dataPoint at: 'zeroCount') equals: '1'.
	self assert: ((dataPoint at: 'positive') at: 'offset') equals: 1.
	self assert: ((dataPoint at: 'positive') at: 'bucketCounts') equals: #( '2' '0' '4' ).
	self assert: ((dataPoint at: 'negative') at: 'offset') equals: -2.
	self assert: ((dataPoint at: 'negative') at: 'bucketCounts') equals: #( '1' ).
	self assert: (dataPoint at: 'zeroThreshold') equals: 0.25
]

{ #category : 'tests' }
OTOtlpJsonMetricEncoderTest >> testEncodeSnapshotProducesSpecShapedOtlpJsonPayload [

	| attributesByKey gauge histogram metricPayload payload resourceMetrics scopeMetrics sum |
	payload := encoder encodeSnapshot: self sampleSnapshot.
	self assert: payload keys asArray equals: #( 'resourceMetrics' ).
	resourceMetrics := (payload at: 'resourceMetrics') first.
	self assert: (resourceMetrics at: 'schemaUrl') equals: 'https://resource.example/schema'.
	attributesByKey := self attributeValuesByKeyFrom: ((resourceMetrics at: 'resource') at: 'attributes').
	self assert: ((attributesByKey at: 'service.name') at: 'stringValue') equals: 'demo'.
	scopeMetrics := (resourceMetrics at: 'scopeMetrics') first.
	self assert: (scopeMetrics at: 'schemaUrl') equals: 'https://scope.example/schema'.
	self assert: ((scopeMetrics at: 'scope') at: 'name') equals: 'instrumentation'.
	self assert: (scopeMetrics at: 'metrics') size equals: 3.
	sum := (scopeMetrics at: 'metrics') first.
	self assert: (sum at: 'name') equals: 'requests.total'.
	metricPayload := sum at: 'sum'.
	self assert: (metricPayload at: 'aggregationTemporality') equals: 2.
	self assert: (metricPayload at: 'isMonotonic').
	self assert: ((metricPayload at: 'dataPoints') first at: 'asInt') equals: '4'.
	gauge := (scopeMetrics at: 'metrics') second.
	self assert: (((gauge at: 'gauge') at: 'dataPoints') first at: 'asDouble') equals: 7.5.
	histogram := (scopeMetrics at: 'metrics') third.
	self assert: ((histogram at: 'histogram') at: 'aggregationTemporality') equals: 1.
	self assert: (((histogram at: 'histogram') at: 'dataPoints') first at: 'count') equals: '3'.
	self assert: (((histogram at: 'histogram') at: 'dataPoints') first at: 'bucketCounts') equals: #( '1' '1' '1' )
]

{ #category : 'tests' }
OTOtlpJsonMetricEncoderTest >> testEncodeSnapshotProducesSummaryJsonPayload [

	| dataPoint payload quantiles resourceMetrics scopeMetrics |
	payload := encoder encodeSnapshot: self sampleSummarySnapshot.
	resourceMetrics := (payload at: 'resourceMetrics') first.
	scopeMetrics := (resourceMetrics at: 'scopeMetrics') first.
	dataPoint := (((scopeMetrics at: 'metrics') first at: 'summary') at: 'dataPoints') first.
	self assert: (dataPoint at: 'count') equals: '2'.
	self assert: (dataPoint at: 'sum') equals: 3.0.
	quantiles := dataPoint at: 'quantileValues'.
	self assert: quantiles size equals: 2.
	self assert: (quantiles first at: 'quantile') equals: 0.5.
	self assert: (quantiles first at: 'value') equals: 1.5.
	self assert: (quantiles second at: 'quantile') equals: 0.9.
	self assert: (quantiles second at: 'value') equals: 2.5
]
