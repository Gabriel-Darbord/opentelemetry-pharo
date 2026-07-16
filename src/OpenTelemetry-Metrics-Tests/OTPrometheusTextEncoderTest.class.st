Class {
	#name : 'OTPrometheusTextEncoderTest',
	#superclass : 'TestCase',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTPrometheusTextEncoderTest >> sampleResource [

	^ OTResource attributes:
		{ 'service.name' -> 'demo'.
		'service.namespace' -> 'shop'.
		'service.instance.id' -> 'pharo-1' }
]

{ #category : 'private' }
OTPrometheusTextEncoderTest >> sampleScope [

	^ OTInstrumentationScope
		named: 'instrumentation'
		version: '1.0.0'
		schemaUrl: 'https://scope.example/schema'
		attributes: { 'scope.key' -> 'scope-value' }
]

{ #category : 'private' }
OTPrometheusTextEncoderTest >> occurrencesOfSubstring: aSubstring in: aString [

	| count index |
	count := 0.
	index := 1.
	[
		index := aString findString: aSubstring startingAt: index.
		index > 0 ]
		whileTrue: [
			count := count + 1.
			index := index + aSubstring size ].
	^ count
]

{ #category : 'running' }
OTPrometheusTextEncoderTest >> setUp [

	super setUp.
	encoder := OTPrometheusTextEncoder new
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotAddsUnitSuffixAndUnitMetadataForOpenMetrics [

	| metric point snapshot text |
	point := OTNumberDataPoint
		attributes: { 'method' -> 'GET' }
		value: 4
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'response.size';
		description: 'Response size';
		unit: 'By';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		resource: self sampleResource
		measurements: #()
		metrics: { metric }
		collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (text includesSubstring: '# TYPE response_size_bytes_total counter').
	self assert: (text includesSubstring: '# UNIT response_size_bytes_total bytes').
	self assert: (text includesSubstring: 'response_size_bytes_total{').
	text := encoder encodeSnapshot: snapshot.
	self deny: (text includesSubstring: '# UNIT response_size_bytes_total bytes')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotDropsExponentialHistogramsFromTextOutput [

	| metric point snapshot text |
	point := OTExponentialHistogramDataPoint new.
	point
		attributes: { 'method' -> 'GET' };
		count: 3;
		sum: 12;
		scale: 0;
		timestamp: DateAndTime unixEpoch.
	metric := OTExponentialHistogramMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { point };
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		resource: self sampleResource
		measurements: #()
		metrics: { metric }
		collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self deny: (text includesSubstring: 'request_duration').
	self assert: (text includesSubstring: 'target_info')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotDropsMetricFamilyWhenPrometheusTypesConflict [

	| counterMetric gaugeMetric counterPoint gaugePoint snapshot text warnings |
	counterPoint := OTNumberDataPoint
		attributes: { 'source' -> 'counter' }
		value: 4
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	gaugePoint := OTNumberDataPoint
		attributes: { 'source' -> 'gauge' }
		value: 2
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	counterMetric := OTSumMetricData new.
	counterMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Counter form';
		unit: '1';
		points: { counterPoint };
		monotonic: true;
		temporality: #cumulative.
	gaugeMetric := OTGaugeMetricData new.
	gaugeMetric
		instrumentationScope: self sampleScope;
		name: 'requests.total';
		description: 'Gauge form';
		unit: '1';
		points: { gaugePoint }.
	snapshot := OTMetricSnapshot
		resource: OTResource empty
		measurements: #()
		metrics: { counterMetric. gaugeMetric }
		collectedAt: DateAndTime unixEpoch.
	warnings := OrderedCollection new.
	encoder warningSink: [ :message | warnings add: message ].
	text := encoder encodeSnapshot: snapshot format: #prometheusText100.
	self deny: (text includesSubstring: '# TYPE requests_total').
	self deny: (text includesSubstring: 'requests_total{').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'conflicting types')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesCountersScopeLabelsAndTargetInfo [

	| metric point snapshot text |
	point := OTNumberDataPoint
		attributes: { 'http.method' -> 'GET' }
		value: 4
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'http.requests';
		description: 'Request count';
		unit: '1';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		resource: self sampleResource
		measurements: #()
		metrics: { metric }
		collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: '# TYPE http_requests_total counter').
	self assert: (text includesSubstring: 'http_requests_total{').
	self assert: (text includesSubstring: 'http_method="GET"').
	self assert: (text includesSubstring: 'otel_scope_name="instrumentation"').
	self assert: (text includesSubstring: 'otel_scope_version="1.0.0"').
	self assert: (text includesSubstring: 'otel_scope_schema_url="https://scope.example/schema"').
	self assert: (text includesSubstring: 'otel_scope_scope_key="scope-value"').
	self assert: (text includesSubstring: 'target_info{').
	self assert: (text includesSubstring: 'job="shop/demo"').
	self assert: (text includesSubstring: 'instance="pharo-1"')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesSingleHelpLineWhenDescriptionsConflict [

	| firstMetric secondMetric firstPoint secondPoint snapshot text warnings |
	firstPoint := OTNumberDataPoint
		attributes: { 'source' -> 'one' }
		value: 1
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	secondPoint := OTNumberDataPoint
		attributes: { 'source' -> 'two' }
		value: 2
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	firstMetric := OTSumMetricData new.
	firstMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'First description';
		unit: '1';
		points: { firstPoint };
		monotonic: true;
		temporality: #cumulative.
	secondMetric := OTSumMetricData new.
	secondMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Second description';
		unit: '1';
		points: { secondPoint };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		resource: OTResource empty
		measurements: #()
		metrics: { firstMetric. secondMetric }
		collectedAt: DateAndTime unixEpoch.
	warnings := OrderedCollection new.
	encoder warningSink: [ :message | warnings add: message ].
	text := encoder encodeSnapshot: snapshot format: #prometheusText100.
	self
		assert: (self occurrencesOfSubstring: '# HELP requests_total ' in: text)
		equals: 1.
	self assert: (text includesSubstring: 'source="one"').
	self assert: (text includesSubstring: 'source="two"').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'HELP')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesHistogramBucketsCumulatively [

	| metric point snapshot text |
	point := OTHistogramDataPoint
		attributes: { 'http.method' -> 'GET' }
		count: 10
		sum: 42
		min: 1
		max: 25
		explicitBounds: #( 10 20 )
		bucketCounts: #( 2 3 5 )
		startTimestamp: DateAndTime unixEpoch
		timestamp: DateAndTime unixEpoch.
	metric := OTHistogramMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { point };
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		resource: OTResource empty
		measurements: #()
		metrics: { metric }
		collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: '# TYPE request_duration_milliseconds histogram').
	self assert: (text includesSubstring: 'request_duration_milliseconds_bucket{').
	self assert: (text includesSubstring: 'le="10"} 2').
	self assert: (text includesSubstring: 'le="20"} 5').
	self assert: (text includesSubstring: 'le="+Inf"} 10').
	self assert: (text includesSubstring: 'request_duration_milliseconds_sum{').
	self assert: (text includesSubstring: '} 42').
	self assert: (text includesSubstring: 'request_duration_milliseconds_count{').
	self assert: (text includesSubstring: '} 10')
]
